import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run check_l10n_key_parity.dart <left.json> <right.json>',
    );
    exitCode = 64;
    return;
  }

  final Set<String> leftKeys = _keyPaths(_readObject(arguments[0]));
  final Set<String> rightKeys = _keyPaths(_readObject(arguments[1]));
  final List<String> onlyLeft = leftKeys.difference(rightKeys).toList()..sort();
  final List<String> onlyRight = rightKeys.difference(leftKeys).toList()
    ..sort();

  if (onlyLeft.isNotEmpty || onlyRight.isNotEmpty) {
    if (onlyLeft.isNotEmpty) {
      stderr.writeln('Only in ${arguments[0]}: ${onlyLeft.join(', ')}');
    }
    if (onlyRight.isNotEmpty) {
      stderr.writeln('Only in ${arguments[1]}: ${onlyRight.join(', ')}');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Localization key parity: ${leftKeys.length} keys');
}

Map<String, Object?> _readObject(String path) {
  final Object? value = jsonDecode(File(path).readAsStringSync());
  if (value is! Map<String, Object?>) {
    throw FormatException('Expected a JSON object in $path');
  }
  return value;
}

Set<String> _keyPaths(Map<String, Object?> object, [String prefix = '']) {
  final Set<String> paths = <String>{};
  for (final MapEntry<String, Object?> entry in object.entries) {
    final String path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    paths.add(path);
    final Object? value = entry.value;
    if (value is Map<String, Object?>) {
      paths.addAll(_keyPaths(value, path));
    }
  }
  return paths;
}
