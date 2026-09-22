import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/config/constants.dart';

void main() {
  group('Constants.semesterCodeFor', () {
    test('August starts semester 1 of the new academic year', () {
      expect(Constants.semesterCodeFor(DateTime(2026, 8)), '1151');
    });

    test('September through December stay in semester 1', () {
      expect(Constants.semesterCodeFor(DateTime(2026, 9, 23)), '1151');
      expect(Constants.semesterCodeFor(DateTime(2026, 12, 31)), '1151');
    });

    test('January still belongs to semester 1 of the previous AD year', () {
      expect(Constants.semesterCodeFor(DateTime(2027, 1, 15)), '1151');
    });

    test('February through July are semester 2', () {
      expect(Constants.semesterCodeFor(DateTime(2027, 2)), '1152');
      expect(Constants.semesterCodeFor(DateTime(2027, 7, 31)), '1152');
    });

    test('next August rolls over to the following academic year', () {
      expect(Constants.semesterCodeFor(DateTime(2027, 8)), '1161');
    });

    test('currentSemesterCode is a 4-digit code', () {
      expect(Constants.currentSemesterCode, matches(RegExp(r'^\d{3}[12]$')));
    });
  });
}
