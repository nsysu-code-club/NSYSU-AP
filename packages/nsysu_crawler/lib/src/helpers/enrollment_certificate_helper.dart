import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nsysu_crawler/src/build_mode.dart';

/// Categories of recoverable enrollment-certificate failures.
enum EnrollmentCertificateExceptionKind {
  /// The caller did not provide a usable username/password, or RegWeb rejected
  /// them at the login step.
  credentials,

  /// A request exceeded the configured RegWeb timeout.
  timeout,

  /// RegWeb returned a non-success status outside the login credential case.
  http,

  /// A redirect was missing, malformed, excessive, or outside the allowed host.
  redirect,

  /// RegWeb declared or streamed a response larger than the safety limit.
  tooLarge,

  /// The final response was not a bounded PDF payload.
  invalidPdf,

  /// The helper was closed or the underlying Dio request was cancelled.
  cancelled,

  /// The request failed before a trusted HTTP response was available.
  network,
}

/// Typed failure returned by [EnrollmentCertificateHelper].
class EnrollmentCertificateException implements Exception {
  const EnrollmentCertificateException(
    this.kind,
    this.message, {
    this.statusCode,
    this.cause,
  });

  /// Machine-readable category used by app UI to choose a user message.
  final EnrollmentCertificateExceptionKind kind;

  /// Developer-facing failure summary.
  final String message;

  /// HTTP status attached to the failure, when one was available.
  final int? statusCode;

  /// Original transport/parser error, when this exception wraps one.
  final Object? cause;

  @override
  String toString() {
    final String status = statusCode == null ? '' : ' ($statusCode)';
    return 'EnrollmentCertificateException.${kind.name}$status: $message';
  }
}

/// Downloads the currently authenticated student's enrollment certificate.
///
/// Every helper owns an independent cookie jar and keeps all three RegWeb
/// requests in that one session. Redirects are followed manually so cookies
/// are retained without allowing RegWeb to redirect credentials elsewhere.
class EnrollmentCertificateHelper {
  /// Creates an isolated RegWeb client.
  ///
  /// Pass [dio] and [cookieJar] only in tests. Production callers should create
  /// a fresh helper per download and call [close] when the page is disposed or
  /// the request finishes.
  EnrollmentCertificateHelper({Dio? dio, CookieJar? cookieJar})
    : _dio = dio ?? _createProductionDio(),
      _cookieJar = cookieJar ?? CookieJar() {
    _configureDio();
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final Uri _loginUri = Uri.parse(
    'https://regweb.nsysu.edu.tw/webreg/wregloginchk2.asp',
  );
  static final Uri _contextUri = Uri.parse(
    'https://regweb.nsysu.edu.tw/webreg/'
    'WRegMain3.asp?act=71&out=print/enrollcert.asp',
  );
  static final Uri _certificateUri = Uri.parse(
    'https://regweb.nsysu.edu.tw/webreg/print/enrollcert.asp',
  );
  static const String _mainReferer =
      'https://regweb.nsysu.edu.tw/webreg/WRegMain3.asp';
  static const String _allowedHost = 'regweb.nsysu.edu.tw';
  static const String _allowedPathPrefix = '/webreg/';
  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 Chrome/138 Safari/537.36';
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxResponseBytes = 10 * 1024 * 1024;
  static const int _minimumPdfBytes = 1024;
  static const int _maxRedirects = 5;
  static const String _debugLogName = 'nsysu_crawler.enrollment_certificate';

  final Dio _dio;
  final CookieJar _cookieJar;
  final Set<CancelToken> _activeCancelTokens = <CancelToken>{};
  final Set<_ResponseStreamReader> _activeReaders = <_ResponseStreamReader>{};
  bool _isClosed = false;

  static Dio _createProductionDio() {
    final Dio dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // The app has historically installed an Android-wide HttpOverride.
        // Resetting this callback keeps RegWeb on normal platform TLS checks.
        final HttpClient client = HttpClient();
        client.badCertificateCallback = null;
        return client;
      },
    );
    return dio;
  }

  void _configureDio() {
    _dio.options
      ..connectTimeout = _requestTimeout
      ..sendTimeout = _requestTimeout
      ..receiveTimeout = _requestTimeout
      ..followRedirects = false
      ..responseType = ResponseType.stream
      ..validateStatus = ((int? status) => status != null)
      ..headers[HttpHeaders.userAgentHeader] = _userAgent;
  }

  /// Logs in to RegWeb, enters the enrollment-certificate context, and returns
  /// the generated PDF bytes.
  ///
  /// The method does not persist credentials or cache the PDF. Callers are
  /// responsible for storage and for closing this helper after use.
  Future<Uint8List> download({
    required String username,
    required String password,
  }) async {
    if (_isClosed) {
      _debugLog('event=download_rejected reason=helper_closed');
      throw const EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.cancelled,
        'The enrollment certificate session is closed.',
      );
    }

    final String normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.trim().isEmpty) {
      _debugLog(
        'event=download_rejected reason=missing_credentials '
        'usernamePresent=${normalizedUsername.isNotEmpty} '
        'passwordPresent=${password.trim().isNotEmpty}',
      );
      throw const EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.credentials,
        'A non-empty username and password are required.',
      );
    }

    _debugLog('event=download_start');
    try {
      final _BufferedResponse loginResponse = await _request(
        stage: 'login',
        method: 'POST',
        uri: _loginUri,
        form: <String, String>{'ID': normalizedUsername, 'passwd': password},
      );
      _requireSuccess(loginResponse, credentialsOnUnauthorized: true);
      _debugLog(
        'event=stage_complete stage=login status=${loginResponse.statusCode} '
        'responseBytes=${loginResponse.bytes.length}',
      );

      final _BufferedResponse contextResponse = await _request(
        stage: 'context',
        method: 'GET',
        uri: _contextUri,
        referer: _mainReferer,
      );
      _requireSuccess(contextResponse);
      _debugLog(
        'event=stage_complete stage=context '
        'status=${contextResponse.statusCode} '
        'responseBytes=${contextResponse.bytes.length}',
      );

      final _BufferedResponse certificateResponse = await _request(
        stage: 'certificate',
        method: 'POST',
        uri: _certificateUri,
        referer: _mainReferer,
        form: <String, String>{'ssn1': 'idno', 'idno': normalizedUsername},
      );
      _requireSuccess(certificateResponse);
      _debugLog(
        'event=stage_complete stage=certificate '
        'status=${certificateResponse.statusCode} '
        'responseBytes=${certificateResponse.bytes.length}',
      );
      final Uint8List pdf = _normalizePdf(certificateResponse.bytes);
      _debugLog('event=download_complete pdfBytes=${pdf.length}');
      return pdf;
    } on EnrollmentCertificateException catch (error) {
      _debugLog(
        'event=download_failure kind=${error.kind.name} '
        'status=${_debugStatus(error.statusCode)}',
      );
      rethrow;
    } on DioException catch (error) {
      final EnrollmentCertificateException mapped = _fromDioException(error);
      _debugLog(
        'event=download_failure kind=${mapped.kind.name} '
        'status=${_debugStatus(mapped.statusCode)} '
        'transport=${error.type.name}',
      );
      throw mapped;
    } on TimeoutException catch (error) {
      final EnrollmentCertificateException mapped =
          EnrollmentCertificateException(
            EnrollmentCertificateExceptionKind.timeout,
            'The RegWeb request timed out.',
            cause: error,
          );
      _debugLog('event=download_failure kind=${mapped.kind.name} status=none');
      throw mapped;
    } on SocketException catch (error) {
      final EnrollmentCertificateException mapped =
          EnrollmentCertificateException(
            EnrollmentCertificateExceptionKind.network,
            'The RegWeb request could not reach the server.',
            cause: error,
          );
      _debugLog(
        'event=download_failure kind=${mapped.kind.name} status=none '
        'sourceType=${error.runtimeType}',
      );
      throw mapped;
    } on Exception catch (error) {
      final EnrollmentCertificateException mapped =
          EnrollmentCertificateException(
            EnrollmentCertificateExceptionKind.network,
            'The RegWeb request failed.',
            cause: error,
          );
      _debugLog(
        'event=download_failure kind=${mapped.kind.name} status=none '
        'sourceType=${error.runtimeType}',
      );
      throw mapped;
    }
  }

  Future<_BufferedResponse> _request({
    required String stage,
    required String method,
    required Uri uri,
    Map<String, String>? form,
    String? referer,
  }) async {
    String currentMethod = method;
    Uri currentUri = uri;
    Map<String, String>? currentForm = form;
    int redirectCount = 0;

    while (true) {
      _requireAllowedUri(currentUri);
      _debugLog(
        'event=request_start stage=$stage method=$currentMethod '
        'redirectHop=$redirectCount',
      );
      final Map<String, Object> headers = <String, Object>{
        if (referer != null) HttpHeaders.refererHeader: referer,
      };
      final CancelToken cancelToken = CancelToken();
      _activeCancelTokens.add(cancelToken);
      final Response<ResponseBody> response;
      final Uint8List bytes;
      try {
        response = await _dio.requestUri<ResponseBody>(
          currentUri,
          data: currentForm,
          cancelToken: cancelToken,
          options: Options(
            method: currentMethod,
            headers: headers,
            contentType: currentForm == null
                ? null
                : Headers.formUrlEncodedContentType,
            responseType: ResponseType.stream,
            followRedirects: false,
            validateStatus: (int? status) => status != null,
            sendTimeout: _requestTimeout,
            receiveTimeout: _requestTimeout,
          ),
        );
        _debugLog(
          'event=response_headers stage=$stage '
          'status=${_debugStatus(response.statusCode)} '
          'contentType=${_debugContentType(response.headers)} '
          'declaredBytes=${_debugDeclaredLength(response.headers)}',
        );
        bytes = await _readBounded(
          response,
          stage: stage,
          cancelToken: cancelToken,
        );
      } on DioException catch (error) {
        _debugLog(
          'event=request_transport_failure stage=$stage '
          'transport=${error.type.name} '
          'status=${_debugStatus(error.response?.statusCode)}',
        );
        rethrow;
      } on EnrollmentCertificateException catch (error) {
        _debugLog(
          'event=request_body_failure stage=$stage kind=${error.kind.name} '
          'status=${_debugStatus(error.statusCode)}',
        );
        rethrow;
      } finally {
        _activeCancelTokens.remove(cancelToken);
      }
      final int statusCode = response.statusCode ?? 0;
      _debugLog(
        'event=response_body_complete stage=$stage status=$statusCode '
        'responseBytes=${bytes.length}',
      );

      if (!_isRedirectStatus(statusCode)) {
        if (statusCode >= 300 && statusCode < 400) {
          _debugLog(
            'event=redirect_rejected stage=$stage '
            'reason=unsupported_status status=$statusCode',
          );
          throw EnrollmentCertificateException(
            EnrollmentCertificateExceptionKind.redirect,
            'RegWeb returned an unsupported redirect status.',
            statusCode: statusCode,
          );
        }
        return _BufferedResponse(statusCode, bytes);
      }

      if (redirectCount >= _maxRedirects) {
        _debugLog(
          'event=redirect_rejected stage=$stage reason=limit_exceeded '
          'status=$statusCode redirectHop=$redirectCount',
        );
        throw EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.redirect,
          'RegWeb exceeded the $_maxRedirects redirect limit.',
          statusCode: statusCode,
        );
      }
      final String? location = response.headers.value(
        HttpHeaders.locationHeader,
      );
      if (location == null || location.trim().isEmpty) {
        _debugLog(
          'event=redirect_rejected stage=$stage reason=missing_location '
          'status=$statusCode redirectHop=$redirectCount',
        );
        throw EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.redirect,
          'RegWeb returned a redirect without a Location header.',
          statusCode: statusCode,
        );
      }

      final Uri nextUri;
      try {
        nextUri = currentUri.resolve(location.trim());
      } on FormatException catch (error) {
        _debugLog(
          'event=redirect_rejected stage=$stage reason=invalid_location '
          'status=$statusCode redirectHop=$redirectCount',
        );
        throw EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.redirect,
          'RegWeb returned an invalid redirect target.',
          statusCode: statusCode,
          cause: error,
        );
      }
      try {
        _requireAllowedUri(nextUri, statusCode: statusCode);
      } on EnrollmentCertificateException {
        _debugLog(
          'event=redirect_rejected stage=$stage reason=target_not_allowed '
          'status=$statusCode redirectHop=$redirectCount',
        );
        rethrow;
      }

      final String previousMethod = currentMethod;
      if (statusCode == 303 ||
          ((statusCode == 301 || statusCode == 302) &&
              currentMethod == 'POST')) {
        currentMethod = 'GET';
        currentForm = null;
      }
      currentUri = nextUri;
      redirectCount += 1;
      _debugLog(
        'event=redirect_follow stage=$stage status=$statusCode '
        'redirectHop=$redirectCount method=$currentMethod '
        'methodChanged=${previousMethod != currentMethod}',
      );
    }
  }

  Future<Uint8List> _readBounded(
    Response<ResponseBody> response, {
    required String stage,
    required CancelToken cancelToken,
  }) async {
    final ResponseBody? responseBody = response.data;
    if (responseBody == null) {
      if (_hasOversizedDeclaredLength(response)) {
        _debugLog(
          'event=response_rejected stage=$stage '
          'reason=declared_size_exceeded '
          'declaredBytes=${_debugDeclaredLength(response.headers)}',
        );
        throw const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.tooLarge,
          'A RegWeb response exceeded the 10 MiB safety limit.',
        );
      }
      _debugLog('event=response_body_missing stage=$stage');
      return Uint8List(0);
    }

    final _ResponseStreamReader reader = _ResponseStreamReader(
      responseBody.stream,
      maxBytes: _maxResponseBytes,
    );
    _activeReaders.add(reader);
    reader.startPaused();
    try {
      if (_isClosed) {
        _debugLog('event=response_cancelled stage=$stage reason=helper_closed');
        await _cancelTransport(cancelToken);
        await reader.dispose();
        throw const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.cancelled,
          'The enrollment certificate session is closed.',
        );
      }
      if (_hasOversizedDeclaredLength(response)) {
        _debugLog(
          'event=response_rejected stage=$stage '
          'reason=declared_size_exceeded '
          'declaredBytes=${_debugDeclaredLength(response.headers)}',
        );
        await _cancelTransport(cancelToken);
        await reader.dispose();
        throw const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.tooLarge,
          'A RegWeb response exceeded the 10 MiB safety limit.',
        );
      }
      reader.resume();
      try {
        return await reader.result;
      } on EnrollmentCertificateException catch (error) {
        if (error.kind == EnrollmentCertificateExceptionKind.tooLarge) {
          _debugLog(
            'event=response_rejected stage=$stage '
            'reason=stream_size_exceeded '
            'receivedBytes=${reader.receivedBytes}',
          );
          await _cancelTransport(cancelToken, reason: error);
        }
        rethrow;
      }
    } finally {
      _activeReaders.remove(reader);
      await reader.dispose();
    }
  }

  static bool _hasOversizedDeclaredLength(Response<ResponseBody> response) {
    final List<String>? declaredLengths =
        response.headers[Headers.contentLengthHeader];
    if (declaredLengths == null) return false;
    for (final String rawValue in declaredLengths) {
      for (final String value in rawValue.split(',')) {
        final int? declaredLength = int.tryParse(value.trim());
        if (declaredLength != null && declaredLength > _maxResponseBytes) {
          return true;
        }
      }
    }
    return false;
  }

  static String _debugDeclaredLength(Headers headers) {
    final List<String>? rawValues = headers[Headers.contentLengthHeader];
    if (rawValues == null) return 'none';
    for (final String rawValue in rawValues) {
      for (final String value in rawValue.split(',')) {
        final int? parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed.toString();
      }
    }
    return 'invalid';
  }

  static String _debugContentType(Headers headers) {
    final List<String>? values = headers[HttpHeaders.contentTypeHeader];
    if (values == null || values.isEmpty) return 'none';
    final String mediaType = values.first.split(';').first.trim().toLowerCase();
    return switch (mediaType) {
      'application/pdf' => 'application/pdf',
      'text/html' => 'text/html',
      'text/plain' => 'text/plain',
      'application/octet-stream' => 'application/octet-stream',
      _ => 'other',
    };
  }

  static String _debugStatus(int? statusCode) {
    return statusCode?.toString() ?? 'none';
  }

  static void _debugLog(String message) {
    if (!kCrawlerDebugMode) return;
    developer.log(message, name: _debugLogName);
  }

  static Future<void> _cancelTransport(
    CancelToken cancelToken, {
    Object? reason,
  }) async {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel(reason ?? 'Enrollment certificate response rejected');
    }
    // Dio's public cancellation hook closes the underlying ResponseBody and
    // cancels its source subscription in a microtask.
    await Future<void>.delayed(Duration.zero);
  }

  static bool _isRedirectStatus(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  static void _requireAllowedUri(Uri uri, {int? statusCode}) {
    final bool hasTraversal = uri.pathSegments.any((String segment) {
      final String decoded;
      try {
        decoded = Uri.decodeComponent(segment);
      } on FormatException {
        return true;
      }
      return decoded == '..' || decoded.contains('/') || decoded.contains(r'\');
    });
    final bool allowed =
        uri.scheme == 'https' &&
        uri.host == _allowedHost &&
        uri.userInfo.isEmpty &&
        uri.port == 443 &&
        uri.path.startsWith(_allowedPathPrefix) &&
        !hasTraversal;
    if (!allowed) {
      throw EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.redirect,
        'RegWeb attempted to leave its allowed HTTPS path.',
        statusCode: statusCode,
      );
    }
  }

  static void _requireSuccess(
    _BufferedResponse response, {
    bool credentialsOnUnauthorized = false,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (credentialsOnUnauthorized &&
        (response.statusCode == 401 || response.statusCode == 403)) {
      throw EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.credentials,
        'RegWeb rejected the supplied credentials.',
        statusCode: response.statusCode,
      );
    }
    throw EnrollmentCertificateException(
      EnrollmentCertificateExceptionKind.http,
      'RegWeb returned an unsuccessful HTTP status.',
      statusCode: response.statusCode,
    );
  }

  static Uint8List _normalizePdf(Uint8List bytes) {
    _debugLog('event=pdf_validation_start responseBytes=${bytes.length}');
    int start = 0;
    while (start < bytes.length && _isAsciiWhitespace(bytes[start])) {
      start += 1;
    }

    const List<int> pdfHeader = <int>[0x25, 0x50, 0x44, 0x46, 0x2D];
    if (!_matchesAt(bytes, start, pdfHeader)) {
      _debugLog(
        'event=pdf_validation_failure reason=missing_header '
        'responseBytes=${bytes.length} leadingWhitespaceBytes=$start',
      );
      throw const EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.invalidPdf,
        'RegWeb returned a response without a PDF signature.',
      );
    }

    const List<int> eofMarker = <int>[0x25, 0x25, 0x45, 0x4F, 0x46];
    final int eofStart = _lastIndexOf(bytes, eofMarker);
    if (eofStart < start) {
      _debugLog(
        'event=pdf_validation_failure reason=missing_eof '
        'responseBytes=${bytes.length} leadingWhitespaceBytes=$start',
      );
      throw const EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.invalidPdf,
        'RegWeb returned an incomplete PDF response.',
      );
    }
    final int end = eofStart + eofMarker.length;
    for (int index = end; index < bytes.length; index += 1) {
      if (!_isAsciiWhitespace(bytes[index])) {
        _debugLog(
          'event=pdf_validation_failure reason=trailing_data '
          'responseBytes=${bytes.length} trailingOffset=$index',
        );
        throw const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.invalidPdf,
          'RegWeb returned unexpected data after the PDF trailer.',
        );
      }
    }
    if (end - start < _minimumPdfBytes) {
      _debugLog(
        'event=pdf_validation_failure reason=too_short '
        'pdfBytes=${end - start} minimumBytes=$_minimumPdfBytes',
      );
      throw const EnrollmentCertificateException(
        EnrollmentCertificateExceptionKind.invalidPdf,
        'RegWeb returned a PDF response that was unexpectedly short.',
      );
    }

    final Uint8List pdf = Uint8List.fromList(bytes.sublist(start, end));
    _debugLog(
      'event=pdf_validation_complete pdfBytes=${pdf.length} '
      'leadingWhitespaceBytes=$start trailingWhitespaceBytes=${bytes.length - end}',
    );
    return pdf;
  }

  static bool _matchesAt(Uint8List bytes, int index, List<int> pattern) {
    if (index < 0 || index + pattern.length > bytes.length) return false;
    for (int offset = 0; offset < pattern.length; offset += 1) {
      if (bytes[index + offset] != pattern[offset]) return false;
    }
    return true;
  }

  static int _lastIndexOf(Uint8List bytes, List<int> pattern) {
    for (int index = bytes.length - pattern.length; index >= 0; index -= 1) {
      if (_matchesAt(bytes, index, pattern)) return index;
    }
    return -1;
  }

  static bool _isAsciiWhitespace(int byte) {
    return byte == 0x20 || (byte >= 0x09 && byte <= 0x0D);
  }

  static EnrollmentCertificateException _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.timeout,
          'The RegWeb request timed out.',
          cause: error,
        );
      case DioExceptionType.cancel:
        return EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.cancelled,
          'The RegWeb request was cancelled.',
          cause: error,
        );
      case DioExceptionType.badResponse:
        return EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.http,
          'RegWeb returned an unsuccessful HTTP status.',
          statusCode: error.response?.statusCode,
          cause: error,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.network,
          'The RegWeb request could not reach the server securely.',
          cause: error,
        );
    }
  }

  /// Cancels active requests/readers and closes the Dio client.
  void close() {
    if (_isClosed) return;
    _debugLog(
      'event=helper_close activeRequests=${_activeCancelTokens.length} '
      'activeReaders=${_activeReaders.length}',
    );
    _isClosed = true;
    for (final CancelToken cancelToken in List<CancelToken>.of(
      _activeCancelTokens,
    )) {
      cancelToken.cancel('Enrollment certificate helper closed');
    }
    for (final _ResponseStreamReader reader in List<_ResponseStreamReader>.of(
      _activeReaders,
    )) {
      unawaited(reader.cancel());
    }
    _dio.close(force: true);
  }
}

class _BufferedResponse {
  const _BufferedResponse(this.statusCode, this.bytes);

  final int statusCode;
  final Uint8List bytes;
}

class _ResponseStreamReader {
  _ResponseStreamReader(this._stream, {required this.maxBytes}) {
    // Cancellation can be requested synchronously from a stream's onListen
    // callback. Keep that typed error handled until _readBounded awaits it.
    result.ignore();
  }

  final Stream<Uint8List> _stream;
  final int maxBytes;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  final Completer<Uint8List> _completer = Completer<Uint8List>();
  late final Future<Uint8List> result = _completer.future;

  StreamSubscription<Uint8List>? _subscription;
  Future<void>? _cancelFuture;
  int _receivedBytes = 0;
  bool _cancelRequested = false;
  bool _isPaused = false;

  int get receivedBytes => _receivedBytes;

  void startPaused() {
    if (_subscription != null) return;
    // Stored below and cancelled by cancel()/dispose().
    // ignore: cancel_subscriptions
    final StreamSubscription<Uint8List> subscription = _stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: true,
    );
    _subscription = subscription;
    if (_cancelRequested) {
      unawaited(_cancelSubscription());
      return;
    }
    subscription.pause();
    _isPaused = true;
  }

  void resume() {
    if (!_isPaused || _cancelRequested) return;
    _isPaused = false;
    _subscription?.resume();
  }

  void _onData(Uint8List chunk) {
    if (_completer.isCompleted) return;
    _receivedBytes += chunk.length;
    if (_receivedBytes > maxBytes) {
      _completer.completeError(
        const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.tooLarge,
          'A RegWeb response exceeded the 10 MiB safety limit.',
        ),
        StackTrace.current,
      );
      unawaited(_cancelSubscription());
      return;
    }
    _builder.add(chunk);
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }

  void _onDone() {
    if (_completer.isCompleted) return;
    _completer.complete(_builder.takeBytes());
  }

  Future<void> cancel() async {
    _cancelRequested = true;
    if (!_completer.isCompleted) {
      _completer.completeError(
        const EnrollmentCertificateException(
          EnrollmentCertificateExceptionKind.cancelled,
          'The enrollment certificate session is closed.',
        ),
        StackTrace.current,
      );
    }
    await _cancelSubscription();
  }

  Future<void> dispose() async {
    _cancelRequested = true;
    await _cancelSubscription();
  }

  Future<void> _cancelSubscription() {
    final StreamSubscription<Uint8List>? subscription = _subscription;
    if (subscription == null) {
      _cancelRequested = true;
      return Future<void>.value();
    }
    return _cancelFuture ??= _cancelIgnoringErrors(subscription);
  }

  static Future<void> _cancelIgnoringErrors(
    StreamSubscription<Uint8List> subscription,
  ) async {
    try {
      await subscription.cancel();
    } on Object {
      // Cleanup must not replace the typed download failure already selected.
    }
  }
}
