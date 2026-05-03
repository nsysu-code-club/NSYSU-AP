import 'dart:io';

import 'package:dio/dio.dart';

/// Mask the middle of a string before printing it. Use for any value that
/// could identify a real student (id, name, department, class, etc.) so
/// that pasted live-test output doesn't leak PII into chats / screenshots
/// / CI logs.
///
/// - null:   `<null>`
/// - empty:  `<empty>`
/// - 1 char: `••`
/// - 2 char: first char + `•` (e.g. `梁•`)
/// - ≥3 char: first + middle bullets + last (e.g. `B••••••78`)
String redact(String? value) {
  if (value == null) return '<null>';
  if (value.isEmpty) return '<empty>';
  if (value.length == 1) return '••';
  if (value.length == 2) return '${value[0]}•';
  return '${value[0]}${"•" * (value.length - 2)}${value[value.length - 1]}';
}

class _RequestLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[http] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // ignore: avoid_print
    print(
      '[http] ← ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final int? code = err.response?.statusCode;
    final String location =
        err.response?.headers.value('location') ?? '';
    // ignore: avoid_print
    print(
      '[http] ✗ ${code ?? err.type.name} '
      '${err.requestOptions.uri.path}'
      '${location.isEmpty ? '' : ' → $location'}',
    );
    handler.next(err);
  }
}

/// Opt-in transport-level dio logger. Default live runs print only
/// `[live] <action>` / `[live]   ← <result>` semantic checkpoints; set
/// `NSYSU_HTTP_LOG=1` to also dump every request URL + redirect chain
/// (useful when debugging session / cookie issues — but the output may
/// contain cookies and URL-embedded student ids, so don't paste publicly).
void enableHttpLogging(Dio dio) {
  if (Platform.environment['NSYSU_HTTP_LOG'] != '1') return;
  // ignore: avoid_print
  print(
    '[live] !! NSYSU_HTTP_LOG=1: dumping every request URL '
    '(may include student id / cookies — do not paste publicly) !!',
  );
  dio.interceptors.add(_RequestLogInterceptor());
}
