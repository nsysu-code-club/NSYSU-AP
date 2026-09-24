import 'dart:async';
import 'dart:io' show Cookie;
import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enrollment_registration_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enrollment_certificate_session.dart';
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

/// Builds the recovery page with only the current download's RegWeb cookies.
typedef EnrollmentCertificateRegistrationPageBuilder =
    Widget Function(BuildContext context, List<Cookie> cookies);

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
    this.currentSemesterCodeProvider,
    this.refreshSemesterCode,
    this.registrationPageBuilder,
  });

  final EnrollmentCertificateCredentialsProvider? credentialsProvider;
  final EnrollmentCertificateDownload? downloadCertificate;
  final EnrollmentCertificateCacheReader? readCachedCertificate;
  final EnrollmentCertificateCacheWriter? writeCachedCertificate;
  final SupportDirectoryProvider? supportDirectoryProvider;
  final EnrollmentCertificatePdfExporter? exportPdf;
  final EnrollmentCertificatePdfViewBuilder? pdfViewBuilder;
  final Future<String?> Function()? currentSemesterCodeProvider;
  final Future<void> Function()? refreshSemesterCode;
  final EnrollmentCertificateRegistrationPageBuilder? registrationPageBuilder;

  @override
  State<EnrollCertificatePage> createState() => _EnrollCertificatePageState();
}

class _EnrollCertificatePageState extends State<EnrollCertificatePage> {
  static const String _debugPrefix = '[EnrollCertificatePage]';

  bool _isRunning = true;
  bool _isFetching = false;
  bool _isOpeningRegistration = false;
  late String _status;
  String _username = '';
  String _password = '';
  String? _semesterCode;
  Uint8List? _pdfData;
  late EnrollCertificateCache _cache;
  EnrollmentCertificateHelper? _activeHelper;
  late final EnrollmentCertificateSession _session;
  bool _disposed = false;

  bool get _isActive => mounted && !_session.isCancelled;

  @override
  void initState() {
    super.initState();
    _session = EnrollmentCertificateSession(onCancel: _cancelSession);
    _status = app.enrollCertificate.loadingCached;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initialize();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_session.close());
    super.dispose();
  }

  Future<void>? _cancelSession() {
    final EnrollmentCertificateHelper? helper = _activeHelper;
    _debugLog('event=dispose activeHelper=${helper != null}');
    _activeHelper = null;
    helper?.close();
    _username = '';
    _password = '';
    _pdfData = null;
    if (!_disposed && mounted) {
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingCredentials;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(app.enrollCertificate.title)),
      body: _buildBody(),
      floatingActionButton: _pdfData == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FloatingActionButton(
                  key: const ValueKey<String>('enroll-certificate-download'),
                  heroTag: 'enroll-certificate-download',
                  onPressed: _download,
                  tooltip: app.enrollCertificate.download,
                  child: const Icon(Icons.download_rounded),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  key: const ValueKey<String>('enroll-certificate-regenerate'),
                  heroTag: 'enroll-certificate-regenerate',
                  onPressed: _isRunning || _isOpeningRegistration
                      ? null
                      : _retrieve,
                  tooltip: app.enrollCertificate.regenerate,
                  child: const Icon(Icons.autorenew_rounded),
                ),
              ],
            ),
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
            PdfPreview(build: (_) => pdf, useActions: false),
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
                onPressed: _isOpeningRegistration ? null : _retrieve,
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
    if (!_isActive) return;
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
      if (!_isActive) return;
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
      _semesterCode = await _resolveSemesterCode();
      if (!_isActive) return;
      unawaited(_refreshSemesterCode());
      _debugLog('event=cache_read_start');
      final Uint8List? cachedPdf = await _readCachedCertificate();
      if (!_isActive) return;
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
    if (!SelcrsHelper.instance.isLogin) {
      return const EnrollmentCertificateCredentials(username: '', password: '');
    }
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

  Future<void> _retrieve({bool openRegistrationOnFailure = true}) async {
    if (!_isActive || _isFetching || _isOpeningRegistration) {
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
      if (!_isActive) return;
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingCredentials;
      });
      return;
    }

    final String mode = _pdfData == null ? 'initial' : 'regenerate';
    bool needsRegistration = false;
    List<Cookie> registrationCookies = const <Cookie>[];
    _debugLog('event=retrieve_start mode=$mode');
    _isFetching = true;
    if (mounted) {
      setState(() {
        _isRunning = true;
        _status = app.enrollCertificate.retrieving;
      });
    }

    try {
      final String? semesterCode = await _resolveSemesterCode();
      if (!_isActive) return;
      final Uint8List pdf = await _fetchCertificate();
      final DateTime retrievedAt = DateTime.now().toUtc();
      _debugLog('event=retrieve_download_complete pdfBytes=${pdf.length}');
      if (!_isActive) {
        _debugLog('event=retrieve_cancelled reason=page_unmounted');
        return;
      }
      bool cacheSaveFailed = false;
      try {
        await _session.write(
          () => _writeCachedCertificate(pdf, semesterCode, retrievedAt),
        );
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
      if (!_isActive) {
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
      needsRegistration =
          error.kind == EnrollmentCertificateExceptionKind.registrationRequired;
      registrationCookies = error.registrationCookies;
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
    if (_isActive && needsRegistration && openRegistrationOnFailure) {
      await _openRegistration(registrationCookies);
    }
  }

  Future<void> _openRegistration(List<Cookie> cookies) async {
    if (!_isActive || _isOpeningRegistration) return;
    setState(() => _isOpeningRegistration = true);
    bool retry = false;
    try {
      retry =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              fullscreenDialog: true,
              builder: (BuildContext context) =>
                  widget.registrationPageBuilder?.call(context, cookies) ??
                  EnrollmentRegistrationPage(
                    username: _username,
                    password: _password,
                    registrationCookies: cookies,
                  ),
            ),
          ) ??
          false;
    } finally {
      if (mounted) setState(() => _isOpeningRegistration = false);
    }
    if (_isActive && retry) {
      // A still-blocked response remains visible instead of reopening the
      // window in a loop. The student can retry manually when ready.
      await _retrieve(openRegistrationOnFailure: false);
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
    final String? semesterCode = _semesterCode;
    if (semesterCode == null) return Future<Uint8List?>.value();
    return _cache.read(semesterCode: semesterCode);
  }

  Future<void> _writeCachedCertificate(
    Uint8List bytes,
    String? semesterCode,
    DateTime retrievedAt,
  ) {
    final EnrollmentCertificateCacheWriter? writer =
        widget.writeCachedCertificate;
    if (writer != null) {
      return writer(username: _username, bytes: bytes);
    }
    return _cache.save(
      bytes,
      semesterCode: semesterCode,
      retrievedAt: retrievedAt,
    );
  }

  Future<String?> _resolveSemesterCode() async {
    if (widget.currentSemesterCodeProvider != null) {
      return widget.currentSemesterCodeProvider!();
    }
    // Use the same configured current semester as the course page, never a
    // semester selected by the user or a hard-coded historical fallback.
    try {
      final FirebaseRemoteConfig? config =
          FirebaseRemoteConfigUtils.instance.remoteConfig;
      if (config != null) {
        final String code = config
            .getString(Constants.defaultCourseSemesterCode)
            .trim();
        if (_isSemesterCode(code)) return code;
      }
    } catch (_) {
      // Previously resolved course configuration remains usable offline.
    }
    final String code = PreferenceUtil.instance
        .getString(Constants.defaultCourseSemesterCode, '')
        .trim();
    return _isSemesterCode(code) ? code : null;
  }

  Future<void> _refreshSemesterCode() async {
    try {
      if (widget.refreshSemesterCode != null) {
        await widget.refreshSemesterCode!().timeout(const Duration(seconds: 3));
      } else if (widget.currentSemesterCodeProvider == null) {
        final FirebaseRemoteConfig? config =
            FirebaseRemoteConfigUtils.instance.remoteConfig;
        if (config != null) {
          await config.fetch().timeout(const Duration(seconds: 3));
          if (_isActive) await config.activate();
        }
      }
    } catch (_) {
      // Refresh never blocks disk reads or invalidates activated values.
    }
  }

  static bool _isSemesterCode(String code) =>
      RegExp(r'^\d{3}[0-3]$').hasMatch(code);

  String _messageFor(EnrollmentCertificateExceptionKind kind) {
    return switch (kind) {
      EnrollmentCertificateExceptionKind.credentials =>
        app.enrollCertificate.missingCredentials,
      EnrollmentCertificateExceptionKind.timeout =>
        app.enrollCertificate.requestTimedOut,
      EnrollmentCertificateExceptionKind.registrationRequired =>
        app.enrollCertificate.registrationRequired,
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
    if (!_isActive) return;
    setState(() {
      _isRunning = false;
      _status = _pdfData == null ? message : '';
    });
    if (_pdfData != null) {
      _showMessage(message);
    }
  }

  Future<void> _download() async {
    if (!_isActive) return;
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
      if (!_isActive) return;
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
