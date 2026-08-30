import 'dart:async';
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

    expect(helper.dio.options.followRedirects, isFalse);

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

  test(
    'logout cancels an in-flight login without restoring the session',
    () async {
      final Completer<void> requestStarted = Completer<void>();
      final Completer<void> releaseResponse = Completer<void>();
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        beforeResponse: (RequestOptions options) async {
          if (options.uri.path != '/include/loginCheck.php') return;
          requestStarted.complete();
          await releaseResponse.future;
        },
        responseFactory: (_) => _htmlResponse(
          '<a href="afterCheck.php?OK=SHOULD_NOT_CONTINUE">continue</a>',
        ),
      );
      helper.dio.httpClientAdapter = adapter;
      addTearDown(helper.dio.close);

      final Future<ApiResult<GeneralResponse>> login = helper.login(
        username: 'student',
        password: 'password',
      );
      await requestStarted.future;
      helper.logout();
      releaseResponse.complete();
      final ApiResult<GeneralResponse> result = await login;

      expect(result, isNot(isA<ApiSuccess<GeneralResponse>>()));
      expect(helper.isLogin, isFalse);
      expect(helper.username, isEmpty);
      expect(adapter.requests, hasLength(1));
    },
  );

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

  test('proof downloads stay in the authenticated Dio session', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (_) => _htmlResponse('%PDF-1.7\nproof'),
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<Uint8List> result = await helper.downloadProof(
      username: 'student',
      password: 'password',
      proofUrl: 'https://sis.nsysu.edu.tw/SLAMS/download.php?id=SL1130001',
    );

    expect(result, isA<ApiSuccess<Uint8List>>());
    expect(
      (result as ApiSuccess<Uint8List>).data.sublist(0, 5),
      utf8.encode('%PDF-'),
    );
    expect(adapter.requests, hasLength(1));
    expect(adapter.requestUris.single.path, '/SLAMS/download.php');
    expect(adapter.requests.single.followRedirects, isFalse);
  });

  test('proof downloads reject untrusted URLs before any request', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<Uint8List> result = await helper.downloadProof(
      username: 'student',
      password: 'password',
      proofUrl: 'https://evil.example/SLAMS/download.php?id=SL1130001',
    );

    expect(result, isA<ApiError<Uint8List>>());
    expect(adapter.requests, isEmpty);
  });

  test(
    'HTML responses reject declared and streamed oversized bodies',
    () async {
      const int maximumBytes = 2 * 1024 * 1024;
      final List<ResponseBody Function()> oversizedResponses =
          <ResponseBody Function()>[
            () => ResponseBody.fromBytes(
              Uint8List(maximumBytes + 1),
              200,
              headers: <String, List<String>>{
                Headers.contentLengthHeader: <String>['${maximumBytes + 1}'],
              },
            ),
            () => ResponseBody(
              Stream<Uint8List>.fromIterable(<Uint8List>[
                Uint8List(1024 * 1024),
                Uint8List(1024 * 1024 + 1),
              ]),
              200,
            ),
          ];

      for (final ResponseBody Function() responseFactory
          in oversizedResponses) {
        final StudentLeaveHelper helper = StudentLeaveHelper();
        final _RecordingAdapter adapter = _RecordingAdapter(
          responseFactory: (_) => responseFactory(),
        );
        helper.dio.httpClientAdapter = adapter;
        helper
          ..isLogin = true
          ..username = 'student';
        addTearDown(helper.dio.close);

        expect(
          await helper.getLeaveRecords(
            username: 'student',
            password: 'password',
          ),
          isA<ApiFailure<List<StudentLeaveRecord>>>(),
        );
        expect(adapter.requests, hasLength(1));
      }
    },
  );

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
          if (options.uri.path == '/SLAMS/SLAMS_stuLeave_add.php') {
            return _htmlResponse(_leaveAddForm());
          }
          if (options.uri.path == '/SLAMS/SLAMS_stuLeave_add_view.php') {
            return _htmlResponse(_leaveConfirmForm());
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

  test('getLeaveFormConstraints exposes the current SIS form rules', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (RequestOptions options) => _htmlResponse(
        options.uri.path == '/SLAMS/SLAMS_stuLeave_add.php'
            ? _leaveAddForm()
            : '<html>authenticated</html>',
      ),
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<StudentLeaveFormConstraints> result = await helper
        .getLeaveFormConstraints(username: 'student', password: 'password');

    expect(result, isA<ApiSuccess<StudentLeaveFormConstraints>>());
    final StudentLeaveFormConstraints constraints =
        (result as ApiSuccess<StudentLeaveFormConstraints>).data;
    expect(constraints.maxReasonLength, 100);
    expect(constraints.maxAttachmentBytes, 1572864);
    expect(adapter.requests, hasLength(2));
  });

  test(
    'preview mirrors JavaScript encodeURI before urlencoded serialization',
    () async {
      const String reason = '中文請假 / 50% & #1';
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: _studentLeaveResponse,
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
            request: _leaveRequest(reason: reason),
          );

      expect(result, isA<ApiSuccess<StudentLeavePreviewResult>>());
      final String body = utf8.decode(adapter.requestBodies.last);
      final String encodedReason = Uri.encodeFull(reason);
      expect(
        body,
        contains('sla_cont=${Uri.encodeQueryComponent(encodedReason)}'),
      );
      expect(body, isNot(contains(reason)));
    },
  );

  test(
    'multipart preview keeps the percent-encoded reason and PDF data',
    () async {
      const String reason = '附件請假測試';
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: _studentLeaveResponse,
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
            request: _leaveRequest(
              reason: reason,
              attachment: StudentLeaveAttachment(
                fileName: 'proof.PDF',
                bytes: Uint8List.fromList(utf8.encode('%PDF-1.7\nproof')),
              ),
            ),
          );

      expect(result, isA<ApiSuccess<StudentLeavePreviewResult>>());
      final String body = utf8.decode(
        adapter.requestBodies.last,
        allowMalformed: true,
      );
      expect(body, contains(Uri.encodeFull(reason)));
      expect(body, contains('filename="proof.PDF"'));
      expect(body, contains('content-type: application/pdf'));
      expect(body, isNot(contains(reason)));
      expect(
        adapter.requests.last.headers[Headers.contentTypeHeader].toString(),
        contains('multipart/form-data'),
      );
    },
  );

  test('multipart preview owns caller-provided mutable PDF bytes', () async {
    final Uint8List proofBytes = Uint8List.fromList(
      utf8.encode('%PDF-1.7\noriginal-proof'),
    );
    final Completer<void> uploadReady = Completer<void>();
    final Completer<void> consumeUpload = Completer<void>();
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      beforeRequestBody: (RequestOptions options) async {
        if (options.uri.path != '/SLAMS/SLAMS_stuLeave_add_view.php') return;
        uploadReady.complete();
        await consumeUpload.future;
      },
      responseFactory: _studentLeaveResponse,
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final Future<ApiResult<StudentLeavePreviewResult>> preview = helper
        .previewLeave(
          username: 'student',
          password: 'password',
          request: _leaveRequest(
            attachment: StudentLeaveAttachment(
              fileName: 'proof.pdf',
              bytes: proofBytes,
            ),
          ),
        );
    await uploadReady.future;
    proofBytes.fillRange(0, proofBytes.length, 0x58);
    consumeUpload.complete();

    expect(await preview, isA<ApiSuccess<StudentLeavePreviewResult>>());
    final String body = utf8.decode(
      adapter.requestBodies.last,
      allowMalformed: true,
    );
    expect(body, contains('%PDF-1.7\noriginal-proof'));
  });

  test(
    'multipart preview validates PDF content loaded from a file path',
    () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'student-leave-test-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));
      final File proof = File('${tempDirectory.path}/proof.pdf');
      await proof.writeAsBytes(utf8.encode('%PDF-1.7\nproof'));

      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: _studentLeaveResponse,
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
            request: _leaveRequest(
              attachment: StudentLeaveAttachment(
                fileName: 'proof.pdf',
                filePath: proof.path,
              ),
            ),
          );

      expect(result, isA<ApiSuccess<StudentLeavePreviewResult>>());
      expect(
        adapter.requestUris.last.path,
        '/SLAMS/SLAMS_stuLeave_add_view.php',
      );
      expect(
        utf8.decode(adapter.requestBodies.last, allowMalformed: true),
        contains('%PDF-1.7'),
      );
    },
  );

  test('preview rejects invalid attachments before the preview POST', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: _studentLeaveResponse,
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final List<StudentLeaveAttachment> attachments = <StudentLeaveAttachment>[
      StudentLeaveAttachment(fileName: 'proof.pdf', bytes: Uint8List(1572865)),
      StudentLeaveAttachment(
        fileName: 'proof.jpg',
        bytes: Uint8List.fromList(<int>[1]),
      ),
      StudentLeaveAttachment(
        fileName: 'fake.pdf',
        bytes: Uint8List.fromList(utf8.encode('not a PDF')),
      ),
      const StudentLeaveAttachment(
        fileName: 'proof.pdf',
        filePath: '/missing/proof.pdf',
      ),
    ];

    for (final StudentLeaveAttachment attachment in attachments) {
      final int requestsBefore = adapter.requests.length;
      final ApiResult<StudentLeavePreviewResult> result = await helper
          .previewLeave(
            username: 'student',
            password: 'password',
            request: _leaveRequest(attachment: attachment),
          );
      expect(result, isA<ApiError<StudentLeavePreviewResult>>());
      expect(adapter.requests.length, requestsBefore + 2);
      expect(
        adapter.requestUris.skip(requestsBefore).map((Uri uri) => uri.path),
        isNot(contains('/SLAMS/SLAMS_stuLeave_add_view.php')),
      );
    }
  });

  test('confirmLeave only posts to the expected SIS endpoint', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (RequestOptions options) =>
          _htmlResponse(switch (options.uri.path) {
            '/SLAMS/SLAMS_stuLeave_add.php' => _leaveAddForm(),
            '/SLAMS/SLAMS_stuLeave_add_view.php' => _leaveConfirmForm(
              action: 'SLAMS_stuLeave_add_act.php?token=expected',
            ),
            _ => '<html>authenticated</html>',
          }),
    );
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

    final StudentLeaveConfirmForm confirmForm = await _previewConfirmForm(
      helper,
    );
    final ApiResult<StudentLeaveSubmitResult> acceptedResult = await helper
        .confirmLeave(confirmForm: confirmForm);
    expect(acceptedResult, isA<ApiSuccess<StudentLeaveSubmitResult>>());
    expect(adapter.requests, hasLength(4));
    expect(adapter.requestUris.last.path, '/SLAMS/SLAMS_stuLeave_add_act.php');
    expect(adapter.requestUris.last.queryParameters['token'], 'expected');
  });

  test(
    'confirmLeave mirrors the live confirmation form encodeURI behavior',
    () async {
      const String reason = '最終確認 / 50% & #1';
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: (RequestOptions options) =>
            _htmlResponse(switch (options.uri.path) {
              '/SLAMS/SLAMS_stuLeave_add.php' => _leaveAddForm(),
              '/SLAMS/SLAMS_stuLeave_add_view.php' => _leaveConfirmForm(
                reason: reason,
              ),
              _ => '<html>authenticated</html>',
            }),
      );
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      final StudentLeaveConfirmForm confirmForm = await _previewConfirmForm(
        helper,
        reason: reason,
      );
      final ApiResult<StudentLeaveSubmitResult> result = await helper
          .confirmLeave(confirmForm: confirmForm);

      expect(result, isA<ApiSuccess<StudentLeaveSubmitResult>>());
      expect(
        utf8.decode(adapter.requestBodies.last),
        contains(
          'sla_cont=${Uri.encodeQueryComponent(Uri.encodeFull(reason))}',
        ),
      );
    },
  );

  test('confirm forms are session-bound and single-use', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: _studentLeaveResponse,
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final StudentLeaveConfirmForm confirmForm = await _previewConfirmForm(
      helper,
    );
    final ApiResult<StudentLeaveSubmitResult> first = await helper.confirmLeave(
      confirmForm: confirmForm,
    );
    final int requestCount = adapter.requests.length;
    final ApiResult<StudentLeaveSubmitResult> replay = await helper
        .confirmLeave(confirmForm: confirmForm);

    expect(first, isA<ApiSuccess<StudentLeaveSubmitResult>>());
    expect(replay, isA<ApiError<StudentLeaveSubmitResult>>());
    expect(adapter.requests, hasLength(requestCount));
  });

  test('a confirm form cannot cross a subsequent login session', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (RequestOptions options) => switch (options.uri.path) {
        '/include/loginCheck.php' => _htmlResponse(
          '<a href="afterCheck.php?OK=NEW_TOKEN">continue</a>',
        ),
        '/SLAMS/SLAMS_stuLeave_add.php' => _htmlResponse(_leaveAddForm()),
        '/SLAMS/SLAMS_stuLeave_add_view.php' => _htmlResponse(
          _leaveConfirmForm(),
        ),
        _ => _htmlResponse('<html>authenticated</html>'),
      },
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student-a';
    addTearDown(helper.dio.close);

    final StudentLeaveConfirmForm staleForm = await _previewConfirmForm(
      helper,
      username: 'student-a',
    );
    expect(
      await helper.login(username: 'student-b', password: 'password'),
      isA<ApiSuccess<GeneralResponse>>(),
    );
    final int requestCount = adapter.requests.length;
    final ApiResult<StudentLeaveSubmitResult> result = await helper
        .confirmLeave(confirmForm: staleForm);

    expect(result, isA<ApiError<StudentLeaveSubmitResult>>());
    expect(adapter.requests, hasLength(requestCount));
    expect(
      adapter.requestUris.skip(3).map((Uri uri) => uri.path),
      isNot(contains('/SLAMS/SLAMS_stuLeave_add_act.php')),
    );
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

    final int requestCount = adapter.requests.length;
    expect(
      await helper.deleteLeave(leaveNumber: 'B1232450051150811'),
      isA<ApiError<StudentLeaveDeleteResult>>(),
    );
    expect(adapter.requests, hasLength(requestCount));
  });

  test(
    'leave deletion check rejects an unrelated successful response',
    () async {
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: (_) => _htmlResponse('<html>maintenance</html>'),
      );
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      final ApiResult<GeneralResponse> checkResult = await helper
          .checkLeaveDeletion(
            username: 'student',
            password: 'password',
            leaveNumber: 'SL1130001',
          );
      final ApiResult<StudentLeaveDeleteResult> deleteResult = await helper
          .deleteLeave(leaveNumber: 'SL1130001');

      expect(checkResult, isA<ApiError<GeneralResponse>>());
      expect(deleteResult, isA<ApiError<StudentLeaveDeleteResult>>());
      expect(adapter.requests, hasLength(1));
      expect(adapter.requestUris.single.queryParameters['act'], 'check');
    },
  );

  test('leave deletion check rejects non-executable or ambiguous URLs', () async {
    const List<String> rejectedResponses = <String>[
      '<p>SLAMS_stuLeave_ischecked.php?SLA_SNO=SL1130001&amp;act=del</p>',
      '''<!-- <script>location.href="SLAMS_stuLeave_ischecked.php?SLA_SNO=SL1130001&amp;act=del";</script> -->''',
      '''<script>location.href="SLAMS_stuLeave_ischecked.php?SLA_SNO=SL1130001&amp;SLA_SNO=OTHER&amp;act=del";</script>''',
      '''<script type="application/json">location.href="SLAMS_stuLeave_ischecked.php?SLA_SNO=SL1130001&amp;act=del";</script>''',
      '''<script src="delete.js">location.href="SLAMS_stuLeave_ischecked.php?SLA_SNO=SL1130001&amp;act=del";</script>''',
    ];

    for (final String response in rejectedResponses) {
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        responseFactory: (_) => _htmlResponse(response),
      );
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      expect(
        await helper.checkLeaveDeletion(
          username: 'student',
          password: 'password',
          leaveNumber: 'SL1130001',
        ),
        isA<ApiError<GeneralResponse>>(),
        reason: response,
      );
    }
  });

  test('leave deletion cannot bypass its check request', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    expect(
      await helper.deleteLeave(leaveNumber: 'SL1130001'),
      isA<ApiError<StudentLeaveDeleteResult>>(),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'an intervening session operation invalidates a deletion check',
    () async {
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter();
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      expect(
        await helper.checkLeaveDeletion(
          username: 'student',
          password: 'password',
          leaveNumber: 'SL1130001',
        ),
        isA<ApiSuccess<GeneralResponse>>(),
      );
      expect(
        await helper.getLeaveRecords(username: 'student', password: 'password'),
        isA<ApiSuccess<List<StudentLeaveRecord>>>(),
      );
      expect(
        await helper.deleteLeave(leaveNumber: 'SL1130001'),
        isA<ApiError<StudentLeaveDeleteResult>>(),
      );
      expect(
        adapter.requestUris.map((Uri uri) => uri.queryParameters['act']),
        <String?>['check', null],
      );
    },
  );

  test(
    'check and delete remain atomic against queued session requests',
    () async {
      final Completer<void> checkStarted = Completer<void>();
      final Completer<void> releaseCheck = Completer<void>();
      final StudentLeaveHelper helper = StudentLeaveHelper();
      final _RecordingAdapter adapter = _RecordingAdapter(
        beforeResponse: (RequestOptions options) async {
          if (options.uri.queryParameters['act'] != 'check') return;
          checkStarted.complete();
          await releaseCheck.future;
        },
      );
      helper.dio.httpClientAdapter = adapter;
      helper
        ..isLogin = true
        ..username = 'student';
      addTearDown(helper.dio.close);

      final Future<ApiResult<StudentLeaveDeleteResult>> deletion = helper
          .checkAndDeleteLeave(
            username: 'student',
            password: 'password',
            leaveNumber: 'SL1130001',
          );
      await checkStarted.future;
      final Future<ApiResult<List<StudentLeaveRecord>>> records = helper
          .getLeaveRecords(username: 'student', password: 'password');
      releaseCheck.complete();

      expect(await deletion, isA<ApiSuccess<StudentLeaveDeleteResult>>());
      expect(await records, isA<ApiSuccess<List<StudentLeaveRecord>>>());
      expect(
        adapter.requestUris.map((Uri uri) => uri.queryParameters['act']),
        <String?>['check', 'del', null],
      );
    },
  );

  test('a deletion check cannot cross a subsequent login session', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      responseFactory: (RequestOptions options) {
        if (options.uri.queryParameters['act'] == 'check') {
          return _authorizedDeleteCheckResponse(options);
        }
        return options.uri.path == '/include/loginCheck.php'
            ? _htmlResponse(
                '<a href="afterCheck.php?OK=NEW_TOKEN">continue</a>',
              )
            : _htmlResponse('<html>authenticated</html>');
      },
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student-a';
    addTearDown(helper.dio.close);

    expect(
      await helper.checkLeaveDeletion(
        username: 'student-a',
        password: 'password',
        leaveNumber: 'SL1130001',
      ),
      isA<ApiSuccess<GeneralResponse>>(),
    );
    expect(
      await helper.login(username: 'student-b', password: 'password'),
      isA<ApiSuccess<GeneralResponse>>(),
    );
    final int requestCount = adapter.requests.length;

    expect(
      await helper.deleteLeave(leaveNumber: 'SL1130001'),
      isA<ApiError<StudentLeaveDeleteResult>>(),
    );
    expect(adapter.requests, hasLength(requestCount));
  });

  test('stateful SIS requests are serialized', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      beforeResponse: (_) =>
          Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    await Future.wait(<Future<ApiResult<List<StudentLeaveRecord>>>>[
      helper.getLeaveRecords(username: 'student', password: 'password'),
      helper.getLeaveRecords(username: 'student', password: 'password'),
    ]);

    expect(adapter.requests, hasLength(2));
    expect(adapter.maxConcurrentRequests, 1);
  });

  test('logout invalidates in-flight and queued record requests', () async {
    final Completer<void> requestStarted = Completer<void>();
    final Completer<void> releaseResponse = Completer<void>();
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter(
      beforeResponse: (_) async {
        requestStarted.complete();
        await releaseResponse.future;
      },
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final Future<ApiResult<List<StudentLeaveRecord>>> first = helper
        .getLeaveRecords(username: 'student', password: 'password');
    await requestStarted.future;
    final Future<ApiResult<List<StudentLeaveRecord>>> queued = helper
        .getLeaveRecords(username: 'student', password: 'password');
    helper.logout();
    releaseResponse.complete();

    expect(await first, isNot(isA<ApiSuccess<List<StudentLeaveRecord>>>()));
    expect(await queued, isNot(isA<ApiSuccess<List<StudentLeaveRecord>>>()));
    expect(adapter.requests, hasLength(1));
    expect(helper.isLogin, isFalse);
  });

  test('a total operation deadline cancels the active session', () async {
    final Completer<void> requestStarted = Completer<void>();
    final Completer<void> releaseResponse = Completer<void>();
    final StudentLeaveHelper helper = StudentLeaveHelper(
      operationTimeout: const Duration(milliseconds: 20),
    );
    final _RecordingAdapter adapter = _RecordingAdapter(
      beforeResponse: (_) async {
        requestStarted.complete();
        await releaseResponse.future;
      },
    );
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final Future<ApiResult<List<StudentLeaveRecord>>> records = helper
        .getLeaveRecords(username: 'student', password: 'password');
    await requestStarted.future;
    final ApiResult<List<StudentLeaveRecord>> result = await records;
    releaseResponse.complete();

    expect(result, isA<ApiError<List<StudentLeaveRecord>>>());
    expect(helper.isLogin, isFalse);
    expect(helper.username, isEmpty);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    this.responseFactory,
    this.beforeRequestBody,
    this.beforeResponse,
  });

  final ResponseBody Function(RequestOptions options)? responseFactory;
  final Future<void> Function(RequestOptions options)? beforeRequestBody;
  final Future<void> Function(RequestOptions options)? beforeResponse;
  Uri? requestUri;
  final List<Uri> requestUris = <Uri>[];
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<Uint8List> requestBodies = <Uint8List>[];
  int _concurrentRequests = 0;
  int maxConcurrentRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUri = options.uri;
    requestUris.add(options.uri);
    requests.add(options);
    _concurrentRequests++;
    if (_concurrentRequests > maxConcurrentRequests) {
      maxConcurrentRequests = _concurrentRequests;
    }
    final BytesBuilder bodyBuilder = BytesBuilder(copy: false);
    try {
      await beforeRequestBody?.call(options);
      if (requestStream != null) {
        await for (final Uint8List chunk in requestStream) {
          bodyBuilder.add(chunk);
        }
      }
      requestBodies.add(bodyBuilder.takeBytes());
      await beforeResponse?.call(options);
      return responseFactory?.call(options) ??
          (options.uri.queryParameters['act'] == 'check'
              ? _authorizedDeleteCheckResponse(options)
              : _htmlResponse('<html><body></body></html>'));
    } finally {
      _concurrentRequests--;
    }
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _htmlResponse(String body) {
  return ResponseBody.fromBytes(
    big5.encode(body),
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['text/html'],
    },
  );
}

ResponseBody _authorizedDeleteCheckResponse(RequestOptions options) {
  final String? leaveNumber = options.uri.queryParameters['SLA_SNO'];
  return _htmlResponse('''
<script>
location.href = "SLAMS_stuLeave_ischecked.php?SLA_SNO=$leaveNumber&amp;act=del";
</script>
''');
}

StudentLeaveRequest _leaveRequest({
  String reason = 'private leave reason',
  StudentLeaveAttachment? attachment,
}) {
  return StudentLeaveRequest(
    type: StudentLeaveType.values.first,
    startDateTime: DateTime(2026, 8, 11, 9),
    endDateTime: DateTime(2026, 8, 11, 10),
    reason: reason,
    attachment: attachment,
  );
}

ResponseBody _studentLeaveResponse(RequestOptions options) {
  return _htmlResponse(switch (options.uri.path) {
    '/SLAMS/SLAMS_stuLeave_add.php' => _leaveAddForm(),
    '/SLAMS/SLAMS_stuLeave_add_view.php' => _leaveConfirmForm(),
    _ => '<html>authenticated</html>',
  });
}

Future<StudentLeaveConfirmForm> _previewConfirmForm(
  StudentLeaveHelper helper, {
  String username = 'student',
  String reason = 'private leave reason',
}) async {
  final ApiResult<StudentLeavePreviewResult> preview = await helper
      .previewLeave(
        username: username,
        password: 'password',
        request: _leaveRequest(reason: reason),
      );
  expect(preview, isA<ApiSuccess<StudentLeavePreviewResult>>());
  return (preview as ApiSuccess<StudentLeavePreviewResult>).data.confirmForm;
}

String _leaveAddForm() => '''
<script>const maxSize = 1.5 * 1024 * 1024;</script>
<form action="SLAMS_stuLeave_add_view.php">
  <select name="class_name"><option value="11">Official leave</option></select>
  <input name="start_date" min="2026-03-01">
  <select name="start_time">
    <option value="09:00">09:00</option><option value="10:00">10:00</option>
  </select>
  <input name="end_date" max="2026-09-30">
  <select name="end_time">
    <option value="09:00">09:00</option><option value="10:00">10:00</option>
  </select>
  <textarea name="sla_cont" maxlength="100"></textarea>
  <input name="upload_file" type="file" accept=".pdf">
</form>
''';

String _leaveConfirmForm({
  String action = 'SLAMS_stuLeave_add_act.php',
  String reason = 'private leave reason',
}) =>
    '''
<form action="$action">
  <input name="Lclass" value="1">
  <input name="sub_Lclass" value="11">
  <input name="s_date" value="2026/08/11">
  <input name="s_time" value="09:00">
  <input name="e_date" value="2026/08/11">
  <input name="e_time" value="10:00">
  <textarea name="sla_cont">$reason</textarea>
</form>
''';
