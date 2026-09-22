import 'dart:io';

Future<void> main() async {
  final String repoRoot = await _repoRoot();
  Directory.current = repoRoot;

  await _checkCustomHooksPath();
  await _writeStableHookWrappers();

  stdout.writeln(
    'Git hooks installed. pre-commit uses the installed copy of '
    'tool/pre_commit.dart. Reinstall from a trusted checkout to update it.',
  );
}

Future<String> _repoRoot() async {
  final ProcessResult result = await Process.run('git', <String>[
    'rev-parse',
    '--show-toplevel',
  ], environment: _processEnvironment());
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }

  final String script = Platform.script.toFilePath();
  return File(script).parent.parent.absolute.path;
}

Future<void> _checkCustomHooksPath() async {
  final ProcessResult currentHooksPath = await Process.run('git', <String>[
    'config',
    '--get',
    'core.hooksPath',
  ], environment: _processEnvironment());

  final String hooksPath = (currentHooksPath.stdout as String).trim();
  if (hooksPath.isEmpty) {
    return;
  }

  stderr.writeln(
    'core.hooksPath is configured as "$hooksPath". Installation stopped; '
    'existing hooks and Git configuration were preserved. '
    'Integrate tool/pre_commit.dart with your hook manager before retrying.',
  );
  exit(1);
}

Future<void> _writeStableHookWrappers() async {
  final ProcessResult result = await Process.run('git', <String>[
    'rev-parse',
    '--git-path',
    'hooks',
  ], environment: _processEnvironment());
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  final Directory hooksDirectory = Directory((result.stdout as String).trim());
  await hooksDirectory.create(recursive: true);
  const String wrapper = _installedHookWrapper;
  for (final String hookName in <String>['pre-commit']) {
    final File hookFile = File('${hooksDirectory.path}/$hookName');
    if (hookFile.existsSync()) {
      final String existing = await hookFile.readAsString();
      if (existing != wrapper && existing != _legacyHookWrapper) {
        stderr.writeln(
          'Existing pre-commit hook preserved. Integrate tool/pre_commit.dart manually.',
        );
        exit(1);
      }
    }

    // Install only when explicitly invoked from a trusted checkout. Branch
    // changes must never replace the code executed by an existing Git hook.
    final File source = File.fromUri(
      Platform.script.resolve('pre_commit.dart'),
    );
    final String payload = await source.readAsString();
    await File(
      '${hooksDirectory.path}/nsysu-pre-commit.dart',
    ).writeAsString(payload);
    await File(
      '${hooksDirectory.path}/nsysu-dart-path',
    ).writeAsString('${Platform.resolvedExecutable}\n');
    await hookFile.writeAsString(wrapper);
    if (!Platform.isWindows) {
      final ProcessResult chmod = await Process.run('chmod', <String>[
        '+x',
        hookFile.path,
      ], environment: _processEnvironment());
      stdout.write(chmod.stdout);
      stderr.write(chmod.stderr);
      if (chmod.exitCode != 0) {
        exit(chmod.exitCode);
      }
    }
  }
}

Map<String, String> _processEnvironment() {
  final Map<String, String> environment = Map<String, String>.of(
    Platform.environment,
  );
  final String pathSeparator = Platform.isWindows ? ';' : ':';
  final String currentPath = environment['PATH'] ?? '';
  final List<String> extraPaths = <String>[
    if (!Platform.isWindows) ...<String>[
      '/usr/bin',
      '/bin',
      '/opt/homebrew/bin',
      '/usr/local/bin',
    ],
  ];
  environment['PATH'] = <String>[
    ...extraPaths,
    currentPath,
  ].where((String path) => path.isNotEmpty).join(pathSeparator);
  return environment;
}

const String _installedHookWrapper =
    '#!/bin/sh\n'
    '# NSYSU installed pre-commit snapshot; reinstall to update.\n'
    'set -e\n'
    'export PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"\n'
    'hook_dir="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"\n'
    'repo_root="\$(git rev-parse --show-toplevel)"\n'
    'cd "\$repo_root"\n'
    'IFS= read -r dart_executable < "\$hook_dir/nsysu-dart-path"\n'
    'exec "\$dart_executable" "\$hook_dir/nsysu-pre-commit.dart"\n';

// Recognize the previous exact wrapper so reinstalling upgrades managed hooks
// while still refusing to overwrite a user's custom hook.
const String _legacyHookWrapper =
    '#!/bin/sh\n'
    '# Hook installed by git_hooks and normalized by tool/install_git_hooks.dart.\n'
    'set -e\n'
    '\n'
    'export PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"\n'
    '\n'
    'repo_root="\$(git rev-parse --show-toplevel)"\n'
    'cd "\$repo_root"\n'
    'hookName="\$(basename "\$0")"\n'
    '\n'
    'if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then\n'
    '  exec fvm dart bin/git_hooks.dart "\$hookName"\n'
    'fi\n'
    '\n'
    'if command -v dart >/dev/null 2>&1; then\n'
    '  exec dart bin/git_hooks.dart "\$hookName"\n'
    'fi\n'
    '\n'
    'echo "git_hooks > \$hookName"\n'
    'echo "Cannot find fvm or dart in PATH"\n'
    'exit 1\n';
