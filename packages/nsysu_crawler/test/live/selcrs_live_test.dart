@Tags(<String>['live'])
@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_dio_logging.dart';

/// Hits the real selcrs.nsysu.edu.tw. Excluded by default.
///
/// Run with: `NSYSU_USER=... NSYSU_PASS=... dart test -P live -r expanded`
void main() {
  final String username = Platform.environment['NSYSU_USER'] ?? '';
  final String password = Platform.environment['NSYSU_PASS'] ?? '';
  final bool hasCreds = username.isNotEmpty && password.isNotEmpty;
  final String? skipReason = hasCreds
      ? null
      : 'NSYSU_USER / NSYSU_PASS env vars not set';

  group('SelcrsHelper', () {
    setUpAll(() async {
      enableRequestLogging(SelcrsHelper.instance.dio);
      if (!hasCreds) return;
      final ApiResult<GeneralResponse> result = await SelcrsHelper.instance
          .login(username: username, password: password);
      expect(
        result,
        isA<ApiSuccess<GeneralResponse>>(),
        reason: 'login pre-condition for selcrs flow',
      );
    });

    test(
      'login → success and isLogin flag flips',
      () {
        expect(SelcrsHelper.instance.isLogin, isTrue);
      },
      skip: skipReason,
    );

    test(
      'getUserInfo returns a UserInfo whose id matches NSYSU_USER',
      () async {
        final ApiResult<UserInfo> result = await SelcrsHelper.instance
            .getUserInfo();
        expect(result, isA<ApiSuccess<UserInfo>>());
        final UserInfo data = (result as ApiSuccess<UserInfo>).data;
        expect(data.id, equals(username));
        expect(data.name, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getCourseSemesterData returns at least one semester option',
      () async {
        final ApiResult<SemesterData> result = await SelcrsHelper.instance
            .getCourseSemesterData(
              defaultSemester: const Semester(
                year: '113',
                value: '1',
                text: '113 上學期',
              ),
            );
        expect(result, isA<ApiSuccess<SemesterData>>());
        final SemesterData data = (result as ApiSuccess<SemesterData>).data;
        expect(data.data, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getCourseData returns a CourseData for the latest semester',
      () async {
        final ApiResult<SemesterData> semesterResult = await SelcrsHelper
            .instance
            .getCourseSemesterData(
              defaultSemester: const Semester(
                year: '113',
                value: '1',
                text: '113 上學期',
              ),
            );
        final SemesterData semesterData =
            (semesterResult as ApiSuccess<SemesterData>).data;
        final Semester semester = semesterData.data.first;
        final ApiResult<CourseData> result = await SelcrsHelper.instance
            .getCourseData(
              username: username,
              timeCodeConfig: const TimeCodeConfig(
                timeCodes: <TimeCode>[
                  TimeCode(title: 'A', startTime: '08:10', endTime: '09:00'),
                  TimeCode(title: '1', startTime: '09:10', endTime: '10:00'),
                  TimeCode(title: '2', startTime: '10:10', endTime: '11:00'),
                  TimeCode(title: '3', startTime: '11:10', endTime: '12:00'),
                  TimeCode(title: '4', startTime: '12:10', endTime: '13:00'),
                  TimeCode(title: '5', startTime: '13:10', endTime: '14:00'),
                  TimeCode(title: '6', startTime: '14:10', endTime: '15:00'),
                  TimeCode(title: '7', startTime: '15:10', endTime: '16:00'),
                  TimeCode(title: '8', startTime: '16:10', endTime: '17:00'),
                  TimeCode(title: '9', startTime: '17:10', endTime: '18:00'),
                  TimeCode(title: 'B', startTime: '18:10', endTime: '19:00'),
                  TimeCode(title: 'C', startTime: '19:10', endTime: '20:00'),
                  TimeCode(title: 'D', startTime: '20:10', endTime: '21:00'),
                  TimeCode(title: 'E', startTime: '21:10', endTime: '22:00'),
                ],
              ),
              semester: '${semester.year}${semester.value}',
            );
        expect(result, isA<ApiSuccess<CourseData>>());
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'getScoreSemesterData returns at least one year/semester option',
      () async {
        final ApiResult<ScoreSemesterData> result = await SelcrsHelper.instance
            .getScoreSemesterData();
        expect(result, isA<ApiSuccess<ScoreSemesterData>>());
        final ScoreSemesterData data =
            (result as ApiSuccess<ScoreSemesterData>).data;
        expect(data.years, isNotEmpty);
        expect(data.semesters, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getScoreData returns ScoreData for the currently-selected semester',
      () async {
        final ApiResult<ScoreSemesterData> semResult = await SelcrsHelper
            .instance
            .getScoreSemesterData();
        final ScoreSemesterData semData =
            (semResult as ApiSuccess<ScoreSemesterData>).data;
        final ApiResult<ScoreData> result = await SelcrsHelper.instance
            .getScoreData(
              year: semData.year.value,
              semester: semData.semester.value,
            );
        expect(result, isA<ApiSuccess<ScoreData>>());
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
