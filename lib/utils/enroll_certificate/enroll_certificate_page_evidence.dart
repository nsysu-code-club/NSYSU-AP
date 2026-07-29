import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class EnrollCertificatePageEvidence {
  const EnrollCertificatePageEvidence({
    required this.hasLoginForm,
    required this.captchaError,
    required this.credentialError,
    required this.systemError,
    required this.hasRegistrationMarker,
    required this.hasCertificateEntry,
  });

  const EnrollCertificatePageEvidence.unknown()
    : hasLoginForm = false,
      captchaError = false,
      credentialError = false,
      systemError = false,
      hasRegistrationMarker = false,
      hasCertificateEntry = false;

  factory EnrollCertificatePageEvidence.fromHtml(String html) {
    final dom.Document document = html_parser.parse(html);
    final String content = '${document.body?.text ?? ''}\n$html';
    return EnrollCertificatePageEvidence(
      hasLoginForm:
          document.querySelector(
            'input[name="ValidCode"], input[name="passwdtmp"]',
          ) !=
          null,
      captchaError: RegExp(
        r'驗證碼[^\n]*(?:錯|不正確|失敗)|'
        r'(?:validation|verified) code[^\n]*(?:error|incorrect|failed)',
        caseSensitive: false,
      ).hasMatch(content),
      credentialError: RegExp(
        r'(?:帳號|密碼)[^\n]*(?:錯|不正確|失敗)|'
        r'(?:username|password)[^\n]*(?:error|incorrect|failed)',
        caseSensitive: false,
      ).hasMatch(content),
      systemError: RegExp(
        'incorrect return code|無使用本系統權限|系統異常|系統錯誤|'
        'session expired|請重新登入',
        caseSensitive: false,
      ).hasMatch(content),
      hasRegistrationMarker: RegExp(
        '網路註冊|選課系統|Online Registration',
        caseSensitive: false,
      ).hasMatch(content),
      hasCertificateEntry: RegExp(
        'enrollcert|在學證明|Certificate of Enrollment',
        caseSensitive: false,
      ).hasMatch(content),
    );
  }

  factory EnrollCertificatePageEvidence.fromJavascript(Object? result) {
    try {
      Object? decoded = jsonDecode(result?.toString() ?? '');
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map<String, dynamic>) {
        return EnrollCertificatePageEvidence(
          hasLoginForm: decoded['hasLoginForm'] == true,
          captchaError: decoded['captchaError'] == true,
          credentialError: decoded['credentialError'] == true,
          systemError: decoded['systemError'] == true,
          hasRegistrationMarker: decoded['hasRegistrationMarker'] == true,
          hasCertificateEntry: decoded['hasCertificateEntry'] == true,
        );
      }
    } catch (_) {}
    return const EnrollCertificatePageEvidence.unknown();
  }

  final bool hasLoginForm;
  final bool captchaError;
  final bool credentialError;
  final bool systemError;
  final bool hasRegistrationMarker;
  final bool hasCertificateEntry;
}
