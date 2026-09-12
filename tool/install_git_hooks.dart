import 'dart:io';

Future<void> main() async {
  final String repoRoot = await _repoRoot();
  Directory.current = repoRoot;

  await _checkCustomHooksPath();
  await _writeStableHookWrappers();

  stdout.writeln(
    'Git hooks installed by git_hooks. pre-commit will run tool/pre_commit.dart before each commit.',
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
  for (final String hookName in <String>['pre-commit']) {
    final File hookFile = File('${hooksDirectory.path}/$hookName');
    if (hookFile.existsSync() &&
        await hookFile.readAsString() != _hookWrapper) {
      stderr.writeln(
        'Existing pre-commit hook preserved. Integrate tool/pre_commit.dart manually.',
      );
      exit(1);
    }

    await hookFile.writeAsString(_hookWrapper);
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

const String _hookWrapper =
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
