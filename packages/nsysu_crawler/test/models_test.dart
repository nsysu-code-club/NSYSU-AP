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

    test(
      'falls back to NameEn / DepartureEn / DestinationEn when zh missing',
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
      },
    );
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

  group('StudentLeaveSemester', () {
    test('calculates the current academic semester', () {
      expect(
        StudentLeaveSemester.current(now: DateTime(2026, 7, 14)).code,
        '1142',
      );
      expect(StudentLeaveSemester.current(now: DateTime(2026, 8)).code, '1151');
    });

    test('builds recent semesters in descending order', () {
      final List<StudentLeaveSemester> semesters = StudentLeaveSemester.recent(
        count: 4,
        now: DateTime(2026, 7, 14),
      );
      expect(
        semesters.map((StudentLeaveSemester value) => value.code),
        <String>['1142', '1141', '1132', '1131'],
      );
    });
  });

  group('StudentLeaveSubmitResult', () {
    const StudentLeaveConfirmation confirmation = StudentLeaveConfirmation(
      sections: <StudentLeaveConfirmationSection>[],
      messages: <String>[],
      rawText: '',
    );

    test('detects successful submit responses', () {
      const StudentLeaveSubmitResult result = StudentLeaveSubmitResult(
        statusCode: 200,
        body: '假單新增成功',
        confirmation: confirmation,
      );

      expect(result.looksSuccessful, isTrue);
    });

    test('does not treat negative success words as successful', () {
      const List<String> bodies = <String>[
        '儲存不成功',
        '交易未完成',
        '假單送出失敗',
        '系統錯誤',
        '處理異常',
      ];

      for (final String body in bodies) {
        final StudentLeaveSubmitResult result = StudentLeaveSubmitResult(
          statusCode: 200,
          body: body,
          confirmation: confirmation,
        );
        expect(result.looksSuccessful, isFalse);
      }
    });
  });
}
