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
      : 'NSYSU_USER / NSYSU_PASS env vars not set';

  group('TuitionHelper', () {
    setUpAll(() async {
      enableHttpLogging(TuitionHelper.instance.dio);
      if (!hasCreds) {
        print('[live] no credentials in env — tuition tests will skip');
        return;
      }
      print('[live] login as ${redact(username)} (tfstu tuition system)');
      final ApiResult<GeneralResponse> result = await TuitionHelper.instance
          .login(username: username, password: password);
      print(
        '[live]   ← isLogin=${TuitionHelper.instance.isLogin} '
        'result=${result.runtimeType}',
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
        print('[live] GET /tfstu/tfstudata.asp?act=11 (tuition list)');
        final ApiResult<List<TuitionAndFees>> result = await TuitionHelper
            .instance
            .getData();
        expect(result, isA<ApiSuccess<List<TuitionAndFees>>>());
        final List<TuitionAndFees> data =
            (result as ApiSuccess<List<TuitionAndFees>>).data;
        print(
          '[live]   ← ${data.length} tuition entries '
          '(amounts/serials redacted)',
        );
      },
      skip: skipReason,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
