// ignore_for_file: avoid_print
@Tags(<String>['live', 'live-anonymous'])
@TestOn('vm')
library;

import 'package:dio/dio.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Liveness probes for every NSYSU endpoint we depend on. No
/// authentication or parsing. School servers must respond below 500 and the
/// iBus+ guest token endpoint must respond with HTTP 200. If any of these fail, the school is having an
/// outage; the parser-shaped tests in `selcrs_live_test.dart` /
/// `graduation_live_test.dart` / `tuition_live_test.dart` will fail
/// differently when only the HTML structure has drifted.
///
/// Test names start with `Health Check` so the crawler-monitor workflow
/// can classify failures (server-down vs parser-drift) by grepping the
/// reporter output.
///
/// Tagged with both `live` and `live-anonymous` so a `dart test -P live`
/// run (creds present) and a `dart test -P live-anonymous` run (no creds)
/// both include connectivity checks.
void main() {
  final Dio healthDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      followRedirects: true,
      validateStatus: (int? status) => status != null && status < 500,
    ),
  );

  setUpAll(() {
    enableHttpLogging(healthDio);
  });

  const Map<String, String> endpoints = <String, String>{
    'Selcrs (course/score/graduation)': 'https://selcrs.nsysu.edu.tw/',
    'Tfstu (tuition)': 'https://tfstu.nsysu.edu.tw/',
  };

  for (final MapEntry<String, String> entry in endpoints.entries) {
    test('Health Check ${entry.key} is reachable', () async {
      logTarget('HealthCheck', 'getEndpoint', <String, dynamic>{
        'name': entry.key,
        'url': entry.value,
      });
      final Response<dynamic> response = await healthDio.get<dynamic>(
        entry.value,
      );
      expect(
        response.statusCode,
        isNotNull,
        reason: '${entry.key} (${entry.value}) returned no status',
      );
      expect(
        response.statusCode! < 500,
        isTrue,
        reason:
            '${entry.key} returned HTTP ${response.statusCode} (server '
            'error / outage)',
      );
      logSuccess('HealthCheck', 'getEndpoint', <String, dynamic>{
        'name': entry.key,
        'statusCode': response.statusCode,
      });
    }, timeout: const Timeout(Duration(seconds: 30)));
  }

  test('Health Check iBus+ (guest token) is reachable', () async {
    const String endpoint = BusHelper.tokenPath;
    logTarget('HealthCheck', 'postEndpoint', <String, dynamic>{
      'name': 'iBus+ (guest token)',
      'url': endpoint,
    });
    final Response<dynamic> response = await healthDio.post<dynamic>(
      endpoint,
      options: Options(
        contentType: 'application/json; charset=utf-8',
        headers: <String, dynamic>{'X-Api-Version': '1'},
      ),
    );
    expect(response.statusCode, 200);
    logSuccess('HealthCheck', 'postEndpoint', <String, dynamic>{
      'name': 'iBus+ (guest token)',
      'statusCode': response.statusCode,
    });
  }, timeout: const Timeout(Duration(seconds: 30)));
}
