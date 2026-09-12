import 'dart:io';

/// Regression checks run only in a temporary repository.
Future<void> main() async {
  final String installer = File('tool/install_git_hooks.dart').absolute.path;
  final Directory temporary = await Directory.systemTemp.createTemp(
    'hook-test-',
  );
  final Map<String, String> environment = <String, String>{
    'GIT_CONFIG_GLOBAL': '${temporary.path}/global.config',
    'GIT_CONFIG_NOSYSTEM': '1',
  };
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
    final File unrelated = File('${temporary.path}/.git/hooks/pre-push');
    await unrelated.writeAsString('#!/bin/sh\nexit 42\n');
    check((await install()).exitCode == 0, 'fresh install');
    check(
      await unrelated.readAsString() == '#!/bin/sh\nexit 42\n',
      'preserve pre-push',
    );
    check((await install()).exitCode == 0, 'idempotent install');
    final File preCommit = File('${temporary.path}/.git/hooks/pre-commit');
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
