import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/api/parser/html_parser.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';

String _readFixture(String name) {
  return File('test/fixtures/$name').readAsStringSync();
}

void main() {
  group('parseUserInfo', () {
    test('should parse user info from HTML', () {
      final String html = _readFixture('user_info.html');
      final UserInfo result = parseUserInfo(html);

      expect(result.department, '資訊工程學系');
      expect(result.className, '資工三');
      expect(result.id, 'B123456789');
      expect(result.name, '王小明');
      expect(result.email, 'test@student.nsysu.edu.tw');
    });

    test('should return empty UserInfo for empty HTML', () {
      final UserInfo result = parseUserInfo('<html></html>');
      expect(result.id, '');
    });
  });

  group('parseCourseSemesterData', () {
    test('should parse semester options from HTML', () {
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
    test('should parse course table from HTML', () {
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
      expect(first.instructors?.first, '張教授');
      expect(first.location?.room, 'EC2001');
      expect(first.times?.length, 3);

      final Course second = result.courses[1];
      expect(second.code, 'CSE202');
      expect(second.title, '資料結構');
    });

    test('should parse English title when languageCode is en', () {
      final String html = _readFixture('course_data.html');
      final TimeCodeConfig config = TimeCodeConfig(
        timeCodes: <TimeCode>[],
      );

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
    test('should parse year and semester options', () {
      final String html = _readFixture('score_semester.html');
      final result = parseScoreSemesterData(html);

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
    test('should parse scores and detail from HTML', () {
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

  group('parseGraduationReport', () {
    test('should parse graduation report from HTML', () {
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

    test('should return null for invalid HTML', () {
      final result = parseGraduationReport('<html><body></body></html>');
      expect(result, isNull);
    });
  });

  group('parseTuitionData', () {
    test('should parse tuition data from HTML', () {
      final String html = _readFixture('tuition_data.html');
      final List<TuitionAndFees>? result = parseTuitionData(html);

      expect(result, isNotNull);
      expect(result!.length, 2);
      // reversed order
      expect(result[0].titleEN, '112-2 Tuition');
      expect(result[1].titleEN, '113-1 Tuition');
      expect(result[1].amount, '25,000');
      expect(result[1].serialNumber, '/print/12345');
      expect(result[1].paymentStatusZH, contains('繳費成功'));
    });

    test('should return null for empty data', () {
      final String html = _readFixture('tuition_empty.html');
      final result = parseTuitionData(html);
      expect(result, isNull);
    });
  });

  group('BusInfo JSON parsing', () {
    test('should parse bus info list from JSON', () {
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
    test('should parse bus time list from JSON', () {
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
