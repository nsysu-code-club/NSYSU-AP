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

  group('TuitionHelper', () {
    setUpAll(() async {
      enableHttpLogging(TuitionHelper.instance.dio);
      if (!hasCreds) {
        logInfo('TuitionHelper', 'login', <String, dynamic>{
          'status': 'skipped',
          'reason': '[ALERT] NSYSU_USER / NSYSU_PASS env vars not set.',
        });
        return;
      }
      logInfo('TuitionHelper', 'login', <String, dynamic>{
        'user': redact(username),
      });
      final ApiResult<GeneralResponse> result = await TuitionHelper.instance
          .login(username: username, password: password);
      logStructured(
        tag:
            result is ApiSuccess<GeneralResponse> &&
                TuitionHelper.instance.isLogin
            ? 'SUCCESS'
            : 'ERROR',
        scope: 'TuitionHelper',
        action: 'login',
        fields: <String, dynamic>{
          'isLogin': TuitionHelper.instance.isLogin,
          'result': result.runtimeType.toString(),
        },
      );
      expect(
        result,
        isA<ApiSuccess<GeneralResponse>>(),
        reason: 'login pre-condition for tuition flow',
      );
    });

    test('login → success and isLogin flag flips', () {
      expect(TuitionHelper.instance.isLogin, isTrue);
    }, skip: skipReason);

    test(
      'getData returns a list (possibly empty)',
      () async {
        logTarget('TuitionHelper', 'getData', <String, dynamic>{
          'method': 'GET',
          'path': '/tfstu/tfstudata.asp?act=11',
        });
        final ApiResult<List<TuitionAndFees>> result = await TuitionHelper
            .instance
            .getData();
        expect(result, isA<ApiSuccess<List<TuitionAndFees>>>());
        final List<TuitionAndFees> data =
            (result as ApiSuccess<List<TuitionAndFees>>).data;
        logSuccess('TuitionHelper', 'getData', <String, dynamic>{
          'count': data.length,
        });
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
