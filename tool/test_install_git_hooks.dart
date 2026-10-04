import 'dart:convert';
import 'dart:io';

/// Regression checks run only in a temporary repository.
Future<void> main() async {
  final String installerSource = await File(
    'tool/install_git_hooks.dart',
  ).readAsString();
  final String preCommitSource = await File(
    'tool/pre_commit.dart',
  ).readAsString();
  final Directory temporary = await Directory.systemTemp.createTemp(
    'hook test-',
  );
  final Map<String, String> environment = <String, String>{
    'GIT_CONFIG_GLOBAL': '${temporary.path}/global.config',
    'GIT_CONFIG_NOSYSTEM': '1',
  };
  final String installer = '${temporary.path}/tool/install_git_hooks.dart';
  Future<ProcessResult> git(List<String> args) => Process.run(
    'git',
    args,
    workingDirectory: temporary.path,
    environment: environment,
  );
  Future<ProcessResult> install() => Process.run(
    Platform.resolvedExecutable,
    <String>[installer],
    workingDirectory: temporary.path,
    environment: environment,
  );
  void check(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  try {
    check((await git(<String>['init', '-q'])).exitCode == 0, 'git init');
    await Directory('${temporary.path}/tool').create();
    await File(installer).writeAsString(installerSource);
    final Directory dartTool = Directory('${temporary.path}/.dart_tool');
    await dartTool.create();
    final Directory slang = Directory('${temporary.path}/trusted-slang/bin');
    await slang.create(recursive: true);
    final File generator = File('${slang.path}/slang.dart');
    await generator.writeAsString(
      "import 'dart:io';\n"
      "import 'package:generator_helper/helper.dart';\n"
      'void main() { stdout.writeln(message); exit(24); }\n',
    );
    final File helper = File(
      '${temporary.path}/trusted-helper/lib/helper.dart',
    );
    await helper.parent.create(recursive: true);
    await helper.writeAsString("const message = 'trusted generator';\n");
    final File packageConfig = File('${dartTool.path}/package_config.json');
    await packageConfig.writeAsString(
      jsonEncode(<String, dynamic>{
        'configVersion': 2,
        'packages': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'slang',
            'rootUri': '../trusted-slang',
            'packageUri': 'lib/',
            'languageVersion': '3.10',
          },
          <String, dynamic>{
            'name': 'generator_helper',
            'rootUri': '../trusted-helper',
            'packageUri': 'lib/',
            'languageVersion': '3.10',
          },
        ],
      }),
    );
    final File source = File('${temporary.path}/tool/pre_commit.dart');
    const String trustedPayload =
        "import 'dart:io';\n"
        "void main() { stdout.writeln('trusted hook'); exit(23); }\n";
    await source.writeAsString(trustedPayload);
    final File unrelated = File('${temporary.path}/.git/hooks/pre-push');
    await unrelated.writeAsString('#!/bin/sh\nexit 42\n');
    check((await install()).exitCode == 0, 'fresh install');
    check(
      await unrelated.readAsString() == '#!/bin/sh\nexit 42\n',
      'preserve pre-push',
    );
    check((await install()).exitCode == 0, 'idempotent install');
    final File preCommit = File('${temporary.path}/.git/hooks/pre-commit');
    final File snapshot = File(
      '${temporary.path}/.git/hooks/nsysu-pre-commit.dart',
    );
    check(
      await snapshot.readAsString() == trustedPayload,
      'snapshot installed',
    );
    await source.writeAsString("void main() { throw 'untrusted worktree'; }");
    await Directory('${temporary.path}/bin').create();
    await File(
      '${temporary.path}/bin/git_hooks.dart',
    ).writeAsString("void main() { throw 'untrusted entrypoint'; }");
    final ProcessResult hook = await Process.run(
      'sh',
      <String>[preCommit.path],
      workingDirectory: temporary.path,
      environment: environment,
    );
    check(
      hook.exitCode == 23 && hook.stdout.toString().contains('trusted hook'),
      'branch scripts cannot replace installed payload; exit code preserved',
    );
    await snapshot.delete();
    final ProcessResult missingSnapshot = await Process.run(
      'sh',
      <String>[preCommit.path],
      workingDirectory: temporary.path,
      environment: environment,
    );
    check(
      missingSnapshot.exitCode != 0 &&
          !missingSnapshot.stderr.toString().contains('untrusted worktree'),
      'missing installed payload fails without executing worktree code',
    );
    await source.writeAsString('$trustedPayload// trusted update\n');
    check((await install()).exitCode == 0, 'explicit snapshot update');
    check(
      await snapshot.readAsString() == '$trustedPayload// trusted update\n',
      'explicit reinstall refreshes payload',
    );
    // Exercise the real hook with dependencies replaced after installation.
    await source.writeAsString(preCommitSource);
    check((await install()).exitCode == 0, 'install actual pre-commit payload');
    final String installedSource = await snapshot.readAsString();
    final File slangSnapshot = File(
      '${temporary.path}/.git/hooks/nsysu-slang.dill',
    );
    final List<int> installedSlang = await slangSnapshot.readAsBytes();
    await generator.writeAsString('this does not compile');
    check(
      (await install()).exitCode != 0,
      'compilation failure rejects install',
    );
    check(
      await snapshot.readAsString() == installedSource &&
          base64Encode(await slangSnapshot.readAsBytes()) ==
              base64Encode(installedSlang),
      'compilation failure preserves installed payloads',
    );
    const String attacker =
        "import 'dart:io';\n"
        "void main() { File('attack-ran').writeAsStringSync('executed'); }\n";
    await generator.writeAsString(attacker);
    await helper.writeAsString(
      "final message = throw 'replaced dependency';\n",
    );
    final File maliciousGenerator = File(
      '${temporary.path}/attacker/bin/slang.dart',
    );
    await maliciousGenerator.parent.create(recursive: true);
    await maliciousGenerator.writeAsString(attacker);
    await packageConfig.writeAsString(
      jsonEncode(<String, dynamic>{
        'configVersion': 2,
        'packages': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'slang',
            'rootUri': '../attacker',
            'packageUri': 'lib/',
            'languageVersion': '3.10',
          },
        ],
      }),
    );
    await File('${temporary.path}/pubspec.yaml').writeAsString(
      'name: fixture\ndependencies:\n  slang:\n    path: attacker\n',
    );
    final File translation = File('${temporary.path}/lib/l10n/en.json');
    await translation.parent.create(recursive: true);
    await translation.writeAsString('{"title":"Test"}\n');
    check(
      (await git(<String>['add', 'lib/l10n/en.json'])).exitCode == 0,
      'stage l10n to trigger generation',
    );
    Future<ProcessResult> runHook() => Process.run(
      'sh',
      <String>[preCommit.path],
      workingDirectory: temporary.path,
      environment: environment,
    );
    final ProcessResult isolated = await runHook();
    check(
      isolated.exitCode == 24 &&
          isolated.stdout.toString().contains('trusted generator') &&
          !File('${temporary.path}/attack-ran').existsSync(),
      'installed generator ignores replaced package graph and transitive code',
    );
    await slangSnapshot.delete();
    final ProcessResult missingGenerator = await runHook();
    check(
      missingGenerator.exitCode != 0 &&
          missingGenerator.stderr.toString().trim() ==
              'missing snapshot for git precommit, '
                  'please reinstall in the secured branch' &&
          !File('${temporary.path}/attack-ran').existsSync(),
      'missing generator blocks commit without package fallback',
    );
    await preCommit.writeAsString('#!/bin/sh\nexit 13\n');
    check((await install()).exitCode != 0, 'reject conflicting pre-commit');
    check(
      await preCommit.readAsString() == '#!/bin/sh\nexit 13\n',
      'preserve pre-commit',
    );
    for (final String scope in <String>['--global', '--local']) {
      await git(<String>['config', scope, 'core.hooksPath', 'custom-hooks']);
      final ProcessResult result = await install();
      check(
        result.exitCode != 0 &&
            result.stderr.toString().contains('core.hooksPath'),
        'clear $scope conflict',
      );
      check(
        (await git(<String>[
              'config',
              scope,
              '--get',
              'core.hooksPath',
            ])).stdout.toString().trim() ==
            'custom-hooks',
        'preserve $scope config',
      );
    }
    stdout.writeln('All hook installation regression checks passed.');
  } finally {
    await temporary.delete(recursive: true);
  }
}
