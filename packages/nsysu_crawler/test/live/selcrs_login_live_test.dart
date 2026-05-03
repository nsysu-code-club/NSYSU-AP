@Tags(<String>['live'])
@TestOn('vm')
library;

import 'dart:io';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

/// Hits the real selcrs.nsysu.edu.tw. Excluded by default.
///
/// Run with: `NSYSU_USER=... NSYSU_PASS=... dart test -P live -r expanded`
void main() {
  final String username = Platform.environment['NSYSU_USER'] ?? '';
  final String password = Platform.environment['NSYSU_PASS'] ?? '';
  final bool hasCreds = username.isNotEmpty && password.isNotEmpty;

  test(
    'login succeeds against the real selcrs server',
    () async {
      final SelcrsHelper helper = SelcrsHelper();
      final ApiResult<GeneralResponse> result = await helper.login(
        username: username,
        password: password,
      );
      expect(result, isA<ApiSuccess<GeneralResponse>>());
    },
    skip: hasCreds ? false : 'NSYSU_USER / NSYSU_PASS env vars not set',
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
