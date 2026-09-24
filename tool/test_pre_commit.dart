import 'dart:io';

import 'pre_commit.dart' as hook;

/// Exercises real Git index/worktree differences without touching this repo.
Future<void> main() async {
  final Directory temporary = await Directory.systemTemp.createTemp(
    'pre-commit-staged-test-',
  );
  final Map<String, String> environment = <String, String>{
    'GIT_CONFIG_GLOBAL': '${temporary.path}/global.config',
    'GIT_CONFIG_NOSYSTEM': '1',
  };
  int checks = 0;

  Future<void> git(List<String> arguments) async {
    final ProcessResult result = await Process.run(
      'git',
      arguments,
      workingDirectory: temporary.path,
      environment: environment,
    );
    if (result.exitCode != 0) {
      throw StateError('git ${arguments.join(' ')}: ${result.stderr}');
    }
  }

  Future<void> write(String path, String content) async {
    final File file = File('${temporary.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> expectChanges(bool expected, String scenario) async {
    final bool actual = await hook.hasStagedL10nChanges(
      workingDirectory: temporary.path,
    );
    if (actual != expected) throw StateError(scenario);
    checks++;
    stdout.writeln('PASS $scenario');
  }

  Future<void> reset() => git(<String>['reset', '--mixed', '-q', 'HEAD']);

  try {
    await git(<String>['init', '-q', '--template=']);
    await expectChanges(false, 'empty initial index skips l10n');
    await write('lib/l10n/en.json', '{"title":"Hello"}\n');
    await write('lib/example.dart', 'void main() {}\n');
    await git(<String>['add', '.']);
    await expectChanges(true, 'initial staged l10n triggers generation');
    await git(<String>[
      '-c',
      'user.name=Hook Test',
      '-c',
      'user.email=hook-test@example.invalid',
      '-c',
      'commit.gpgsign=false',
      'commit',
      '-q',
      '--no-verify',
      '-m',
      'fixture',
    ]);
    await expectChanges(false, 'clean index skips l10n');

    await write('lib/l10n/en.json', '{"title":"Changed"}\n');
    await write('lib/l10n/ja.json', '{"title":"Japanese"}\n');
    await write('lib/l10n/strings_ja.g.dart', '// untracked generated file\n');
    await write('lib/example.dart', 'void main() { /* staged */ }\n');
    await git(<String>['add', 'lib/example.dart']);
    await expectChanges(false, 'only staged Dart ignores dirty/untracked l10n');
    await git(<String>['add', 'lib/l10n/en.json']);
    await expectChanges(true, 'staged translation edit triggers generation');
    await write('lib/l10n/en.json', '{"title":"Another working edit"}\n');
    await expectChanges(true, 'partially staged translation still triggers');

    await reset();
    await git(<String>['add', 'lib/l10n/ja.json']);
    await expectChanges(true, 'staged new translation triggers');
    await reset();
    await git(<String>['add', 'lib/l10n/strings_ja.g.dart']);
    await expectChanges(true, 'staged generated file triggers');
    await reset();
    await File('${temporary.path}/lib/l10n/en.json').delete();
    await expectChanges(false, 'unstaged deletion skips l10n');
    await git(<String>['add', '-u', '--', 'lib/l10n']);
    await expectChanges(true, 'staged deletion triggers');

    await reset();
    await git(<String>['restore', '--worktree', '--', 'lib/l10n/en.json']);
    await git(<String>['mv', 'lib/l10n/en.json', 'lib/l10n/english.json']);
    await expectChanges(true, 'staged rename within l10n triggers');
    await git(<String>['mv', 'lib/l10n/english.json', 'lib/english.json']);
    await expectChanges(true, 'staged move out of l10n triggers');
    await reset();
    await git(<String>['restore', '--worktree', '--', 'lib/l10n/en.json']);
    await git(<String>['mv', 'lib/example.dart', 'lib/l10n/example.dart']);
    await expectChanges(true, 'staged move into l10n triggers');

    final Directory notARepo = await Directory.systemTemp.createTemp(
      'pre-commit-not-a-repo-',
    );
    try {
      bool failed = false;
      try {
        await hook.hasStagedL10nChanges(workingDirectory: notARepo.path);
      } on ProcessException {
        failed = true;
      }
      if (!failed) throw StateError('Git errors must not silently skip checks');
      checks++;
      stdout.writeln('PASS Git errors do not silently skip validation');
    } finally {
      await notARepo.delete(recursive: true);
    }
    stdout.writeln('All $checks staged l10n regression checks passed.');
  } finally {
    await temporary.delete(recursive: true);
  }
}
