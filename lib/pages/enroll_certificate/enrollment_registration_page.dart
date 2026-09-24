import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lets the student complete the school's registration requirements manually.
class EnrollmentRegistrationPage extends StatefulWidget {
  const EnrollmentRegistrationPage({super.key, this.webViewBuilder});

  /// Replaces the platform web view in widget tests.
  final WidgetBuilder? webViewBuilder;

  @override
  State<EnrollmentRegistrationPage> createState() =>
      _EnrollmentRegistrationPageState();
}

class _EnrollmentRegistrationPageState
    extends State<EnrollmentRegistrationPage> {
  double _progress = 0;

  bool get _supportsWebView =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (widget.webViewBuilder == null && !_supportsWebView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBrowser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.enrollCertificate.registrationTitle),
        actions: <Widget>[
          IconButton(
            tooltip: app.openBrowserToFill,
            onPressed: _openBrowser,
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(app.enrollCertificate.registrationRequired),
            ),
            if (widget.webViewBuilder == null &&
                _supportsWebView &&
                _progress < 1)
              LinearProgressIndicator(value: _progress),
            Expanded(child: _buildWebView(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                key: const ValueKey<String>('enroll-registration-complete'),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(app.enrollCertificate.registrationComplete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    final WidgetBuilder? builder = widget.webViewBuilder;
    if (builder != null) return builder(context);
    if (!_supportsWebView) {
      return Center(
        child: TextButton.icon(
          onPressed: _openBrowser,
          icon: const Icon(Icons.open_in_browser_rounded),
          label: Text(app.openBrowserToFill),
        ),
      );
    }
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri.uri(EnrollmentCertificateHelper.registrationUri),
      ),
      onProgressChanged: (InAppWebViewController controller, int progress) {
        if (mounted) setState(() => _progress = progress / 100);
      },
      onReceivedError:
          (
            InAppWebViewController controller,
            WebResourceRequest request,
            WebResourceError error,
          ) {
            if (request.isForMainFrame == true && mounted) {
              setState(() => _progress = 1);
            }
          },
    );
  }

  Future<void> _openBrowser() async {
    try {
      final bool opened = await launchUrl(
        EnrollmentCertificateHelper.registrationUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {
      // Keep the registration window open so the user can try again.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(app.enrollCertificate.requestFailed)),
    );
  }
}
