import 'package:ap_common_core/ap_common_core.dart';
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

  group('currentAcademicSemester', () {
    test('March → previous ROC year, semester 2 (spring)', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2026, 3, 15));
      expect(sem.year, equals('114'));
      expect(sem.value, equals('2'));
      expect(sem.text, contains('114'));
      expect(sem.text, contains('二'));
    });

    test('June → still previous ROC year, semester 2', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2026, 6, 1));
      expect(sem.year, equals('114'));
      expect(sem.value, equals('2'));
    });

    test('September → still previous ROC year, semester 2 (last day)', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2026, 9, 30));
      expect(sem.year, equals('114'));
      expect(sem.value, equals('2'));
    });

    test('October → current ROC year, semester 1 (fall)', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2026, 10, 1));
      expect(sem.year, equals('115'));
      expect(sem.value, equals('1'));
      expect(sem.text, contains('一'));
    });

    test('December → current ROC year, semester 1', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2026, 12, 31));
      expect(sem.year, equals('115'));
      expect(sem.value, equals('1'));
    });

    test('January → previous ROC year, semester 1 (still in fall term)', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2027, 1, 15));
      expect(sem.year, equals('115'));
      expect(sem.value, equals('1'));
    });

    test('February → previous ROC year, semester 1', () {
      final Semester sem =
          currentAcademicSemester(DateTime(2027, 2, 28));
      expect(sem.year, equals('115'));
      expect(sem.value, equals('1'));
    });
  });
}
