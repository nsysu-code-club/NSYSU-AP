import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/l10n/strings.g.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enrollment_registration_page.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enrollment_certificate_session.dart';
import 'package:nsysu_ap/utils/enroll_certificate/registration_cookie_store.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.zhHantTw));

  for (final bool logout in <bool>[false, true]) {
    testWidgets('removes RegWeb cookies after ${logout ? 'logout' : 'close'}', (
      WidgetTester tester,
    ) async {
      final _TestCookieManager manager = _TestCookieManager();
      await tester.pumpWidget(
        MaterialApp(
          home: EnrollmentRegistrationPage(
            registrationCookies: <io.Cookie>[
              io.Cookie('ASPSESSIONID', 'account-a'),
            ],
            cookieManager: manager,
            webViewBuilder: (_, URLRequest request, _) =>
                const Text('Private form'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(manager.hasSession, isTrue);
      if (logout) {
        final Future<void> cleanup = EnrollmentCertificateSession.cancelAll();
        await tester.pump();
        await tester.pump();
        await cleanup;
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.pumpAndSettle();
      expect(manager.hasSession, isFalse);
      expect(manager.origins.toSet(), <String>{'regweb.nsysu.edu.tw'});
      expect(find.text('Private form'), findsNothing);
    });
  }

  test(
    'logout cleanup tries remaining paths after a native deletion fails',
    () async {
      final _TestCookieManager manager = _TestCookieManager(
        failDeletePath: '/',
      );
      await RegistrationCookieStore.clear(manager: manager);
      expect(
        manager.deletedPaths,
        containsAll(<String>['/', '/webreg', '/webreg/']),
      );
    },
  );

  test('a new session waits for the previous native view cleanup', () async {
    final Completer<void> stopped = Completer<void>();
    final _TestCookieManager manager = _TestCookieManager();
    final Future<void> closing = RegistrationCookieStore.clear(
      manager: manager,
      beforeClear: () => stopped.future,
    );
    final Future<bool> opening = RegistrationCookieStore.run(
      () => manager.setCookie(
        url: WebUri.uri(EnrollmentCertificateHelper.registrationSessionUri),
        name: 'ASPSESSIONID',
        value: 'account-b',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(manager.writes, isEmpty);
    stopped.complete();
    await closing;
    await opening;
    expect(manager.hasSession, isTrue);
  });

  testWidgets('keeps native navigation payloads out of debug logs', (
    WidgetTester tester,
  ) async {
    final DebugLoggingSettings original =
        PlatformInAppWebViewController.debugLoggingSettings;
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentRegistrationPage(
          cookieManager: _TestCookieManager(),
          username: 'A123456789',
          password: 'test password',
          webViewBuilder: (_, URLRequest request, _) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      PlatformInAppWebViewController.debugLoggingSettings.enabled,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(PlatformInAppWebViewController.debugLoggingSettings, same(original));
  });

  for (final String destination in <String>['login', 'form', 'error']) {
    testWidgets('handles $destination after native login only once', (
      WidgetTester tester,
    ) async {
      late EnrollmentRegistrationLoadStop onLoadStop;
      await tester.pumpWidget(
        MaterialApp(
          home: EnrollmentRegistrationPage(
            cookieManager: _TestCookieManager(),
            username: 'A123456789',
            password: 'test password',
            webViewBuilder:
                (
                  _,
                  URLRequest request,
                  EnrollmentRegistrationLoadStop callback,
                ) {
                  onLoadStop = callback;
                  return const SizedBox.shrink();
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final _TestWebViewController controller = _TestWebViewController();
      await onLoadStop(controller, WebUri('about:blank'));
      final Uri uri = switch (destination) {
        'login' => EnrollmentCertificateHelper.registrationLoginUri,
        'error' => Uri.parse(
          'https://regweb.nsysu.edu.tw/webreg/show_error.asp',
        ),
        _ => Uri.parse('https://regweb.nsysu.edu.tw/webreg/profile.asp'),
      };
      await onLoadStop(controller, WebUri.uri(uri));
      await onLoadStop(controller, WebUri.uri(uri));
      if (destination == 'form') {
        expect(controller.requests, isEmpty);
      } else {
        expect(controller.requests, hasLength(1));
        expect(controller.requests.single.body, isNull);
        expect(
          controller.requests.single.url?.uriValue,
          destination == 'login'
              ? EnrollmentCertificateHelper.registrationSessionUri
              : EnrollmentCertificateHelper.registrationUri,
        );
      }
    });
  }

  for (final bool cookieSyncWorks in <bool>[true, false]) {
    testWidgets('logs in inside WebView with cookie sync $cookieSyncWorks', (
      WidgetTester tester,
    ) async {
      final Completer<bool> write = Completer<bool>();
      final _TestCookieManager manager = _TestCookieManager(write: write);
      const String password = 'test +&=%密碼';
      URLRequest? initialRequest;
      int builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EnrollmentRegistrationPage(
            username: 'A123456789',
            password: password,
            registrationCookies: <io.Cookie>[
              io.Cookie('ASPSESSIONID', 'previous-session'),
            ],
            cookieManager: manager,
            webViewBuilder: (_, URLRequest request, _) {
              initialRequest = request;
              builds++;
              return const Text('Native web view');
            },
          ),
        ),
      );
      await tester.pump();
      expect(initialRequest, isNull);
      write.complete(cookieSyncWorks);
      await tester.pumpAndSettle();
      expect(initialRequest?.method, 'POST');
      expect(
        initialRequest?.url?.uriValue,
        EnrollmentCertificateHelper.registrationLoginUri,
      );
      expect(initialRequest?.url?.query, isEmpty);
      expect(
        initialRequest?.headers?['Content-Type'],
        'application/x-www-form-urlencoded',
      );
      expect(
        Uri.splitQueryString(utf8.decode(initialRequest!.body!)),
        <String, String>{'ID': 'A123456789', 'passwd': password},
      );
      await tester.pump();
      expect(builds, 1);
    });
  }

  testWidgets('can establish a browser session without imported cookies', (
    WidgetTester tester,
  ) async {
    URLRequest? initialRequest;
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentRegistrationPage(
          cookieManager: _TestCookieManager(),
          username: 'A123456789',
          password: 'test password',
          webViewBuilder: (_, URLRequest request, _) {
            initialRequest = request;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(initialRequest?.method, 'POST');
    expect(
      initialRequest?.url?.uriValue,
      EnrollmentCertificateHelper.registrationLoginUri,
    );
  });

  testWidgets('waits for cookie writes before opening authenticated RegWeb', (
    WidgetTester tester,
  ) async {
    final Completer<bool> write = Completer<bool>();
    final _TestCookieManager manager = _TestCookieManager(write: write);
    Uri? opened;
    final io.Cookie cookie = io.Cookie('ASPSESSIONID', 'current')
      ..path = '/webreg/'
      ..secure = true
      ..httpOnly = true;
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentRegistrationPage(
          registrationCookies: <io.Cookie>[cookie],
          cookieManager: manager,
          webViewBuilder: (_, URLRequest request, _) {
            opened = request.url?.uriValue;
            return const Text('Registration content');
          },
        ),
      ),
    );
    await tester.pump();
    expect(opened, isNull);
    expect(manager.writes, hasLength(1));
    expect(
      manager.deletedPaths,
      unorderedEquals(<String>['/', '/webreg', '/webreg/']),
    );
    expect(manager.origins.toSet(), <String>{'regweb.nsysu.edu.tw'});
    expect(manager.writes.single, <String, Object?>{
      'name': 'ASPSESSIONID',
      'value': 'current',
      'path': '/webreg/',
      'domain': null,
      'secure': true,
      'httpOnly': true,
      'expiresDate': null,
      'maxAge': null,
    });
    write.complete(true);
    await tester.pumpAndSettle();
    expect(opened, EnrollmentCertificateHelper.registrationSessionUri);
    expect(find.text('Registration content'), findsOneWidget);
  });

  for (final String scenario in <String>['empty', 'write fails', 'throws']) {
    testWidgets('uses manual HTTPS login when session $scenario', (
      WidgetTester tester,
    ) async {
      final _TestCookieManager manager = _TestCookieManager(
        result: false,
        shouldThrow: scenario == 'throws',
      );
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: EnrollmentRegistrationPage(
            registrationCookies: scenario == 'empty'
                ? const <io.Cookie>[]
                : <io.Cookie>[io.Cookie('ASPSESSIONID', 'current')],
            cookieManager: manager,
            webViewBuilder: (_, URLRequest request, _) {
              opened = request.url?.uriValue;
              return const Text('Manual login');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(opened, EnrollmentCertificateHelper.registrationUri);
      expect(opened?.scheme, 'https');
      expect(manager.writes, scenario == 'empty' ? isEmpty : hasLength(1));
    });
  }

  testWidgets('leaving during synchronization does not load a late web view', (
    WidgetTester tester,
  ) async {
    final Completer<bool> write = Completer<bool>();
    final _TestCookieManager manager = _TestCookieManager(write: write);
    int webViews = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentRegistrationPage(
          registrationCookies: <io.Cookie>[
            io.Cookie('ASPSESSIONID', 'current'),
          ],
          cookieManager: manager,
          webViewBuilder: (_, URLRequest request, _) {
            webViews++;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    write.complete(true);
    await tester.pumpAndSettle();
    expect(webViews, 0);
    expect(manager.hasSession, isFalse);
    expect(manager.deletedPaths.length, 6);
    expect(tester.takeException(), isNull);
  });
}

class _TestWebViewController extends Fake implements InAppWebViewController {
  final List<URLRequest> requests = <URLRequest>[];

  @override
  Future<void> loadUrl({
    required URLRequest urlRequest,
    Uri? iosAllowingReadAccessTo,
    WebUri? allowingReadAccessTo,
  }) async {
    requests.add(urlRequest);
  }
}

class _TestCookieManager extends Fake implements CookieManager {
  _TestCookieManager({
    this.write,
    this.result = true,
    this.shouldThrow = false,
    this.failDeletePath,
  });

  final Completer<bool>? write;
  final bool result;
  final bool shouldThrow;
  final String? failDeletePath;
  bool hasSession = false;
  final List<String> deletedPaths = <String>[];
  final List<String> origins = <String>[];
  final List<Map<String, Object?>> writes = <Map<String, Object?>>[];

  @override
  Future<bool> deleteCookies({
    required WebUri url,
    String path = '/',
    String? domain,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    origins.add(url.host);
    deletedPaths.add(path);
    if (path == failDeletePath) throw StateError('Cookie deletion failed');
    hasSession = false;
    return true;
  }

  @override
  Future<bool> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    int? expiresDate,
    int? maxAge,
    bool? isSecure,
    bool? isHttpOnly,
    HTTPCookieSameSitePolicy? sameSite,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    origins.add(url.host);
    writes.add(<String, Object?>{
      'name': name,
      'value': value,
      'path': path,
      'domain': domain,
      'secure': isSecure,
      'httpOnly': isHttpOnly,
      'expiresDate': expiresDate,
      'maxAge': maxAge,
    });
    if (shouldThrow) throw StateError('Native cookie store unavailable');
    final bool saved = await (write?.future ?? Future<bool>.value(result));
    hasSession = saved;
    return saved;
  }
}
