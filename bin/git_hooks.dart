// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:git_hooks/git_hooks.dart';

Future<void> main(List<String> arguments) async {
  GitHooks.call(arguments, <Git, UserBackFun>{Git.preCommit: _preCommit});
}

Future<bool> _preCommit() async {
  final bool useFvm =
      await _commandExists('fvm') && File('.fvmrc').existsSync();
  final String executable = useFvm ? 'fvm' : 'dart';
  final List<String> arguments = useFvm
      ? <String>['dart', 'run', 'tool/pre_commit.dart']
      : <String>['run', 'tool/pre_commit.dart'];

  final Process process = await Process.start(
    executable,
    arguments,
    environment: _processEnvironment(),
    mode: ProcessStartMode.inheritStdio,
  );
  return await process.exitCode == 0;
}

Future<bool> _commandExists(String command) async {
  final String lookupCommand = Platform.isWindows ? 'where' : 'which';
  final ProcessResult result = await Process.run(lookupCommand, <String>[
    command,
  ], environment: _processEnvironment());
  return result.exitCode == 0;
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
