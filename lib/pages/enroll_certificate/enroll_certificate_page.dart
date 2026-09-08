import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:printing/printing.dart';

/// Supplies the credentials used by [EnrollCertificatePage].
typedef EnrollmentCertificateCredentialsProvider =
    EnrollmentCertificateCredentials Function();

/// Retrieves a fresh enrollment certificate PDF.
typedef EnrollmentCertificateDownload =
    Future<Uint8List> Function({
      required String username,
      required String password,
    });

/// Reads an account-scoped cached enrollment certificate PDF.
typedef EnrollmentCertificateCacheReader =
    Future<Uint8List?> Function({required String username});

/// Writes an account-scoped cached enrollment certificate PDF.
typedef EnrollmentCertificateCacheWriter =
    Future<void> Function({required String username, required Uint8List bytes});

/// Exports the displayed PDF to the platform share/save flow.
typedef EnrollmentCertificatePdfExporter =
    Future<bool> Function({required Uint8List bytes, required String fileName});

/// Builds the PDF viewer for a validated enrollment certificate.
typedef EnrollmentCertificatePdfViewBuilder =
    Widget Function(BuildContext context, Uint8List bytes, String fileName);

/// Username/password pair used to retrieve an enrollment certificate.
class EnrollmentCertificateCredentials {
  const EnrollmentCertificateCredentials({
    required this.username,
    required this.password,
  });

  /// Student ID used by RegWeb.
  final String username;

  /// Password for the school account.
  final String password;
}

/// Loads, refreshes, displays, and exports the current user's enrollment
/// certificate PDF.
///
/// The optional callbacks keep network, cache, export, and PDF rendering
/// injectable for widget tests. In production, the page reads the active app
/// credentials, uses [EnrollmentCertificateHelper] for RegWeb, and stores the
/// last valid PDF in [EnrollCertificateCache].
class EnrollCertificatePage extends StatefulWidget {
  const EnrollCertificatePage({
    super.key,
    this.credentialsProvider,
    this.downloadCertificate,
    this.readCachedCertificate,
    this.writeCachedCertificate,
    this.supportDirectoryProvider,
    this.exportPdf,
    this.pdfViewBuilder,
  });

  final EnrollmentCertificateCredentialsProvider? credentialsProvider;
  final EnrollmentCertificateDownload? downloadCertificate;
  final EnrollmentCertificateCacheReader? readCachedCertificate;
  final EnrollmentCertificateCacheWriter? writeCachedCertificate;
  final SupportDirectoryProvider? supportDirectoryProvider;
  final EnrollmentCertificatePdfExporter? exportPdf;
  final EnrollmentCertificatePdfViewBuilder? pdfViewBuilder;

  @override
  State<EnrollCertificatePage> createState() => _EnrollCertificatePageState();
}

class _EnrollCertificatePageState extends State<EnrollCertificatePage> {
  static const String _debugPrefix = '[EnrollCertificatePage]';

  bool _isRunning = true;
  bool _isFetching = false;
  late String _status;
  String _username = '';
  String _password = '';
  Uint8List? _pdfData;
  late EnrollCertificateCache _cache;
  EnrollmentCertificateHelper? _activeHelper;

  @override
  void initState() {
    super.initState();
    _status = app.enrollCertificate.loadingCached;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initialize();
    });
  }

  @override
  void dispose() {
    final EnrollmentCertificateHelper? helper = _activeHelper;
    _debugLog('event=dispose activeHelper=${helper != null}');
    _activeHelper = null;
    helper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.enrollCertificate.title),
        actions: <Widget>[
          if (_pdfData != null) ...<Widget>[
            IconButton(
              key: const ValueKey<String>('enroll-certificate-download'),
              onPressed: _download,
              tooltip: app.enrollCertificate.download,
              icon: const Icon(Icons.download_rounded),
            ),
            TextButton.icon(
              key: const ValueKey<String>('enroll-certificate-regenerate'),
              onPressed: _isRunning ? null : _retrieve,
              icon: const Icon(Icons.autorenew_rounded),
              label: Text(app.enrollCertificate.regenerate),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final Uint8List? pdf = _pdfData;
    if (pdf != null && !_isRunning) {
      final String fileName = app.enrollCertificate.fileName;
      return KeyedSubtree(
        key: const ValueKey<String>('enroll-certificate-pdf'),
        child:
            widget.pdfViewBuilder?.call(context, pdf, fileName) ??
            HeroMode(
              enabled: false,
              child: PdfView(
                state: PdfState.finish,
                data: pdf,
                fileName: fileName,
              ),
            ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_isRunning)
              const CircularProgressIndicator(
                key: ValueKey<String>('enroll-certificate-progress'),
              )
            else
              const Icon(Icons.info_outline_rounded, size: 36),
            const SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
            if (!_isRunning) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey<String>('enroll-certificate-retry'),
                onPressed: _retrieve,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(app.enrollCertificate.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    final EnrollmentCertificateCredentials credentials =
        widget.credentialsProvider?.call() ?? _loadCredentials();
    _username = credentials.username.replaceAll(' ', '').trim().toUpperCase();
    _password = credentials.password;
    _debugLog(
      'event=initialize usernamePresent=${_username.isNotEmpty} '
      'passwordPresent=${_password.isNotEmpty}',
    );

    if (_username.isEmpty) {
      _debugLog('event=initialize_blocked reason=missing_account');
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingAccount;
      });
      return;
    }

    _cache = EnrollCertificateCache(
      username: _username,
      supportDirectoryProvider: widget.supportDirectoryProvider,
    );
    try {
      _debugLog('event=cache_read_start');
      final Uint8List? cachedPdf = await _readCachedCertificate();
      if (!mounted) return;
      if (cachedPdf != null) {
        _debugLog('event=cache_hit pdfBytes=${cachedPdf.length}');
        setState(() {
          _pdfData = cachedPdf;
          _isRunning = false;
          _status = '';
        });
        return;
      }
      _debugLog('event=cache_miss');
    } on Exception catch (error) {
      _debugLog('event=cache_read_failure sourceType=${error.runtimeType}');
      // A cache read failure is treated as a miss; a fresh copy can still load.
    }

    await _retrieve();
  }

  EnrollmentCertificateCredentials _loadCredentials() {
    String username = SelcrsHelper.instance.username.trim();
    String password = SelcrsHelper.instance.password;
    username = username.isNotEmpty
        ? username
        : PreferenceUtil.instance.getString(Constants.prefUsername, '').trim();
    password = password.isNotEmpty
        ? password
        : PreferenceUtil.instance.getStringSecurity(Constants.prefPassword, '');
    return EnrollmentCertificateCredentials(
      username: username,
      password: password,
    );
  }

  Future<void> _retrieve() async {
    if (!mounted || _isFetching) {
      if (_isFetching) {
        _debugLog('event=retrieve_ignored reason=already_running');
      }
      return;
    }
    if (_username.isEmpty || _password.isEmpty) {
      _debugLog(
        'event=retrieve_blocked reason=missing_credentials '
        'usernamePresent=${_username.isNotEmpty} '
        'passwordPresent=${_password.isNotEmpty}',
      );
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingCredentials;
      });
      return;
    }

    final String mode = _pdfData == null ? 'initial' : 'regenerate';
    _debugLog('event=retrieve_start mode=$mode');
    _isFetching = true;
    if (mounted) {
      setState(() {
        _isRunning = true;
        _status = app.enrollCertificate.retrieving;
      });
    }

    try {
      final Uint8List pdf = await _fetchCertificate();
      _debugLog('event=retrieve_download_complete pdfBytes=${pdf.length}');
      if (!mounted) {
        _debugLog('event=retrieve_cancelled reason=page_unmounted');
        return;
      }
      bool cacheSaveFailed = false;
      try {
        await _writeCachedCertificate(pdf);
        _debugLog('event=cache_write_complete pdfBytes=${pdf.length}');
      } on FormatException catch (error) {
        _debugLog(
          'event=cache_write_failure sourceType=${error.runtimeType} '
          'fatal=true',
        );
        rethrow;
      } on Exception catch (error) {
        _debugLog(
          'event=cache_write_failure sourceType=${error.runtimeType} '
          'fatal=false',
        );
        cacheSaveFailed = true;
      }
      if (!mounted) {
        _debugLog('event=retrieve_cancelled reason=page_unmounted');
        return;
      }
      setState(() {
        _pdfData = pdf;
        _isRunning = false;
        _status = '';
      });
      _debugLog(
        'event=retrieve_complete mode=$mode cacheSaved=${!cacheSaveFailed}',
      );
      if (cacheSaveFailed) {
        _showMessage(app.enrollCertificate.saveFailed);
      }
    } on EnrollmentCertificateException catch (error) {
      _debugLog(
        'event=retrieve_failure kind=${error.kind.name} '
        'status=${error.statusCode ?? 'none'}',
      );
      _handleRetrievalFailure(_messageFor(error.kind));
    } catch (error) {
      _debugLog(
        'event=retrieve_failure kind=unexpected '
        'sourceType=${error.runtimeType}',
      );
      _handleRetrievalFailure(app.enrollCertificate.requestFailed);
    } finally {
      _isFetching = false;
      _debugLog('event=retrieve_end mode=$mode');
    }
  }

  Future<Uint8List> _fetchCertificate() async {
    final EnrollmentCertificateDownload? injectedDownload =
        widget.downloadCertificate;
    if (injectedDownload != null) {
      _debugLog('event=fetch_transport kind=injected');
      return injectedDownload(username: _username, password: _password);
    }

    _debugLog('event=fetch_transport kind=regweb');
    final EnrollmentCertificateHelper helper = EnrollmentCertificateHelper();
    _activeHelper = helper;
    try {
      return await helper.download(username: _username, password: _password);
    } finally {
      if (identical(_activeHelper, helper)) {
        _activeHelper = null;
        _debugLog('event=fetch_transport_close kind=regweb');
        helper.close();
      }
    }
  }

  Future<Uint8List?> _readCachedCertificate() {
    final EnrollmentCertificateCacheReader? reader =
        widget.readCachedCertificate;
    if (reader != null) {
      return reader(username: _username);
    }
    return _cache.read();
  }

  Future<void> _writeCachedCertificate(Uint8List bytes) {
    final EnrollmentCertificateCacheWriter? writer =
        widget.writeCachedCertificate;
    if (writer != null) {
      return writer(username: _username, bytes: bytes);
    }
    return _cache.save(bytes);
  }

  String _messageFor(EnrollmentCertificateExceptionKind kind) {
    return switch (kind) {
      EnrollmentCertificateExceptionKind.credentials =>
        app.enrollCertificate.missingCredentials,
      EnrollmentCertificateExceptionKind.timeout =>
        app.enrollCertificate.requestTimedOut,
      EnrollmentCertificateExceptionKind.tooLarge ||
      EnrollmentCertificateExceptionKind.invalidPdf =>
        app.enrollCertificate.invalidResponse,
      EnrollmentCertificateExceptionKind.http ||
      EnrollmentCertificateExceptionKind.redirect ||
      EnrollmentCertificateExceptionKind.cancelled ||
      EnrollmentCertificateExceptionKind.network =>
        app.enrollCertificate.requestFailed,
    };
  }

  void _handleRetrievalFailure(String message) {
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _status = _pdfData == null ? message : '';
    });
    if (_pdfData != null) {
      _showMessage(message);
    }
  }

  Future<void> _download() async {
    final Uint8List? pdf = _pdfData;
    if (pdf == null) return;
    _debugLog('event=export_start pdfBytes=${pdf.length}');
    final String fileName = '${app.enrollCertificate.fileName}.pdf';
    try {
      final EnrollmentCertificatePdfExporter? exporter = widget.exportPdf;
      final bool exported;
      if (exporter != null) {
        exported = await exporter(bytes: pdf, fileName: fileName);
      } else {
        exported = await Printing.sharePdf(bytes: pdf, filename: fileName);
      }
      _debugLog('event=export_complete success=$exported');
      if (!exported && mounted) {
        _showMessage(app.enrollCertificate.downloadFailed);
      }
    } catch (error) {
      _debugLog('event=export_failure sourceType=${error.runtimeType}');
      if (!mounted) return;
      _showMessage(app.enrollCertificate.downloadFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('$_debugPrefix $message');
  }
}
