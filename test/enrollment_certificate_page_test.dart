import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show DebugPrintCallback, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/l10n/strings.g.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enroll_certificate_page.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.zhHantTw);
  });

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
}) {
  return MaterialApp(
    home: EnrollCertificatePage(
      credentialsProvider: () => EnrollmentCertificateCredentials(
        username: username,
        password: password,
      ),
      downloadCertificate: download,
      readCachedCertificate: ({required String username}) async => cachedPdf,
      writeCachedCertificate:
          ({required String username, required Uint8List bytes}) async {
            if (saveError != null) throw saveError;
            cachedPdf = bytes;
            onSavePdf?.call(bytes);
          },
      exportPdf: exportPdf,
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
