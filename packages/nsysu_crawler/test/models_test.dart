import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  group('BusInfo', () {
    test('round-trips through JSON without losing fields', () {
      final BusInfo info = BusInfo(
        carId: 'A123',
        stopName: '校門口',
        routeId: 1,
        name: '校園公車',
        isOpenData: 'N',
        departure: '校門口',
        destination: '海洋學院',
        updateTime: '12:00',
      );
      final BusInfo restored = BusInfo.fromRawJson(info.toRawJson());
      expect(restored.carId, info.carId);
      expect(restored.routeId, info.routeId);
      expect(restored.stopName, info.stopName);
      expect(restored.destination, info.destination);
    });

    test('falls back to NameEn / DepartureEn / DestinationEn when zh missing',
        () {
      const String raw = '''
      {
        "CarID": "A1",
        "StopName": "Gate",
        "RouteID": 2,
        "NameEn": "Campus Bus",
        "isOpenData": "Y",
        "DepartureEn": "Gate",
        "DestinationEn": "Marine",
        "UpdateTime": null
      }
      ''';
      final BusInfo info = BusInfo.fromRawJson(raw);
      expect(info.name, 'Campus Bus');
      expect(info.departure, 'Gate');
      expect(info.destination, 'Marine');
    });
  });

  group('TuitionAndFees', () {
    test('keeps zh and en fields separate (no l10n logic in package)', () {
      final TuitionAndFees t = TuitionAndFees(
        titleZH: '學雜費',
        titleEN: 'Tuition',
        amount: '42000',
        paymentStatusZH: '繳費成功',
        paymentStatusEN: 'completed',
        dateOfPayment: '2026-01-01',
        serialNumber: 'X1',
      );
      expect(t.titleZH, '學雜費');
      expect(t.titleEN, 'Tuition');
      // Intentionally no `title` / `paymentStatus` / `isPayment` getters
      // here — those live in the host app's UI extension.
    });
  });

  group('ScoreSemesterData', () {
    test('falls back to default years/semesters when empty', () {
      final ScoreSemesterData data = ScoreSemesterData(
        years: <SemesterOptions>[],
        semesters: <SemesterOptions>[],
      );
      expect(data.year.value, '107');
      expect(data.semester.value, '1');
    });
  });
}
