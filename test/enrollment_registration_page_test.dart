import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/l10n/strings.g.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enrollment_registration_page.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.zhHantTw));

  testWidgets('keeps native navigation payloads out of debug logs', (
    WidgetTester tester,
  ) async {
    final DebugLoggingSettings original =
        PlatformInAppWebViewController.debugLoggingSettings;
    await tester.pumpWidget(
      MaterialApp(
        home: EnrollmentRegistrationPage(
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
  });

  final Completer<bool>? write;
  final bool result;
  final bool shouldThrow;
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
    return write?.future ?? result;
  }
}
