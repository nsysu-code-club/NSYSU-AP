import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'enrollment_certificate_cache_test_',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  EnrollCertificateCache createCache(String username) {
    return EnrollCertificateCache(
      username: username,
      supportDirectoryProvider: () async => temporaryDirectory,
    );
  }

  test('normalizes a valid PDF before saving and reads it back', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    final Uint8List pdf = _validPdf('certificate');
    final Uint8List response = Uint8List.fromList(<int>[
      ...' \t\r\n'.codeUnits,
      ...pdf,
      ...'\r\n '.codeUnits,
    ]);

    await cache.save(response);

    expect(await cache.read(), pdf);
    final File file = await _cachedPdfFile(temporaryDirectory);
    expect(await file.readAsBytes(), pdf);
  });

  test('normalizes usernames and isolates different accounts', () async {
    final EnrollCertificateCache normalizedCache = createCache(
      '  b123456789  ',
    );
    final EnrollCertificateCache sameAccountCache = createCache('B123456789');
    final EnrollCertificateCache otherAccountCache = createCache('B987654321');
    final Uint8List pdf = _validPdf('first');

    await normalizedCache.save(pdf);

    expect(await sameAccountCache.read(), pdf);
    expect(await otherAccountCache.read(), isNull);
    final File file = await _cachedPdfFile(temporaryDirectory);
    final String accountKey = sha256
        .convert(utf8.encode('B123456789'))
        .toString()
        .substring(0, 16);
    expect(file.path, endsWith('/enroll_certificate_$accountKey.pdf'));
  });

  test(
    'rejects truncated, small, HTML-prefixed, and arbitrary-prefixed data',
    () {
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
      expect(
        EnrollCertificateCache.extractPdf(
          Uint8List.fromList(<int>[
            ...'arbitrary-prefix'.codeUnits,
            ..._validPdf('fake'),
          ]),
        ),
        isNull,
      );
    },
  );

  test('rejects a PDF larger than ten MiB', () {
    final Uint8List oversized = Uint8List(
      EnrollCertificateCache.maximumPdfLength + 1,
    );
    oversized.setAll(0, '%PDF-'.codeUnits);
    oversized.fillRange(5, oversized.length - 5, 0x20);
    oversized.setAll(oversized.length - 5, '%%EOF'.codeUnits);

    expect(EnrollCertificateCache.extractPdf(oversized), isNull);
  });

  test('validation failure preserves the existing cached PDF', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    final Uint8List original = _validPdf('original');
    await cache.save(original);

    await expectLater(
      cache.save(Uint8List.fromList('<html>error</html>'.codeUnits)),
      throwsFormatException,
    );

    expect(await cache.read(), original);
  });

  test('I/O failure before replacement preserves the existing PDF', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    final Uint8List original = _validPdf('original');
    await cache.save(original);
    final File file = await _cachedPdfFile(temporaryDirectory);
    await Directory('${file.path}.tmp').create();

    await expectLater(
      cache.save(_validPdf('replacement')),
      throwsA(isA<FileSystemException>()),
    );

    expect(await cache.read(), original);
  });

  test('atomically replaces an existing PDF after validation', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    await cache.save(_validPdf('old'));
    final Uint8List replacement = _validPdf('new');

    await cache.save(replacement);

    expect(await cache.read(), replacement);
    final Directory directory = Directory(
      '${temporaryDirectory.path}/enroll_certificates',
    );
    final List<FileSystemEntity> artifacts = await directory.list().toList();
    expect(
      artifacts.where((FileSystemEntity item) => item.path.endsWith('.bak')),
      isEmpty,
    );
    expect(
      artifacts.where((FileSystemEntity item) => item.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('deletes an invalid cached file when reading it', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    await cache.save(_validPdf('valid'));
    final File file = await _cachedPdfFile(temporaryDirectory);
    await file.writeAsBytes('<html>expired session</html>'.codeUnits);

    expect(await cache.read(), isNull);
    expect(await file.exists(), isFalse);
  });

  test(
    'recovers a missing main file from backup before temporary data',
    () async {
      final EnrollCertificateCache cache = createCache('B123456789');
      final Uint8List backupPdf = _validPdf('last-committed');
      final Uint8List temporaryPdf = _validPdf('uncommitted');
      await cache.save(backupPdf);
      final File file = await _cachedPdfFile(temporaryDirectory);
      final File backupFile = await file.rename('${file.path}.bak');
      final File temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsBytes(temporaryPdf, flush: true);

      expect(await cache.read(), backupPdf);
      expect(await file.readAsBytes(), backupPdf);
      expect(await backupFile.exists(), isFalse);
      expect(await temporaryFile.exists(), isFalse);
    },
  );

  test(
    'recovers a valid temporary file when no main or backup exists',
    () async {
      final EnrollCertificateCache cache = createCache('B123456789');
      final Uint8List temporaryPdf = _validPdf('temporary');
      await cache.save(temporaryPdf);
      final File file = await _cachedPdfFile(temporaryDirectory);
      final File temporaryFile = await file.rename('${file.path}.tmp');

      expect(await cache.read(), temporaryPdf);
      expect(await file.readAsBytes(), temporaryPdf);
      expect(await temporaryFile.exists(), isFalse);
    },
  );

  test('recovers a valid backup after deleting an invalid main file', () async {
    final EnrollCertificateCache cache = createCache('B123456789');
    final Uint8List backupPdf = _validPdf('backup');
    await cache.save(backupPdf);
    final File file = await _cachedPdfFile(temporaryDirectory);
    final File backupFile = await file.copy('${file.path}.bak');
    await file.writeAsString('<html>invalid main</html>', flush: true);

    expect(await cache.read(), backupPdf);
    expect(await file.readAsBytes(), backupPdf);
    expect(await backupFile.exists(), isFalse);
  });

  test(
    'rejects and deletes an oversized cache without reading it whole',
    () async {
      final EnrollCertificateCache cache = createCache('B123456789');
      await cache.save(_validPdf('valid'));
      final File file = await _cachedPdfFile(temporaryDirectory);
      final RandomAccessFile oversizedFile = await file.open(
        mode: FileMode.write,
      );
      await oversizedFile.truncate(EnrollCertificateCache.maximumPdfLength + 1);
      await oversizedFile.close();

      expect(await cache.read(), isNull);
      expect(await file.exists(), isFalse);
    },
  );

  test(
    'clear removes the current account cache and replacement artifacts',
    () async {
      final EnrollCertificateCache cache = createCache('B123456789');
      await cache.save(_validPdf('valid'));
      final File file = await _cachedPdfFile(temporaryDirectory);
      await File('${file.path}.tmp').writeAsString('stale');
      await File('${file.path}.bak').writeAsString('stale');

      await cache.clear();

      expect(await file.exists(), isFalse);
      expect(await File('${file.path}.tmp').exists(), isFalse);
      expect(await File('${file.path}.bak').exists(), isFalse);
    },
  );
}

Future<File> _cachedPdfFile(Directory supportDirectory) async {
  final Directory directory = Directory(
    '${supportDirectory.path}/enroll_certificates',
  );
  final List<File> files = await directory
      .list()
      .where(
        (FileSystemEntity item) => item is File && item.path.endsWith('.pdf'),
      )
      .cast<File>()
      .toList();
  expect(files, hasLength(1));
  return files.single;
}

Uint8List _validPdf(String marker) {
  return Uint8List.fromList(<int>[
    ...'%PDF-1.4\n$marker\n'.codeUnits,
    ...List<int>.filled(1100, 0x20),
    ...'\n%%EOF'.codeUnits,
  ]);
}
