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

  static const List<int> _pdfHeader = <int>[0x25, 0x50, 0x44, 0x46, 0x2d];
  static const List<int> _pdfEof = <int>[0x25, 0x25, 0x45, 0x4f, 0x46];

  final String _accountKey;
  final SupportDirectoryProvider _supportDirectoryProvider;

  /// Returns the current account's cached PDF, or `null` when no valid cache
  /// exists.
  ///
  /// Invalid primary files are deleted, and valid `.bak` / `.tmp` recovery
  /// artifacts are promoted back to the primary path when possible.
  Future<Uint8List?> read() async {
    final File file = await _cacheFile();
    final File temporaryFile = File('${file.path}.tmp');
    final File backupFile = File('${file.path}.bak');

    final Uint8List? cachedPdf = await _readValidPdf(file);
    if (cachedPdf != null) {
      // A committed cache always wins. Cleanup is intentionally best-effort:
      // stale crash artifacts must never make a valid certificate unreadable.
      await _deleteBestEffort(backupFile);
      await _deleteBestEffort(temporaryFile);
      return cachedPdf;
    }
    await _deleteBestEffort(file);

    // A backup is the last committed value, so prefer it over a temporary
    // replacement if both survived an interrupted save.
    final Uint8List? backupPdf = await _readValidPdf(backupFile);
    if (backupPdf != null) {
      await _restoreArtifact(source: backupFile, destination: file);
      await _deleteBestEffort(temporaryFile);
      return backupPdf;
    }
    await _deleteBestEffort(backupFile);

    final Uint8List? temporaryPdf = await _readValidPdf(temporaryFile);
    if (temporaryPdf != null) {
      await _restoreArtifact(source: temporaryFile, destination: file);
      return temporaryPdf;
    }
    await _deleteBestEffort(temporaryFile);
    return null;
  }

  /// Saves [bytes] after extracting one bounded PDF payload.
  ///
  /// Throws [FormatException] before touching disk when the response is not a
  /// valid PDF. I/O failures during replacement restore the previous cache when
  /// possible, then rethrow the original error.
  Future<void> save(Uint8List bytes) async {
    // Validate before touching any on-disk state so a bad response can never
    // replace a previously cached certificate.
    final Uint8List? pdf = extractPdf(bytes);
    if (pdf == null) {
      throw const FormatException('The certificate response is not a PDF.');
    }

    final File file = await _cacheFile(createDirectory: true);
    final File temporaryFile = File('${file.path}.tmp');
    final File backupFile = File('${file.path}.bak');

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }
    await temporaryFile.writeAsBytes(pdf, flush: true);

    bool existingFileWasMoved = false;
    try {
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      if (await file.exists()) {
        await file.rename(backupFile.path);
        existingFileWasMoved = true;
      }

      await temporaryFile.rename(file.path);
    } catch (error, stackTrace) {
      if (existingFileWasMoved &&
          !await file.exists() &&
          await backupFile.exists()) {
        await backupFile.rename(file.path);
      }
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    // The replacement is already complete. A stale backup is harmless and
    // must not turn a successful, atomic replacement into an apparent error.
    if (await backupFile.exists()) {
      try {
        await backupFile.delete();
      } on FileSystemException {
        // Best-effort cleanup; clear() also removes this account's backup.
      }
    }
  }

  /// Removes the current account's primary cache and pending replacement
  /// artifacts.
  Future<void> clear() async {
    final File file = await _cacheFile();
    for (final File artifact in <File>[
      file,
      File('${file.path}.tmp'),
      File('${file.path}.bak'),
    ]) {
      if (await artifact.exists()) {
        await artifact.delete();
      }
    }
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

  static Future<void> _restoreArtifact({
    required File source,
    required File destination,
  }) async {
    try {
      if (await destination.exists()) {
        await destination.delete();
      }
      await source.rename(destination.path);
    } on FileSystemException {
      // The validated source remains readable even if cleanup or promotion is
      // denied. A later read can retry recovery without losing the cache.
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
