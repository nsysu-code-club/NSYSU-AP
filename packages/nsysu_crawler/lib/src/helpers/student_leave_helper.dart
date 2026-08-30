import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:nsysu_crawler/src/build_mode.dart';
import 'package:nsysu_crawler/src/models/student_leave.dart';
import 'package:nsysu_crawler/src/parsers/html_parser.dart';
import 'package:nsysu_crawler/src/utils/big5/big5.dart';

class StudentLeaveHelper {
  static const String baseUrl = 'https://sis.nsysu.edu.tw';
  static const int _maxHtmlBytes = 2 * 1024 * 1024;
  static const int _maxProofBytes = 10 * 1024 * 1024;
  static const Duration _deleteAuthorizationLifetime = Duration(seconds: 30);
  static const GeneralResponse _loginError = GeneralResponse(
    statusCode: 401,
    message: 'sis login error',
  );
  static const GeneralResponse _sessionExpired = GeneralResponse(
    statusCode: 401,
    message: 'sis session expired',
  );
  static const GeneralResponse _operationTimedOut = GeneralResponse(
    statusCode: 408,
    message: 'student leave operation timed out',
  );
  static const GeneralResponse _invalidConfirmAction = GeneralResponse(
    statusCode: 400,
    message: 'invalid sis confirmation action',
  );
  static const GeneralResponse _invalidConfirmSession = GeneralResponse(
    statusCode: 409,
    message: 'student leave confirmation session changed',
  );
  static const GeneralResponse _invalidDeleteAuthorization = GeneralResponse(
    statusCode: 409,
    message: 'student leave deletion must be checked first',
  );
  static const GeneralResponse _deleteCheckRejected = GeneralResponse(
    statusCode: 409,
    message: 'student leave deletion check was not authorized',
  );
  static const GeneralResponse _invalidLeaveRequest = GeneralResponse(
    statusCode: 400,
    message: 'invalid student leave request',
  );
  static const GeneralResponse _leaveFormUnavailable = GeneralResponse(
    statusCode: 503,
    message: 'student leave form constraints unavailable',
  );
  static const GeneralResponse _invalidProofResponse = GeneralResponse(
    statusCode: 422,
    message: 'invalid student leave proof response',
  );

  static StudentLeaveHelper? _instance;

  // ignore: prefer_constructors_over_static_methods
  static StudentLeaveHelper get instance {
    return _instance ??= StudentLeaveHelper();
  }

  StudentLeaveHelper({Duration operationTimeout = const Duration(seconds: 90)})
    : assert(operationTimeout > Duration.zero),
      _operationTimeout = operationTimeout {
    initCookiesJar();
  }

  Dio dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
    ),
  );
  CookieJar cookieJar = CookieJar();

  bool isLogin = false;
  String username = '';
  final Duration _operationTimeout;
  Future<void> _sessionQueue = Future<void>.value();
  int _sessionGeneration = 0;
  Object _sessionIdentity = Object();
  CancelToken _sessionCancelToken = CancelToken();
  final Set<StudentLeaveConfirmForm> _pendingConfirmForms =
      <StudentLeaveConfirmForm>{};
  final Map<String, DateTime> _authorizedDeletions = <String, DateTime>{};

  Options get _streamFormOption => Options(
    responseType: ResponseType.stream,
    contentType: Headers.formUrlEncodedContentType,
  );

  Options get _streamOption => Options(responseType: ResponseType.stream);

  void initCookiesJar() {
    if (!_sessionCancelToken.isCancelled) {
      _sessionCancelToken.cancel('student leave session reset');
    }
    _sessionCancelToken = CancelToken();
    _sessionGeneration++;
    _sessionIdentity = Object();
    _pendingConfirmForms.clear();
    _authorizedDeletions.clear();
    cookieJar = CookieJar();
    dio.interceptors.removeWhere(
      (Interceptor interceptor) => interceptor is CookieManager,
    );
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(baseUrl));
  }

  void logout() {
    _resetSession();
  }

  void _resetSession() {
    isLogin = false;
    username = '';
    initCookiesJar();
  }

  Future<ApiResult<GeneralResponse>> login({
    required String username,
    required String password,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _login(username: username, password: password),
    );
  }

  Future<ApiResult<GeneralResponse>> _login({
    required String username,
    required String password,
  }) async {
    _resetSession();
    final Object loginSessionIdentity = _sessionIdentity;
    final CancelToken cancelToken = _sessionCancelToken;
    try {
      final Response<Uint8List> loginResponse = await _postHtml(
        '$baseUrl/include/loginCheck.php',
        data: <String, String>{
          'tmpid': username,
          'tmpwd': password,
          'tmprole': 'stu',
        },
        formEncoded: true,
        cancelToken: cancelToken,
      );
      if (!identical(loginSessionIdentity, _sessionIdentity)) {
        return const ApiError<GeneralResponse>(_sessionExpired);
      }
      final String loginText = big5.decode(loginResponse.data!);
      final String? okToken = RegExp(
        r'''afterCheck\.php\?OK=([^"']+)''',
      ).firstMatch(loginText)?.group(1);
      if (okToken == null || okToken.isEmpty) {
        _resetSession();
        return const ApiError<GeneralResponse>(_loginError);
      }

      await _getHtml(
        Uri.parse(
          '$baseUrl/include/afterCheck.php',
        ).replace(queryParameters: <String, String>{'OK': okToken}).toString(),
        cancelToken: cancelToken,
      );
      if (!identical(loginSessionIdentity, _sessionIdentity)) {
        return const ApiError<GeneralResponse>(_sessionExpired);
      }
      final Response<Uint8List> mainResponse = await _getHtml(
        '$baseUrl/main.php',
        cancelToken: cancelToken,
      );
      final String mainText = big5.decode(mainResponse.data!);
      if (!identical(loginSessionIdentity, _sessionIdentity)) {
        return const ApiError<GeneralResponse>(_sessionExpired);
      }
      if (mainText.contains('loginCheck.php') || mainText.contains('請重新登入')) {
        _resetSession();
        return const ApiError<GeneralResponse>(_loginError);
      }

      this.username = username;
      isLogin = true;
      return ApiSuccess<GeneralResponse>(GeneralResponse.success());
    } on DioException catch (e) {
      if (identical(loginSessionIdentity, _sessionIdentity)) _resetSession();
      return ApiFailure<GeneralResponse>(e);
    } on Exception catch (_) {
      if (identical(loginSessionIdentity, _sessionIdentity)) _resetSession();
      if (kCrawlerDebugMode) rethrow;
      return ApiError<GeneralResponse>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<StudentLeavePreviewResult>> previewLeave({
    required String username,
    required String password,
    required StudentLeaveRequest request,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _previewLeave(
        username: username,
        password: password,
        request: request,
      ),
    );
  }

  Future<ApiResult<StudentLeavePreviewResult>> _previewLeave({
    required String username,
    required String password,
    required StudentLeaveRequest request,
  }) async {
    try {
      final ApiResult<GeneralResponse> loginResult = await _ensureLogin(
        username: username,
        password: password,
      );
      switch (loginResult) {
        case ApiSuccess<GeneralResponse>():
          break;
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<StudentLeavePreviewResult>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<StudentLeavePreviewResult>(response);
      }
      final Object sessionIdentity = _sessionIdentity;
      final CancelToken cancelToken = _sessionCancelToken;

      final String? addPageText = await _prepareLeaveSession(
        username,
        cancelToken: cancelToken,
      );
      if (addPageText == null) {
        return const ApiError<StudentLeavePreviewResult>(_sessionExpired);
      }
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<StudentLeavePreviewResult>(_sessionExpired);
      }
      final StudentLeaveFormConstraints? constraints =
          parseStudentLeaveFormConstraints(addPageText);
      if (constraints == null) {
        return const ApiError<StudentLeavePreviewResult>(_leaveFormUnavailable);
      }
      if (constraints.validate(request) != null) {
        return const ApiError<StudentLeavePreviewResult>(_invalidLeaveRequest);
      }
      final Object? submitData = await _submitData(request, constraints);
      if (submitData == null) {
        return const ApiError<StudentLeavePreviewResult>(_invalidLeaveRequest);
      }

      final Response<Uint8List> response = await _postHtml(
        '$baseUrl/SLAMS/SLAMS_stuLeave_add_view.php',
        data: submitData,
        formEncoded: submitData is! FormData,
        cancelToken: cancelToken,
      );
      final String text = big5.decode(response.data!);
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<StudentLeavePreviewResult>(_sessionExpired);
      }
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        _resetSession();
        return const ApiError<StudentLeavePreviewResult>(_sessionExpired);
      }
      final StudentLeaveConfirmForm? confirmForm = parseStudentLeaveConfirmForm(
        text,
      );
      if (confirmForm == null ||
          _confirmActionUri(confirmForm.action) == null) {
        return ApiError<StudentLeavePreviewResult>(
          GeneralResponse.unknownError(),
        );
      }
      final StudentLeaveConfirmForm boundConfirmForm = confirmForm
          .bindToSession(sessionIdentity);
      _pendingConfirmForms
        ..clear()
        ..add(boundConfirmForm);
      return ApiSuccess<StudentLeavePreviewResult>(
        StudentLeavePreviewResult(
          statusCode: response.statusCode,
          body: text,
          confirmation: parseStudentLeaveConfirmation(text),
          confirmForm: boundConfirmForm,
        ),
      );
    } on DioException catch (e) {
      return ApiFailure<StudentLeavePreviewResult>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<StudentLeavePreviewResult>(
        GeneralResponse.unknownError(),
      );
    }
  }

  Future<ApiResult<StudentLeaveFormConstraints>> getLeaveFormConstraints({
    required String username,
    required String password,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _getLeaveFormConstraints(username: username, password: password),
    );
  }

  Future<ApiResult<StudentLeaveFormConstraints>> _getLeaveFormConstraints({
    required String username,
    required String password,
  }) async {
    try {
      final ApiResult<GeneralResponse> loginResult = await _ensureLogin(
        username: username,
        password: password,
      );
      switch (loginResult) {
        case ApiSuccess<GeneralResponse>():
          break;
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<StudentLeaveFormConstraints>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<StudentLeaveFormConstraints>(response);
      }
      final Object sessionIdentity = _sessionIdentity;
      final CancelToken cancelToken = _sessionCancelToken;

      final String? addPageText = await _prepareLeaveSession(
        username,
        cancelToken: cancelToken,
      );
      if (addPageText == null) {
        return const ApiError<StudentLeaveFormConstraints>(_sessionExpired);
      }
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<StudentLeaveFormConstraints>(_sessionExpired);
      }
      final StudentLeaveFormConstraints? constraints =
          parseStudentLeaveFormConstraints(addPageText);
      if (constraints == null) {
        return const ApiError<StudentLeaveFormConstraints>(
          _leaveFormUnavailable,
        );
      }
      return ApiSuccess<StudentLeaveFormConstraints>(constraints);
    } on DioException catch (e) {
      return ApiFailure<StudentLeaveFormConstraints>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<StudentLeaveFormConstraints>(
        GeneralResponse.unknownError(),
      );
    }
  }

  Future<ApiResult<List<StudentLeaveRecord>>> getLeaveRecords({
    required String username,
    required String password,
    StudentLeaveSemester? semester,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _getLeaveRecords(
        username: username,
        password: password,
        semester: semester,
      ),
    );
  }

  Future<ApiResult<List<StudentLeaveRecord>>> _getLeaveRecords({
    required String username,
    required String password,
    StudentLeaveSemester? semester,
  }) async {
    try {
      final ApiResult<GeneralResponse> loginResult = await _ensureLogin(
        username: username,
        password: password,
      );
      switch (loginResult) {
        case ApiSuccess<GeneralResponse>():
          break;
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<List<StudentLeaveRecord>>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<List<StudentLeaveRecord>>(response);
      }
      final Object sessionIdentity = _sessionIdentity;
      final CancelToken cancelToken = _sessionCancelToken;
      final StudentLeaveSemester selectedSemester =
          semester ?? StudentLeaveSemester.current();
      final Response<Uint8List> response = await _getHtml(
        _studentViewUrl(username: username, semester: selectedSemester),
        cancelToken: cancelToken,
      );
      final String text = big5.decode(response.data!);
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<List<StudentLeaveRecord>>(_sessionExpired);
      }
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        _resetSession();
        return const ApiError<List<StudentLeaveRecord>>(_sessionExpired);
      }
      return ApiSuccess<List<StudentLeaveRecord>>(
        parseStudentLeaveRecords(text),
      );
    } on DioException catch (e) {
      return ApiFailure<List<StudentLeaveRecord>>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<List<StudentLeaveRecord>>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<StudentLeaveSubmitResult>> confirmLeave({
    required StudentLeaveConfirmForm confirmForm,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _confirmLeave(confirmForm: confirmForm),
    );
  }

  Future<ApiResult<Uint8List>> downloadProof({
    required String username,
    required String password,
    required String proofUrl,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _downloadProof(
        username: username,
        password: password,
        proofUrl: proofUrl,
      ),
    );
  }

  Future<ApiResult<Uint8List>> _downloadProof({
    required String username,
    required String password,
    required String proofUrl,
  }) async {
    final Uri? proofUri = _proofUri(proofUrl);
    if (proofUri == null) {
      return const ApiError<Uint8List>(_invalidProofResponse);
    }
    try {
      final ApiResult<GeneralResponse> loginResult = await _ensureLogin(
        username: username,
        password: password,
      );
      switch (loginResult) {
        case ApiSuccess<GeneralResponse>():
          break;
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<Uint8List>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<Uint8List>(response);
      }
      final Object sessionIdentity = _sessionIdentity;
      final CancelToken cancelToken = _sessionCancelToken;
      final Response<ResponseBody> response = await dio.get<ResponseBody>(
        proofUri.toString(),
        options: _streamOption,
        cancelToken: cancelToken,
      );
      final ResponseBody? responseBody = response.data;
      if (responseBody == null) {
        return const ApiError<Uint8List>(_invalidProofResponse);
      }
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final Uint8List chunk in responseBody.stream) {
        if (builder.length + chunk.length > _maxProofBytes) {
          return const ApiError<Uint8List>(_invalidProofResponse);
        }
        builder.add(chunk);
      }
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<Uint8List>(_sessionExpired);
      }
      final Uint8List bytes = builder.takeBytes();
      if (!_hasPdfSignature(bytes)) {
        final String text = big5.decode(bytes);
        if (_isSessionExpired(text)) {
          _resetSession();
          return const ApiError<Uint8List>(_sessionExpired);
        }
        return const ApiError<Uint8List>(_invalidProofResponse);
      }
      return ApiSuccess<Uint8List>(bytes);
    } on DioException catch (e) {
      return ApiFailure<Uint8List>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<Uint8List>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<StudentLeaveSubmitResult>> _confirmLeave({
    required StudentLeaveConfirmForm confirmForm,
  }) async {
    final Uri? confirmUri = _confirmActionUri(confirmForm.action);
    if (confirmUri == null) {
      return const ApiError<StudentLeaveSubmitResult>(_invalidConfirmAction);
    }
    if (!_hasActiveSession) {
      return const ApiError<StudentLeaveSubmitResult>(_sessionExpired);
    }
    final Object sessionIdentity = _sessionIdentity;
    final CancelToken cancelToken = _sessionCancelToken;
    if (!confirmForm.isBoundToSession(sessionIdentity) ||
        !_pendingConfirmForms.remove(confirmForm)) {
      return const ApiError<StudentLeaveSubmitResult>(_invalidConfirmSession);
    }
    try {
      final Map<String, String> fields = Map<String, String>.of(
        confirmForm.fields,
      );
      final String? reason = fields['sla_cont'];
      if (reason != null) fields['sla_cont'] = Uri.encodeFull(reason);
      final Response<Uint8List> response = await _postHtml(
        confirmUri.toString(),
        data: fields,
        formEncoded: true,
        cancelToken: cancelToken,
      );
      final String text = big5.decode(response.data!);
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<StudentLeaveSubmitResult>(_sessionExpired);
      }
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        _resetSession();
        return const ApiError<StudentLeaveSubmitResult>(_sessionExpired);
      }
      return ApiSuccess<StudentLeaveSubmitResult>(
        StudentLeaveSubmitResult(
          statusCode: response.statusCode,
          body: text,
          confirmation: parseStudentLeaveConfirmation(text),
        ),
      );
    } on DioException catch (e) {
      return ApiFailure<StudentLeaveSubmitResult>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<StudentLeaveSubmitResult>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<GeneralResponse>> checkLeaveDeletion({
    required String username,
    required String password,
    required String leaveNumber,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _checkLeaveDeletion(
        username: username,
        password: password,
        leaveNumber: leaveNumber,
      ),
    );
  }

  Future<ApiResult<GeneralResponse>> _checkLeaveDeletion({
    required String username,
    required String password,
    required String leaveNumber,
  }) async {
    if (!_isValidLeaveNumber(leaveNumber)) {
      return const ApiError<GeneralResponse>(_invalidLeaveRequest);
    }
    try {
      final ApiResult<GeneralResponse> loginResult = await _ensureLogin(
        username: username,
        password: password,
      );
      switch (loginResult) {
        case ApiSuccess<GeneralResponse>():
          break;
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<GeneralResponse>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<GeneralResponse>(response);
      }
      final Object sessionIdentity = _sessionIdentity;
      final CancelToken cancelToken = _sessionCancelToken;

      final Response<Uint8List> checkResponse = await _getHtml(
        _leaveMaintenanceUri(leaveNumber, 'check').toString(),
        cancelToken: cancelToken,
      );
      final String checkText = big5.decode(checkResponse.data!);
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<GeneralResponse>(_sessionExpired);
      }
      if (_isSessionExpired(checkText)) {
        _resetSession();
        return const ApiError<GeneralResponse>(_sessionExpired);
      }
      if (!_authorizesLeaveDeletion(checkText, leaveNumber)) {
        return const ApiError<GeneralResponse>(_deleteCheckRejected);
      }
      _authorizedDeletions[leaveNumber] = DateTime.now().add(
        _deleteAuthorizationLifetime,
      );
      return ApiSuccess<GeneralResponse>(GeneralResponse.success());
    } on DioException catch (e) {
      return ApiFailure<GeneralResponse>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<GeneralResponse>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<StudentLeaveDeleteResult>> deleteLeave({
    required String leaveNumber,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(
      generation,
      () => _deleteLeave(leaveNumber: leaveNumber),
      preserveDeletionAuthorization: true,
    );
  }

  Future<ApiResult<StudentLeaveDeleteResult>> checkAndDeleteLeave({
    required String username,
    required String password,
    required String leaveNumber,
  }) {
    final int generation = _sessionGeneration;
    return _withSessionOperation(generation, () async {
      final ApiResult<GeneralResponse> checkResult = await _checkLeaveDeletion(
        username: username,
        password: password,
        leaveNumber: leaveNumber,
      );
      switch (checkResult) {
        case ApiSuccess<GeneralResponse>():
          return _deleteLeave(leaveNumber: leaveNumber);
        case ApiFailure<GeneralResponse>(:final DioException exception):
          return ApiFailure<StudentLeaveDeleteResult>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<StudentLeaveDeleteResult>(response);
      }
    });
  }

  Future<ApiResult<StudentLeaveDeleteResult>> _deleteLeave({
    required String leaveNumber,
  }) async {
    if (!_hasActiveSession) {
      return const ApiError<StudentLeaveDeleteResult>(_sessionExpired);
    }
    final DateTime? authorizationExpiresAt = _authorizedDeletions.remove(
      leaveNumber,
    );
    if (!_isValidLeaveNumber(leaveNumber) ||
        authorizationExpiresAt == null ||
        DateTime.now().isAfter(authorizationExpiresAt)) {
      return const ApiError<StudentLeaveDeleteResult>(
        _invalidDeleteAuthorization,
      );
    }
    final Object sessionIdentity = _sessionIdentity;
    final CancelToken cancelToken = _sessionCancelToken;
    try {
      final Response<Uint8List> deleteResponse = await _getHtml(
        _leaveMaintenanceUri(leaveNumber, 'del').toString(),
        cancelToken: cancelToken,
      );
      final String text = big5.decode(deleteResponse.data!);
      if (!identical(sessionIdentity, _sessionIdentity)) {
        return const ApiError<StudentLeaveDeleteResult>(_sessionExpired);
      }
      if (_isSessionExpired(text)) {
        _resetSession();
        return const ApiError<StudentLeaveDeleteResult>(_sessionExpired);
      }
      return ApiSuccess<StudentLeaveDeleteResult>(
        StudentLeaveDeleteResult(
          statusCode: deleteResponse.statusCode,
          body: text,
        ),
      );
    } on DioException catch (e) {
      return ApiFailure<StudentLeaveDeleteResult>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<StudentLeaveDeleteResult>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<GeneralResponse>> _ensureLogin({
    required String username,
    required String password,
  }) async {
    if (isLogin && this.username == username) {
      return ApiSuccess<GeneralResponse>(GeneralResponse.success());
    }
    return _login(username: username, password: password);
  }

  Future<Response<Uint8List>> _getHtml(
    String url, {
    required CancelToken cancelToken,
  }) async {
    final Response<ResponseBody> response = await dio.get<ResponseBody>(
      url,
      options: _streamOption,
      cancelToken: cancelToken,
    );
    return _boundedHtmlResponse(response);
  }

  Future<Response<Uint8List>> _postHtml(
    String url, {
    required Object? data,
    required bool formEncoded,
    required CancelToken cancelToken,
  }) async {
    final Response<ResponseBody> response = await dio.post<ResponseBody>(
      url,
      options: formEncoded ? _streamFormOption : _streamOption,
      data: data,
      cancelToken: cancelToken,
    );
    return _boundedHtmlResponse(response);
  }

  Future<Response<Uint8List>> _boundedHtmlResponse(
    Response<ResponseBody> response,
  ) async {
    final ResponseBody? responseBody = response.data;
    if (responseBody == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'missing student leave response body',
      );
    }
    final int? declaredLength = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    if (declaredLength != null && declaredLength > _maxHtmlBytes) {
      final StreamSubscription<Uint8List> subscription = responseBody.stream
          .listen((_) {});
      await subscription.cancel();
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        message: 'student leave response exceeds the size limit',
      );
    }

    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final Uint8List chunk in responseBody.stream) {
      if (builder.length + chunk.length > _maxHtmlBytes) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.badResponse,
          message: 'student leave response exceeds the size limit',
        );
      }
      builder.add(chunk);
    }
    return Response<Uint8List>(
      data: builder.takeBytes(),
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: response.extra,
      headers: response.headers,
    );
  }

  Future<String?> _prepareLeaveSession(
    String username, {
    required CancelToken cancelToken,
  }) async {
    final StudentLeaveSemester currentSemester = StudentLeaveSemester.current();
    final Response<Uint8List> studentViewResponse = await _getHtml(
      _studentViewUrl(username: username, semester: currentSemester),
      cancelToken: cancelToken,
    );
    if (_isSessionExpired(big5.decode(studentViewResponse.data!))) {
      _resetSession();
      return null;
    }
    final Response<Uint8List> addPageResponse = await _getHtml(
      '$baseUrl/SLAMS/SLAMS_stuLeave_add.php',
      cancelToken: cancelToken,
    );
    if (_isSessionExpired(big5.decode(addPageResponse.data!))) {
      _resetSession();
      return null;
    }
    return big5.decode(addPageResponse.data!);
  }

  String _studentViewUrl({
    required String username,
    required StudentLeaveSemester semester,
  }) {
    final String encodedId = Uri.encodeQueryComponent(
      base64.encode(utf8.encode(username)),
    );
    return '$baseUrl/SLAMS/SLAMS_student_view.php?'
        'ID=$encodedId&GPID=07&APFLAG=49&search_type=year&'
        'school_year=${semester.schoolYear}&sem=${semester.semester}';
  }

  Uri _leaveMaintenanceUri(String leaveNumber, String action) {
    return Uri.parse('$baseUrl/SLAMS/SLAMS_stuLeave_ischecked.php').replace(
      queryParameters: <String, String>{'SLA_SNO': leaveNumber, 'act': action},
    );
  }

  bool _authorizesLeaveDeletion(String text, String leaveNumber) {
    final RegExp assignmentPattern = RegExp(
      r'''^\s*(?:window\.)?location\.href\s*=\s*(?:"([^"]+)"|'([^']+)')\s*;?\s*$''',
      caseSensitive: false,
    );
    const Set<String> executableScriptTypes = <String>{
      '',
      'module',
      'text/javascript',
      'application/javascript',
      'text/ecmascript',
      'application/ecmascript',
    };
    final List<RegExpMatch> assignments = html_parser
        .parse(text, encoding: 'BIG-5')
        .getElementsByTagName('script')
        .where((element) {
          final String type = (element.attributes['type'] ?? '')
              .trim()
              .toLowerCase();
          return element.attributes['src'] == null &&
              executableScriptTypes.contains(type);
        })
        .map((element) => assignmentPattern.firstMatch(element.text))
        .whereType<RegExpMatch>()
        .toList();
    if (assignments.length != 1) return false;

    final String action =
        (assignments.single.group(1) ?? assignments.single.group(2)!)
            .replaceAll('&amp;', '&');
    final Uri? candidate = Uri.tryParse(action);
    if (candidate == null) return false;
    final Uri baseUri = Uri.parse('$baseUrl/SLAMS/');
    final Uri resolved = baseUri.resolveUri(candidate);
    final List<String>? leaveNumbers = resolved.queryParametersAll['SLA_SNO'];
    final List<String>? actions = resolved.queryParametersAll['act'];
    return resolved.scheme == baseUri.scheme &&
        resolved.host == baseUri.host &&
        resolved.port == baseUri.port &&
        resolved.userInfo.isEmpty &&
        !resolved.hasFragment &&
        resolved.path == '/SLAMS/SLAMS_stuLeave_ischecked.php' &&
        leaveNumbers?.length == 1 &&
        leaveNumbers!.single == leaveNumber &&
        actions?.length == 1 &&
        actions!.single == 'del';
  }

  bool _isSessionExpired(String text) =>
      text.contains('loginCheck.php') || text.contains('請重新登入');

  bool get _hasActiveSession => isLogin && username.isNotEmpty;

  Uri? _confirmActionUri(String action) {
    final String trimmedAction = action.trim();
    if (trimmedAction.isEmpty) return null;
    final Uri? parsedAction = Uri.tryParse(trimmedAction);
    if (parsedAction == null) return null;

    final Uri baseUri = Uri.parse('$baseUrl/SLAMS/');
    final Uri resolvedUri = baseUri.resolveUri(parsedAction);
    if (resolvedUri.scheme != 'https' ||
        resolvedUri.host != baseUri.host ||
        resolvedUri.port != baseUri.port ||
        resolvedUri.userInfo.isNotEmpty ||
        resolvedUri.hasFragment ||
        resolvedUri.path != '/SLAMS/SLAMS_stuLeave_add_act.php') {
      return null;
    }
    return resolvedUri;
  }

  Uri? _proofUri(String proofUrl) {
    final Uri? parsedUri = Uri.tryParse(proofUrl.trim());
    if (parsedUri == null) return null;
    final Uri baseUri = Uri.parse('$baseUrl/SLAMS/');
    final Uri resolvedUri = baseUri.resolveUri(parsedUri);
    final bool allowedPath =
        resolvedUri.path == '/SLAMS/download.php' ||
        resolvedUri.path.startsWith('/doctr02/');
    if (resolvedUri.scheme != baseUri.scheme ||
        resolvedUri.host != baseUri.host ||
        resolvedUri.port != baseUri.port ||
        resolvedUri.userInfo.isNotEmpty ||
        resolvedUri.hasFragment ||
        !allowedPath) {
      return null;
    }
    return resolvedUri;
  }

  Future<Object?> _submitData(
    StudentLeaveRequest request,
    StudentLeaveFormConstraints constraints,
  ) async {
    final Map<String, dynamic> fields = <String, dynamic>{
      'Lclass': request.leaveClass,
      'class_name': request.type.code,
      'start_date': _formatDate(request.startDateTime),
      'start_time': _formatTime(request.startDateTime),
      'end_date': _formatDate(request.endDateTime),
      'end_time': _formatTime(request.endDateTime),
      'sla_cont': Uri.encodeFull(request.reason.trim()),
    };
    final StudentLeaveAttachment? attachment = request.attachment;
    if (attachment == null || !attachment.hasData) {
      return fields.cast<String, String>();
    }
    final Uint8List attachmentBytes;
    try {
      final Uint8List? loadedBytes = await _attachmentBytes(
        attachment,
        maxBytes: constraints.maxAttachmentBytes,
      );
      if (loadedBytes == null || !_hasPdfSignature(loadedBytes)) return null;
      attachmentBytes = loadedBytes;
    } on Exception catch (_) {
      return null;
    }
    if (constraints.validate(
          request,
          attachmentSizeBytes: attachmentBytes.length,
        ) !=
        null) {
      return null;
    }
    fields['upload_file'] = MultipartFile.fromBytes(
      attachmentBytes,
      filename: attachment.fileName,
      contentType: DioMediaType('application', 'pdf'),
    );
    return FormData.fromMap(fields);
  }

  Future<Uint8List?> _attachmentBytes(
    StudentLeaveAttachment attachment, {
    required int maxBytes,
  }) async {
    final Uint8List? bytes = attachment.bytes;
    if (bytes != null) return Uint8List.fromList(bytes);

    final String? filePath = attachment.filePath;
    if (filePath == null || filePath.trim().isEmpty) return null;
    final File file = File(filePath);
    final RandomAccessFile openedFile = await file.open();
    try {
      final int fileLength = await openedFile.length();
      if (fileLength <= 0 || fileLength > maxBytes) return null;
      final Uint8List loadedBytes = await openedFile.read(maxBytes + 1);
      if (loadedBytes.isEmpty || loadedBytes.length > maxBytes) return null;
      return loadedBytes;
    } finally {
      await openedFile.close();
    }
  }

  bool _hasPdfSignature(Uint8List bytes) {
    const List<int> signature = <int>[0x25, 0x50, 0x44, 0x46, 0x2D];
    final int scanLength = bytes.length < 1024 ? bytes.length : 1024;
    for (int offset = 0; offset <= scanLength - signature.length; offset++) {
      bool matches = true;
      for (int index = 0; index < signature.length; index++) {
        if (bytes[offset + index] != signature[index]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  String _formatDate(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isValidLeaveNumber(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(value);

  Future<ApiResult<T>> _withSessionOperation<T>(
    int expectedGeneration,
    Future<ApiResult<T>> Function() operation, {
    bool preserveDeletionAuthorization = false,
  }) {
    return _withSessionLock(() async {
      if (expectedGeneration != _sessionGeneration) {
        return ApiError<T>(_sessionExpired);
      }
      if (!preserveDeletionAuthorization) _authorizedDeletions.clear();
      return operation().timeout(
        _operationTimeout,
        onTimeout: () {
          _resetSession();
          return ApiError<T>(_operationTimedOut);
        },
      );
    });
  }

  Future<T> _withSessionLock<T>(Future<T> Function() operation) {
    final Future<void> previous = _sessionQueue;
    final Completer<void> release = Completer<void>();
    _sessionQueue = release.future;
    return () async {
      await previous;
      try {
        return await operation();
      } finally {
        release.complete();
      }
    }();
  }
}
