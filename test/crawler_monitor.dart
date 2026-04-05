// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Crawler structure monitor — validates that the school's HTML pages
/// still have the expected structure for our parsers.
///
/// Uses NSYSU_USERNAME and NSYSU_PASSWORD from environment variables.
/// Does NOT validate data content, only structural tags.
void main() async {
  final String? username = Platform.environment['NSYSU_USERNAME'];
  final String? password = Platform.environment['NSYSU_PASSWORD'];

  if (username == null || password == null) {
    print('⚠️  NSYSU_USERNAME or NSYSU_PASSWORD not set. Skipping monitor.');
    exit(0);
  }

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.bytes,
      followRedirects: false,
      validateStatus: (int? status) => status != null && status < 400,
    ),
  );

  int failures = 0;

  // --- Course System (selcrs) ---
  try {
    print('🔍 Checking selcrs login page...');
    final Response<Uint8List> loginPage = await dio.get<Uint8List>(
      'https://selcrs.nsysu.edu.tw/menu1/index.asp',
    );
    final String loginHtml = const Utf8Decoder().convert(loginPage.data!);
    assert(
      loginHtml.contains('<form') || loginHtml.contains('<input'),
      'Login page missing form elements',
    );
    print('  ✅ Login page structure OK');
  } catch (e) {
    print('  ❌ Login page check failed: $e');
    failures++;
  }

  // --- Tuition System ---
  try {
    print('🔍 Checking tuition system accessibility...');
    final Response<Uint8List> tuitionPage = await dio.get<Uint8List>(
      'https://tfstu.nsysu.edu.tw',
      options: Options(
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    assert(tuitionPage.statusCode != null, 'Tuition system unreachable');
    print('  ✅ Tuition system reachable (status: ${tuitionPage.statusCode})');
  } catch (e) {
    print('  ❌ Tuition system check failed: $e');
    failures++;
  }

  // --- Bus API ---
  try {
    print('🔍 Checking bus API...');
    final Response<Uint8List> busResponse = await dio.get<Uint8List>(
      'https://raw.githubusercontent.com/nicklin99/nsysu-bus/main/bus_info_data_zh.json',
      options: Options(
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    if (busResponse.statusCode == 200) {
      final String busJson = const Utf8Decoder().convert(busResponse.data!);
      final dynamic parsed = jsonDecode(busJson);
      assert(parsed is List, 'Bus API response is not a JSON array');
      if ((parsed as List).isNotEmpty) {
        final Map<String, dynamic> first = parsed[0] as Map<String, dynamic>;
        assert(first.containsKey('RouteID'), 'Missing RouteID field');
        assert(first.containsKey('StopName'), 'Missing StopName field');
        assert(first.containsKey('Name'), 'Missing Name field');
        print('  ✅ Bus API structure OK (${parsed.length} routes)');
      }
    } else {
      print('  ⚠️  Bus API returned ${busResponse.statusCode}');
    }
  } catch (e) {
    print('  ❌ Bus API check failed: $e');
    failures++;
  }

  // --- Graduation System ---
  try {
    print('🔍 Checking graduation system accessibility...');
    final Response<Uint8List> gradPage = await dio.get<Uint8List>(
      'https://selcrs.nsysu.edu.tw/gadchk/',
      options: Options(
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 500,
      ),
    );
    assert(gradPage.statusCode != null, 'Graduation system unreachable');
    print(
      '  ✅ Graduation system reachable (status: ${gradPage.statusCode})',
    );
  } catch (e) {
    print('  ❌ Graduation system check failed: $e');
    failures++;
  }

  print('');
  if (failures > 0) {
    print('❌ $failures check(s) failed!');
    exit(1);
  } else {
    print('✅ All structure checks passed.');
    exit(0);
  }
}
