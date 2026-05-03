@Tags(<String>['live'])
@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  final String username = Platform.environment['NSYSU_USER'] ?? '';
  final String password = Platform.environment['NSYSU_PASS'] ?? '';
  final bool hasCreds = username.isNotEmpty && password.isNotEmpty;
  final String? skipReason = hasCreds
      ? null
      : 'NSYSU_USER / NSYSU_PASS env vars not set';

  group('GraduationHelper', () {
    setUpAll(() async {
      if (!hasCreds) return;
      final ApiResult<GeneralResponse> result = await GraduationHelper.instance
          .login(username: username, password: password);
      expect(
        result,
        isA<ApiSuccess<GeneralResponse>>(),
        reason: 'login pre-condition for graduation flow',
      );
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
        final ApiResult<GraduationReportData?> result = await GraduationHelper
            .instance
            .getGraduationReport(username: username);
        expect(result, isA<ApiSuccess<GraduationReportData?>>());
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
