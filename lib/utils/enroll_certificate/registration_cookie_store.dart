import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

/// Serializes native cookie writes and cleanup across registration pages.
class RegistrationCookieStore {
  static Future<void>? _pending;
  static final Set<String> paths = <String>{'/', '/webreg', '/webreg/'};

  static Future<T> run<T>(Future<T> Function() action) {
    final Future<T> result = _pending == null
        ? Future<T>.sync(action)
        : _pending!.then((_) => action());
    final Future<void> settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending = settled;
    settled.then((_) {
      if (identical(_pending, settled)) _pending = null;
    });
    return result;
  }

  /// Removes only RegWeb cookies; leaves unrelated school services untouched.
  /// Run after WebViews stop and outstanding cookie writes have completed.
  static Future<void> clear({
    CookieManager? manager,
    Future<void> Function()? beforeClear,
  }) => run(() async {
    await beforeClear?.call();
    final CookieManager cookies;
    try {
      cookies = manager ?? CookieManager.instance();
    } catch (_) {
      return; // Native cookie storage is unavailable on this platform.
    }
    for (final String path in Set<String>.of(paths)) {
      try {
        await cookies.deleteCookies(
          url: WebUri.uri(EnrollmentCertificateHelper.registrationSessionUri),
          path: path,
        );
      } catch (_) {
        // Attempt every path even if one native deletion fails. Never log
        // cookie values or platform errors containing authenticated data.
      }
    }
  });
}
