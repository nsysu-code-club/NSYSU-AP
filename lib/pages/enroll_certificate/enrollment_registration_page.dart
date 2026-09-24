import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:url_launcher/url_launcher.dart';

typedef EnrollmentRegistrationLoadStop =
    Future<void> Function(InAppWebViewController controller, WebUri? url);

typedef EnrollmentRegistrationWebViewBuilder =
    Widget Function(
      BuildContext context,
      URLRequest initialRequest,
      EnrollmentRegistrationLoadStop onLoadStop,
    );

/// Lets the student complete the school's registration requirements manually.
class EnrollmentRegistrationPage extends StatefulWidget {
  const EnrollmentRegistrationPage({
    super.key,
    this.username = '',
    this.password = '',
    this.registrationCookies = const <io.Cookie>[],
    this.webViewBuilder,
    this.cookieManager,
  });

  /// Active app credentials, used only in a POST to the fixed RegWeb endpoint.
  /// Never put these in URLs, page scripts, diagnostics, or persistent state.
  final String username;
  final String password;

  /// Cookies from this certificate request, never the global Selcrs session.
  final List<io.Cookie> registrationCookies;

  /// Replaces the platform web view in widget tests.
  final EnrollmentRegistrationWebViewBuilder? webViewBuilder;

  /// Replaces the native cookie store in widget tests.
  final CookieManager? cookieManager;

  @override
  State<EnrollmentRegistrationPage> createState() =>
      _EnrollmentRegistrationPageState();
}

class _EnrollmentRegistrationPageState
    extends State<EnrollmentRegistrationPage> {
  static int _activeViews = 0;
  static DebugLoggingSettings? _previousLogging;
  static final DebugLoggingSettings _privateLogging = DebugLoggingSettings(
    enabled: false,
  );

  double _progress = 0;
  URLRequest? _initialRequest;
  bool _loginNavigationPending = false;

  bool get _supportsWebView =>
      !kIsWeb &&
      (io.Platform.isAndroid || io.Platform.isIOS || io.Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    // Plugin navigation logs include request bodies. Silence them while any
    // registration view is alive so neither POST credentials nor form data
    // can appear in debug output. Restore the prior settings on final close.
    if (_activeViews++ == 0) {
      _previousLogging = PlatformInAppWebViewController.debugLoggingSettings;
      PlatformInAppWebViewController.debugLoggingSettings = _privateLogging;
    }
    if (widget.webViewBuilder == null && !_supportsWebView) {
      _initialRequest = URLRequest(
        url: WebUri.uri(EnrollmentCertificateHelper.registrationUri),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBrowser();
      });
    } else {
      _prepareSession();
    }
  }

  @override
  void dispose() {
    if (--_activeViews == 0) {
      if (identical(
        PlatformInAppWebViewController.debugLoggingSettings,
        _privateLogging,
      )) {
        PlatformInAppWebViewController.debugLoggingSettings = _previousLogging!;
      }
      _previousLogging = null;
    }
    super.dispose();
  }

  Future<void> _prepareSession() async {
    final bool synchronized = await _synchronizeCookies();
    if (!mounted) return;
    final String username = widget.username.trim();
    final bool canLogin = username.isNotEmpty && widget.password.isNotEmpty;
    setState(() {
      _loginNavigationPending = canLogin;
      _initialRequest = canLogin
          ? URLRequest(
              url: WebUri.uri(EnrollmentCertificateHelper.registrationLoginUri),
              method: 'POST',
              headers: const <String, String>{
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: Uint8List.fromList(
                utf8.encode(
                  Uri(
                    queryParameters: <String, String>{
                      'ID': username,
                      'passwd': widget.password,
                    },
                  ).query,
                ),
              ),
            )
          : URLRequest(
              url: WebUri.uri(
                synchronized
                    ? EnrollmentCertificateHelper.registrationSessionUri
                    : EnrollmentCertificateHelper.registrationUri,
              ),
            );
    });
  }

  Future<void> _onLoadStop(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    if (!mounted ||
        !_loginNavigationPending ||
        url == null ||
        url.scheme == 'about') {
      return;
    }
    _loginNavigationPending = false;
    final Uri loginUri = EnrollmentCertificateHelper.registrationLoginUri;
    if (url.scheme == loginUri.scheme &&
        url.host == loginUri.host &&
        url.path.toLowerCase() == '/webreg/show_error.asp') {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri.uri(EnrollmentCertificateHelper.registrationUri),
        ),
      );
      return;
    }
    // A server/JavaScript redirect has priority. If the login response stays
    // at its endpoint, continue to the main page using this SAME web view's
    // native cookie store. HTTP 200 alone is not treated as proof of login.
    if (url.scheme == loginUri.scheme &&
        url.host == loginUri.host &&
        url.port == loginUri.port &&
        url.userInfo.isEmpty &&
        url.path.toLowerCase() == loginUri.path.toLowerCase()) {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri.uri(EnrollmentCertificateHelper.registrationSessionUri),
        ),
      );
    }
  }

  Future<bool> _synchronizeCookies() async {
    if (widget.registrationCookies.isEmpty) return false;
    try {
      final CookieManager manager =
          widget.cookieManager ?? CookieManager.instance();
      final WebUri url = WebUri.uri(
        EnrollmentCertificateHelper.registrationSessionUri,
      );
      // Clear only this origin's relevant paths so a prior account's ASP
      // session cannot compete with the current request. Other hosts are kept.
      final Set<String> paths = <String>{
        '/',
        '/webreg',
        '/webreg/',
        ...widget.registrationCookies.map(
          (io.Cookie cookie) => cookie.path ?? '/webreg',
        ),
      };
      for (final String path in paths) {
        if (!mounted || !await manager.deleteCookies(url: url, path: path)) {
          return false;
        }
      }
      for (final io.Cookie cookie in widget.registrationCookies) {
        if (!mounted) return false;
        if (cookie.expires?.isBefore(DateTime.now()) ?? false) return false;
        final bool saved = await manager.setCookie(
          url: url,
          name: cookie.name,
          value: cookie.value,
          path: cookie.path ?? '/webreg',
          // Keep the imported session on RegWeb, even if the server originally
          // used a parent-domain cookie. Do not expand it to another host.
          isSecure: cookie.secure,
          isHttpOnly: cookie.httpOnly,
          expiresDate: cookie.expires?.millisecondsSinceEpoch,
          maxAge: cookie.maxAge,
        );
        if (!saved) return false;
      }
      return true;
    } catch (_) {
      // A native cookie-store failure must still leave manual login usable.
      // Cookie values and platform errors may contain secrets; do not log them.
      return false;
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
                onPressed: _initialRequest == null
                    ? null
                    : () => Navigator.of(context).pop(true),
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
    final URLRequest? initialRequest = _initialRequest;
    if (initialRequest == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final EnrollmentRegistrationWebViewBuilder? builder = widget.webViewBuilder;
    if (builder != null) return builder(context, initialRequest, _onLoadStop);
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
      initialUrlRequest: initialRequest,
      initialSettings: InAppWebViewSettings(useShouldOverrideUrlLoading: true),
      shouldOverrideUrlLoading:
          (InAppWebViewController controller, NavigationAction action) async {
            final WebUri? url = action.request.url;
            final Uri loginUri = EnrollmentCertificateHelper.registrationUri;
            // Expired RegWeb sessions redirect to the old HTTP login URL.
            // Keep manual login on the verified HTTPS portal.
            if (url?.scheme == 'http' &&
                url?.host == loginUri.host &&
                url?.path == loginUri.path) {
              await controller.loadUrl(
                urlRequest: URLRequest(url: WebUri.uri(loginUri)),
              );
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
      onLoadStop: _onLoadStop,
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
