import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  group('redact', () {
    test('null → <null>', () {
      expect(redact(null), equals('<null>'));
    });

    test('empty → <empty>', () {
      expect(redact(''), equals('<empty>'));
    });

    test('single char → 2 bullets', () {
      expect(redact('A'), equals('••'));
    });

    test('two chars → first + bullet', () {
      expect(redact('AB'), equals('A•'));
    });

    test('three chars → first + bullet + last', () {
      expect(redact('ABC'), equals('A•C'));
    });

    test('long string → first + bullets + last', () {
      expect(redact('B12345678'), equals('B•••••••8'));
    });
  });
}
