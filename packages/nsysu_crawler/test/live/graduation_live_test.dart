@Tags(<String>['live'])
@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  final String username = Platform.environment['NSYSU_USER'] ?? '';
  final String password = Platform.environment['NSYSU_PASS'] ?? '';
  final bool hasCreds = username.isNotEmpty && password.isNotEmpty;
  final String? skipReason = hasCreds
      ? null
      : 'NSYSU_USER / NSYSU_PASS env vars not set';

  group('GraduationHelper', () {
    setUpAll(() async {
      enableHttpLogging(GraduationHelper.instance.dio);
      if (!hasCreds) {
        // ignore: avoid_print
        print('[live] no credentials in env — graduation tests will skip');
        return;
      }
      // ignore: avoid_print
      print(
        '[live] login as ${redact(username)} (gadchk graduation system)',
      );
      final ApiResult<GeneralResponse> result = await GraduationHelper.instance
          .login(username: username, password: password);
      // ignore: avoid_print
      print(
        '[live]   ← isLogin=${GraduationHelper.instance.isLogin} '
        'result=${result.runtimeType}',
      );
      expect(result, isA<ApiSuccess<GeneralResponse>>(),
          reason: 'login pre-condition for graduation flow');
    });

    test(
      'login → success and isLogin flag flips',
      () {
        expect(GraduationHelper.instance.isLogin, isTrue);
      },
      skip: skipReason,
    );

    test(
      'getGraduationReport returns a non-error result',
      () async {
        // ignore: avoid_print
        print('[live] GET /gadchk/gad_chk_stu_list.asp (graduation report)');
        final ApiResult<GraduationReportData?> result = await GraduationHelper
            .instance
            .getGraduationReport(username: username);
        expect(result, isA<ApiSuccess<GraduationReportData?>>());
        final GraduationReportData? data =
            (result as ApiSuccess<GraduationReportData?>).data;
        if (data == null) {
          // ignore: avoid_print
          print('[live]   ← null (no report — first-year / non-degree?)');
        } else {
          // ignore: avoid_print
          print(
            '[live]   ← missing=${data.missingRequiredCourse.length} '
            'general=${data.generalEducationCourse.length} '
            'other=${data.otherEducationsCourse.length} '
            '(detail credits redacted)',
          );
        }
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
