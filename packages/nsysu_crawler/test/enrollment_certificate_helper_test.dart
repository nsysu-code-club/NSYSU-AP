import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

const String _loginUrl = 'https://regweb.nsysu.edu.tw/webreg/wregloginchk2.asp';
const String _contextUrl =
    'https://regweb.nsysu.edu.tw/webreg/'
    'WRegMain3.asp?act=71&out=print/enrollcert.asp';
const String _certificateUrl =
    'https://regweb.nsysu.edu.tw/webreg/print/enrollcert.asp';
const String _mainReferer = 'https://regweb.nsysu.edu.tw/webreg/WRegMain3.asp';
const int _maxResponseBytes = 10 * 1024 * 1024;

void main() {
  group('EnrollmentCertificateHelper flow', () {
    test(
      'uses the exact three-request session and normalizes the PDF',
      () async {
        final Uint8List pdf = _validPdf();
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.text(
            '<html>login</html>',
            headers: <String, List<String>>{
              HttpHeaders.setCookieHeader: <String>[
                'ASPSESSIONID=session-1; Path=/webreg/; Secure; HttpOnly',
              ],
            },
          ),
          _Reply.text('<html>context</html>'),
          _Reply.bytes(
            <int>[...ascii.encode(' \r\n\t'), ...pdf, ...ascii.encode('\r\n ')],
            headers: <String, List<String>>{
              // A valid signature is authoritative, not this misleading type.
              HttpHeaders.contentTypeHeader: <String>['text/html'],
            },
          ),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);
        addTearDown(helper.close);

        final Uint8List result = await helper.download(
          username: ' B123456789 ',
          password: 'secret',
        );

        expect(result, orderedEquals(pdf));
        expect(adapter.requests, hasLength(3));
        expect(
          adapter.requests.map((_RecordedRequest request) => request.method),
          orderedEquals(<String>['POST', 'GET', 'POST']),
        );
        expect(
          adapter.requests.map((_RecordedRequest request) => request.uri),
          orderedEquals(<Uri>[
            Uri.parse(_loginUrl),
            Uri.parse(_contextUrl),
            Uri.parse(_certificateUrl),
          ]),
        );
        expect(
          _form(adapter.requests[0]),
          equals(<String, String>{'ID': 'B123456789', 'passwd': 'secret'}),
        );
        expect(adapter.requests[1].body, isEmpty);
        expect(
          _form(adapter.requests[2]),
          equals(<String, String>{'ssn1': 'idno', 'idno': 'B123456789'}),
        );
        expect(
          _header(adapter.requests[0], HttpHeaders.contentTypeHeader),
          startsWith(Headers.formUrlEncodedContentType),
        );
        expect(
          _header(adapter.requests[2], HttpHeaders.contentTypeHeader),
          startsWith(Headers.formUrlEncodedContentType),
        );
        expect(
          _header(adapter.requests[0], HttpHeaders.userAgentHeader),
          equals(
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
            'AppleWebKit/537.36 Chrome/138 Safari/537.36',
          ),
        );
        expect(_header(adapter.requests[0], HttpHeaders.refererHeader), isNull);
        expect(
          _header(adapter.requests[1], HttpHeaders.refererHeader),
          equals(_mainReferer),
        );
        expect(
          _header(adapter.requests[2], HttpHeaders.refererHeader),
          equals(_mainReferer),
        );
        expect(
          _header(adapter.requests[1], HttpHeaders.cookieHeader),
          contains('ASPSESSIONID=session-1'),
        );
        expect(
          _header(adapter.requests[2], HttpHeaders.cookieHeader),
          contains('ASPSESSIONID=session-1'),
        );
        for (final _RecordedRequest request in adapter.requests) {
          expect(request.responseType, ResponseType.stream);
          expect(request.followRedirects, isFalse);
          expect(request.connectTimeout, const Duration(seconds: 30));
          expect(request.sendTimeout, const Duration(seconds: 30));
          expect(request.receiveTimeout, const Duration(seconds: 30));
        }
      },
    );

    test('default instances do not share cookies', () async {
      Future<_FakeHttpClientAdapter> runSession(String sessionId) async {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.text(
            'login',
            headers: <String, List<String>>{
              HttpHeaders.setCookieHeader: <String>[
                'ASPSESSIONID=$sessionId; Path=/webreg/',
              ],
            },
          ),
          _Reply.text('context'),
          _Reply.bytes(_validPdf()),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);
        await helper.download(username: 'A1', password: 'password');
        helper.close();
        return adapter;
      }

      final _FakeHttpClientAdapter first = await runSession('first');
      final _FakeHttpClientAdapter second = await runSession('second');

      expect(_header(first.requests.first, HttpHeaders.cookieHeader), isNull);
      expect(_header(second.requests.first, HttpHeaders.cookieHeader), isNull);
      expect(
        _header(second.requests[1], HttpHeaders.cookieHeader),
        contains('ASPSESSIONID=second'),
      );
      expect(
        _header(second.requests[1], HttpHeaders.cookieHeader),
        isNot(contains('ASPSESSIONID=first')),
      );
    });

    test('rejects missing credentials before making a request', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: '  ', password: 'secret'),
        EnrollmentCertificateExceptionKind.credentials,
      );
      expect(adapter.requests, isEmpty);
    });

    test('maps login 401 to a credentials failure', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('unauthorized', statusCode: 401),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await expectLater(
        helper.download(username: 'A1', password: 'wrong'),
        throwsA(
          isA<EnrollmentCertificateException>()
              .having(
                (EnrollmentCertificateException error) => error.kind,
                'kind',
                EnrollmentCertificateExceptionKind.credentials,
              )
              .having(
                (EnrollmentCertificateException error) => error.statusCode,
                'statusCode',
                401,
              ),
        ),
      );
    });

    test('maps an unsuccessful context status to http', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('login'),
        _Reply.text('server error', statusCode: 500),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await expectLater(
        helper.download(username: 'A1', password: 'password'),
        throwsA(
          isA<EnrollmentCertificateException>()
              .having(
                (EnrollmentCertificateException error) => error.kind,
                'kind',
                EnrollmentCertificateExceptionKind.http,
              )
              .having(
                (EnrollmentCertificateException error) => error.statusCode,
                'statusCode',
                500,
              ),
        ),
      );
    });
  });

  group('EnrollmentCertificateHelper redirects', () {
    for (final int statusCode in <int>[301, 302, 303, 307, 308]) {
      test(
        'follows $statusCode manually with browser method semantics',
        () async {
          final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(
            <_Reply>[
              _Reply.redirect(
                statusCode,
                'login-redirect.asp',
                headers: <String, List<String>>{
                  HttpHeaders.setCookieHeader: <String>[
                    'ASPSESSIONID=redirect-cookie; Path=/webreg/',
                  ],
                },
              ),
              _Reply.text('login complete'),
              _Reply.text('context'),
              _Reply.bytes(_validPdf()),
            ],
          );
          final EnrollmentCertificateHelper helper = _helper(adapter);
          addTearDown(helper.close);

          await helper.download(username: 'A1', password: 'password');

          expect(adapter.requests, hasLength(4));
          expect(
            adapter.requests[1].uri,
            Uri.parse('https://regweb.nsysu.edu.tw/webreg/login-redirect.asp'),
          );
          final bool preservesPost = statusCode == 307 || statusCode == 308;
          expect(adapter.requests[1].method, preservesPost ? 'POST' : 'GET');
          if (preservesPost) {
            expect(
              _form(adapter.requests[1]),
              equals(<String, String>{'ID': 'A1', 'passwd': 'password'}),
            );
          } else {
            expect(adapter.requests[1].body, isEmpty);
          }
          expect(
            _header(adapter.requests[1], HttpHeaders.cookieHeader),
            contains('ASPSESSIONID=redirect-cookie'),
          );
        },
      );
    }

    for (final int statusCode in <int>[302, 307, 308]) {
      test('rejects a $statusCode redirect to another host', () async {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.redirect(
            statusCode,
            'https://attacker.example/webreg/capture.asp',
          ),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);
        addTearDown(helper.close);

        await _expectKind(
          helper.download(username: 'A1', password: 'password'),
          EnrollmentCertificateExceptionKind.redirect,
        );
        expect(adapter.requests, hasLength(1));
      });
    }

    for (final String location in <String>[
      'http://regweb.nsysu.edu.tw/webreg/insecure.asp',
      'https://regweb.nsysu.edu.tw/outside.asp',
      'https://regweb.nsysu.edu.tw:444/webreg/wrong-port.asp',
      'https://regweb.nsysu.edu.tw/webreg/%2e%2e/outside.asp',
    ]) {
      test('rejects redirect target $location', () async {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.redirect(302, location),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);
        addTearDown(helper.close);

        await _expectKind(
          helper.download(username: 'A1', password: 'password'),
          EnrollmentCertificateExceptionKind.redirect,
        );
        expect(adapter.requests, hasLength(1));
      });
    }

    test('stops after five followed redirects', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(
        List<_Reply>.generate(
          6,
          (int index) => _Reply.redirect(302, 'hop-$index.asp'),
        ),
      );
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.redirect,
      );
      expect(adapter.requests, hasLength(6));
    });

    test('rejects redirect without Location', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('', statusCode: 302),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.redirect,
      );
    });
  });

  group('EnrollmentCertificateHelper response validation', () {
    test('does not trust an application/pdf Content-Type', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('login'),
        _Reply.text('context'),
        _Reply.text(
          '<html>login expired</html>',
          headers: <String, List<String>>{
            HttpHeaders.contentTypeHeader: <String>['application/pdf'],
          },
        ),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.invalidPdf,
      );
    });

    test('requires a complete PDF of at least 1024 bytes', () async {
      for (final Uint8List invalidPdf in <Uint8List>[
        Uint8List.fromList(ascii.encode('%PDF-1.7\nshort\n%%EOF')),
        Uint8List.fromList(<int>[
          ...ascii.encode('%PDF-1.7\n'),
          ...List<int>.filled(1100, 0x41),
        ]),
        Uint8List.fromList(<int>[0x58, ..._validPdf()]),
        Uint8List.fromList(<int>[..._validPdf(), 0x58]),
      ]) {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.text('login'),
          _Reply.text('context'),
          _Reply.bytes(invalidPdf),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);

        await _expectKind(
          helper.download(username: 'A1', password: 'password'),
          EnrollmentCertificateExceptionKind.invalidPdf,
        );
        helper.close();
      }
    });

    test('rejects oversized declared content before buffering it', () async {
      final Completer<void> listened = Completer<void>();
      final Completer<void> cancelled = Completer<void>();
      late final StreamController<Uint8List> responseController;
      responseController = StreamController<Uint8List>(
        onListen: listened.complete,
        onCancel: cancelled.complete,
      );
      addTearDown(responseController.close);
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('login'),
        _Reply.text('context'),
        _Reply.stream(
          responseController.stream,
          headers: <String, List<String>>{
            HttpHeaders.contentLengthHeader: <String>[
              '${_maxResponseBytes + 1}',
            ],
          },
        ),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.tooLarge,
      );
      expect(listened.isCompleted, isTrue);
      expect(cancelled.isCompleted, isTrue);
    });

    test('bounds intermediate HTML responses too', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text(
          'login page',
          headers: <String, List<String>>{
            HttpHeaders.contentLengthHeader: <String>[
              '${_maxResponseBytes + 1}',
            ],
          },
        ),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.tooLarge,
      );
      expect(adapter.requests, hasLength(1));
    });

    test('rejects a streamed body that crosses 10 MiB', () async {
      final Uint8List oneMiB = Uint8List(1024 * 1024);
      final Completer<void> cancelled = Completer<void>();
      late final StreamController<Uint8List> responseController;
      responseController = StreamController<Uint8List>(
        onListen: () {
          for (int index = 0; index < 10; index += 1) {
            responseController.add(oneMiB);
          }
          responseController.add(Uint8List.fromList(<int>[0]));
        },
        onCancel: cancelled.complete,
      );
      addTearDown(responseController.close);
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.text('login'),
        _Reply.text('context'),
        _Reply.stream(responseController.stream),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      addTearDown(helper.close);

      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.tooLarge,
      );
      expect(cancelled.isCompleted, isTrue);
    });
  });

  group('EnrollmentCertificateHelper transport failures', () {
    final Map<DioExceptionType, EnrollmentCertificateExceptionKind> cases =
        <DioExceptionType, EnrollmentCertificateExceptionKind>{
          DioExceptionType.connectionTimeout:
              EnrollmentCertificateExceptionKind.timeout,
          DioExceptionType.cancel: EnrollmentCertificateExceptionKind.cancelled,
          DioExceptionType.connectionError:
              EnrollmentCertificateExceptionKind.network,
        };

    for (final MapEntry<DioExceptionType, EnrollmentCertificateExceptionKind>
        entry
        in cases.entries) {
      test('maps ${entry.key.name} to ${entry.value.name}', () async {
        final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
          _Reply.failure(entry.key),
        ]);
        final EnrollmentCertificateHelper helper = _helper(adapter);
        addTearDown(helper.close);

        await _expectKind(
          helper.download(username: 'A1', password: 'password'),
          entry.value,
        );
      });
    }

    test('close is idempotent and prevents another request', () async {
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[]);
      final EnrollmentCertificateHelper helper = _helper(adapter);

      helper.close();
      helper.close();

      expect(adapter.isClosed, isTrue);
      await _expectKind(
        helper.download(username: 'A1', password: 'password'),
        EnrollmentCertificateExceptionKind.cancelled,
      );
      expect(adapter.requests, isEmpty);
    });

    test('close cancels an active streamed response', () async {
      final Completer<void> listened = Completer<void>();
      final Completer<void> delivered = Completer<void>();
      final Completer<void> cancelled = Completer<void>();
      late final StreamController<Uint8List> responseController;
      responseController = StreamController<Uint8List>(
        onListen: () {
          listened.complete();
          responseController.add(Uint8List.fromList(<int>[1, 2, 3]));
        },
        onCancel: cancelled.complete,
      );
      addTearDown(responseController.close);
      final Stream<Uint8List> observedStream = responseController.stream.map((
        Uint8List chunk,
      ) {
        if (!delivered.isCompleted) delivered.complete();
        return chunk;
      });
      final _FakeHttpClientAdapter adapter = _FakeHttpClientAdapter(<_Reply>[
        _Reply.stream(observedStream),
      ]);
      final EnrollmentCertificateHelper helper = _helper(adapter);
      final Future<Uint8List> download = helper.download(
        username: 'A1',
        password: 'password',
      );
      final Future<void> expectation = _expectKind(
        download,
        EnrollmentCertificateExceptionKind.cancelled,
      );

      await listened.future;
      await delivered.future;
      helper.close();

      await expectation;
      expect(cancelled.isCompleted, isTrue);
      expect(adapter.isClosed, isTrue);
    });
  });
}

EnrollmentCertificateHelper _helper(_FakeHttpClientAdapter adapter) {
  final Dio dio = Dio();
  dio.httpClientAdapter = adapter;
  return EnrollmentCertificateHelper(dio: dio);
}

Future<void> _expectKind(
  Future<Uint8List> future,
  EnrollmentCertificateExceptionKind kind,
) {
  return expectLater(
    future,
    throwsA(
      isA<EnrollmentCertificateException>().having(
        (EnrollmentCertificateException error) => error.kind,
        'kind',
        kind,
      ),
    ),
  );
}

Uint8List _validPdf() {
  final List<int> header = ascii.encode('%PDF-1.7\n');
  final List<int> eof = ascii.encode('%%EOF');
  final int fillerLength = 1024 - header.length - eof.length;
  return Uint8List.fromList(<int>[
    ...header,
    ...List<int>.filled(fillerLength, 0x41),
    ...eof,
  ]);
}

Map<String, String> _form(_RecordedRequest request) {
  return Uri.splitQueryString(utf8.decode(request.body));
}

String? _header(_RecordedRequest request, String name) {
  for (final MapEntry<String, dynamic> entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value?.toString();
    }
  }
  return null;
}

class _RecordedRequest {
  const _RecordedRequest({required this.options, required this.body});

  final RequestOptions options;
  final Uint8List body;

  String get method => options.method;
  Uri get uri => options.uri;
  Map<String, dynamic> get headers => options.headers;
  ResponseType get responseType => options.responseType;
  bool get followRedirects => options.followRedirects;
  Duration? get connectTimeout => options.connectTimeout;
  Duration? get sendTimeout => options.sendTimeout;
  Duration? get receiveTimeout => options.receiveTimeout;
}

class _Reply {
  const _Reply._({
    required this.statusCode,
    required this.bodyChunks,
    this.headers = const <String, List<String>>{},
    this.failureType,
    this.responseStream,
  });

  factory _Reply.text(
    String body, {
    int statusCode = 200,
    Map<String, List<String>> headers = const <String, List<String>>{},
  }) {
    return _Reply.bytes(
      utf8.encode(body),
      statusCode: statusCode,
      headers: headers,
    );
  }

  factory _Reply.bytes(
    List<int> body, {
    int statusCode = 200,
    Map<String, List<String>> headers = const <String, List<String>>{},
  }) {
    return _Reply._(
      statusCode: statusCode,
      bodyChunks: <Uint8List>[Uint8List.fromList(body)],
      headers: headers,
    );
  }

  factory _Reply.stream(
    Stream<Uint8List> stream, {
    int statusCode = 200,
    Map<String, List<String>> headers = const <String, List<String>>{},
  }) {
    return _Reply._(
      statusCode: statusCode,
      bodyChunks: const <Uint8List>[],
      headers: headers,
      responseStream: stream,
    );
  }

  factory _Reply.redirect(
    int statusCode,
    String location, {
    Map<String, List<String>> headers = const <String, List<String>>{},
  }) {
    return _Reply._(
      statusCode: statusCode,
      bodyChunks: <Uint8List>[Uint8List(0)],
      headers: <String, List<String>>{
        ...headers,
        HttpHeaders.locationHeader: <String>[location],
      },
    );
  }

  factory _Reply.failure(DioExceptionType type) {
    return _Reply._(
      statusCode: 0,
      bodyChunks: const <Uint8List>[],
      failureType: type,
    );
  }

  final int statusCode;
  final List<Uint8List> bodyChunks;
  final Map<String, List<String>> headers;
  final DioExceptionType? failureType;
  final Stream<Uint8List>? responseStream;

  ResponseBody respond(RequestOptions options) {
    switch (failureType) {
      case DioExceptionType.connectionTimeout:
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 30),
          requestOptions: options,
        );
      case DioExceptionType.cancel:
        throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'test cancellation',
        );
      case DioExceptionType.connectionError:
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'test connection error',
        );
      case null:
        return ResponseBody(
          responseStream ?? Stream<Uint8List>.fromIterable(bodyChunks),
          statusCode,
          headers: headers,
        );
      case _:
        throw StateError('Unsupported test failure: $failureType');
    }
  }
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._replies);

  final List<_Reply> _replies;
  final List<_RecordedRequest> requests = <_RecordedRequest>[];
  int _replyIndex = 0;
  bool isClosed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final BytesBuilder body = BytesBuilder(copy: false);
    if (requestStream != null) {
      await for (final Uint8List chunk in requestStream) {
        body.add(chunk);
      }
    }
    requests.add(_RecordedRequest(options: options, body: body.takeBytes()));
    if (_replyIndex >= _replies.length) {
      throw StateError('No fake response for request ${options.uri}');
    }
    final _Reply reply = _replies[_replyIndex];
    _replyIndex += 1;
    return reply.respond(options);
  }

  @override
  void close({bool force = false}) {
    isClosed = true;
  }
}
