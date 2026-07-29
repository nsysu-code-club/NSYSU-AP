import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enroll_certificate_webview_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class EnrollCertificatePage extends StatefulWidget {
  const EnrollCertificatePage({super.key});

  @override
  State<EnrollCertificatePage> createState() => _EnrollCertificatePageState();
}

class _EnrollCertificatePageState extends State<EnrollCertificatePage> {
  bool _isRunning = true;
  bool _isStartingFlow = false;
  String _status = app.enrollCertificate.loadingCached;
  String _username = '';
  String _password = '';
  Uint8List? _pdfData;
  EnrollCertificateCache? _cache;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.enrollCertificate.title),
        actions: <Widget>[
          if (_pdfData != null)
            TextButton.icon(
              onPressed: _isRunning ? null : _regenerate,
              icon: const Icon(Icons.autorenew_rounded),
              label: Text(app.enrollCertificate.regenerate),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_pdfData != null && !_isRunning) {
      return HeroMode(
        enabled: false,
        child: PdfView(
          state: PdfState.finish,
          data: _pdfData,
          fileName: app.enrollCertificate.fileName,
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
              const CircularProgressIndicator()
            else
              const Icon(Icons.info_outline_rounded, size: 36),
            const SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
            if (!_isRunning) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _startAutomatedFlow,
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
    _loadCredentials();
    if (_username.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingAccount;
      });
      return;
    }

    _cache = EnrollCertificateCache(username: _username);
    try {
      final Uint8List? cachedPdf = await _cache!.read();
      if (!mounted) return;
      if (cachedPdf != null) {
        setState(() {
          _pdfData = cachedPdf;
          _isRunning = false;
          _status = '';
        });
        return;
      }
    } catch (_) {
      if (!mounted) return;
    }
    await _startAutomatedFlow();
  }

  void _loadCredentials() {
    _username = SelcrsHelper.instance.username.trim();
    _password = SelcrsHelper.instance.password;
    _username = _username.isNotEmpty
        ? _username
        : PreferenceUtil.instance.getString(Constants.prefUsername, '').trim();
    _password = _password.isNotEmpty
        ? _password
        : PreferenceUtil.instance.getStringSecurity(Constants.prefPassword, '');
    _username = _username.replaceAll(' ', '').toUpperCase();
  }

  Future<void> _regenerate() => _startAutomatedFlow();

  Future<void> _startAutomatedFlow() async {
    if (_isStartingFlow) {
      return;
    }
    _isStartingFlow = true;

    if (_username.isEmpty || _password.isEmpty) {
      _isStartingFlow = false;
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _status = app.enrollCertificate.missingCredentials;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isRunning = true;
        _status = app.enrollCertificate.openingFlow;
      });
    }
    try {
      final Uint8List? pdf = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => EnrollCertificateWebViewPage(
            username: _username,
            password: _password,
            savePdf: _cache?.save,
          ),
        ),
      );
      if (pdf != null) {
        _pdfData = pdf;
      }
    } catch (_) {
      if (mounted && _pdfData == null) {
        _status = app.enrollCertificate.saveFailed;
      }
    } finally {
      _isStartingFlow = false;
    }
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      if (_pdfData == null) {
        _status = app.enrollCertificate.notObtained;
      } else {
        _status = '';
      }
    });
  }
}
