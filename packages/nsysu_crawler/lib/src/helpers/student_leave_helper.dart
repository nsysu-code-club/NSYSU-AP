import 'dart:convert';
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nsysu_crawler/src/build_mode.dart';
import 'package:nsysu_crawler/src/models/student_leave.dart';
import 'package:nsysu_crawler/src/parsers/html_parser.dart';
import 'package:nsysu_crawler/src/utils/big5/big5.dart';

class StudentLeaveHelper {
  static const String baseUrl = 'https://sis.nsysu.edu.tw';

  static StudentLeaveHelper? _instance;

  // ignore: prefer_constructors_over_static_methods
  static StudentLeaveHelper get instance {
    return _instance ??= StudentLeaveHelper();
  }

  StudentLeaveHelper() {
    initCookiesJar();
  }

  Dio dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  CookieJar cookieJar = CookieJar();

  bool isLogin = false;
  String username = '';

  Options get _bytesOption => Options(responseType: ResponseType.bytes);

  Options get _formOption => Options(
    responseType: ResponseType.bytes,
    contentType: Headers.formUrlEncodedContentType,
  );

  void initCookiesJar() {
    cookieJar = CookieJar();
    dio.interceptors.clear();
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(baseUrl));
  }

  void logout() {
    isLogin = false;
    username = '';
    initCookiesJar();
  }

  Future<ApiResult<GeneralResponse>> login({
    required String username,
    required String password,
  }) async {
    try {
      final Response<Uint8List> loginResponse = await dio.post<Uint8List>(
        '$baseUrl/include/loginCheck.php',
        options: _formOption,
        data: <String, String>{
          'tmpid': username,
          'tmpwd': password,
          'tmprole': 'stu',
        },
      );
      final String loginText = big5.decode(loginResponse.data!);
      final String okToken =
          RegExp(
            r'''afterCheck\.php\?OK=([^"']+)''',
          ).firstMatch(loginText)?.group(1) ??
          'MTJZ';

      await dio.get<Uint8List>(
        '$baseUrl/include/afterCheck.php?OK=$okToken',
        options: _bytesOption,
      );
      final Response<Uint8List> mainResponse = await dio.get<Uint8List>(
        '$baseUrl/main.php',
        options: _bytesOption,
      );
      final String mainText = big5.decode(mainResponse.data!);
      if (mainText.contains('loginCheck.php') || mainText.contains('請重新登入')) {
        return const ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 401, message: 'sis login error'),
        );
      }

      this.username = username;
      isLogin = true;
      return ApiSuccess<GeneralResponse>(GeneralResponse.success());
    } on DioException catch (e) {
      return ApiFailure<GeneralResponse>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<GeneralResponse>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<StudentLeavePreviewResult>> previewLeave({
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

      await _prepareLeaveSession(username);

      final Response<Uint8List> response = await dio.post<Uint8List>(
        '$baseUrl/SLAMS/SLAMS_stuLeave_add_view.php',
        options: _submitOption(request),
        data: await _submitData(request),
      );
      final String text = big5.decode(response.data!);
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        isLogin = false;
        return const ApiError<StudentLeavePreviewResult>(
          GeneralResponse(statusCode: 401, message: 'sis session expired'),
        );
      }
      final StudentLeaveConfirmForm? confirmForm = parseStudentLeaveConfirmForm(
        text,
      );
      if (confirmForm == null) {
        return ApiError<StudentLeavePreviewResult>(
          GeneralResponse.unknownError(),
        );
      }
      return ApiSuccess<StudentLeavePreviewResult>(
        StudentLeavePreviewResult(
          statusCode: response.statusCode,
          body: text,
          confirmation: parseStudentLeaveConfirmation(text),
          confirmForm: confirmForm,
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

  Future<ApiResult<List<StudentLeaveRecord>>> getLeaveRecords({
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
      final StudentLeaveSemester selectedSemester =
          semester ?? StudentLeaveSemester.current();
      final Response<Uint8List> response = await dio.get<Uint8List>(
        _studentViewUrl(username: username, semester: selectedSemester),
        options: _bytesOption,
      );
      final String text = big5.decode(response.data!);
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        isLogin = false;
        return const ApiError<List<StudentLeaveRecord>>(
          GeneralResponse(statusCode: 401, message: 'sis session expired'),
        );
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
  }) async {
    try {
      final Response<Uint8List> response = await dio.post<Uint8List>(
        _resolveUrl(confirmForm.action, '$baseUrl/SLAMS/'),
        options: _formOption,
        data: confirmForm.fields,
      );
      final String text = big5.decode(response.data!);
      if (text.contains('loginCheck.php') || text.contains('請重新登入')) {
        isLogin = false;
        return const ApiError<StudentLeaveSubmitResult>(
          GeneralResponse(statusCode: 401, message: 'sis session expired'),
        );
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
          return ApiFailure<GeneralResponse>(exception);
        case ApiError<GeneralResponse>(:final GeneralResponse response):
          return ApiError<GeneralResponse>(response);
      }

      final Response<Uint8List> checkResponse = await dio.get<Uint8List>(
        _leaveMaintenanceUri(leaveNumber, 'check').toString(),
        options: _bytesOption,
      );
      final String checkText = big5.decode(checkResponse.data!);
      if (_isSessionExpired(checkText)) {
        isLogin = false;
        return const ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 401, message: 'sis session expired'),
        );
      }
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
  }) async {
    try {
      final Response<Uint8List> deleteResponse = await dio.get<Uint8List>(
        _leaveMaintenanceUri(leaveNumber, 'del').toString(),
        options: _bytesOption,
      );
      final String text = big5.decode(deleteResponse.data!);
      if (_isSessionExpired(text)) {
        isLogin = false;
        return const ApiError<StudentLeaveDeleteResult>(
          GeneralResponse(statusCode: 401, message: 'sis session expired'),
        );
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
    return login(username: username, password: password);
  }

  Future<void> _prepareLeaveSession(String username) async {
    final StudentLeaveSemester currentSemester = StudentLeaveSemester.current();
    await dio.get<Uint8List>(
      _studentViewUrl(username: username, semester: currentSemester),
      options: _bytesOption,
    );
    await dio.get<Uint8List>(
      '$baseUrl/SLAMS/SLAMS_stuLeave_add.php',
      options: _bytesOption,
    );
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

  bool _isSessionExpired(String text) =>
      text.contains('loginCheck.php') || text.contains('請重新登入');

  Future<Object> _submitData(StudentLeaveRequest request) async {
    final Map<String, dynamic> fields = <String, dynamic>{
      'Lclass': request.leaveClass,
      'class_name': request.type.code,
      'start_date': _formatDate(request.startDateTime),
      'start_time': _formatTime(request.startDateTime),
      'end_date': _formatDate(request.endDateTime),
      'end_time': _formatTime(request.endDateTime),
      'sla_cont': request.reason,
    };
    final StudentLeaveAttachment? attachment = request.attachment;
    if (attachment == null || !attachment.hasData) {
      return fields.cast<String, String>();
    }
    fields['upload_file'] = await _multipartFile(attachment);
    return FormData.fromMap(fields);
  }

  Future<MultipartFile> _multipartFile(
    StudentLeaveAttachment attachment,
  ) async {
    final Uint8List? bytes = attachment.bytes;
    if (bytes != null) {
      return MultipartFile.fromBytes(bytes, filename: attachment.fileName);
    }
    return MultipartFile.fromFile(
      attachment.filePath!,
      filename: attachment.fileName,
    );
  }

  Options _submitOption(StudentLeaveRequest request) {
    if (request.attachment?.hasData ?? false) {
      return Options(responseType: ResponseType.bytes);
    }
    return _formOption;
  }

  String _resolveUrl(String action, String base) {
    if (action.startsWith('http')) return action;
    return Uri.parse(base).resolve(action).toString();
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
}
