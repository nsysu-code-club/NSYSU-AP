import 'dart:io';

/// Regression checks run only in a temporary repository.
Future<void> main() async {
  final String installerSource = await File(
    'tool/install_git_hooks.dart',
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
