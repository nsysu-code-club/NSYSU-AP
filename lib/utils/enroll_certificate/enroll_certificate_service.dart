import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:nsysu_ap/utils/captcha_ocr/captcha_ocr.dart';

class EnrollCertificateService {
  EnrollCertificateService({Dio? dio, CaptchaOcr? captchaOcr})
    : _dio = dio ?? Dio(),
      _captchaOcr = captchaOcr ?? CaptchaOcr() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final Uri enrollUri = Uri.parse(
    'https://selcrs.nsysu.edu.tw/stu_enroll/',
  );
  static final Uri certificateUri = Uri.parse(
    'https://regweb.nsysu.edu.tw/webreg/WRegMain3.asp?act=71&out=print/enrollcert.asp',
  );
  static final Uri registrationMainUri = Uri.parse(
    'https://regweb.nsysu.edu.tw/webreg/WRegMain3.asp?act=11',
  );

  final Dio _dio;
  final CookieJar _cookieJar = CookieJar();
  final CaptchaOcr _captchaOcr;
  String _lastLoginHtml = '';

  String get lastLoginHtml => _lastLoginHtml;

  Future<List<Cookie>> loadCookiesFor(Uri uri) =>
      _cookieJar.loadForRequest(uri);

  Map<String, String> buildLoginFormData({
    required String username,
    required String password,
    required String captchaCode,
    String html = '',
  }) {
    final String normalizedUsername = username
        .replaceAll(' ', '')
        .toUpperCase();
    final Map<String, String> formData = _extractLoginFormData(html);
    formData.addAll(<String, String>{
      'IDtmp': normalizedUsername,
      'passwdtmp': password,
      'ID': normalizedUsername,
      'passwd': password,
      'ValidCode': captchaCode,
    });
    return formData;
  }

  Uri resolveLoginAction(String html) {
    final html_dom.Element? form = html_parser
        .parse(html)
        .querySelector('form[name="f1"], form');
    final String? action = form?.attributes['action']?.trim();
    if (action == null || action.isEmpty) {
      return enrollUri.resolve('stu_enroll_loginchk.asp');
    }
    return enrollUri.resolve(action);
  }

  Future<EnrollCaptcha> loadCaptcha({bool recognize = true}) async {
    final Response<Uint8List> pageResponse = await _dio.get<Uint8List>(
      enrollUri.toString(),
      options: _bytesOption(),
    );
    final String html = _decode(pageResponse.data);
    _lastLoginHtml = html;
    final Uri captchaUri = _resolveCaptchaUri(html);
    final Response<Uint8List> captchaResponse = await _dio.get<Uint8List>(
      captchaUri.toString(),
      options: _bytesOption(),
    );

    final EnrollCaptcha captcha = EnrollCaptcha(
      bytes: captchaResponse.data ?? Uint8List(0),
      uri: captchaUri,
      contentType: _headerValue(
        captchaResponse.headers,
        HttpHeaders.contentTypeHeader,
      ),
    );

    if (!recognize) {
      return captcha;
    }

    File? file;
    try {
      file = await captcha.writeToTemporaryFile();
      final String recognizedText = await _captchaOcr
          .recognizeTextFromImagePath(file.path);
      return captcha.copyWith(
        recognizedText: _normalizeCaptcha(recognizedText),
      );
    } finally {
      try {
        await file?.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<Uint8List> loginAndDownloadCertificate({
    required String username,
    required String password,
    required String captchaCode,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('正在登入網路註冊系統...');
    final _HtmlNavigationResult loginResult = await _postLogin(
      username: username,
      password: password,
      captchaCode: captchaCode,
      onProgress: onProgress,
    );

    onProgress?.call('登入成功，正在進入網路註冊系統...');
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final _HtmlNavigationResult mainResult = await _getRegistrationMainPage(
      loginResult.uri,
      onProgress: onProgress,
    );

    onProgress?.call('正在取得在學證明 PDF...');
    final Uri resolvedCertificateUri =
        _findCertificateUri(_decode(mainResult.data), mainResult.uri) ??
        certificateUri;
    final Uint8List data = await _getFollowingHtmlRedirects(
      resolvedCertificateUri,
      referer: mainResult.uri,
      onProgress: onProgress,
    );
    final Uint8List? pdf = _extractPdfBytes(data);
    if (pdf != null) {
      return pdf;
    }

    final String text = _decode(data);
    if (text.contains('重新登入') || text.contains('失敗')) {
      throw EnrollCertificateException(_extractServerMessage(text));
    }
    throw EnrollCertificateException(
      '取得的內容不是 PDF：${_extractServerMessage(text)}'
      '（PDF header=${_indexOfBytes(data, _pdfHeader)}, '
      'EOF=${_lastIndexOfBytes(data, _pdfEof)}）',
    );
  }

  Future<_HtmlNavigationResult> _postLogin({
    required String username,
    required String password,
    required String captchaCode,
    void Function(String message)? onProgress,
  }) async {
    final String html = _lastLoginHtml;
    final Uri loginAction = resolveLoginAction(html);
    final Response<Uint8List> response = await _dio.post<Uint8List>(
      loginAction.toString(),
      data: buildLoginFormData(
        username: username,
        password: password,
        captchaCode: captchaCode,
        html: html,
      ),
      options: _bytesOption(
        contentType: Headers.formUrlEncodedContentType,
        headers: _browserHeaders(referer: enrollUri),
      ),
    );

    final _HtmlNavigationResult loginResult = await _followLoginHtmlRedirects(
      response,
      referer: enrollUri,
      onProgress: onProgress,
    );
    _throwIfLoginFailed(loginResult.data);

    final String text = _decode(response.data);
    if (text.contains('驗證碼') && text.contains('錯')) {
      throw const EnrollCertificateException('驗證碼錯誤，請重新載入後再試');
    }
    if (text.contains('密碼') && text.contains('錯')) {
      throw const EnrollCertificateException('帳號或密碼錯誤');
    }
    if (text.contains('alert(')) {
      throw EnrollCertificateException(_extractServerMessage(text));
    }
    return loginResult;
  }

  Future<_HtmlNavigationResult> _getRegistrationMainPage(
    Uri referer, {
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('正在載入網路註冊主頁...');
    final Uint8List data = await _getFollowingHtmlRedirects(
      registrationMainUri,
      referer: referer,
      onProgress: onProgress,
    );
    final String text = _decode(data);
    if (text.contains('incorrect return code') ||
        text.contains('您無使用本系統權限') ||
        text.contains('重新登入')) {
      throw EnrollCertificateException(_extractServerMessage(text));
    }
    if (!text.contains('網路註冊') && !text.contains('Online Registration')) {
      throw EnrollCertificateException(
        '尚未進入網路註冊主頁：${_extractServerMessage(text)}',
      );
    }
    return _HtmlNavigationResult(uri: registrationMainUri, data: data);
  }

  Future<_HtmlNavigationResult> _followLoginHtmlRedirects(
    Response<Uint8List> response, {
    required Uri referer,
    void Function(String message)? onProgress,
  }) async {
    Uri currentUri = response.realUri;
    Uri currentReferer = referer;
    Uint8List data = response.data ?? Uint8List(0);
    Uri? nextUri = _findHtmlRedirectUri(_decode(data), currentUri);
    for (int i = 0; i < 8 && nextUri != null; i++) {
      onProgress?.call('等待登入跳轉到 ${nextUri.host}...');
      final Response<Uint8List> nextResponse = await _dio.get<Uint8List>(
        nextUri.toString(),
        options: _bytesOption(
          headers: <String, String>{
            HttpHeaders.refererHeader: currentReferer.toString(),
          },
        ),
      );
      data = nextResponse.data ?? Uint8List(0);
      currentReferer = currentUri;
      currentUri = nextResponse.realUri;
      nextUri = _findHtmlRedirectUri(_decode(data), currentUri);
    }
    return _HtmlNavigationResult(uri: currentUri, data: data);
  }

  Future<Uint8List> _getFollowingHtmlRedirects(
    Uri uri, {
    required Uri referer,
    void Function(String message)? onProgress,
  }) async {
    Uri currentUri = uri;
    Uri currentReferer = referer;
    Uint8List data = Uint8List(0);

    for (int i = 0; i < 8; i++) {
      final Response<Uint8List> response = await _dio.get<Uint8List>(
        currentUri.toString(),
        options: _bytesOption(
          headers: <String, String>{
            HttpHeaders.refererHeader: currentReferer.toString(),
          },
        ),
      );
      data = response.data ?? Uint8List(0);
      final Uint8List? pdf = _extractPdfBytes(data);
      if (pdf != null) {
        return pdf;
      }

      final String text = _decode(data);
      final Uri? nextUri = _findHtmlRedirectUri(text, response.realUri);
      if (nextUri == null) {
        return data;
      }

      onProgress?.call('等待跳轉到 ${nextUri.host}...');
      currentReferer = response.realUri;
      currentUri = nextUri;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return data;
  }

  Uri _resolveCaptchaUri(String html) {
    final String? src = html_parser
        .parse(html)
        .querySelector('img#imgVC')
        ?.attributes['src'];
    if (src == null || src.isEmpty) {
      throw const EnrollCertificateException('找不到驗證碼圖片');
    }
    return enrollUri.resolve(src);
  }

  Map<String, String> _extractLoginFormData(String html) {
    final Map<String, String> formData = <String, String>{};
    final html_dom.Element? form = html_parser
        .parse(html)
        .querySelector('form[name="f1"], form');
    if (form == null) {
      return formData;
    }
    for (final html_dom.Element input in form.querySelectorAll('input')) {
      final String? name = input.attributes['name']?.trim();
      if (name == null || name.isEmpty) {
        continue;
      }
      formData[name] = input.attributes['value'] ?? '';
    }
    return formData;
  }

  Uri? _findCertificateUri(String html, Uri baseUri) {
    final html_dom.Document document = html_parser.parse(html);
    for (final html_dom.Element anchor in document.querySelectorAll('a')) {
      final String href = anchor.attributes['href'] ?? '';
      final String text = anchor.text;
      if (href.isNotEmpty &&
          (_looksLikeCertificateLink(href) ||
              _looksLikeCertificateLink(text))) {
        return baseUri.resolve(href);
      }
    }
    for (final html_dom.Element button in document.querySelectorAll('button')) {
      final String onclick = button.attributes['onclick'] ?? '';
      final String text = button.text;
      if (!_looksLikeCertificateLink(onclick) &&
          !_looksLikeCertificateLink(text)) {
        continue;
      }
      final Uri? uri = _extractWindowOpenUri(onclick, baseUri);
      if (uri != null) {
        return uri;
      }
    }

    final Match? match = RegExp(
      '''['"]([^'"]*(?:enrollcert|在學證明|Certificate of Enrollment)[^'"]*)['"]''',
      caseSensitive: false,
    ).firstMatch(html);
    final String? value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return baseUri.resolve(value);
  }

  bool _looksLikeCertificateLink(String value) {
    final String normalized = value.toLowerCase();
    return normalized.contains('enrollcert') ||
        normalized.contains('certificate of enrollment') ||
        value.contains('在學證明');
  }

  Uri? _extractWindowOpenUri(String javascript, Uri baseUri) {
    final String? value = RegExp(
      r'''window\.open\(\s*['"]([^'"]+)['"]''',
      caseSensitive: false,
    ).firstMatch(javascript)?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return baseUri.resolve(value);
  }

  Options _bytesOption({
    String? contentType,
    Map<String, String>? headers,
    bool followRedirects = true,
  }) {
    return Options(
      responseType: ResponseType.bytes,
      contentType: contentType,
      headers: headers,
      followRedirects: followRedirects,
      maxRedirects: 8,
    );
  }

  Map<String, String> _browserHeaders({required Uri referer}) {
    return <String, String>{
      HttpHeaders.acceptHeader:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      HttpHeaders.acceptLanguageHeader: 'zh-TW,zh;q=0.9,en;q=0.8',
      HttpHeaders.cacheControlHeader: 'no-cache',
      HttpHeaders.refererHeader: referer.toString(),
      'Origin': '${referer.scheme}://${referer.host}',
      'Pragma': 'no-cache',
      'Upgrade-Insecure-Requests': '1',
      HttpHeaders.userAgentHeader:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 '
          'Mobile/15E148 Safari/604.1',
    };
  }

  String _decode(Uint8List? data) {
    if (data == null || data.isEmpty) {
      return '';
    }
    return const Utf8Decoder(allowMalformed: true).convert(data);
  }

  String _headerValue(Headers headers, String name) {
    return headers.value(name) ?? '';
  }

  Uint8List? _extractPdfBytes(Uint8List bytes) {
    final int start = _indexOfBytes(bytes, _pdfHeader);
    if (start < 0) {
      return null;
    }

    final int eofStart = _lastIndexOfBytes(bytes, _pdfEof);
    if (eofStart < start) {
      return bytes.sublist(start);
    }

    return bytes.sublist(start, eofStart + _pdfEof.length);
  }

  String _normalizeCaptcha(String text) {
    final String normalized = text
        .replaceAll(RegExp('[^0-9A-Za-z]'), '')
        .trim();
    if (normalized.length <= 4) {
      return normalized;
    }
    return normalized.substring(0, 4);
  }

  String _extractServerMessage(String text) {
    final String bodyText = html_parser.parse(text).body?.text ?? text;
    final String alertText =
        RegExp(
          r'''alert\(['"](.+?)['"]\)''',
          multiLine: true,
        ).firstMatch(text)?.group(1) ??
        bodyText;
    final String normalized = alertText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '伺服器沒有回傳 PDF';
    }
    if (normalized.length <= 120) {
      return normalized;
    }
    return '${normalized.substring(0, 120)}...';
  }

  void _throwIfLoginFailed(Uint8List data) {
    final String text = _decode(data);
    if (text.contains('驗證碼') && text.contains('錯')) {
      throw const EnrollCertificateException('驗證碼錯誤，請重新載入後再試');
    }
    if (text.contains('密碼') && text.contains('錯')) {
      throw const EnrollCertificateException('帳號或密碼錯誤');
    }
    if (text.contains('重新登入') || text.contains('請重新登')) {
      throw EnrollCertificateException(_extractServerMessage(text));
    }
    if (text.contains('alert(')) {
      throw EnrollCertificateException(_extractServerMessage(text));
    }
  }

  Uri? _findHtmlRedirectUri(String html, Uri baseUri) {
    final Uri? locationHref = _matchRedirectUri(
      html,
      RegExp(
        r'''(?:(?:window|top|parent|self)\.)?location(?:\.href)?\s*=\s*['"]([^'"]+)['"]''',
        caseSensitive: false,
      ),
      baseUri,
    );
    if (locationHref != null) {
      return locationHref;
    }

    final Uri? locationReplace = _matchRedirectUri(
      html,
      RegExp(
        r'''(?:(?:window|top|parent|self)\.)?location\.replace\(\s*['"]([^'"]+)['"]\s*\)''',
        caseSensitive: false,
      ),
      baseUri,
    );
    if (locationReplace != null) {
      return locationReplace;
    }

    final Uri? windowOpen = _matchRedirectUri(
      html,
      RegExp(r'''window\.open\(\s*['"]([^'"]+)['"]''', caseSensitive: false),
      baseUri,
    );
    if (windowOpen != null) {
      return windowOpen;
    }

    final Uri? autoSubmitAction = _findAutoSubmitFormAction(html, baseUri);
    if (autoSubmitAction != null) {
      return autoSubmitAction;
    }

    final String? refreshContent = html_parser
        .parse(html)
        .querySelector('meta[http-equiv="refresh"]')
        ?.attributes['content'];
    if (refreshContent == null) {
      return null;
    }
    final Match? refreshMatch = RegExp(
      r'''url\s*=\s*['"]?([^'";]+)''',
      caseSensitive: false,
    ).firstMatch(refreshContent);
    final String? value = refreshMatch?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return baseUri.resolve(value);
  }

  Uri? _findAutoSubmitFormAction(String html, Uri baseUri) {
    final html_dom.Document document = html_parser.parse(html);
    final List<html_dom.Element> forms = document.querySelectorAll('form');
    if (forms.isEmpty) {
      return null;
    }
    final bool hasAutoSubmit =
        RegExp(r'''\.submit\(\)''', caseSensitive: false).hasMatch(html) ||
        RegExp(r'''onload\s*=''', caseSensitive: false).hasMatch(html);
    if (!hasAutoSubmit) {
      return null;
    }

    for (final html_dom.Element form in forms) {
      final String? action = form.attributes['action']?.trim();
      if (action != null && action.isNotEmpty) {
        return baseUri.resolve(action);
      }
    }
    return null;
  }

  Uri? _matchRedirectUri(String html, RegExp pattern, Uri baseUri) {
    final String? value = pattern.firstMatch(html)?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return baseUri.resolve(value);
  }

  int _indexOfBytes(Uint8List source, List<int> pattern) {
    if (pattern.isEmpty || source.length < pattern.length) {
      return -1;
    }
    for (int i = 0; i <= source.length - pattern.length; i++) {
      if (_matchesAt(source, pattern, i)) {
        return i;
      }
    }
    return -1;
  }

  int _lastIndexOfBytes(Uint8List source, List<int> pattern) {
    if (pattern.isEmpty || source.length < pattern.length) {
      return -1;
    }
    for (int i = source.length - pattern.length; i >= 0; i--) {
      if (_matchesAt(source, pattern, i)) {
        return i;
      }
    }
    return -1;
  }

  bool _matchesAt(Uint8List source, List<int> pattern, int offset) {
    for (int i = 0; i < pattern.length; i++) {
      if (source[offset + i] != pattern[i]) {
        return false;
      }
    }
    return true;
  }
}

const List<int> _pdfHeader = <int>[0x25, 0x50, 0x44, 0x46, 0x2d];
const List<int> _pdfEof = <int>[0x25, 0x25, 0x45, 0x4f, 0x46];

class EnrollCaptcha {
  const EnrollCaptcha({
    required this.bytes,
    required this.uri,
    this.contentType = '',
    this.recognizedText = '',
  });

  final Uint8List bytes;
  final Uri uri;
  final String contentType;
  final String recognizedText;

  EnrollCaptcha copyWith({String? recognizedText}) {
    return EnrollCaptcha(
      bytes: bytes,
      uri: uri,
      contentType: contentType,
      recognizedText: recognizedText ?? this.recognizedText,
    );
  }

  Future<File> writeToTemporaryFile() async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'nsysu_enroll_cert_',
    );
    final File file = File('${directory.path}/captcha.$fileExtension');
    return file.writeAsBytes(bytes, flush: true);
  }

  String get fileExtension {
    final String normalizedContentType = contentType.toLowerCase();
    if (normalizedContentType.contains('bmp') || _looksLikeBitmap) {
      return 'bmp';
    }
    if (normalizedContentType.contains('png')) {
      return 'png';
    }
    if (normalizedContentType.contains('jpeg') ||
        normalizedContentType.contains('jpg')) {
      return 'jpg';
    }
    return 'img';
  }

  bool get _looksLikeBitmap =>
      bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4d;
}

class EnrollCertificateException implements Exception {
  const EnrollCertificateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _HtmlNavigationResult {
  const _HtmlNavigationResult({required this.uri, required this.data});

  final Uri uri;
  final Uint8List data;
}
