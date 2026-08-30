import 'dart:typed_data';

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
      expect(restored.busIds, <String>['A123']);
      expect(restored.isOperating, isTrue);
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

  group('BusTime', () {
    test('round-trips typed iBus fields and legacy fields', () {
      final BusTime time = BusTime(
        routeId: 901,
        stopId: '2059',
        name: '哈瑪星',
        arrivedTime: '3',
        realArrivedTime: '12:00',
        isGoBack: 'N',
        seqNo: 1,
        direction: BusDirection.go,
        arrivalStatus: BusArrivalStatus.minutes,
        etaMinutes: 3,
        scheduledTime: '12:00',
      );

      final BusTime restored = BusTime.fromRawJson(time.toRawJson());
      expect(restored.direction, BusDirection.go);
      expect(restored.arrivalStatus, BusArrivalStatus.minutes);
      expect(restored.etaMinutes, 3);
      expect(restored.scheduledTime, '12:00');
      expect(restored.arrivedTime, '3');
      expect(restored.isGoBack, 'N');
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

  group('StudentLeaveSemester', () {
    test('calculates the current academic semester', () {
      expect(
        StudentLeaveSemester.current(now: DateTime(2026, 7, 14)).code,
        '1142',
      );
      expect(StudentLeaveSemester.current(now: DateTime(2026, 8)).code, '1151');
      expect(
        StudentLeaveSemester.current(now: DateTime(2026, 12, 31)).code,
        '1151',
      );
      expect(StudentLeaveSemester.current(now: DateTime(2027)).code, '1151');
      expect(
        StudentLeaveSemester.current(now: DateTime(2027, 1, 31)).code,
        '1151',
      );
      expect(StudentLeaveSemester.current(now: DateTime(2027, 2)).code, '1152');
      expect(
        StudentLeaveSemester.current(now: DateTime(2027, 7, 31)).code,
        '1152',
      );
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

  group('StudentLeaveReviewStatus', () {
    test('keeps negative and exempt statuses out of approved', () {
      const Map<String, StudentLeaveReviewStatus> cases =
          <String, StudentLeaveReviewStatus>{
            '已通過': StudentLeaveReviewStatus.approved,
            '未確認': StudentLeaveReviewStatus.pending,
            'not confirmed': StudentLeaveReviewStatus.pending,
            'not-confirmed': StudentLeaveReviewStatus.pending,
            '審核中': StudentLeaveReviewStatus.pending,
            '未通過': StudentLeaveReviewStatus.rejected,
            '未完成': StudentLeaveReviewStatus.rejected,
            'not approved': StudentLeaveReviewStatus.rejected,
            'unapproved': StudentLeaveReviewStatus.rejected,
            'disapproved': StudentLeaveReviewStatus.rejected,
            'not completed': StudentLeaveReviewStatus.rejected,
            '未審核': StudentLeaveReviewStatus.pending,
            '不須確認': StudentLeaveReviewStatus.noReview,
            '免確認': StudentLeaveReviewStatus.noReview,
            'unexpected status': StudentLeaveReviewStatus.unknown,
          };

      for (final MapEntry<String, StudentLeaveReviewStatus> entry
          in cases.entries) {
        expect(
          resolveStudentLeaveReviewStatus(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('unknown and rejected records are not summarized as approved', () {
      const StudentLeaveRecord unknownRecord = StudentLeaveRecord(
        number: 'SL1',
        schoolYear: '115',
        semester: '1',
        category: '事假',
        dateRange: '',
        tutorStatus: '已通過',
        chairStatus: '免審核',
        instructorStatus: 'new server status',
        proofText: '無',
      );
      const StudentLeaveRecord rejectedRecord = StudentLeaveRecord(
        number: 'SL2',
        schoolYear: '115',
        semester: '1',
        category: '事假',
        dateRange: '',
        tutorStatus: '審核中',
        chairStatus: '未通過',
        instructorStatus: '已通過',
        proofText: '無',
      );

      expect(
        resolveStudentLeaveOverallStatus(unknownRecord),
        StudentLeaveReviewStatus.unknown,
      );
      expect(
        resolveStudentLeaveOverallStatus(rejectedRecord),
        StudentLeaveReviewStatus.rejected,
      );
    });
  });

  group('StudentLeaveFormConstraints', () {
    final StudentLeaveFormConstraints constraints = StudentLeaveFormConstraints(
      leaveTypes: const <StudentLeaveType>[
        StudentLeaveType(code: '12', name: '事假'),
      ],
      firstStartDate: DateTime(2026, 2),
      lastStartDate: DateTime(2026, 9, 30),
      firstEndDate: DateTime(2026, 7),
      lastEndDate: DateTime(2026, 9, 30),
      startTimes: const <String>['09:00', '09:30'],
      endTimes: const <String>['09:30', '10:00'],
      maxReasonLength: 5,
      allowedAttachmentExtensions: const <String>['pdf'],
      maxAttachmentBytes: 10,
    );

    test('accepts a request that matches the live form constraints', () {
      expect(constraints.validate(_leaveRequest()), isNull);
      expect(constraints.allowsAttachmentFileName('PROOF.PDF'), isTrue);
    });

    test('rejects date ranges or times with no possible end', () {
      StudentLeaveFormConstraints buildInvalid({
        required DateTime lastStartDate,
        required DateTime lastEndDate,
        required List<String> startTimes,
        required List<String> endTimes,
      }) => StudentLeaveFormConstraints(
        leaveTypes: const <StudentLeaveType>[
          StudentLeaveType(code: '12', name: '事假'),
        ],
        firstStartDate: DateTime(2026, 9),
        lastStartDate: lastStartDate,
        firstEndDate: DateTime(2026, 9),
        lastEndDate: lastEndDate,
        startTimes: startTimes,
        endTimes: endTimes,
        maxReasonLength: 100,
        allowedAttachmentExtensions: const <String>['pdf'],
        maxAttachmentBytes: 1024,
      );

      expect(
        () => buildInvalid(
          lastStartDate: DateTime(2026, 9, 2),
          lastEndDate: DateTime(2026, 9),
          startTimes: const <String>['09:00'],
          endTimes: const <String>['10:00'],
        ),
        throwsArgumentError,
      );
      expect(
        () => buildInvalid(
          lastStartDate: DateTime(2026, 9),
          lastEndDate: DateTime(2026, 9),
          startTimes: const <String>['10:00'],
          endTimes: const <String>['09:00'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects caller-controlled leave classes', () {
      expect(
        constraints.validate(_leaveRequest(leaveClass: 'admin')),
        StudentLeaveRequestIssue.invalidLeaveClass,
      );
    });

    test('rejects unsupported dates, times and long reasons', () {
      expect(
        constraints.validate(_leaveRequest(start: DateTime(2026, 1, 31, 9))),
        StudentLeaveRequestIssue.invalidDateRange,
      );
      expect(
        constraints.validate(_leaveRequest(end: DateTime(2026, 6, 30, 9, 30))),
        StudentLeaveRequestIssue.invalidDateRange,
      );
      expect(
        constraints.validate(_leaveRequest(start: DateTime(2026, 7, 1, 9, 15))),
        StudentLeaveRequestIssue.invalidTime,
      );
      expect(
        constraints.validate(_leaveRequest(reason: '超過五個字限制')),
        StudentLeaveRequestIssue.reasonTooLong,
      );
    });

    test('counts user-perceived Unicode characters like the Flutter field', () {
      const String family = '👨‍👩‍👦';
      final String fiveFamilies = List<String>.filled(5, family).join();
      final String sixFamilies = List<String>.filled(6, family).join();
      expect(constraints.validate(_leaveRequest(reason: fiveFamilies)), isNull);
      expect(
        constraints.validate(_leaveRequest(reason: sixFamilies)),
        StudentLeaveRequestIssue.reasonTooLong,
      );
    });

    test('rejects invalid, empty and oversized attachments', () {
      expect(
        constraints.validate(
          _leaveRequest(
            attachment: StudentLeaveAttachment(
              fileName: 'proof.jpg',
              bytes: Uint8List(1),
            ),
          ),
        ),
        StudentLeaveRequestIssue.invalidAttachment,
      );
      expect(
        constraints.validate(
          _leaveRequest(
            attachment: StudentLeaveAttachment(
              fileName: 'proof.pdf',
              bytes: Uint8List(0),
            ),
          ),
        ),
        StudentLeaveRequestIssue.emptyAttachment,
      );
      expect(
        constraints.validate(
          _leaveRequest(
            attachment: StudentLeaveAttachment(
              fileName: 'proof.pdf',
              bytes: Uint8List(11),
            ),
          ),
        ),
        StudentLeaveRequestIssue.attachmentTooLarge,
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

    test('treats unrecognized submit responses as unknown', () {
      const StudentLeaveSubmitResult result = StudentLeaveSubmitResult(
        statusCode: 200,
        body: '系統已收到資料，請稍後查詢處理狀態',
        confirmation: confirmation,
      );

      expect(result.looksSuccessful, isNull);
    });
  });
}

StudentLeaveRequest _leaveRequest({
  DateTime? start,
  DateTime? end,
  String reason = '事假',
  StudentLeaveAttachment? attachment,
  String leaveClass = '1',
}) {
  return StudentLeaveRequest(
    leaveClass: leaveClass,
    type: const StudentLeaveType(code: '12', name: '事假'),
    startDateTime: start ?? DateTime(2026, 7, 1, 9),
    endDateTime: end ?? DateTime(2026, 7, 1, 9, 30),
    reason: reason,
    attachment: attachment,
  );
}
