import 'package:dio/dio.dart';

class _RequestLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('  → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // ignore: avoid_print
    print(
      '  ← ${response.statusCode} ${response.requestOptions.uri.path}',
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
      '  ✗ ${code ?? err.type.name} '
      '${err.requestOptions.uri.path}'
      '${location.isEmpty ? '' : ' → $location'}',
    );
    handler.next(err);
  }
}

/// Attach a request/response logger to the given dio instance(s).
/// Call from each live test's `setUpAll` so every endpoint hit is printed.
void enableRequestLogging(Dio dio) {
  dio.interceptors.add(_RequestLogInterceptor());
}
