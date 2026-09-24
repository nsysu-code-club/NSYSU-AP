import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/utils.dart';

// Boundaries per 各級學校學生學年學期假期辦法 §2–3: the academic year starts on
// August 1; semester 1 is Aug 1 – Jan 31, semester 2 is Feb 1 – Jul 31.
void main() {
  group('Utils.semesterCodeFor', () {
    test('August 1 starts semester 1 of the new academic year', () {
      expect(Utils.semesterCodeFor(DateTime(2026, 8)), '1151');
    });

    test('September through December stay in semester 1', () {
      expect(Utils.semesterCodeFor(DateTime(2026, 9, 23)), '1151');
      expect(Utils.semesterCodeFor(DateTime(2026, 12, 31)), '1151');
    });

    test('January 31 still belongs to semester 1 of the previous AD year', () {
      expect(Utils.semesterCodeFor(DateTime(2027, 1, 31)), '1151');
    });

    test('February 1 through July 31 are semester 2', () {
      expect(Utils.semesterCodeFor(DateTime(2027, 2)), '1152');
      expect(Utils.semesterCodeFor(DateTime(2027, 7, 31)), '1152');
    });

    test('next August 1 rolls over to the following academic year', () {
      expect(Utils.semesterCodeFor(DateTime(2027, 8)), '1161');
    });

    test('never guesses a summer session (0 碩專暑 / 3 暑修)', () {
      for (int month = 1; month <= 12; month++) {
        final String code = Utils.semesterCodeFor(DateTime(2027, month));
        expect(code.substring(3), isIn(<String>['1', '2']), reason: '$month');
      }
    });

    test('currentSemesterCode is a 4-digit regular semester code', () {
      expect(Utils.currentSemesterCode, matches(RegExp(r'^\d{3}[12]$')));
    });
  });

  group('Utils.semesterCodeAt', () {
    test('switches at midnight Taiwan time on August 1', () {
      // 2026-07-31 23:59 and 2026-08-01 00:00 in Taiwan (UTC+8).
      expect(Utils.semesterCodeAt(DateTime.utc(2026, 7, 31, 15, 59)), '1142');
      expect(Utils.semesterCodeAt(DateTime.utc(2026, 7, 31, 16)), '1151');
    });

    test('switches at midnight Taiwan time on February 1', () {
      // 2027-01-31 23:59 and 2027-02-01 00:00 in Taiwan (UTC+8).
      expect(Utils.semesterCodeAt(DateTime.utc(2027, 1, 31, 15, 59)), '1151');
      expect(Utils.semesterCodeAt(DateTime.utc(2027, 1, 31, 16)), '1152');
    });

    test('does not depend on the device time zone', () {
      // The same instant in UTC and as a local DateTime gives the same code.
      final DateTime instant = DateTime.utc(2026, 7, 31, 16);
      expect(Utils.semesterCodeAt(instant.toLocal()), '1151');
    });
  });
}
