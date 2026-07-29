import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'enroll_certificate_cache_test_',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('stores only the PDF section and reads it back', () async {
    final EnrollCertificateCache cache = EnrollCertificateCache(
      username: 'B123456789',
      supportDirectoryProvider: () async => temporaryDirectory,
    );
    final Uint8List pdf = _validPdf('certificate');
    final Uint8List response = Uint8List.fromList(<int>[
      ...'prefix'.codeUnits,
      ...pdf,
      ...'trailing'.codeUnits,
    ]);

    await cache.save(response);

    expect(await cache.read(), pdf);
  });

  test('keeps cached certificates separate for each account', () async {
    final EnrollCertificateCache firstCache = EnrollCertificateCache(
      username: 'B123456789',
      supportDirectoryProvider: () async => temporaryDirectory,
    );
    final EnrollCertificateCache secondCache = EnrollCertificateCache(
      username: 'B987654321',
      supportDirectoryProvider: () async => temporaryDirectory,
    );

    await firstCache.save(_validPdf('first'));

    expect(await firstCache.read(), isNotNull);
    expect(await secondCache.read(), isNull);
  });

  test('rejects truncated and implausibly small PDF responses', () {
    expect(
      EnrollCertificateCache.extractPdf(
        Uint8List.fromList('%PDF-1.4\ntruncated'.codeUnits),
      ),
      isNull,
    );
    expect(
      EnrollCertificateCache.extractPdf(
        Uint8List.fromList('%PDF-1.4\nsmall\n%%EOF'.codeUnits),
      ),
      isNull,
    );
    expect(
      EnrollCertificateCache.extractPdf(
        Uint8List.fromList(<int>[
          ...'<html><body>'.codeUnits,
          ..._validPdf('fake'),
          ...'</body></html>'.codeUnits,
        ]),
      ),
      isNull,
    );
  });

  test('does not replace an existing PDF when validation fails', () async {
    final EnrollCertificateCache cache = EnrollCertificateCache(
      username: 'B123456789',
      supportDirectoryProvider: () async => temporaryDirectory,
    );
    final Uint8List original = _validPdf('original');
    await cache.save(original);

    await expectLater(
      cache.save(Uint8List.fromList('<html>error</html>'.codeUnits)),
      throwsFormatException,
    );

    expect(await cache.read(), original);
  });

  test('replaces an existing PDF only after the new PDF is valid', () async {
    final EnrollCertificateCache cache = EnrollCertificateCache(
      username: 'B123456789',
      supportDirectoryProvider: () async => temporaryDirectory,
    );
    await cache.save(_validPdf('old'));
    final Uint8List replacement = _validPdf('new');

    await cache.save(replacement);

    expect(await cache.read(), replacement);
  });
}

Uint8List _validPdf(String marker) {
  return Uint8List.fromList(<int>[
    ...'%PDF-1.4\n$marker\n'.codeUnits,
    ...List<int>.filled(1100, 0x20),
    ...'\n%%EOF'.codeUnits,
  ]);
}
