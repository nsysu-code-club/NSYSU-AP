import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:dio/dio.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  test('login starts with a fresh cookie jar', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (RequestOptions options) {
        return switch (options.uri.path) {
          '/include/loginCheck.php' => _htmlResponse(
            '<a href="afterCheck.php?OK=NEW_TOKEN">continue</a>',
          ),
          '/include/afterCheck.php' => _htmlResponse('<html></html>'),
          '/main.php' => _htmlResponse('<html>student dashboard</html>'),
          _ => _htmlResponse('<html></html>'),
        };
      },
    );
    helper.dio.httpClientAdapter = adapter;
    await helper.cookieJar.saveFromResponse(
      Uri.parse(StudentLeaveHelper.baseUrl),
      <Cookie>[Cookie('SIS_SESSION', 'old-session')],
    );
    helper
      ..isLogin = true
      ..username = 'old-student';
    addTearDown(helper.dio.close);

    final ApiResult<GeneralResponse> result = await helper.login(
      username: 'new-student',
      password: 'password',
    );

    expect(result, isA<ApiSuccess<GeneralResponse>>());
    expect(helper.isLogin, isTrue);
    expect(helper.username, 'new-student');
    expect(adapter.requests, hasLength(3));
    expect(
      adapter.requests.first.headers[HttpHeaders.cookieHeader]?.toString(),
      anyOf(isNull, isNot(contains('old-session'))),
    );
    expect(adapter.requestUris[1].queryParameters['OK'], 'NEW_TOKEN');
  });

  test('login fails closed when the dynamic OK token is missing', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (_) => _htmlResponse('<html>login failed</html>'),
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'old-student';
    addTearDown(helper.dio.close);

    final ApiResult<GeneralResponse> result = await helper.login(
      username: 'new-student',
      password: 'wrong-password',
    );

    expect(result, isA<ApiError<GeneralResponse>>());
    expect(helper.isLogin, isFalse);
    expect(helper.username, isEmpty);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requestUris.single.path, '/include/loginCheck.php');
  });

  test('getLeaveRecords sends the selected academic semester', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<List<StudentLeaveRecord>> result = await helper
        .getLeaveRecords(
          username: 'student',
          password: 'password',
          semester: const StudentLeaveSemester(schoolYear: 113, semester: 1),
        );

    expect(result, isA<ApiSuccess<List<StudentLeaveRecord>>>());
    expect(
      adapter.requestUri?.queryParameters['ID'],
      base64.encode(utf8.encode('student')),
    );
    expect(adapter.requestUri?.queryParameters['school_year'], '113');
    expect(adapter.requestUri?.queryParameters['sem'], '1');
  });

  for (final int expiredStep in <int>[1, 2]) {
    test(
      'expired preparation session at step $expiredStep stops before posting',
      () async {
        int requestCount = 0;
        final StudentLeaveHelper helper = StudentLeaveHelper();
        final _RecordingAdapter adapter = _RecordingAdapter(
          responseFactory: (_) {
            requestCount++;
            return _htmlResponse(
              requestCount == expiredStep
                  ? '<a href="/include/loginCheck.php">login</a>'
                  : '<html>authenticated</html>',
            );
          },
        );
        helper.dio.httpClientAdapter = adapter;
        await helper.cookieJar.saveFromResponse(
          Uri.parse(StudentLeaveHelper.baseUrl),
          <Cookie>[Cookie('SIS_SESSION', 'expired-session')],
        );
        helper
          ..isLogin = true
          ..username = 'student';
        addTearDown(helper.dio.close);

        final ApiResult<StudentLeavePreviewResult> result = await helper
            .previewLeave(
              username: 'student',
              password: 'password',
              request: _leaveRequest(),
            );

        expect(result, isA<ApiError<StudentLeavePreviewResult>>());
        expect(helper.isLogin, isFalse);
        expect(helper.username, isEmpty);
        expect(adapter.requests, hasLength(expiredStep));
        expect(
          adapter.requestUris.map((Uri uri) => uri.path),
          isNot(contains('/SLAMS/SLAMS_stuLeave_add_view.php')),
        );
        expect(
          await helper.cookieJar.loadForRequest(
            Uri.parse(StudentLeaveHelper.baseUrl),
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'authenticated preparation reaches the trusted preview endpoint',
    () async {
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: (RequestOptions options) {
          if (options.uri.path == '/SLAMS/SLAMS_stuLeave_add_view.php') {
            return _htmlResponse('''
            <form action="SLAMS_stuLeave_add_act.php">
              <input name="Lclass" value="1">
              <input name="sub_Lclass" value="12">
              <input name="s_date" value="2026/08/11">
              <input name="s_time" value="09:00">
              <input name="e_date" value="2026/08/11">
              <input name="e_time" value="10:00">
            </form>
          ''');
          }
          return _htmlResponse('<html>authenticated</html>');
        },
      );
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      final ApiResult<StudentLeavePreviewResult> result = await helper
          .previewLeave(
            username: 'student',
            password: 'password',
            request: _leaveRequest(),
          );

      expect(result, isA<ApiSuccess<StudentLeavePreviewResult>>());
      expect(adapter.requests, hasLength(3));
      expect(adapter.requests.last.method, 'POST');
      expect(
        adapter.requestUris.last.path,
        '/SLAMS/SLAMS_stuLeave_add_view.php',
      );
    },
  );

  test('confirmLeave only posts to the expected SIS endpoint', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    const List<String> rejectedActions = <String>[
      '',
      'http://sis.nsysu.edu.tw/SLAMS/SLAMS_stuLeave_add_act.php',
      'https://example.com/collect',
      'https://sis.nsysu.edu.tw:444/SLAMS/SLAMS_stuLeave_add_act.php',
      'https://sis.nsysu.edu.tw/SLAMS/other.php',
      '//example.com/SLAMS/SLAMS_stuLeave_add_act.php',
    ];

    for (final String action in rejectedActions) {
      final ApiResult<StudentLeaveSubmitResult> result = await helper
          .confirmLeave(
            confirmForm: StudentLeaveConfirmForm(
              action: action,
              fields: const <String, String>{'confirm': '1'},
            ),
          );
      expect(result, isA<ApiError<StudentLeaveSubmitResult>>(), reason: action);
    }
    expect(adapter.requests, isEmpty);

    final ApiResult<StudentLeaveSubmitResult> acceptedResult = await helper
        .confirmLeave(
          confirmForm: const StudentLeaveConfirmForm(
            action: 'SLAMS_stuLeave_add_act.php?token=expected',
            fields: <String, String>{'confirm': '1'},
          ),
        );
    expect(acceptedResult, isA<ApiSuccess<StudentLeaveSubmitResult>>());
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requestUris.single.path,
      '/SLAMS/SLAMS_stuLeave_add_act.php',
    );
    expect(adapter.requestUris.single.queryParameters['token'], 'expected');
  });

  test('destructive follow-up requests require an active session', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    addTearDown(helper.dio.close);

    final ApiResult<StudentLeaveSubmitResult> confirmResult = await helper
        .confirmLeave(
          confirmForm: const StudentLeaveConfirmForm(
            action: 'SLAMS_stuLeave_add_act.php',
            fields: <String, String>{'confirm': '1'},
          ),
        );
    final ApiResult<StudentLeaveDeleteResult> deleteResult = await helper
        .deleteLeave(leaveNumber: 'SL1130001');

    expect(confirmResult, isA<ApiError<StudentLeaveSubmitResult>>());
    expect(deleteResult, isA<ApiError<StudentLeaveDeleteResult>>());
    expect(adapter.requests, isEmpty);
  });

  test('leave deletion follows the SIS check then delete sequence', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<GeneralResponse> checkResult = await helper
        .checkLeaveDeletion(
          username: 'student',
          password: 'password',
          leaveNumber: 'B1232450051150811',
        );
    final ApiResult<StudentLeaveDeleteResult> result = await helper.deleteLeave(
      leaveNumber: 'B1232450051150811',
    );

    expect(checkResult, isA<ApiSuccess<GeneralResponse>>());
    expect(result, isA<ApiSuccess<StudentLeaveDeleteResult>>());
    expect(adapter.requestUris, hasLength(2));
    expect(
      adapter.requestUris.map((Uri uri) => uri.queryParameters['act']),
      <String?>['check', 'del'],
    );
    expect(
      adapter.requestUris.map((Uri uri) => uri.queryParameters['SLA_SNO']),
      <String?>['B1232450051150811', 'B1232450051150811'],
    );
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.responseFactory});

  final ResponseBody Function(RequestOptions options)? responseFactory;
  Uri? requestUri;
  final List<Uri> requestUris = <Uri>[];
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUri = options.uri;
    requestUris.add(options.uri);
    requests.add(options);
    return responseFactory?.call(options) ??
        _htmlResponse('<html><body></body></html>');
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _htmlResponse(String body) {
  return ResponseBody.fromBytes(
    utf8.encode(body),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['text/html'],
    },
  );
}

StudentLeaveRequest _leaveRequest() {
  return StudentLeaveRequest(
    type: StudentLeaveType.values.first,
    startDateTime: DateTime(2026, 8, 11, 9),
    endDateTime: DateTime(2026, 8, 11, 10),
    reason: 'private leave reason',
  );
}
