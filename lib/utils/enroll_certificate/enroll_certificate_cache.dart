import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

class EnrollCertificateCache {
  EnrollCertificateCache({
    required String username,
    SupportDirectoryProvider? supportDirectoryProvider,
  }) : _accountKey = sha256
           .convert(utf8.encode(username.trim().toUpperCase()))
           .toString()
           .substring(0, 16),
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const List<int> _pdfHeader = <int>[0x25, 0x50, 0x44, 0x46, 0x2d];
  static const List<int> _pdfEof = <int>[0x25, 0x25, 0x45, 0x4f, 0x46];
  static const int minimumPdfLength = 1024;

  final String _accountKey;
  final SupportDirectoryProvider _supportDirectoryProvider;

  Future<Uint8List?> read() async {
    final File file = await _cacheFile();
    if (!await file.exists()) {
      return null;
    }
    final Uint8List? pdf = extractPdf(await file.readAsBytes());
    if (pdf == null) {
      await file.delete();
      return null;
    }
    return pdf;
  }

  Future<void> save(Uint8List bytes) async {
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
    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    final bool hadExistingFile = await file.exists();
    if (hadExistingFile) {
      await file.rename(backupFile.path);
    }
    try {
      await temporaryFile.rename(file.path);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (_) {
      if (!await file.exists() && await backupFile.exists()) {
        await backupFile.rename(file.path);
      }
      rethrow;
    }
  }

  Future<void> clear() async {
    final File file = await _cacheFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Uint8List? extractPdf(Uint8List bytes) {
    final int start = _indexOf(bytes, _pdfHeader);
    if (start < 0) {
      return null;
    }
    final String prefix = ascii
        .decode(bytes.sublist(0, start), allowInvalid: true)
        .toLowerCase();
    if (prefix.contains('<html') || prefix.contains('<!doctype')) {
      return null;
    }
    final int eofStart = _lastIndexOf(bytes, _pdfEof);
    if (eofStart < start) {
      return null;
    }
    final Uint8List pdf = Uint8List.fromList(
      bytes.sublist(start, eofStart + _pdfEof.length),
    );
    return pdf.length >= minimumPdfLength ? pdf : null;
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

  static int _indexOf(List<int> source, List<int> pattern) {
    for (int i = 0; i <= source.length - pattern.length; i++) {
      if (_matchesAt(source, pattern, i)) {
        return i;
      }
    }
    return -1;
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
    for (int i = 0; i < pattern.length; i++) {
      if (source[offset + i] != pattern[i]) {
        return false;
      }
    }
    return true;
  }
}
