import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final List<_StepResult> results = <_StepResult>[];

  final String repoRoot = await _repoRoot();
  Directory.current = repoRoot;

  final bool useFvm =
      await _commandExists('fvm') && File('.fvmrc').existsSync();
  final List<String> dartCommand = useFvm
      ? <String>['fvm', 'dart']
      : <String>['dart'];

  if (await hasStagedL10nChanges()) {
    results.add(
      await _runStep('Generate l10n', dartCommand.first, <String>[
        ...dartCommand.skip(1),
        'run',
        'slang',
      ]),
    );
    if (results.last.failed) {
      _printSummary(results);
      exit(results.last.exitCode);
    }

    results.add(await _ensureL10nIsCommitted());
    if (results.last.failed) {
      _printSummary(results);
      exit(results.last.exitCode);
    }
  } else {
    stdout.writeln('\nNo staged changes in lib/l10n; skipping l10n checks.');
    results.addAll(const <_StepResult>[
      _StepResult(title: 'Generate l10n', exitCode: 0, skipped: true),
      _StepResult(
        title: 'Check l10n generated files',
        exitCode: 0,
        skipped: true,
      ),
    ]);
  }

  results.add(
    await _runStep('Dart analyze', dartCommand.first, <String>[
      ...dartCommand.skip(1),
      'analyze',
      '.',
    ]),
  );
  if (results.last.failed) {
    _printSummary(results);
    exit(results.last.exitCode);
  }

  _printSummary(results);
  stdout.writeln('\nPre-commit checks passed.');
}

/// Includes staged additions, modifications, deletions and moves into/out of l10n.
Future<bool> hasStagedL10nChanges({String? workingDirectory}) async {
  final List<String> arguments = <String>[
    'diff',
    '--cached',
    '--quiet',
    '--no-ext-diff',
    '--no-renames',
    '--',
    'lib/l10n',
  ];
  final ProcessResult result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
    environment: _processEnvironment(),
  );
  if (result.exitCode == 0) return false;
  if (result.exitCode == 1) return true;
  // Git errors must block the hook rather than silently skipping validation.
  throw ProcessException(
    'git',
    arguments,
    result.stderr.toString().trim(),
    result.exitCode,
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

Future<bool> _commandExists(String command) async {
  final String lookupCommand = Platform.isWindows ? 'where' : 'which';
  final ProcessResult result = await Process.run(lookupCommand, <String>[
    command,
  ], environment: _processEnvironment());
  return result.exitCode == 0;
}

Future<_StepResult> _runStep(
  String title,
  String executable,
  List<String> arguments,
) async {
  stdout.writeln('\n==> $title');

  final Process process = await Process.start(
    executable,
    arguments,
    environment: _processEnvironment(),
  );

  final Future<void> stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((String line) {
        stdout.writeln(line);
      });
  final Future<void> stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((String line) {
        stderr.writeln(line);
      });

  final int exitCode = await process.exitCode;
  await Future.wait(<Future<void>>[stdoutDone, stderrDone]);
  if (exitCode != 0) {
    stderr.writeln('\nERROR: "$title" failed with exit code $exitCode.');
  }
  return _StepResult(title: title, exitCode: exitCode);
}

Future<_StepResult> _ensureL10nIsCommitted() async {
  stdout.writeln('\n==> Check l10n generated files');

  final ProcessResult result = await Process.run('git', <String>[
    'diff',
    '--quiet',
    '--',
    'lib/l10n',
  ], environment: _processEnvironment());
  final ProcessResult untracked = await Process.run('git', <String>[
    'ls-files',
    '--others',
    '--exclude-standard',
    '--',
    'lib/l10n',
  ], environment: _processEnvironment());
  if (result.exitCode == 0 &&
      untracked.exitCode == 0 &&
      (untracked.stdout as String).trim().isEmpty) {
    stdout.writeln('No unstaged or untracked l10n changes detected.');
    return const _StepResult(title: 'Check l10n generated files', exitCode: 0);
  }

  stderr.writeln('\nERROR: l10n generated files changed after generation.');
  stderr.writeln('Please review and stage these files before committing:');

  final ProcessResult changedFiles = await Process.run('git', <String>[
    'diff',
    '--name-only',
    '--',
    'lib/l10n',
  ], environment: _processEnvironment());
  stderr.write(changedFiles.stdout);
  stderr.write(untracked.stdout);
  stderr.write(untracked.stderr);
  return const _StepResult(title: 'Check l10n generated files', exitCode: 1);
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

void _printSummary(List<_StepResult> results) {
  stdout.writeln('\nPre-commit summary');
  stdout.writeln('==================');
  for (final _StepResult result in results) {
    if (result.skipped) {
      stdout.writeln('- SKIPPED ${result.title} (no staged l10n changes)');
      continue;
    }
    final String status = result.succeeded ? 'SUCCESS' : 'FAILED';
    stdout.writeln('- $status ${result.title} (exit code ${result.exitCode})');
  }

  final bool hasFailure = results.any((_StepResult result) => result.failed);
  stdout.writeln(
    hasFailure
        ? '\nCommit blocked because at least one pre-commit check failed.'
        : '\nAll pre-commit checks succeeded. Commit can continue.',
  );
}

class _StepResult {
  const _StepResult({
    required this.title,
    required this.exitCode,
    this.skipped = false,
  });

  final String title;
  final int exitCode;
  final bool skipped;

  bool get succeeded => exitCode == 0;
  bool get failed => !succeeded;
}
