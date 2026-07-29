import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_ap/pages/enroll_certificate/widgets/enroll_certificate_progress_view.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/captcha_ocr/captcha_ocr.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_page_evidence.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_progress.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_service.dart';

class EnrollCertificateWebViewPage extends StatefulWidget {
  const EnrollCertificateWebViewPage({
    required this.username,
    required this.password,
    this.savePdf,
    super.key,
  });

  final String username;
  final String password;
  final Future<void> Function(Uint8List pdf)? savePdf;

  @override
  State<EnrollCertificateWebViewPage> createState() =>
      _EnrollCertificateWebViewPageState();
}

class _EnrollCertificateWebViewPageState
    extends State<EnrollCertificateWebViewPage> {
  static const String _captchaHandlerName = 'enrollCertificateCaptcha';
  static const String _pdfHandlerName = 'enrollCertificatePdf';
  static const int _maxAutomationAttempts = 3;
  static const int _maxSameImageOcrAttempts = 3;
  static const int _maxOcrRefreshes = 5;
  static const Duration _navigationTimeout = Duration(seconds: 15);
  static const Duration _pdfTimeout = Duration(seconds: 30);

  late final WebUri _initialLoginUrl;
  final CaptchaOcr _captchaOcr = CaptchaOcr();
  final CaptchaImagePreprocessor _captchaPreprocessor =
      const CaptchaImagePreprocessor();
  final EnrollCertificateAttemptTracker _attempts =
      EnrollCertificateAttemptTracker();
  final EnrollCertificateRunTracker _runTracker = EnrollCertificateRunTracker();
  final EnrollCertificateNavigationTracker _navigationTracker =
      EnrollCertificateNavigationTracker();
  final EnrollCertificateRetryGate _retryGate = EnrollCertificateRetryGate();
  InAppWebViewController? _controller;
  Timer? _pendingNavigation;
  Timer? _stageTimeout;
  bool _hasRefreshedInitialCaptcha = false;
  bool _needsCaptchaRefresh = false;
  int _captchaRequestId = 0;
  int _completedRunId = -1;
  String _lastOcrVariant = '';
  bool _showManualWebView = false;
  EnrollCertificateProgress _progress =
      const EnrollCertificateProgress.preparing();

  @override
  void initState() {
    super.initState();
    _initialLoginUrl = WebUri(
      EnrollCertificateService.enrollUri
          .replace(
            queryParameters: <String, String>{
              '_': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          )
          .toString(),
    );
  }

  @override
  void dispose() {
    _runTracker.invalidate();
    _captchaRequestId++;
    _pendingNavigation?.cancel();
    _stageTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.enrollCertificate.title),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _retryCurrentStep,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(app.enrollCertificate.regenerate),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: _buildWebView()),
                if (!_showManualWebView)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: SafeArea(
                        child: EnrollCertificateProgressView(
                          progress: _displayProgress,
                          showIndicator: !_isErrorPhase,
                          onRetry: _isErrorPhase ? _retryCurrentStep : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_showManualWebView)
            SafeArea(
              top: false,
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.public_rounded, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _progress.primary,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            if (_progress.secondary.isNotEmpty)
                              Text(
                                _progress.secondary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _progress = EnrollCertificateProgress(
                              phase: EnrollCertificatePhase.manual,
                              primary: app.enrollCertificate.manualOperation,
                            );
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: app.enrollCertificate.hideStatus,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: _initialLoginUrl,
        cachePolicy: URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptCanOpenWindowsAutomatically: true,
        supportMultipleWindows: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (InAppWebViewController controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: _captchaHandlerName,
          callback: _handleCaptchaPayload,
        );
        controller.addJavaScriptHandler(
          handlerName: _pdfHandlerName,
          callback: _handlePdfPayload,
        );
      },
      onLoadStart: (_, WebUri? url) {
        if (_isLoginPostUrl(url)) {
          _pendingNavigation?.cancel();
          _setProgress(
            EnrollCertificatePhase.loginValidating,
            '嘗試 ${_attempts.currentLoginAttempt}/$_maxAutomationAttempts・正在驗證登入',
            '正在確認帳號、密碼與驗證碼',
          );
          _armStageTimeout(_navigationTimeout, _handleNavigationTimeout);
          return;
        }
        if (_isCertificateUrl(url)) {
          _setProgress(
            EnrollCertificatePhase.certificateGenerating,
            '正在產生在學證明 PDF',
            '等待校方系統完成文件處理',
          );
          return;
        }
        if (_isRegistrationHost(url)) {
          _setProgress(
            EnrollCertificatePhase.sessionValidating,
            '登入回應完成・正在驗證 Session',
            '正在載入 ${url?.host ?? '網路註冊系統'}',
          );
          return;
        }
        _setProgress(
          EnrollCertificatePhase.preparing,
          '正在連線校方系統',
          '正在載入 ${url?.host ?? '網頁'}',
        );
      },
      onLoadStop: (_, WebUri? url) => _handleLoadStop(url),
      onCreateWindow:
          (InAppWebViewController controller, CreateWindowAction action) async {
            final WebUri? url = action.request.url;
            if (url != null && _isAllowedAutomationUrl(url)) {
              await controller.loadUrl(urlRequest: URLRequest(url: url));
            } else if (!_showManualWebView) {
              _setError(
                app.enrollCertificate.unknownPage,
                app.enrollCertificate.navigationStopped,
              );
            }
            return true;
          },
      shouldOverrideUrlLoading: (_, NavigationAction action) async {
        final WebUri? url = action.request.url;
        if (!_showManualWebView && !_isAllowedAutomationUrl(url)) {
          _setError(
            app.enrollCertificate.unknownNavigation,
            app.enrollCertificate.retryInstruction,
          );
          return NavigationActionPolicy.CANCEL;
        }
        if (_isCertificateUrl(url)) {
          _setProgress(
            EnrollCertificatePhase.certificateGenerating,
            '正在產生在學證明 PDF',
            '正在前往文件產生頁面',
          );
        } else if (url != null &&
            _progress.phase != EnrollCertificatePhase.completed) {
          _setProgress(
            EnrollCertificatePhase.registrationLoading,
            '正在完成網路註冊系統跳轉',
            '正在前往 ${url.host}',
          );
        }
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Future<void> _handleLoadStop(WebUri? url) async {
    if (url == null) {
      return;
    }
    final int runId = _runId;

    if (_isCertificateUrl(url)) {
      _setProgress(
        EnrollCertificatePhase.certificateGenerating,
        '正在產生在學證明 PDF',
        '等待校方系統完成文件處理',
      );
      return;
    }

    if (_isRegistrationHost(url)) {
      await _validateRegistrationPage(runId);
      return;
    }

    if (_isLoginPostUrl(url) ||
        _progress.phase == EnrollCertificatePhase.loginValidating) {
      await _handleLoginResponse(runId, url);
      return;
    }

    if (_isEnrollLoginPage(url) &&
        (!_hasRefreshedInitialCaptcha || _needsCaptchaRefresh)) {
      _needsCaptchaRefresh = false;
      await _refreshCaptcha();
    }
  }

  bool _isLoginPostUrl(WebUri? url) {
    return url?.path.toLowerCase().endsWith('/stu_enroll_loginchk.asp') ??
        false;
  }

  bool _isEnrollLoginPage(WebUri url) {
    if (url.host != EnrollCertificateService.enrollUri.host) {
      return false;
    }
    final String path = url.path.toLowerCase();
    return !path.endsWith('/stu_enroll_loginchk.asp');
  }

  bool _isEnrollHost(WebUri? url) =>
      url?.host.toLowerCase() ==
      EnrollCertificateService.enrollUri.host.toLowerCase();

  bool _isRegistrationMainUrl(WebUri? url) {
    if (!_isRegistrationHost(url)) {
      return false;
    }
    final WebUri registrationUrl = url!;
    final String path = registrationUrl.path.toLowerCase();
    final String query = registrationUrl.query.toLowerCase();
    return path.endsWith('/webreg/wregmain3.asp') && query.contains('act=11');
  }

  bool _isRegistrationHost(WebUri? url) =>
      url?.host.toLowerCase() == 'regweb.nsysu.edu.tw';

  bool _isAllowedAutomationUrl(WebUri? url) {
    if (url == null) {
      return true;
    }
    final String scheme = url.scheme.toLowerCase();
    if (scheme == 'about' || scheme == 'blob' || scheme == 'data') {
      return true;
    }
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }
    final String host = url.host.toLowerCase();
    return host == EnrollCertificateService.enrollUri.host.toLowerCase() ||
        host == 'regweb.nsysu.edu.tw';
  }

  bool _isCertificateUrl(WebUri? url) {
    if (url == null) {
      return false;
    }
    final String value = url.toString().toLowerCase();
    return value.contains('act=71') ||
        value.contains('enrollcert') ||
        value.contains('/print/');
  }

  Future<void> _disableRegistrationAutoReload() async {
    final InAppWebViewController? controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.evaluateJavascript(
        source: '''
(function () {
  const loadFlag = document.querySelector('[name="fg_load"]');
  const blurFlag = document.querySelector('[name="fg_blur"]');
  if (loadFlag) loadFlag.value = '0';
  if (blurFlag) blurFlag.value = '0';

  window.www_recheck = function () {};
  window.focuscheck = function () {};
  window.setflag = function () {};
  window.onfocus = null;
  window.onblur = null;
  if (document.body) {
    document.body.removeAttribute('onfocus');
    document.body.removeAttribute('onblur');
    document.body.removeAttribute('onpageshow');
  }
  return 'disabled';
})();
''',
      );
    } catch (_) {}
  }

  Future<void> _handleLoginResponse(int runId, WebUri? expectedUrl) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null || !_isCurrentRun(runId)) {
      return;
    }
    final WebUri? currentUrl = await controller.getUrl();
    if (!_isCurrentRun(runId)) {
      return;
    }
    if (!_isEnrollHost(currentUrl)) {
      _debugLog(
        'ignored stale login callback host=${currentUrl?.host ?? 'unknown'}',
      );
      return;
    }
    if (expectedUrl != null &&
        currentUrl!.path.toLowerCase() != expectedUrl.path.toLowerCase()) {
      _debugLog(
        'ignored stale login callback path=${expectedUrl.path} '
        'currentPath=${currentUrl.path}',
      );
      return;
    }

    final EnrollCertificatePageEvidence response = await _probeCurrentPage(
      controller,
    );
    if (!_isCurrentRun(runId)) {
      return;
    }
    final WebUri? verifiedUrl = await controller.getUrl();
    if (!_isCurrentRun(runId) || !_isEnrollHost(verifiedUrl)) {
      _debugLog(
        'ignored login result after host changed to '
        '${verifiedUrl?.host ?? 'unknown'}',
      );
      return;
    }

    if (response.captchaError) {
      _debugLog('login rejected: captcha');
      await _retryAutomatedLogin('驗證碼辨識錯誤，正在自動重試...');
      return;
    }
    if (response.credentialError) {
      _setError(
        app.enrollCertificate.credentialError,
        app.enrollCertificate.checkCredentials,
        fatal: true,
      );
      return;
    }
    if (response.systemError) {
      _setError(
        app.enrollCertificate.loginRejected,
        app.enrollCertificate.retryLater,
        fatal: true,
      );
      return;
    }
    if (response.hasLoginForm) {
      await _retryAutomatedLogin('登入尚未完成，正在重新嘗試...');
      return;
    }

    _setProgress(
      EnrollCertificatePhase.sessionValidating,
      '登入資料已送出・正在驗證 Session',
      '等待校方系統自然跳轉',
    );
    _armStageTimeout(_navigationTimeout, _handleNavigationTimeout);
    _scheduleNavigation(
      const Duration(milliseconds: 1200),
      () => _validateOrOpenRegistrationMain(runId),
      runId: runId,
    );
  }

  Future<EnrollCertificatePageEvidence> _probeCurrentPage(
    InAppWebViewController controller,
  ) async {
    Object? result;
    try {
      result = await controller.evaluateJavascript(
        source: '''
(function () {
  let body = document.body ? document.body.innerText : '';
  let html = document.documentElement ? document.documentElement.innerHTML : '';
  for (let index = 0; index < window.frames.length; index += 1) {
    try {
      const frameDocument = window.frames[index].document;
      body += '\\n' + (frameDocument.body ? frameDocument.body.innerText : '');
      html += '\\n' + (
        frameDocument.documentElement
          ? frameDocument.documentElement.innerHTML
          : ''
      );
    } catch (_) {}
  }
  const content = body + '\\n' + html;
  const certificatePattern = /enrollcert|在學證明|Certificate of Enrollment/i;
  return JSON.stringify({
    hasLoginForm: !!document.querySelector(
      'input[name="ValidCode"], input[name="passwdtmp"]'
    ),
    captchaError: /驗證碼[^\\n]*(?:錯|不正確|失敗)|(?:validation|verified) code[^\\n]*(?:error|incorrect|failed)/i.test(content),
    credentialError: /(?:帳號|密碼)[^\\n]*(?:錯|不正確|失敗)|(?:username|password)[^\\n]*(?:error|incorrect|failed)/i.test(content),
    systemError: /incorrect return code|無使用本系統權限|系統異常|系統錯誤|session expired|請重新登入/i.test(content),
    hasRegistrationMarker: /網路註冊|選課系統|Online Registration/i.test(content),
    hasCertificateEntry: certificatePattern.test(content)
  });
})();
''',
      );
    } catch (_) {
      return const EnrollCertificatePageEvidence.unknown();
    }
    return EnrollCertificatePageEvidence.fromJavascript(result);
  }

  Future<void> _validateRegistrationPage(int runId) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null || !_isCurrentRun(runId)) {
      return;
    }
    _setProgress(
      EnrollCertificatePhase.registrationValidating,
      'Session 已建立・正在驗證註冊頁面',
      '確認頁面內容與在學證明入口',
    );
    final EnrollCertificatePageEvidence probe = await _probeCurrentPage(
      controller,
    );
    if (!_isCurrentRun(runId)) {
      return;
    }
    final WebUri? verifiedUrl = await controller.getUrl();
    if (!_isCurrentRun(runId) || !_isRegistrationHost(verifiedUrl)) {
      _debugLog(
        'ignored registration result after host changed to '
        '${verifiedUrl?.host ?? 'unknown'}',
      );
      return;
    }
    await _logSessionCookiePresence();

    if (probe.systemError) {
      _setError(
        app.enrollCertificate.sessionRejected,
        app.enrollCertificate.retryInstruction,
        fatal: true,
      );
      return;
    }
    if (probe.hasLoginForm) {
      await _retryAutomatedLogin('Session 已失效，正在重新登入...');
      return;
    }

    final bool isValidMainPage =
        _isRegistrationMainUrl(verifiedUrl) &&
        (probe.hasRegistrationMarker || probe.hasCertificateEntry);
    if (!isValidMainPage) {
      if (_isRegistrationMainUrl(verifiedUrl)) {
        _setError(
          app.enrollCertificate.registrationPageInvalid,
          app.enrollCertificate.pageIncomplete,
        );
        return;
      }
      _scheduleNavigation(
        const Duration(milliseconds: 800),
        () => _openRegistrationMainPage(runId),
        runId: runId,
      );
      return;
    }

    _stageTimeout?.cancel();
    await _disableRegistrationAutoReload();
    if (!_isCurrentRun(runId) ||
        !_navigationTracker.beginCertificateRequest(runId)) {
      return;
    }
    _debugLog('login accepted variant=$_lastOcrVariant');
    _setProgress(
      EnrollCertificatePhase.certificateGenerating,
      '註冊頁面驗證完成・正在產生 PDF',
      '正在尋找在學證明入口',
    );
    _scheduleNavigation(
      const Duration(milliseconds: 600),
      () => _openCertificateFromPage(runId),
      runId: runId,
    );
  }

  Future<void> _validateOrOpenRegistrationMain(int runId) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null || !_isCurrentRun(runId)) {
      return;
    }
    final WebUri? url = await controller.getUrl();
    if (!_isCurrentRun(runId)) {
      return;
    }
    if (_isRegistrationHost(url)) {
      await _validateRegistrationPage(runId);
      return;
    }
    final EnrollCertificatePageEvidence probe = await _probeCurrentPage(
      controller,
    );
    if (!_isCurrentRun(runId)) {
      return;
    }
    if (probe.hasLoginForm || probe.systemError) {
      await _handleLoginResponse(runId, url);
      return;
    }
    await _openRegistrationMainPage(runId);
  }

  Future<void> _handleNavigationTimeout(int runId) async {
    if (!_isCurrentRun(runId)) {
      return;
    }
    _debugLog('navigation timeout; validating current page');
    await _validateOrOpenRegistrationMain(runId);
  }

  Future<void> _logSessionCookiePresence() async {
    if (!kDebugMode) {
      return;
    }
    try {
      final List<Cookie> cookies = await CookieManager.instance().getCookies(
        url: WebUri(EnrollCertificateService.registrationMainUri.toString()),
      );
      _debugLog('session cookie presence: ${cookies.isNotEmpty}');
    } catch (_) {
      _debugLog('session cookie presence: unavailable');
    }
  }

  Future<void> _refreshCaptcha() async {
    final InAppWebViewController? controller = _controller;
    if (controller == null ||
        _progress.phase == EnrollCertificatePhase.captchaLoading ||
        _progress.phase == EnrollCertificatePhase.captchaRecognizing ||
        _progress.phase == EnrollCertificatePhase.loginSubmitting) {
      return;
    }
    if (!_attempts.canAttemptLogin) {
      _setError(
        app.enrollCertificate.attemptsReached(count: _maxAutomationAttempts),
        app.enrollCertificate.retryInstruction,
      );
      return;
    }

    _retryGate.release();
    _hasRefreshedInitialCaptcha = true;
    final int runId = _runId;
    final int requestId = ++_captchaRequestId;
    _setProgress(
      EnrollCertificatePhase.captchaLoading,
      '嘗試 ${_attempts.currentLoginAttempt}/$_maxAutomationAttempts・正在取得驗證碼',
      '驗證碼組 ${_attempts.ocrRefreshes + 1}/$_maxOcrRefreshes',
    );
    Object? result;
    try {
      result = await controller.evaluateJavascript(
        source:
            '''
(function () {
  const image = document.getElementById('imgVC');
  const form = document.forms['f1'];
  if (!image || !form) {
    return 'not-found';
  }

  const button = form.elements['b1'];
  const nativeSubmit = HTMLFormElement.prototype.submit.bind(form);
  form.submit = function () {
    if (window.__nsysuLoginSubmitting) {
      return;
    }
    window.__nsysuLoginSubmitting = true;
    if (button) {
      button.disabled = true;
    }
    nativeSubmit();
  };

  window.__nsysuLoginSubmitting = false;
  if (button) {
    button.disabled = true;
  }

  const captchaUrl = new URL('validcode.asp', location.href);
  captchaUrl.searchParams.set('epoch', Date.now().toString());
  fetch(captchaUrl.toString(), {
    method: 'GET',
    credentials: 'same-origin',
    cache: 'no-store'
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error('HTTP ' + response.status);
      }
      const contentType = response.headers.get('content-type') || 'image/bmp';
      return response.arrayBuffer().then((buffer) => ({ buffer, contentType }));
    })
    .then(({ buffer, contentType }) => {
      const bytes = new Uint8Array(buffer);
      let binary = '';
      for (let offset = 0; offset < bytes.length; offset += 8192) {
        binary += String.fromCharCode.apply(
          null,
          bytes.subarray(offset, Math.min(offset + 8192, bytes.length))
        );
      }
      const data = btoa(binary);
      image.src = 'data:' + contentType + ';base64,' + data;
      window.flutter_inappwebview.callHandler(
        '$_captchaHandlerName',
        {
          runId: $runId,
          requestId: $requestId,
          data: data,
          contentType: contentType
        }
      );
    })
    .catch((error) => {
      window.flutter_inappwebview.callHandler(
        '$_captchaHandlerName',
        { runId: $runId, requestId: $requestId, error: String(error) }
      );
    });
  return 'fetching';
})();
''',
      );
    } catch (_) {
      await _retryAutomatedLogin('載入驗證碼時發生錯誤，正在重試...');
      return;
    }

    if (result?.toString() == 'not-found') {
      _setError(
        app.enrollCertificate.loginFormMissing,
        app.enrollCertificate.retryInstruction,
        fatal: true,
      );
    }
  }

  Future<void> _handleCaptchaPayload(List<dynamic> arguments) async {
    if (!mounted) {
      return;
    }
    if (arguments.isEmpty || arguments.first is! Map) {
      await _retryAutomatedLogin('無法讀取驗證碼，正在重試...');
      return;
    }
    final Map<dynamic, dynamic> payload =
        arguments.first as Map<dynamic, dynamic>;
    final int runId = (payload['runId'] as num?)?.toInt() ?? -1;
    final int requestId = (payload['requestId'] as num?)?.toInt() ?? -1;
    if (!_isCurrentRun(runId) || requestId != _captchaRequestId) {
      return;
    }
    final String? error = payload['error'] as String?;
    final String? encodedData = payload['data'] as String?;
    if (error != null || encodedData == null || encodedData.isEmpty) {
      await _retryAutomatedLogin('取得驗證碼失敗，正在重試...');
      return;
    }

    Directory? directory;
    try {
      final Uint8List bytes = base64Decode(encodedData);
      final List<CaptchaImageVariant> variants = _captchaPreprocessor
          .createVariants(bytes)
          .take(_maxSameImageOcrAttempts)
          .toList(growable: false);
      directory = await Directory.systemTemp.createTemp(
        'nsysu_enroll_captcha_',
      );
      String? captchaCode;
      for (int index = 0; index < variants.length; index++) {
        if (!_isCurrentRun(runId)) {
          return;
        }
        final CaptchaImageVariant variant = variants[index];
        _setProgress(
          EnrollCertificatePhase.captchaRecognizing,
          '嘗試 ${_attempts.currentLoginAttempt}/$_maxAutomationAttempts・正在辨識驗證碼',
          '影像版本 ${index + 1}/${variants.length}・正在處理強化圖片',
        );
        final File file = File('${directory.path}/captcha_${variant.name}.png');
        await file.writeAsBytes(variant.bytes, flush: true);
        final Stopwatch stopwatch = Stopwatch()..start();
        final String recognized = await _captchaOcr.recognizeTextFromImagePath(
          file.path,
        );
        stopwatch.stop();
        final String candidate = _normalizeCaptcha(recognized);
        _debugLog(
          'ocr variant=${variant.name} validLength=${candidate.length == 4} '
          'elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
        if (candidate.length == 4) {
          captchaCode = candidate;
          _lastOcrVariant = variant.name;
          break;
        }
      }
      if (captchaCode == null) {
        _attempts.recordOcrRefresh();
        _debugLog(
          'ocr group invalid refresh=${_attempts.ocrRefreshes}/$_maxOcrRefreshes',
        );
        if (!_attempts.canRefreshCaptcha) {
          _setError(
            app.enrollCertificate.captchaUnrecognized(count: _maxOcrRefreshes),
            app.enrollCertificate.retryInstruction,
          );
          return;
        }
        await _retryAutomatedLogin(
          '三種影像版本都沒有四位數結果，正在重新載入驗證碼...',
          countAsFailure: false,
        );
        return;
      }
      _attempts.recordValidCaptcha();
      await _submitLogin(captchaCode, runId);
    } catch (_) {
      await _retryAutomatedLogin('OCR 辨識失敗，正在重試...');
    } finally {
      try {
        await directory?.delete(recursive: true);
      } catch (_) {}
    }
  }

  String _normalizeCaptcha(String value) {
    final String normalized = value
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll(RegExp('[^0-9]'), '');
    return normalized;
  }

  Future<void> _submitLogin(String captchaCode, int runId) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null ||
        !_isCurrentRun(runId) ||
        _progress.phase == EnrollCertificatePhase.loginSubmitting) {
      return;
    }
    _setProgress(
      EnrollCertificatePhase.loginSubmitting,
      '嘗試 ${_attempts.currentLoginAttempt}/$_maxAutomationAttempts・正在自動登入',
      '驗證碼辨識完成，正在安全送出登入資料',
    );
    _armStageTimeout(_navigationTimeout, _handleNavigationTimeout);
    Object? result;
    try {
      result = await controller.evaluateJavascript(
        source:
            '''
(function () {
  const form = document.forms['f1'];
  if (!form) {
    return 'form-not-found';
  }
  form.elements['IDtmp'].value = ${jsonEncode(widget.username)};
  form.elements['passwdtmp'].value = ${jsonEncode(widget.password)};
  form.elements['ValidCode'].value = ${jsonEncode(captchaCode)};
  if (typeof window.f1_submit === 'function') {
    window.f1_submit();
  } else {
    form.elements['ID'].value = ${jsonEncode(widget.username)};
    form.elements['passwd'].value = ${jsonEncode(widget.password)};
    form.submit();
  }
  return 'submitted';
})();
''',
      );
    } catch (_) {
      await _retryAutomatedLogin('送出登入資料時發生錯誤，正在重試...');
      return;
    }
    if (result?.toString() == 'form-not-found') {
      _setError(
        app.enrollCertificate.loginFormMissing,
        app.enrollCertificate.retryInstruction,
        fatal: true,
      );
    }
  }

  Future<void> _retryAutomatedLogin(
    String status, {
    bool countAsFailure = true,
  }) async {
    if (!_retryGate.tryLock()) {
      _debugLog('ignored duplicate retry request status="$status"');
      return;
    }
    if (countAsFailure) {
      _attempts.recordLoginFailure();
    }
    if (!_attempts.canAttemptLogin) {
      _setError(
        app.enrollCertificate.attemptsExhausted(count: _maxAutomationAttempts),
        app.enrollCertificate.retryInstruction,
      );
      return;
    }
    final InAppWebViewController? controller = _controller;
    if (controller == null) {
      _retryGate.release();
      return;
    }
    final int runId = _runId;
    _stageTimeout?.cancel();
    _setProgress(
      EnrollCertificatePhase.captchaLoading,
      status,
      countAsFailure
          ? '準備第 ${_attempts.currentLoginAttempt}/$_maxAutomationAttempts 次嘗試'
          : '驗證碼刷新 ${_attempts.ocrRefreshes}/$_maxOcrRefreshes',
    );
    _needsCaptchaRefresh = true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!_isCurrentRun(runId) || controller != _controller) {
      return;
    }
    final Uri retryUri = EnrollCertificateService.enrollUri.replace(
      queryParameters: <String, String>{
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    try {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(retryUri.toString()),
          cachePolicy: URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
        ),
      );
    } catch (_) {
      _retryGate.release();
      _setError(
        app.enrollCertificate.loginPageReloadFailed,
        app.enrollCertificate.checkNetwork,
      );
    }
  }

  Future<void> _retryCurrentStep() async {
    final InAppWebViewController? controller = _controller;
    if (controller == null) {
      return;
    }
    _runTracker.startNewRun();
    _attempts.reset();
    _captchaRequestId++;
    _completedRunId = -1;
    _lastOcrVariant = '';
    _navigationTracker.reset();
    _retryGate.release();
    _hasRefreshedInitialCaptcha = false;
    _needsCaptchaRefresh = true;
    _showManualWebView = false;
    _pendingNavigation?.cancel();
    _stageTimeout?.cancel();
    _setProgress(EnrollCertificatePhase.preparing, '正在重新產生在學證明', '正在建立新的登入流程');
    final Uri retryUri = EnrollCertificateService.enrollUri.replace(
      queryParameters: <String, String>{
        '_': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    await controller.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(retryUri.toString()),
        cachePolicy: URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA,
      ),
    );
  }

  void _scheduleNavigation(
    Duration delay,
    Future<void> Function() navigation, {
    required int runId,
  }) {
    _pendingNavigation?.cancel();
    _pendingNavigation = Timer(delay, () {
      if (_isCurrentRun(runId)) {
        unawaited(navigation());
      }
    });
  }

  Future<void> _openRegistrationMainPage(int runId) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null || !_isCurrentRun(runId)) {
      return;
    }
    if (!_navigationTracker.beginRegistrationLoad()) {
      _setError(
        app.enrollCertificate.registrationNoResponse,
        app.enrollCertificate.checkNetwork,
      );
      return;
    }
    _setProgress(
      EnrollCertificatePhase.registrationLoading,
      'Session 驗證中・正在進入註冊主頁',
      '等待受保護頁面回應',
    );
    _armStageTimeout(_navigationTimeout, _handleNavigationTimeout);
    await controller.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(EnrollCertificateService.registrationMainUri.toString()),
      ),
    );
  }

  Future<void> _openCertificateFromPage(int runId) async {
    final InAppWebViewController? controller = _controller;
    if (controller == null || !_isCurrentRun(runId)) {
      return;
    }
    _setProgress(
      EnrollCertificatePhase.certificateGenerating,
      '正在產生在學證明 PDF',
      '正在從註冊主頁取得文件入口',
    );
    final Object? result = await controller.evaluateJavascript(
      source:
          '''
(function () {
  function sendResult(payload) {
    payload.runId = $runId;
    window.flutter_inappwebview.callHandler('$_pdfHandlerName', payload);
  }

  function bytesToBase64(bytes) {
    let binary = '';
    for (let offset = 0; offset < bytes.length; offset += 8192) {
      binary += String.fromCharCode.apply(
        null,
        bytes.subarray(offset, Math.min(offset + 8192, bytes.length))
      );
    }
    return btoa(binary);
  }

  async function fetchCertificate(target, requestOptions, depth) {
    const targetUrl = new URL(target, location.href).href;
    const targetHost = new URL(targetUrl).hostname.toLowerCase();
    if (!['selcrs.nsysu.edu.tw', 'regweb.nsysu.edu.tw'].includes(targetHost)) {
      sendResult({ error: 'Blocked certificate host', url: targetUrl });
      return;
    }
    if (depth > 8) {
      sendResult({ error: 'Too many certificate redirects', url: targetUrl });
      return;
    }

    const options = Object.assign({
      method: 'GET',
      credentials: 'include',
      cache: 'no-store'
    }, requestOptions || {});

    try {
      const response = await fetch(targetUrl, options);
      if (!response.ok) {
        throw new Error('HTTP ' + response.status);
      }
      const contentType = response.headers.get('content-type') || '';
      const responseUrl = response.url || targetUrl;
      const bytes = new Uint8Array(await response.arrayBuffer());
      const text = new TextDecoder('utf-8').decode(bytes);

      if (text.includes('%PDF-')) {
        sendResult({
          data: bytesToBase64(bytes),
          contentType: contentType,
          url: responseUrl
        });
        return;
      }

      const embeddedPdf = text.match(
        /data:application\\/pdf;base64,([A-Za-z0-9+/=\\s]+)/i
      );
      if (embeddedPdf && embeddedPdf[1]) {
        sendResult({
          data: embeddedPdf[1].replace(/\\s/g, ''),
          contentType: 'application/pdf',
          url: responseUrl
        });
        return;
      }

      const documentResult = new DOMParser().parseFromString(text, 'text/html');
      const form = documentResult.querySelector('form');
      const hasAutoSubmit =
        /\\.submit\\s*\\(|onload\\s*=/i.test(text);
      if (form && hasAutoSubmit) {
        const action = form.getAttribute('action') || responseUrl;
        const method = (form.getAttribute('method') || 'GET').toUpperCase();
        const parameters = new URLSearchParams();
        for (const input of form.querySelectorAll('input[name]')) {
          parameters.append(input.getAttribute('name'), input.value || '');
        }
        if (method === 'POST') {
          await fetchCertificate(
            new URL(action, responseUrl).href,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
              },
              body: parameters.toString()
            },
            depth + 1
          );
        } else {
          const nextUrl = new URL(action, responseUrl);
          for (const [name, value] of parameters.entries()) {
            nextUrl.searchParams.append(name, value);
          }
          await fetchCertificate(nextUrl.href, null, depth + 1);
        }
        return;
      }

      const redirectPatterns = [
        /(?:(?:window|top|parent|self)\\.)?location(?:\\.href)?\\s*=\\s*['"]([^'"]+)['"]/i,
        /(?:(?:window|top|parent|self)\\.)?location\\.replace\\(\\s*['"]([^'"]+)['"]/i,
        /window\\.open\\(\\s*['"]([^'"]+)['"]/i
      ];
      for (const pattern of redirectPatterns) {
        const match = text.match(pattern);
        if (match && match[1]) {
          await fetchCertificate(
            new URL(match[1], responseUrl).href,
            null,
            depth + 1
          );
          return;
        }
      }

      const refresh = Array.from(
        documentResult.querySelectorAll('meta[http-equiv]')
      ).find((meta) =>
        (meta.getAttribute('http-equiv') || '').toLowerCase() === 'refresh'
      );
      const refreshMatch = (refresh?.getAttribute('content') || '').match(
        /url\\s*=\\s*['"]?([^'";]+)/i
      );
      if (refreshMatch && refreshMatch[1]) {
        await fetchCertificate(
          new URL(refreshMatch[1].trim(), responseUrl).href,
          null,
          depth + 1
        );
        return;
      }

      sendResult({
        data: bytesToBase64(bytes),
        contentType: contentType,
        url: responseUrl
      });
    } catch (error) {
      sendResult({ error: String(error), url: targetUrl });
    }
  }

  function startCertificateFetch(target) {
    const targetUrl = new URL(target, location.href).href;
    fetchCertificate(targetUrl, null, 0);
    return 'fetching:' + targetUrl;
  }

  function targetFromNode(node) {
    const href = node.getAttribute('href') || '';
    if (href) {
      return href;
    }
    const onclick = node.getAttribute('onclick') || '';
    const match = onclick.match(/window\\.open\\(\\s*['"]([^'"]+)['"]/i);
    return match ? match[1] : '';
  }

  const documents = [document];
  for (let i = 0; i < window.frames.length; i += 1) {
    try {
      if (window.frames[i].document) {
        documents.push(window.frames[i].document);
      }
    } catch (_) {}
  }
  for (const doc of documents) {
    const candidates = Array.from(doc.querySelectorAll('button, a, area'));
    const link = candidates.find((node) => {
      const href = node.getAttribute('href') || '';
      const onclick = node.getAttribute('onclick') || '';
      const text = node.textContent || '';
      return /enrollcert|在學證明|Certificate of Enrollment/i.test(href + ' ' + onclick + ' ' + text);
    });
    if (link) {
      const target = targetFromNode(link);
      if (target) {
        return startCertificateFetch(target);
      }
    }
  }
  for (const doc of documents) {
    const html = doc.documentElement ? doc.documentElement.innerHTML : '';
    const match = html.match(/['"]([^'"]*(?:enrollcert|在學證明|Certificate of Enrollment)[^'"]*)['"]/i);
    if (match && match[1]) {
      return startCertificateFetch(match[1]);
    }
  }
  return 'not-found:' + location.href;
})();
''',
    );
    final String message = result?.toString() ?? '';
    if (message.startsWith('fetching:')) {
      _setProgress(
        EnrollCertificatePhase.pdfDownloading,
        '正在下載在學證明 PDF',
        '等待校方系統回傳完整文件',
      );
      _armStageTimeout(_pdfTimeout, _handlePdfTimeout);
      return;
    }
    _showManualHint();
  }

  Future<void> _handlePdfPayload(List<dynamic> arguments) async {
    if (!mounted) {
      return;
    }
    if (arguments.isEmpty || arguments.first is! Map) {
      _setError(
        app.enrollCertificate.pdfUnreadable,
        app.enrollCertificate.retryInstruction,
      );
      return;
    }
    final Map<dynamic, dynamic> payload =
        arguments.first as Map<dynamic, dynamic>;
    final int runId = (payload['runId'] as num?)?.toInt() ?? -1;
    if (!_isCurrentRun(runId) || _completedRunId == runId) {
      return;
    }
    final String? error = payload['error'] as String?;
    final String? encodedData = payload['data'] as String?;
    if (error != null || encodedData == null || encodedData.isEmpty) {
      _debugLog('pdf download failed: payload error');
      _setError(
        app.enrollCertificate.pdfDownloadFailed,
        app.enrollCertificate.retryInstruction,
      );
      return;
    }

    try {
      _setProgress(
        EnrollCertificatePhase.pdfValidating,
        'PDF 已下載・正在驗證文件',
        '確認檔案格式與完整性',
      );
      final Uint8List? pdf = EnrollCertificateCache.extractPdf(
        base64Decode(encodedData),
      );
      if (!_isCurrentRun(runId)) {
        return;
      }
      if (pdf == null) {
        _setError(
          app.enrollCertificate.pdfInvalid,
          app.enrollCertificate.documentIncomplete,
        );
        return;
      }
      _setProgress(
        EnrollCertificatePhase.saving,
        'PDF 驗證完成・正在安全儲存',
        '完成前會保留原本的在學證明',
      );
      await widget.savePdf?.call(pdf);
      if (!mounted || !_runTracker.isCurrent(runId)) {
        return;
      }
      _completedRunId = runId;
      _pendingNavigation?.cancel();
      _stageTimeout?.cancel();
      _setProgress(
        EnrollCertificatePhase.completed,
        '在學證明 PDF 下載完成',
        '正在開啟已驗證的文件',
      );
      Navigator.of(context).pop(pdf);
    } catch (_) {
      _setError(
        app.enrollCertificate.pdfProcessingFailed,
        app.enrollCertificate.retryInstruction,
      );
    }
  }

  void _showManualHint() {
    if (_showManualWebView) {
      return;
    }
    _stageTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _showManualWebView = true;
      _progress = EnrollCertificateProgress(
        phase: EnrollCertificatePhase.manual,
        primary: app.enrollCertificate.manualEntryNotFound,
        secondary: app.enrollCertificate.manualEntryInstruction,
      );
    });
  }

  Future<void> _handlePdfTimeout(int runId) async {
    if (!_isCurrentRun(runId) || _completedRunId == runId) {
      return;
    }
    _setError(
      app.enrollCertificate.pdfTimeout,
      app.enrollCertificate.pdfTimeoutDetail(seconds: 30),
    );
  }

  bool get _isErrorPhase => _progress.shouldOfferRetry;

  EnrollCertificateProgress get _displayProgress {
    if (_isErrorPhase) {
      return EnrollCertificateProgress(
        phase: _progress.phase,
        primary: _progress.primary,
      );
    }
    return EnrollCertificateProgress(
      phase: _progress.phase,
      primary: app.enrollCertificate.attemptProgress(
        current: _attempts.currentLoginAttempt,
        total: _maxAutomationAttempts,
      ),
      secondary: app.enrollCertificate.mayTakeUpToSeconds(seconds: 20),
    );
  }

  int get _runId => _runTracker.current;

  bool _isCurrentRun(int runId) => mounted && _runTracker.isCurrent(runId);

  void _setProgress(
    EnrollCertificatePhase phase,
    String primary, [
    String secondary = '',
  ]) {
    if (!mounted) return;
    _debugLog('phase=${phase.name} primary="$primary" secondary="$secondary"');
    if (_showManualWebView && phase != EnrollCertificatePhase.manual) {
      return;
    }
    setState(() {
      _progress = EnrollCertificateProgress(
        phase: phase,
        primary: primary,
        secondary: secondary,
      );
    });
  }

  void _setError(String primary, String secondary, {bool fatal = false}) {
    _pendingNavigation?.cancel();
    _stageTimeout?.cancel();
    _setProgress(
      fatal
          ? EnrollCertificatePhase.fatalError
          : EnrollCertificatePhase.recoverableError,
      primary,
      secondary,
    );
  }

  void _armStageTimeout(
    Duration duration,
    Future<void> Function(int runId) handler,
  ) {
    final int runId = _runId;
    _stageTimeout?.cancel();
    _stageTimeout = Timer(duration, () {
      if (_isCurrentRun(runId)) {
        unawaited(handler(runId));
      }
    });
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[EnrollCertificate][run=$_runId] $message');
    }
  }
}
