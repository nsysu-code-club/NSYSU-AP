@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:nsysu_crawler/src/parsers/html_parser.dart';
import 'package:test/test.dart';

String _readFixture(String name) {
  // dart test runs with the package directory as cwd, so fixtures live
  // at `test/fixtures/$name` relative to it.
  return File('test/fixtures/$name').readAsStringSync();
}

void main() {
  group('parseUserInfo', () {
    test('parses user info from HTML', () {
      final String html = _readFixture('user_info.html');
      final UserInfo result = parseUserInfo(html);

      expect(result.department, '資訊工程學系');
      expect(result.className, '資工三');
      expect(result.id, 'B123456789');
      expect(result.name, '王小明');
      expect(result.email, 'test@student.nsysu.edu.tw');
    });

    test('returns empty UserInfo for empty HTML', () {
      final UserInfo result = parseUserInfo('<html></html>');
      expect(result.id, '');
    });
  });

  group('parseCourseSemesterData', () {
    test('parses semester options from HTML', () {
      final String html = _readFixture('course_semester.html');
      final SemesterData result = parseCourseSemesterData(
        html,
        defaultSemester: const Semester(
          text: '113學年度第1學期',
          year: '113',
          value: '1',
        ),
      );

      expect(result.data.length, 4);
      expect(result.data[0].year, '113');
      expect(result.data[0].value, '1');
      expect(result.data[0].text, '113學年度第1學期');
      expect(result.data[1].year, '112');
      expect(result.data[1].value, '2');
    });
  });

  group('parseCourseData', () {
    test('parses course table from HTML (zh)', () {
      final String html = _readFixture('course_data.html');
      final TimeCodeConfig config = TimeCodeConfig(
        timeCodes: <TimeCode>[
          for (int i = 1; i <= 9; i++)
            TimeCode(
              title: '$i',
              startTime: '${7 + i}:00',
              endTime: '${8 + i}:00',
            ),
        ],
      );

      final CourseData result = parseCourseData(
        html,
        timeCodeConfig: config,
        languageCode: 'zh',
      );

      expect(result.courses.length, 2);

      final Course first = result.courses[0];
      expect(first.code, 'CSE101');
      expect(first.title, '程式設計');
      expect(first.units, '3');
      expect(first.instructors.first, '張教授');
      expect(first.location?.room, 'EC2001');
      expect(first.times.length, 3);

      final Course second = result.courses[1];
      expect(second.code, 'CSE202');
      expect(second.title, '資料結構');
    });

    test('parses English title when languageCode starts with en', () {
      final String html = _readFixture('course_data.html');
      const TimeCodeConfig config = TimeCodeConfig(timeCodes: <TimeCode>[]);

      final CourseData result = parseCourseData(
        html,
        timeCodeConfig: config,
        languageCode: 'en',
      );

      expect(result.courses[0].title, 'Programming');
      expect(result.courses[1].title, 'Data Structures');
    });
  });

  group('parseScoreSemesterData', () {
    test('parses year and semester options', () {
      final String html = _readFixture('score_semester.html');
      final ScoreSemesterData result = parseScoreSemesterData(html);

      expect(result.years.length, 3);
      expect(result.years[0].text, '113');
      expect(result.years[0].value, '113');
      expect(result.semesters.length, 2);
      expect(result.semesters[0].text, '上學期');
      expect(result.semesters[0].value, '1');
      expect(result.selectSemesterIndex, 1);
    });
  });

  group('parseScoreData', () {
    test('parses scores and detail from HTML', () {
      final String html = _readFixture('score_data.html');
      final ParsedScoreResult result = parseScoreData(html);

      expect(result.scores.length, 3);
      expect(result.scores[0].title, '程式設計');
      expect(result.scores[0].courseNumber, 'CSE101');
      expect(result.scores[0].middleScore, '85');
      expect(result.scores[0].finalScore, '90');

      expect(result.scores[2].title, '演算法');
      expect(result.scores[2].finalScore, '--');

      expect(result.missingFinalScoreCourseNumbers, contains('CSE303'));

      expect(result.detail.creditTaken, 9.0);
      expect(result.detail.creditEarned, 6.0);
      expect(result.detail.average, 86.0);
    });
  });

  group('resolveScoreType', () {
    test('returns numeric when all final scores parse as numbers', () {
      final List<Score> scores = <Score>[
        const Score(
          courseNumber: 'A',
          title: '',
          finalScore: '85',
          middleScore: '',
          units: '',
          hours: '',
          required: '',
          at: '',
          generalScore: '',
          semesterScore: '',
          remark: '',
        ),
      ];
      expect(resolveScoreType(scores), ScoreType.numeric);
    });

    test('returns gradePoint when any final score is a letter grade', () {
      final List<Score> scores = <Score>[
        const Score(
          courseNumber: 'A',
          title: '',
          finalScore: 'A+',
          middleScore: '',
          units: '',
          hours: '',
          required: '',
          at: '',
          generalScore: '',
          semesterScore: '',
          remark: '',
        ),
      ];
      expect(resolveScoreType(scores), ScoreType.gradePoint);
    });

    test('ignores empty / -- placeholders when classifying', () {
      final List<Score> scores = <Score>[
        const Score(
          courseNumber: 'A',
          title: '',
          finalScore: '--',
          middleScore: '',
          units: '',
          hours: '',
          required: '',
          at: '',
          generalScore: '',
          semesterScore: '',
          remark: '',
        ),
      ];
      expect(resolveScoreType(scores), ScoreType.numeric);
    });
  });

  group('parseGraduationReport', () {
    test('parses graduation report from HTML', () {
      final String html = _readFixture('graduation_report.html');
      final GraduationReportData? result = parseGraduationReport(html);

      expect(result, isNotNull);
      expect(result!.missingRequiredCourse.length, 2);
      expect(result.missingRequiredCourse[0].name, '線性代數');
      expect(result.missingRequiredCourse[0].credit, '3');
      expect(result.missingRequiredCourse[1].name, '作業系統');

      expect(result.generalEducationCourse.length, 2);
      expect(result.generalEducationCourse[0].type, '人文');
      expect(
        result.generalEducationCourse[0].generalEducationItem!.first.name,
        '哲學概論',
      );

      expect(result.otherEducationsCourse.length, 1);
      expect(result.otherEducationsCourse[0].name, '服務學習');

      expect(result.totalDescription, contains('目前累計學分數'));
    });

    test('returns null for invalid HTML', () {
      final GraduationReportData? result = parseGraduationReport(
        '<html><body></body></html>',
      );
      expect(result, isNull);
    });
  });

  group('parseTuitionData', () {
    test('parses tuition data from HTML', () {
      final String html = _readFixture('tuition_data.html');
      final List<TuitionAndFees>? result = parseTuitionData(html);

      expect(result, isNotNull);
      expect(result!.length, 2);
      // reversed order — newest first
      expect(result[0].titleEN, '112-2 Tuition');
      expect(result[1].titleEN, '113-1 Tuition');
      expect(result[1].amount, '25,000');
      expect(result[1].serialNumber, '/print/12345');
      expect(result[1].paymentStatusZH, contains('繳費成功'));
    });

    test('returns null for empty data', () {
      final String html = _readFixture('tuition_empty.html');
      final List<TuitionAndFees>? result = parseTuitionData(html);
      expect(result, isNull);
    });
  });

  group('parseStudentLeaveRecords', () {
    test('parses leave records and related links from HTML', () {
      final String html = _readFixture('student_leave_records.html');
      final List<StudentLeaveRecord> result = parseStudentLeaveRecords(html);

      expect(result.length, 2);
      expect(result[0].number, 'SL1130001');
      expect(result[0].schoolYear, '113');
      expect(result[0].semester, '1');
      expect(result[0].category, '病假');
      expect(result[0].dateRange, '2025-01-06 09:00 ~ 2025-01-06 12:00');
      expect(result[0].tutorStatus, '已通過');
      expect(result[0].chairStatus, '審核中');
      expect(result[0].instructorStatus, '免審核');
      expect(result[0].proofText, '病假證明.pdf');
      expect(
        result[0].proofUrl,
        'https://sis.nsysu.edu.tw/SLAMS/download.php?id=SL1130001',
      );
      expect(
        result[0].printUrl,
        'https://sis.nsysu.edu.tw/SLAMS/SLAMS_stuLeave_print.php?id=SL1130001',
      );
      expect(result[0].canDelete, isTrue);
      expect(result[1].number, 'SL1130002');
      expect(result[1].proofText, '無');
      expect(result[1].canDelete, isFalse);
      expect(result[1].proofUrl, isNull);
      expect(result[1].printUrl, isNull);
    });

    test('rejects untrusted proof and print links', () {
      final String html = _readFixture('student_leave_records.html');
      const List<String> untrustedLinks = <String>[
        'https://evil.example/collect',
        '//evil.example/collect',
        'http://sis.nsysu.edu.tw/SLAMS/download.php?id=1',
        'javascript:alert(1)',
        'https://sis.nsysu.edu.tw:444/SLAMS/download.php?id=1',
      ];

      for (final String href in untrustedLinks) {
        final List<StudentLeaveRecord> proofResult = parseStudentLeaveRecords(
          html.replaceFirst('download.php?id=SL1130001', href),
        );
        expect(proofResult.first.proofUrl, isNull, reason: href);

        final List<StudentLeaveRecord> printResult = parseStudentLeaveRecords(
          html.replaceFirst('SLAMS_stuLeave_print.php?id=SL1130001', href),
        );
        expect(printResult.first.printUrl, isNull, reason: href);
      }
    });

    test('allows SIS proof storage paths but not arbitrary SIS pages', () {
      final String html = _readFixture('student_leave_records.html');
      final List<StudentLeaveRecord> storedProof = parseStudentLeaveRecords(
        html.replaceFirst(
          'download.php?id=SL1130001',
          '/doctr02/2026/proof.pdf',
        ),
      );
      expect(
        storedProof.first.proofUrl,
        'https://sis.nsysu.edu.tw/doctr02/2026/proof.pdf',
      );

      final List<StudentLeaveRecord> arbitraryPage = parseStudentLeaveRecords(
        html.replaceFirst('download.php?id=SL1130001', '/SLAMS/other.php'),
      );
      expect(arbitraryPage.first.proofUrl, isNull);
    });
  });

  group('parseStudentLeaveFormConstraints', () {
    test('parses the SIS form options and conservative upload limit', () {
      final String html = _readFixture('student_leave_add_form.html');
      final StudentLeaveFormConstraints? result =
          parseStudentLeaveFormConstraints(html);

      expect(result, isNotNull);
      expect(
        result!.leaveTypes.map((StudentLeaveType type) => type.code),
        <String>['11', '12', '20'],
      );
      expect(
        result.leaveTypes.map((StudentLeaveType type) => type.name),
        <String>['公假', '事假', '心理不適'],
      );
      expect(result.firstStartDate, DateTime(2026, 2));
      expect(result.lastStartDate, DateTime(2026, 9));
      expect(result.firstEndDate, DateTime(2026, 7, 12));
      expect(result.lastEndDate, DateTime(2026, 9));
      expect(result.startTimes, <String>['09:00', '09:30', '10:00']);
      expect(result.endTimes, <String>['09:00', '09:30', '10:00']);
      expect(result.maxReasonLength, 100);
      expect(result.allowedAttachmentExtensions, <String>['pdf']);
      expect(result.maxAttachmentBytes, 1572864);
    });

    test(
      'returns null rather than guessing when required limits are absent',
      () {
        const String html = '''
      <form action="SLAMS_stuLeave_add_view.php">
        <select name="class_name"><option value="12">事假</option></select>
      </form>
      ''';

        expect(parseStudentLeaveFormConstraints(html), isNull);
      },
    );

    test('recovers unique controls reparented by malformed SIS markup', () {
      const String html = '''
      <form action="SLAMS_stuLeave_add_view.php"></form>
      <select name="class_name"><option value="12">事假</option></select>
      <input name="start_date" min="2026-02-01">
      <input name="end_date" max="2026-09-01">
      <select name="start_time"><option value="09:00">09:00</option></select>
      <select name="end_time"><option value="09:30">09:30</option></select>
      <textarea name="sla_cont" maxlength="100"></textarea>
      <p>僅限 PDF，2 MB</p>
      <input name="upload_file">
      <script>const maxSize = 1.5 * 1024 * 1024;</script>
      ''';

      final StudentLeaveFormConstraints? result =
          parseStudentLeaveFormConstraints(html);

      expect(result, isNotNull);
      expect(result!.leaveTypes.single.code, '12');
      expect(result.startTimes, <String>['09:00']);
      expect(result.endTimes, <String>['09:30']);
      expect(result.maxAttachmentBytes, 1572864);

      final String ambiguousHtml = html.replaceFirst(
        '<select name="class_name"><option value="12">事假</option></select>',
        '<select name="class_name"><option value="12">事假</option></select>\n'
            '<select name="class_name"><option value="13">病假</option></select>',
      );
      expect(parseStudentLeaveFormConstraints(ambiguousHtml), isNull);
    });

    test('rejects untrusted or ambiguous form structure', () {
      final String html = _readFixture('student_leave_add_form.html');
      expect(
        parseStudentLeaveFormConstraints(
          html.replaceFirst(
            'action="SLAMS_stuLeave_add_view.php"',
            'action="https://evil.example/SLAMS/SLAMS_stuLeave_add_view.php"',
          ),
        ),
        isNull,
      );
      expect(parseStudentLeaveFormConstraints('$html$html'), isNull);
      expect(
        parseStudentLeaveFormConstraints(
          html.replaceFirst(
            '<select name="class_name">',
            '<select name="class_name"><option value="13">病假</option>\n'
                '</select><select name="class_name">',
          ),
        ),
        isNull,
      );
    });

    test('rejects out-of-range time values instead of normalizing them', () {
      final String html = _readFixture('student_leave_add_form.html')
          .replaceAll('value="09:00"', 'value="24:00"')
          .replaceAll('value="09:30"', 'value="99:99"')
          .replaceAll('value="10:00"', 'value="12:60"');

      expect(parseStudentLeaveFormConstraints(html), isNull);
    });

    test('fails closed when the server advertises unsupported file types', () {
      final String html = _readFixture('student_leave_add_form.html')
          .replaceFirst(
            '<input type="file" name="upload_file">',
            '<input type="file" name="upload_file" accept=".pdf,.jpg">',
          );

      expect(parseStudentLeaveFormConstraints(html), isNull);
    });

    test('caps a server-advertised upload limit at the client hard limit', () {
      final String html = _readFixture(
        'student_leave_add_form.html',
      ).replaceFirst('1.5 * 1024 * 1024', '100 * 1024 * 1024');

      final StudentLeaveFormConstraints? result =
          parseStudentLeaveFormConstraints(html);

      expect(result, isNotNull);
      expect(result!.maxAttachmentBytes, 10 * 1024 * 1024);
    });
  });

  group('parseStudentLeaveConfirmForm', () {
    test('parses preview confirmation form fields from HTML', () {
      final String html = _readFixture('student_leave_confirm_form.html');
      final StudentLeaveConfirmForm? result = parseStudentLeaveConfirmForm(
        html,
      );

      expect(result, isNotNull);
      expect(result!.action, 'SLAMS_stuLeave_add_act.php');
      expect(result.fields['Lclass'], 'stu');
      expect(result.fields['sub_Lclass'], 'student');
      expect(result.fields['s_date'], '2025-01-06');
      expect(result.fields['s_time'], '09:00');
      expect(result.fields['e_date'], '2025-01-06');
      expect(result.fields['e_time'], '12:00');
      expect(result.fields['sla_cont'], '身體不適');
      expect(result.fields['class_name'], '02');

      final StudentLeaveConfirmation confirmation =
          parseStudentLeaveConfirmation(html);
      expect(confirmation.noticeLines, hasLength(5));
      expect(confirmation.noticeLines[0], '請同學注意以下說明：');
      expect(confirmation.noticeLines[1], startsWith('(1)不需課程請假期間：'));
      expect(confirmation.noticeLines[2], contains('請同學檢查請假單內容是否正確'));
      expect(confirmation.noticeLines[3], contains('系所主任代替導師'));
      expect(confirmation.noticeLines[4], contains('自動mail通知'));
    });

    test('falls back to broad notice search when structure is unknown', () {
      const String html = '''
      <html>
        <body>
          <section>
            請同學注意以下說明：<br>
            (1)不需課程請假期間：YYYY/MM/DD至YYYY/MM/DD。<br>
            (2)請同學檢查請假單內容是否正確。
          </section>
        </body>
      </html>
      ''';

      final StudentLeaveConfirmation confirmation =
          parseStudentLeaveConfirmation(html);

      expect(confirmation.noticeLines, hasLength(3));
      expect(confirmation.noticeLines[0], '請同學注意以下說明：');
      expect(confirmation.noticeLines[1], startsWith('(1)不需課程請假期間：'));
      expect(confirmation.noticeLines[2], contains('檢查請假單內容是否正確'));
    });

    test('keeps checked radio and checkbox values only', () {
      const String html = '''
      <html>
        <body>
          <form action="SLAMS_stuLeave_add_act.php">
            <input type="hidden" name="Lclass" value="stu" />
            <input type="hidden" name="sub_Lclass" value="student" />
            <input type="hidden" name="s_date" value="2025-01-06" />
            <input type="hidden" name="s_time" value="09:00" />
            <input type="hidden" name="e_date" value="2025-01-06" />
            <input type="hidden" name="e_time" value="12:00" />
            <input type="radio" name="confirm" value="N" />
            <input type="radio" name="confirm" value="Y" checked />
            <input type="checkbox" name="notify" value="N" />
            <input type="checkbox" name="courseFlag" value="selected" checked />
            <input type="checkbox" name="courseFlag" value="unselected" />
          </form>
        </body>
      </html>
      ''';

      final StudentLeaveConfirmForm? result = parseStudentLeaveConfirmForm(
        html,
      );

      expect(result, isNotNull);
      expect(result!.fields['confirm'], 'Y');
      expect(result.fields['notify'], isNull);
      expect(result.fields['courseFlag'], 'selected');
    });

    test('rejects untrusted or ambiguous confirmation forms', () {
      final String html = _readFixture('student_leave_confirm_form.html');
      expect(
        parseStudentLeaveConfirmForm(
          html.replaceFirst(
            'action="SLAMS_stuLeave_add_act.php"',
            'action="https://evil.example/collect"',
          ),
        ),
        isNull,
      );
      expect(parseStudentLeaveConfirmForm('$html$html'), isNull);
      expect(
        parseStudentLeaveConfirmForm(
          html.replaceFirst(
            '<input type="hidden" name="Lclass" value="stu" />',
            '<input type="hidden" name="Lclass" value="stu" />\n'
                '<input type="hidden" name="Lclass" value="duplicate" />',
          ),
        ),
        isNull,
      );
      final StudentLeaveConfirmForm? disabledDuplicate =
          parseStudentLeaveConfirmForm(
            html.replaceFirst(
              '<input type="hidden" name="Lclass" value="stu" />',
              '<input type="hidden" name="Lclass" value="stu" />\n'
                  '<input type="hidden" name="Lclass" value="ignored" '
                  'disabled />',
            ),
          );
      expect(disabledDuplicate, isNotNull);
      expect(disabledDuplicate!.fields['Lclass'], 'stu');

      final StudentLeaveConfirmForm? effectivelyDisabled =
          parseStudentLeaveConfirmForm(
            html.replaceFirst(
              '<input type="hidden" name="Lclass" value="stu" />',
              '''
<input type="hidden" name="Lclass" value="stu" />
<fieldset disabled>
  <input name="Lclass" value="fieldset-ignored" />
</fieldset>
<input name="otherOwner" value="ignored" form="different-form" />
<select name="disabledChoice">
  <optgroup disabled>
    <option selected value="ignored">ignored</option>
  </optgroup>
</select>
''',
            ),
          );
      expect(effectivelyDisabled, isNotNull);
      expect(effectivelyDisabled!.fields['Lclass'], 'stu');
      expect(effectivelyDisabled.fields['otherOwner'], isNull);
      expect(effectivelyDisabled.fields['disabledChoice'], isNull);
    });
  });

  group('BusInfo JSON parsing', () {
    test('parses bus info list from JSON', () {
      final String json = _readFixture('bus_info.json');
      final List<BusInfo>? result = BusInfo.fromRawList(json);

      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].name, '紅1');
      expect(result[0].routeId, 100);
      expect(result[0].stopName, '西子灣站');
      expect(result[1].name, '紅2');
      expect(result[1].destination, '左營站');
    });
  });

  group('BusTime JSON parsing', () {
    test('parses bus time list from JSON', () {
      final String json = _readFixture('bus_time.json');
      final List<BusTime>? result = BusTime.fromRawList(json);

      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].name, '西子灣站');
      expect(result[0].arrivedTime, '08:30');
      expect(result[0].realArrivedTime, '08:32');
      expect(result[0].seqNo, 1);
      expect(result[1].name, '鼓山站');
    });
  });
}
