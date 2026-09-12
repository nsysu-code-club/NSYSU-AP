// ignore_for_file: avoid_print
@Tags(<String>['live'])
@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Hits the real selcrs.nsysu.edu.tw with a real student account.
/// Reads creds from env so they never live in the repo:
///
///     NSYSU_USER=...   # student id
///     NSYSU_PASS=...   # password
///     dart test -P live -r expanded
///
/// Set `NSYSU_HTTP_LOG=1` to also see every dio request URL.
void main() {
  final String username = Platform.environment['NSYSU_USER'] ?? '';
  final String password = Platform.environment['NSYSU_PASS'] ?? '';
  final bool hasCreds = username.isNotEmpty && password.isNotEmpty;
  final String? skipReason = hasCreds
      ? null
      : '[ALERT] NSYSU_USER / NSYSU_PASS env vars not set.';

  group('SelcrsHelper', () {
    setUpAll(() async {
      enableHttpLogging(SelcrsHelper.instance.dio);
      if (!hasCreds) {
        logInfo('SelcrsHelper', 'login', <String, dynamic>{
          'status': 'skipped',
          'reason': '[ALERT] NSYSU_USER / NSYSU_PASS env vars not set.',
        });
        return;
      }
      logInfo('SelcrsHelper', 'login', <String, dynamic>{
        'user': redact(username),
      });
      final ApiResult<GeneralResponse> result = await SelcrsHelper.instance
          .login(username: username, password: password);
      logStructured(
        tag:
            result is ApiSuccess<GeneralResponse> &&
                SelcrsHelper.instance.isLogin
            ? 'SUCCESS'
            : 'ERROR',
        scope: 'SelcrsHelper',
        action: 'login',
        fields: <String, dynamic>{
          'isLogin': SelcrsHelper.instance.isLogin,
          'result': result.runtimeType.toString(),
        },
      );
      expect(
        result,
        isA<ApiSuccess<GeneralResponse>>(),
        reason: 'login pre-condition for selcrs flow',
      );
    });

    test('login → success and isLogin flag flips', () {
      expect(SelcrsHelper.instance.isLogin, isTrue);
    }, skip: skipReason);

    test(
      'getUserInfo returns a UserInfo whose id matches NSYSU_USER',
      () async {
        logTarget('SelcrsHelper', 'getUserInfo', <String, dynamic>{
          'method': 'GET',
          'path': '/menu4/tools/changedat.asp',
        });
        final ApiResult<UserInfo> result = await SelcrsHelper.instance
            .getUserInfo();
        expect(result, isA<ApiSuccess<UserInfo>>());
        final UserInfo data = (result as ApiSuccess<UserInfo>).data;
        logSuccess('SelcrsHelper', 'getUserInfo', <String, dynamic>{
          'id': redact(data.id),
          'name': redact(data.name),
          'department': redact(data.department),
          'className': redact(data.className),
        });
        expect(data.id, equals(username));
        expect(data.name, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getCourseSemesterData returns at least one semester option',
      () async {
        logTarget('SelcrsHelper', 'getCourseSemesterData', <String, dynamic>{
          'method': 'POST',
          'path': '/menu4/query/stu_slt_up.asp',
        });
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
        logSuccess('SelcrsHelper', 'getCourseSemesterData', <String, dynamic>{
          'count': data.data.length,
          'first': data.data.firstOrNull?.text ?? '<none>',
        });
        expect(data.data, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getCourseData returns a CourseData for the current semester',
      () async {
        // Skip getCourseSemesterData() for picking the term — its first /
        // selected entry is often last term's (the most recent one with
        // any data), not the one the student is actually attending.
        // Derive from wall-clock instead.
        final Semester semester = currentAcademicSemester();
        logTarget('SelcrsHelper', 'getCourseData', <String, dynamic>{
          'method': 'POST',
          'path': '/menu4/query/stu_slt_data.asp',
          'semester': '${semester.year}${semester.value}',
          'semesterText': semester.text,
        });
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
        final CourseData data = (result as ApiSuccess<CourseData>).data;
        logSuccess('SelcrsHelper', 'getCourseData', <String, dynamic>{
          'coursesCount': data.courses.length,
          'timeCodesCount': data.timeCodes.length,
          'sampleCourse': data.courses.isEmpty
              ? '<none>'
              : redact(data.courses.first.title),
        });
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'getScoreSemesterData returns at least one year/semester option',
      () async {
        logTarget('SelcrsHelper', 'getScoreSemesterData', <String, dynamic>{
          'method': 'POST',
          'path': '/scoreqry/sco_query.asp',
          'action': '702',
        });
        final ApiResult<ScoreSemesterData> result = await SelcrsHelper.instance
            .getScoreSemesterData();
        expect(result, isA<ApiSuccess<ScoreSemesterData>>());
        final ScoreSemesterData data =
            (result as ApiSuccess<ScoreSemesterData>).data;
        logSuccess('SelcrsHelper', 'getScoreSemesterData', <String, dynamic>{
          'yearsCount': data.years.length,
          'semestersCount': data.semesters.length,
        });
        expect(data.years, isNotEmpty);
        expect(data.semesters, isNotEmpty);
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getScoreData returns ScoreData for the current semester',
      () async {
        // Same wall-clock override as getCourseData — selcrs's
        // `selectYearsIndex` / `selectSemesterIndex` track the most recent
        // graded term, which routinely points at last semester.
        final Semester semester = currentAcademicSemester();
        logTarget('SelcrsHelper', 'getScoreData', <String, dynamic>{
          'method': 'POST',
          'path': '/scoreqry/sco_query.asp',
          'action': '804',
          'year': semester.year,
          'semester': semester.value,
          'semesterText': semester.text,
        });
        final ApiResult<ScoreData> result = await SelcrsHelper.instance
            .getScoreData(
              year: semester.year,
              semester: semester.value,
              searchPreScore: true,
            );
        expect(result, isA<ApiSuccess<ScoreData>>());
        final ScoreData data = (result as ApiSuccess<ScoreData>).data;
        logSuccess('SelcrsHelper', 'getScoreData', <String, dynamic>{
          'scoresCount': data.scores.length,
        });
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
