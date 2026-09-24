import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Returns the directory where app-support files should be stored.
typedef SupportDirectoryProvider = Future<Directory> Function();

/// Account-scoped storage for the last valid enrollment certificate PDF.
///
/// The cache file name uses a short hash of the normalized username so multiple
/// accounts on the same device do not read each other's certificate. Every
/// write validates the PDF and commits through temporary/backup artifacts so a
/// failed refresh cannot replace a previously usable document.
class EnrollCertificateCache {
  /// Creates a cache bound to [username].
  ///
  /// [supportDirectoryProvider] is injectable so tests can use a temporary
  /// directory without touching the app support directory.
  EnrollCertificateCache({
    required String username,
    SupportDirectoryProvider? supportDirectoryProvider,
  }) : _accountKey = sha256
           .convert(utf8.encode(username.trim().toUpperCase()))
           .toString()
           .substring(0, 16),
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const int minimumPdfLength = 1024;
  static const int maximumPdfLength = 10 * 1024 * 1024;
  static final Map<String, Future<void>> _operations = <String, Future<void>>{};

  static const List<int> _pdfHeader = <int>[0x25, 0x50, 0x44, 0x46, 0x2d];
  static const List<int> _pdfEof = <int>[0x25, 0x25, 0x45, 0x4f, 0x46];

  final String _accountKey;
  final SupportDirectoryProvider _supportDirectoryProvider;

  /// Returns the current account's cached PDF, or `null` when no valid cache
  /// exists.
  /// When [semesterCode] is supplied, matching PDF metadata is also required.
  /// Stale PDFs remain on disk until a successful replacement or logout.
  ///
  /// Invalid primary files are deleted, and valid `.bak` / `.tmp` recovery
  /// artifacts are promoted back to the primary path when possible.
  Future<Uint8List?> read({String? semesterCode}) => _serialize(() async {
    final Uint8List? pdf = await _readPdf();
    if (pdf == null || semesterCode == null) return pdf;
    final File file = await _cacheFile();
    final Map<String, dynamic>? metadata = await _readMetadata(file, pdf);
    return metadata?['semesterCode'] == semesterCode ? pdf : null;
  });

  /// Returns metadata only when it belongs to the supplied PDF.
  /// Legacy, malformed, and interrupted writes are never treated as current.
  Future<Map<String, dynamic>?> readMetadata(Uint8List pdf) =>
      _serialize(() async {
        final File file = await _cacheFile();
        final Map<String, dynamic>? metadata = await _readMetadata(file, pdf);
        return metadata?['semesterCode'] is String ? metadata : null;
      });

  static Future<Map<String, dynamic>?> _readMetadata(
    File file,
    Uint8List pdf,
  ) => _readMetadataFile(File('${file.path}.json'), pdf);

  static Future<Map<String, dynamic>?> _readMetadataFile(
    File metadataFile,
    Uint8List pdf,
  ) async {
    try {
      final dynamic decoded = jsonDecode(await metadataFile.readAsString());
      if (decoded is! Map<String, dynamic> ||
          decoded['pdfSha256'] != sha256.convert(pdf).toString() ||
          (decoded['semesterCode'] != null &&
              decoded['semesterCode'] is! String) ||
          decoded['retrievedAt'] is! String ||
          DateTime.tryParse(decoded['retrievedAt'] as String) == null) {
        return null;
      }
      return decoded;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Uint8List?> _readPdf() async {
    final File file = await _cacheFile();
    final File temporaryFile = File('${file.path}.tmp');
    final File backupFile = File('${file.path}.bak');
    final File metadataFile = File('${file.path}.json');
    final File temporaryMetadata = File('${file.path}.json.tmp');

    final Uint8List? cachedPdf = await _readValidPdf(file);
    final Uint8List? backupPdf = await _readValidPdf(backupFile);
    if (cachedPdf != null) {
      final Map<String, dynamic>? cachedMetadata = await _readMetadata(
        file,
        cachedPdf,
      );
      final Map<String, dynamic>? stagedMetadata = await _readMetadataFile(
        temporaryMetadata,
        cachedPdf,
      );
      // A valid PDF alone does not commit a replacement: its metadata must
      // match too. A crash before metadata promotion leaves the old metadata
      // and backup available, or a staged metadata file for a legacy cache.
      if (backupPdf != null &&
          cachedMetadata == null &&
          (await _readMetadata(file, backupPdf) != null ||
              stagedMetadata != null)) {
        await _restoreArtifact(source: backupFile, destination: file);
        await _deleteBestEffort(temporaryFile);
        await _deleteBestEffort(temporaryMetadata);
        return backupPdf;
      }
      final bool keepStagedMetadata =
          cachedMetadata == null &&
          stagedMetadata != null &&
          !await _restoreArtifact(
            source: temporaryMetadata,
            destination: metadataFile,
          );
      // A committed cache always wins. Cleanup is intentionally best-effort:
      // stale crash artifacts must never make a valid certificate unreadable.
      await _deleteBestEffort(backupFile);
      await _deleteBestEffort(temporaryFile);
      if (!keepStagedMetadata) {
        await _deleteBestEffort(temporaryMetadata);
      }
      return cachedPdf;
    }
    await _deleteBestEffort(file);

    // A backup is the last committed value, so prefer it over a temporary
    // replacement if both survived an interrupted save.
    if (backupPdf != null) {
      await _restoreArtifact(source: backupFile, destination: file);
      await _deleteBestEffort(temporaryFile);
      await _deleteBestEffort(temporaryMetadata);
      return backupPdf;
    }
    await _deleteBestEffort(backupFile);

    final Uint8List? temporaryPdf = await _readValidPdf(temporaryFile);
    if (temporaryPdf != null) {
      final Map<String, dynamic>? cachedMetadata = await _readMetadata(
        file,
        temporaryPdf,
      );
      final Map<String, dynamic>? stagedMetadata = await _readMetadataFile(
        temporaryMetadata,
        temporaryPdf,
      );
      if (cachedMetadata != null || stagedMetadata != null) {
        final bool pdfPromoted = await _restoreArtifact(
          source: temporaryFile,
          destination: file,
        );
        if (pdfPromoted && stagedMetadata != null) {
          await _restoreArtifact(
            source: temporaryMetadata,
            destination: metadataFile,
          );
        }
        return temporaryPdf;
      }
    }
    await _deleteBestEffort(temporaryFile);
    await _deleteBestEffort(temporaryMetadata);
    return null;
  }

  /// Saves [bytes] after extracting one bounded PDF payload.
  ///
  /// Throws [FormatException] before touching disk when the response is not a
  /// valid PDF. I/O failures during replacement restore the previous cache when
  /// possible, then rethrow the original error.
  Future<void> save(
    Uint8List bytes, {
    String? semesterCode,
    DateTime? retrievedAt,
  }) => _serialize(() => _save(bytes, semesterCode, retrievedAt));

  Future<void> _save(
    Uint8List bytes,
    String? semesterCode,
    DateTime? retrievedAt,
  ) async {
    // Validate before touching any on-disk state so a bad response can never
    // replace a previously cached certificate.
    final Uint8List? pdf = extractPdf(bytes);
    if (pdf == null) {
      throw const FormatException('The certificate response is not a PDF.');
    }

    // Recover an interrupted transaction before beginning another one.
    await _readPdf();

    final File file = await _cacheFile(createDirectory: true);
    final File temporaryFile = File('${file.path}.tmp');
    final File backupFile = File('${file.path}.bak');
    final File metadataFile = File('${file.path}.json');
    final File temporaryMetadata = File('${metadataFile.path}.tmp');

    bool existingFileWasMoved = false;
    bool replacementInstalled = false;
    try {
      await temporaryFile.writeAsBytes(pdf, flush: true);
      await temporaryMetadata.writeAsString(
        jsonEncode(<String, Object?>{
          'semesterCode': semesterCode,
          'retrievedAt': (retrievedAt ?? DateTime.now())
              .toUtc()
              .toIso8601String(),
          'pdfSha256': sha256.convert(pdf).toString(),
        }),
        flush: true,
      );
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      if (await file.exists()) {
        await file.rename(backupFile.path);
        existingFileWasMoved = true;
      }

      await temporaryFile.rename(file.path);
      replacementInstalled = true;
      // Keep the previous PDF and metadata until BOTH replacements commit.
      await temporaryMetadata.rename(metadataFile.path);
    } catch (error, stackTrace) {
      if (existingFileWasMoved) {
        await _restoreArtifact(source: backupFile, destination: file);
      } else if (replacementInstalled) {
        await _deleteBestEffort(file);
      }
      await _deleteBestEffort(temporaryFile);
      await _deleteBestEffort(temporaryMetadata);
      Error.throwWithStackTrace(error, stackTrace);
    }

    await _deleteBestEffort(backupFile);
  }

  /// Removes the current account's primary cache and pending replacement
  /// artifacts.
  Future<void> clear() => _serialize(() async {
    final File file = await _cacheFile();
    for (final File artifact in <File>[
      file,
      File('${file.path}.tmp'),
      File('${file.path}.bak'),
      File('${file.path}.json'),
      File('${file.path}.json.tmp'),
    ]) {
      await _deleteBestEffort(artifact);
    }
  });

  Future<T> _serialize<T>(Future<T> Function() action) {
    final Future<T> result = (_operations[_accountKey] ?? Future<void>.value())
        .then((_) => action());
    final Future<void> settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operations[_accountKey] = settled;
    settled.then((_) {
      if (identical(_operations[_accountKey], settled)) {
        _operations.remove(_accountKey);
      }
    });
    return result;
  }

  /// Extracts a single PDF from a RegWeb response.
  ///
  /// Only ASCII whitespace may surround the PDF. HTML error pages, arbitrary
  /// prefixes, truncated files, and oversized payloads return `null`.
  static Uint8List? extractPdf(Uint8List bytes) {
    if (bytes.length > maximumPdfLength) {
      return null;
    }

    int start = 0;
    while (start < bytes.length && _isAsciiWhitespace(bytes[start])) {
      start++;
    }
    if (!_matchesAt(bytes, _pdfHeader, start)) {
      return null;
    }

    final int eofStart = _lastIndexOf(bytes, _pdfEof);
    if (eofStart < start) {
      return null;
    }
    final int end = eofStart + _pdfEof.length;
    for (int index = end; index < bytes.length; index++) {
      if (!_isAsciiWhitespace(bytes[index])) return null;
    }
    final int pdfLength = end - start;
    if (pdfLength < minimumPdfLength || pdfLength > maximumPdfLength) {
      return null;
    }

    return Uint8List.fromList(bytes.sublist(start, end));
  }

  Future<File> _cacheFile({bool createDirectory = false}) async {
    final Directory supportDirectory = await _supportDirectoryProvider();
    final Directory directory = Directory(
      '${supportDirectory.path}/enroll_certificates',
    );
    if (createDirectory) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/enroll_certificate_$_accountKey.pdf');
  }

  static Future<Uint8List?> _readValidPdf(File file) async {
    try {
      final FileStat stat = await file.stat();
      if (stat.type != FileSystemEntityType.file ||
          stat.size < minimumPdfLength ||
          stat.size > maximumPdfLength) {
        return null;
      }

      // File length can change after stat(). Limit both the stream range and
      // the in-memory buffer so a TOCTOU growth cannot allocate unboundedly.
      final BytesBuilder builder = BytesBuilder(copy: false);
      await for (final List<int> chunk in file.openRead(
        0,
        maximumPdfLength + 1,
      )) {
        if (chunk.length > maximumPdfLength - builder.length) {
          return null;
        }
        builder.add(chunk);
      }
      return extractPdf(builder.takeBytes());
    } on FileSystemException {
      return null;
    }
  }

  static Future<bool> _restoreArtifact({
    required File source,
    required File destination,
  }) async {
    try {
      if (await destination.exists()) {
        await destination.delete();
      }
      await source.rename(destination.path);
      return true;
    } on FileSystemException {
      // The validated source remains readable even if cleanup or promotion is
      // denied. A later read can retry recovery without losing the cache.
      return false;
    }
  }

  static Future<void> _deleteBestEffort(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Cleanup failure must not hide a valid cache or recovery artifact.
    }
  }

  static bool _isAsciiWhitespace(int byte) {
    return byte == 0x20 || (byte >= 0x09 && byte <= 0x0d);
  }

  static int _lastIndexOf(List<int> source, List<int> pattern) {
    for (int i = source.length - pattern.length; i >= 0; i--) {
      if (_matchesAt(source, pattern, i)) {
        return i;
      }
    }
    return -1;
  }

  static bool _matchesAt(List<int> source, List<int> pattern, int offset) {
    if (offset < 0 || offset + pattern.length > source.length) {
      return false;
    }
    for (int i = 0; i < pattern.length; i++) {
      if (source[offset + i] != pattern[i]) {
        return false;
      }
    }
    return true;
  }
}
