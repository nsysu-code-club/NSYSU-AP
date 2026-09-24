// ignore_for_file: avoid_print
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
      : '[ALERT] NSYSU_USER / NSYSU_PASS env vars not set.';

  group('GraduationHelper', () {
    setUpAll(() async {
      enableHttpLogging(GraduationHelper.instance.dio);
      if (!hasCreds) {
        logInfo('GraduationHelper', 'login', <String, dynamic>{
          'status': 'skipped',
          'reason': '[ALERT] NSYSU_USER / NSYSU_PASS env vars not set.',
        });
        return;
      }
      logInfo('GraduationHelper', 'login', <String, dynamic>{
        'user': redact(username),
      });
      final ApiResult<GeneralResponse> result = await GraduationHelper.instance
          .login(username: username, password: password);
      logStructured(
        tag:
            result is ApiSuccess<GeneralResponse> &&
                GraduationHelper.instance.isLogin
            ? 'SUCCESS'
            : 'ERROR',
        scope: 'GraduationHelper',
        action: 'login',
        fields: <String, dynamic>{
          'isLogin': GraduationHelper.instance.isLogin,
          'result': result.runtimeType.toString(),
        },
      );
      expect(
        result,
        isA<ApiSuccess<GeneralResponse>>(),
        reason: 'login pre-condition for graduation flow',
      );
    });

    test('login → success and isLogin flag flips', () {
      expect(GraduationHelper.instance.isLogin, isTrue);
    }, skip: skipReason);

    test(
      'getGraduationReport returns a non-error result',
      () async {
        logTarget('GraduationHelper', 'getGraduationReport', <String, dynamic>{
          'method': 'GET',
          'path': '/gadchk/gad_chk_stu_list.asp',
        });
        final ApiResult<GraduationReportData?> result = await GraduationHelper
            .instance
            .getGraduationReport(username: username);
        expect(result, isA<ApiSuccess<GraduationReportData?>>());
        final GraduationReportData? data =
            (result as ApiSuccess<GraduationReportData?>).data;
        if (data == null) {
          logInfo('GraduationHelper', 'getGraduationReport', <String, dynamic>{
            'result': 'null',
            'note': 'no report (first-year or non-degree)',
          });
        } else {
          logSuccess(
            'GraduationHelper',
            'getGraduationReport',
            <String, dynamic>{
              'missingRequired': data.missingRequiredCourse.length,
              'generalEducation': data.generalEducationCourse.length,
              'otherEducations': data.otherEducationsCourse.length,
            },
          );
        }
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
