import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final List<_StepResult> results = <_StepResult>[];
  String crawlerLog = '';

  final String repoRoot = await _repoRoot();
  Directory.current = repoRoot;

  final bool useFvm =
      await _commandExists('fvm') && File('.fvmrc').existsSync();
  final List<String> dartCommand = useFvm
      ? <String>['fvm', 'dart']
      : <String>['dart'];

  results.add(
    await _runStep('Dart analyze', dartCommand.first, <String>[
      ...dartCommand.skip(1),
      'analyze',
      '--no-fatal-warnings',
      '.',
    ]),
  );
  if (results.last.failed) {
    _printSummary(results, crawlerLog);
    exit(results.last.exitCode);
  }

  results.add(
    await _runStep('Generate l10n', dartCommand.first, <String>[
      ...dartCommand.skip(1),
      'run',
      'slang',
    ]),
  );
  if (results.last.failed) {
    _printSummary(results, crawlerLog);
    exit(results.last.exitCode);
  }

  results.add(await _ensureL10nIsCommitted());
  if (results.last.failed) {
    _printSummary(results, crawlerLog);
    exit(results.last.exitCode);
  }

  final _StepResult crawlerResult = await _runStep(
    'Crawler tests',
    dartCommand.first,
    <String>[...dartCommand.skip(1), 'test'],
    workingDirectory: 'packages/nsysu_crawler',
  );
  results.add(crawlerResult);
  crawlerLog = crawlerResult.combinedOutput;
  if (crawlerResult.failed) {
    _printSummary(results, crawlerLog);
    exit(crawlerResult.exitCode);
  }

  _printSummary(results, crawlerLog);
  stdout.writeln('\nPre-commit checks passed.');
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
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln('\n==> $title');

  final Process process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: _processEnvironment(),
  );
  final StringBuffer outputBuffer = StringBuffer();
  final StringBuffer errorBuffer = StringBuffer();

  final Future<void> stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((String line) {
        stdout.writeln(line);
        outputBuffer.writeln(line);
      });
  final Future<void> stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((String line) {
        stderr.writeln(line);
        errorBuffer.writeln(line);
      });

  final int exitCode = await process.exitCode;
  await Future.wait(<Future<void>>[stdoutDone, stderrDone]);
  if (exitCode != 0) {
    stderr.writeln('\nERROR: "$title" failed with exit code $exitCode.');
  }
  return _StepResult(
    title: title,
    exitCode: exitCode,
    stdoutText: outputBuffer.toString(),
    stderrText: errorBuffer.toString(),
  );
}

Future<_StepResult> _ensureL10nIsCommitted() async {
  stdout.writeln('\n==> Check l10n generated files');

  final ProcessResult result = await Process.run('git', <String>[
    'diff',
    '--quiet',
    '--',
    'lib/l10n',
  ], environment: _processEnvironment());
  if (result.exitCode == 0) {
    stdout.writeln('No unstaged l10n changes detected.');
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
  return _StepResult(
    title: 'Check l10n generated files',
    exitCode: 1,
    stdoutText: changedFiles.stdout as String,
    stderrText: 'l10n generated files changed after generation.',
  );
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

void _printSummary(List<_StepResult> results, String crawlerLog) {
  stdout.writeln('\nPre-commit summary');
  stdout.writeln('==================');
  for (final _StepResult result in results) {
    final String status = result.succeeded ? 'SUCCESS' : 'FAILED';
    stdout.writeln('- $status ${result.title} (exit code ${result.exitCode})');
  }

  final bool hasFailure = results.any((_StepResult result) => result.failed);
  stdout.writeln(
    hasFailure
        ? '\nCommit blocked because at least one pre-commit check failed.'
        : '\nAll pre-commit checks succeeded. Commit can continue.',
  );

  stdout.writeln('\nCrawler test log');
  stdout.writeln('================');
  if (crawlerLog.trim().isEmpty) {
    stdout.writeln('Crawler tests did not run or produced no output.');
  } else {
    stdout.write(crawlerLog);
  }
}

class _StepResult {
  const _StepResult({
    required this.title,
    required this.exitCode,
    this.stdoutText = '',
    this.stderrText = '',
  });

  final String title;
  final int exitCode;
  final String stdoutText;
  final String stderrText;

  bool get succeeded => exitCode == 0;
  bool get failed => !succeeded;

  String get combinedOutput => <String>[
    stdoutText,
    stderrText,
  ].where((String text) => text.trim().isNotEmpty).join('\n');
}
