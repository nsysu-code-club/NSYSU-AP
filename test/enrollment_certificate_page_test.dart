import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show DebugPrintCallback, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show URLRequest;
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/l10n/strings.g.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enroll_certificate_page.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enrollment_registration_page.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.zhHantTw);
  });

  testWidgets('passes only the failed request session to registration', (
    WidgetTester tester,
  ) async {
    final List<Cookie> cookies = <Cookie>[
      Cookie('ASPSESSIONID', 'current-session')..path = '/webreg/',
    ];
    List<Cookie>? received;
    await tester.pumpWidget(
      _testApp(
        download: ({required String username, required String password}) {
          throw EnrollmentCertificateException(
            EnrollmentCertificateExceptionKind.registrationRequired,
            'Registration required',
            registrationCookies: cookies,
          );
        },
        registrationPageBuilder: (_, List<Cookie> session) {
          received = session;
          return const Scaffold(body: Text('Registration'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(received, same(cookies));
    expect(find.text('Registration'), findsOneWidget);
  });

  for (final String scenario in <String>[
    'complete',
    'cancel',
    'still blocked',
    'cached',
  ]) {
    testWidgets('registration recovery: $scenario', (
      WidgetTester tester,
    ) async {
      int requests = 0;
      int windows = 0;
      int writes = 0;
      final Uint8List oldPdf = _validPdf('old');
      final Uint8List freshPdf = _validPdf('fresh');
      Uint8List? displayed;
      await tester.pumpWidget(
        _testApp(
          cachedPdf: scenario == 'cached' ? oldPdf : null,
          onBuildPdf: (Uint8List bytes) => displayed = bytes,
          onSavePdf: (Uint8List bytes) => writes++,
          download:
              ({required String username, required String password}) async {
                requests++;
                if (requests == 1 || scenario == 'still blocked') {
                  throw const EnrollmentCertificateException(
                    EnrollmentCertificateExceptionKind.registrationRequired,
                    'School requires registration information.',
                  );
                }
                return freshPdf;
              },
          registrationPageBuilder:
              (BuildContext context, List<Cookie> cookies) {
                windows++;
                return EnrollmentRegistrationPage(
                  webViewBuilder: (_, URLRequest request, _) =>
                      const Text('School registration form'),
                );
              },
        ),
      );
      await tester.pumpAndSettle();
      if (scenario == 'cached') {
        await tester.tap(
          find.byKey(const ValueKey<String>('enroll-certificate-regenerate')),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('School registration form'), findsOneWidget);
      expect(
        find.text(app.enrollCertificate.registrationTitle),
        findsOneWidget,
      );
      expect(windows, 1);
      expect(requests, 1);
      expect(writes, 0);

      if (scenario == 'cancel' || scenario == 'cached') {
        await tester.tap(find.byType(CloseButton));
      } else {
        await tester.tap(
          find.byKey(const ValueKey<String>('enroll-registration-complete')),
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('School registration form'), findsNothing);
      expect(windows, 1);
      if (scenario == 'complete') {
        expect(requests, 2);
        expect(writes, 1);
        expect(displayed, orderedEquals(freshPdf));
      } else if (scenario == 'cached') {
        expect(requests, 1);
        expect(writes, 0);
        expect(displayed, orderedEquals(oldPdf));
      } else {
        expect(requests, scenario == 'still blocked' ? 2 : 1);
        expect(writes, 0);
        expect(
          find.text(app.enrollCertificate.registrationRequired),
          findsOneWidget,
        );
        // A subsequent explicit retry can reopen registration if needed.
        if (scenario == 'still blocked') {
          await tester.tap(
            find.byKey(const ValueKey<String>('enroll-certificate-retry')),
          );
          await tester.pumpAndSettle();
          expect(find.text('School registration form'), findsOneWidget);
          expect(requests, 3);
          expect(windows, 2);
        }
      }
    });
  }

  for (final EnrollmentCertificateExceptionKind kind
      in EnrollmentCertificateExceptionKind.values.where(
        (EnrollmentCertificateExceptionKind value) =>
            value != EnrollmentCertificateExceptionKind.registrationRequired,
      )) {
    testWidgets('${kind.name} does not open registration', (
      WidgetTester tester,
    ) async {
      int windows = 0;
      await tester.pumpWidget(
        _testApp(
          download:
              ({required String username, required String password}) async =>
                  throw EnrollmentCertificateException(kind, 'Test failure'),
          registrationPageBuilder: (_, List<Cookie> cookies) {
            windows++;
            return const Text('Unexpected registration');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(windows, 0);
      expect(
        find.byKey(const ValueKey<String>('enroll-certificate-retry')),
        findsOneWidget,
      );
    });
  }

  for (final String scenario in <String>[
    'current',
    'expired',
    'legacy',
    'unknown',
    'failed',
  ]) {
    testWidgets('semester-aware disk cache: $scenario', (
      WidgetTester tester,
    ) async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'cert_semester_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final EnrollCertificateCache cache = EnrollCertificateCache(
        username: 'B123456789',
        supportDirectoryProvider: () async => directory,
      );
      final Uint8List oldPdf = _validPdf('old');
      final Uint8List freshPdf = _validPdf('fresh');
      await tester.runAsync(
        () => cache.save(
          oldPdf,
          semesterCode: scenario == 'legacy' ? null : '1151',
        ),
      );
      int requests = 0;
      Uint8List? displayed;
      final String? currentCode = scenario == 'unknown'
          ? null
          : scenario == 'current'
          ? '1151'
          : '1152';
      await tester.pumpWidget(
        MaterialApp(
          home: EnrollCertificatePage(
            credentialsProvider: () => const EnrollmentCertificateCredentials(
              username: 'B123456789',
              password: 'secret',
            ),
            currentSemesterCodeProvider: () async => currentCode,
            supportDirectoryProvider: () async => directory,
            downloadCertificate:
                ({required String username, required String password}) async {
                  requests++;
                  if (scenario == 'failed') throw Exception('offline');
                  return freshPdf;
                },
            pdfViewBuilder:
                (BuildContext context, Uint8List bytes, String name) {
                  displayed = bytes;
                  return const Text('PDF ready');
                },
          ),
        ),
      );
      // Real filesystem operations must finish outside the fake async clock.
      await tester.runAsync(() async {
        for (int i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (displayed != null ||
              find
                  .byKey(const ValueKey<String>('enroll-certificate-retry'))
                  .evaluate()
                  .isNotEmpty) {
            break;
          }
        }
      });
      expect(requests, scenario == 'current' ? 0 : 1);
      if (scenario == 'failed') {
        expect(displayed, isNull);
        expect(find.text(app.enrollCertificate.requestFailed), findsOneWidget);
        expect(
          await tester.runAsync(() => cache.read(semesterCode: '1151')),
          oldPdf,
        );
        expect(
          await tester.runAsync(() => cache.read(semesterCode: '1152')),
          isNull,
        );
        return;
      }
      expect(displayed, scenario == 'current' ? oldPdf : freshPdf);
      if (currentCode != null) {
        expect(
          await tester.runAsync(() => cache.read(semesterCode: currentCode)),
          displayed,
        );
      }
    });
  }

  testWidgets('uses an account cache without making a network request', (
    WidgetTester tester,
  ) async {
    final Uint8List cachedPdf = _validPdf('cached');
    int requests = 0;
    Uint8List? displayedPdf;

    await tester.pumpWidget(
      _testApp(
        cachedPdf: cachedPdf,
        password: '',
        download: ({required String username, required String password}) async {
          requests++;
          return _validPdf('network');
        },
        onBuildPdf: (Uint8List bytes) => displayedPdf = bytes,
      ),
    );
    await tester.pumpAndSettle();

    expect(requests, 0);
    expect(displayedPdf, orderedEquals(cachedPdf));
    expect(
      find.byKey(const ValueKey<String>('enroll-certificate-pdf')),
      findsOneWidget,
    );
  });

  testWidgets('retrieves once and caches when no saved PDF exists', (
    WidgetTester tester,
  ) async {
    final Uint8List downloadedPdf = _validPdf('downloaded');
    int requests = 0;
    Uint8List? savedPdf;

    await tester.pumpWidget(
      _testApp(
        onSavePdf: (Uint8List bytes) => savedPdf = bytes,
        download: ({required String username, required String password}) async {
          requests++;
          expect(username, 'B123456789');
          expect(password, 'secret');
          return downloadedPdf;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(requests, 1);
    expect(savedPdf, orderedEquals(downloadedPdf));
  });

  testWidgets('regenerate is single-flight and replaces the cached PDF', (
    WidgetTester tester,
  ) async {
    final Uint8List cachedPdf = _validPdf('old');
    final Uint8List replacementPdf = _validPdf('replacement');
    final Completer<Uint8List> request = Completer<Uint8List>();
    int requests = 0;
    Uint8List? displayedPdf;
    Uint8List? savedPdf;

    await tester.pumpWidget(
      _testApp(
        cachedPdf: cachedPdf,
        download: ({required String username, required String password}) {
          requests++;
          return request.future;
        },
        onBuildPdf: (Uint8List bytes) => displayedPdf = bytes,
        onSavePdf: (Uint8List bytes) => savedPdf = bytes,
      ),
    );
    await tester.pumpAndSettle();

    final Finder regenerate = find.byKey(
      const ValueKey<String>('enroll-certificate-regenerate'),
    );
    await tester.tap(regenerate);
    await tester.tap(regenerate);
    await tester.pump();
    expect(requests, 1);

    request.complete(replacementPdf);
    await tester.pumpAndSettle();

    expect(displayedPdf, orderedEquals(replacementPdf));
    expect(savedPdf, orderedEquals(replacementPdf));
  });

  testWidgets('failed regenerate keeps the old cached PDF visible', (
    WidgetTester tester,
  ) async {
    final Uint8List cachedPdf = _validPdf('old');
    Uint8List? displayedPdf;
    int cacheWrites = 0;

    await tester.pumpWidget(
      _testApp(
        cachedPdf: cachedPdf,
        download: ({required String username, required String password}) =>
            Future<Uint8List>.error(Exception('offline test failure')),
        onBuildPdf: (Uint8List bytes) => displayedPdf = bytes,
        onSavePdf: (Uint8List bytes) => cacheWrites++,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('enroll-certificate-regenerate')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(displayedPdf, orderedEquals(cachedPdf));
    expect(find.text(app.enrollCertificate.requestFailed), findsOneWidget);
    expect(cacheWrites, 0);
  });

  testWidgets('cache write failure still displays the retrieved PDF', (
    WidgetTester tester,
  ) async {
    final Uint8List downloadedPdf = _validPdf('downloaded');
    Uint8List? displayedPdf;

    await tester.pumpWidget(
      _testApp(
        download:
            ({required String username, required String password}) async =>
                downloadedPdf,
        saveError: Exception('offline cache failure'),
        onBuildPdf: (Uint8List bytes) => displayedPdf = bytes,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(displayedPdf, orderedEquals(downloadedPdf));
    expect(find.text(app.enrollCertificate.saveFailed), findsOneWidget);
  });

  testWidgets(
    'debug trace identifies a typed failure without exposing secrets',
    (WidgetTester tester) async {
      const String username = 'DEBUG_USERNAME_SENTINEL';
      const String password = 'DEBUG_PASSWORD_SENTINEL';
      const String privateBody = '<html>DEBUG_BODY_SENTINEL</html>';
      final DebugPrintCallback originalDebugPrint = debugPrint;
      final List<String> logs = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = originalDebugPrint);

      try {
        await tester.pumpWidget(
          _testApp(
            username: username,
            password: password,
            download:
                ({required String username, required String password}) async =>
                    throw const EnrollmentCertificateException(
                      EnrollmentCertificateExceptionKind.http,
                      privateBody,
                      statusCode: 503,
                    ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        debugPrint = originalDebugPrint;
      }

      final String output = logs.join('\n');
      expect(
        output,
        contains(
          '[EnrollCertificatePage] event=retrieve_failure '
          'kind=http status=503',
        ),
      );
      for (final String secret in <String>[username, password, privateBody]) {
        expect(output, isNot(contains(secret)));
      }
      expect(find.text(app.enrollCertificate.requestFailed), findsOneWidget);
    },
  );

  testWidgets('leaving the page prevents a late request from writing cache', (
    WidgetTester tester,
  ) async {
    final Completer<Uint8List> request = Completer<Uint8List>();
    int cacheWrites = 0;
    bool requestStarted = false;

    await tester.pumpWidget(
      _testApp(
        download: ({required String username, required String password}) {
          requestStarted = true;
          return request.future;
        },
        onSavePdf: (Uint8List bytes) => cacheWrites++,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(requestStarted, isTrue);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    request.complete(_validPdf('late'));
    await tester.pump();

    expect(cacheWrites, 0);
  });

  testWidgets('download exports the currently displayed PDF and filename', (
    WidgetTester tester,
  ) async {
    final Uint8List cachedPdf = _validPdf('cached');
    Uint8List? exportedPdf;
    String? exportedFileName;

    await tester.pumpWidget(
      _testApp(
        cachedPdf: cachedPdf,
        download:
            ({required String username, required String password}) async =>
                _validPdf('unused'),
        exportPdf:
            ({required Uint8List bytes, required String fileName}) async {
              exportedPdf = bytes;
              exportedFileName = fileName;
              return true;
            },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('enroll-certificate-download')),
    );
    await tester.pump();

    expect(exportedPdf, orderedEquals(cachedPdf));
    expect(exportedFileName, '${app.enrollCertificate.fileName}.pdf');
  });

  testWidgets('shows an error when the platform cannot export the PDF', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        cachedPdf: _validPdf('cached'),
        download:
            ({required String username, required String password}) async =>
                _validPdf('unused'),
        exportPdf:
            ({required Uint8List bytes, required String fileName}) async =>
                false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('enroll-certificate-download')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(app.enrollCertificate.downloadFailed), findsOneWidget);
  });
}

Widget _testApp({
  required EnrollmentCertificateDownload download,
  Uint8List? cachedPdf,
  String username = 'b123456789',
  String password = 'secret',
  void Function(Uint8List bytes)? onBuildPdf,
  void Function(Uint8List bytes)? onSavePdf,
  Object? saveError,
  EnrollmentCertificatePdfExporter? exportPdf,
  EnrollmentCertificateRegistrationPageBuilder? registrationPageBuilder,
}) {
  Uint8List? currentCachedPdf = cachedPdf;
  return MaterialApp(
    home: EnrollCertificatePage(
      currentSemesterCodeProvider: () async => '1151',
      credentialsProvider: () => EnrollmentCertificateCredentials(
        username: username,
        password: password,
      ),
      downloadCertificate: download,
      readCachedCertificate: ({required String username}) async =>
          currentCachedPdf,
      writeCachedCertificate:
          ({required String username, required Uint8List bytes}) async {
            if (saveError != null) throw saveError;
            currentCachedPdf = bytes;
            onSavePdf?.call(bytes);
          },
      exportPdf: exportPdf,
      registrationPageBuilder: registrationPageBuilder,
      pdfViewBuilder: (BuildContext context, Uint8List bytes, String fileName) {
        onBuildPdf?.call(bytes);
        return const Center(child: Text('PDF ready'));
      },
    ),
  );
}

Uint8List _validPdf(String marker) {
  return Uint8List.fromList(<int>[
    ...'%PDF-1.7\n$marker\n'.codeUnits,
    ...List<int>.filled(1100, 0x20),
    ...'\n%%EOF'.codeUnits,
  ]);
}
