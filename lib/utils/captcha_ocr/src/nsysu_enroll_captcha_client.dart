import 'dart:io';
import 'dart:typed_data';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class NsysuEnrollCaptchaClient {
  NsysuEnrollCaptchaClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final Uri enrollUri = Uri.parse(
    'https://selcrs.nsysu.edu.tw/stu_enroll/',
  );

  final http.Client _httpClient;

  Future<NsysuEnrollCaptchaImage> fetchCaptcha() async {
    final http.Response pageResponse = await _httpClient.get(enrollUri);
    if (pageResponse.statusCode < 200 || pageResponse.statusCode >= 300) {
      throw HttpException(
        'Failed to load enroll page: ${pageResponse.statusCode}',
        uri: enrollUri,
      );
    }

    final Uri captchaUri = _resolveCaptchaUri(pageResponse.body);
    final Map<String, String> headers = <String, String>{};
    final String cookieHeader = _buildCookieHeader(pageResponse);
    if (cookieHeader.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] = cookieHeader;
    }

    final http.Response captchaResponse = await _httpClient.get(
      captchaUri,
      headers: headers,
    );
    if (captchaResponse.statusCode < 200 || captchaResponse.statusCode >= 300) {
      throw HttpException(
        'Failed to load captcha image: ${captchaResponse.statusCode}',
        uri: captchaUri,
      );
    }

    return NsysuEnrollCaptchaImage(
      bytes: captchaResponse.bodyBytes,
      imageUri: captchaUri,
      cookieHeader: cookieHeader,
      contentType: captchaResponse.headers[HttpHeaders.contentTypeHeader],
    );
  }

  void close() {
    _httpClient.close();
  }

  Uri _resolveCaptchaUri(String html) {
    final String? src = html_parser
        .parse(html)
        .querySelector('img#imgVC')
        ?.attributes['src'];
    if (src == null || src.isEmpty) {
      throw const FormatException('Cannot find enroll captcha image.');
    }
    return enrollUri.resolve(src);
  }

  String _buildCookieHeader(http.Response response) {
    final String? setCookie = response.headers[HttpHeaders.setCookieHeader];
    if (setCookie == null || setCookie.isEmpty) {
      return '';
    }

    return setCookie
        .split(',')
        .map((String cookie) => cookie.split(';').first.trim())
        .where((String cookie) => cookie.isNotEmpty)
        .join('; ');
  }
}

class NsysuEnrollCaptchaImage {
  const NsysuEnrollCaptchaImage({
    required this.bytes,
    required this.imageUri,
    required this.cookieHeader,
    this.contentType,
  });

  final Uint8List bytes;
  final Uri imageUri;
  final String cookieHeader;
  final String? contentType;

  Future<File> writeToTemporaryFile() async {
    final Directory directory = await Directory.systemTemp.createTemp(
      'nsysu_captcha_ocr_',
    );
    final File file = File('${directory.path}/captcha.$fileExtension');
    return file.writeAsBytes(bytes, flush: true);
  }

  String get fileExtension {
    final String normalizedContentType = contentType?.toLowerCase() ?? '';
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
