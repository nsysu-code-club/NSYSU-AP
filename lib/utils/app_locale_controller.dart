import 'dart:developer' as developer;

import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_flutter_core/ap_common_flutter_core.dart' as ap_l10n;
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

/// Applies language changes in order and owns the Analytics language property.
class AppLocaleController {
  AppLocaleController({
    PreferenceUtil? preferences,
    AnalyticsUtil? analytics,
    List<Locale> Function()? deviceLocales,
    Future<Locale> Function(Locale)? applyLocale,
    void Function(Object, StackTrace)? onError,
  }) : _preferences = preferences ?? PreferenceUtil.instance,
       _analytics = analytics ?? AnalyticsUtil.instance,
       _deviceLocales =
           deviceLocales ??
           (() => WidgetsBinding.instance.platformDispatcher.locales),
       _applyLocale = applyLocale ?? applyAppLocale,
       _onError = onError ?? _reportError;

  final PreferenceUtil _preferences;
  final AnalyticsUtil _analytics;
  final List<Locale> Function() _deviceLocales;
  final Future<Locale> Function(Locale) _applyLocale;
  final void Function(Object, StackTrace) _onError;

  Future<void> _pending = Future<void>.value();
  String _preferenceCode = ApSupportLanguageConstants.system;
  Locale? _locale;
  int _selectionRevision = 0;

  String get preferenceCode => _preferenceCode;

  Locale? get locale => _locale;

  Future<void> initialize() {
    final String code = _readPreferenceCode();
    _preferenceCode = code;
    _selectionRevision++;
    return _enqueue(() => _apply(_resolveLocale(code, _deviceLocales())));
  }

  String _readPreferenceCode() {
    final String savedCode = _preferences.getString(
      Constants.prefLanguageCode,
      ApSupportLanguageConstants.system,
    );
    return _isSupportedCode(savedCode)
        ? savedCode
        : ApSupportLanguageConstants.system;
  }

  Future<void> selectLanguage(String code) {
    if (!_isSupportedCode(code)) {
      throw ArgumentError.value(
        code,
        'code',
        'Unsupported language preference',
      );
    }
    // Record the request before awaiting so device events cannot override it.
    _preferenceCode = code;
    final int revision = ++_selectionRevision;
    return _enqueue(() async {
      try {
        await _preferences.setString(Constants.prefLanguageCode, code);
        if (_preferences.getString(Constants.prefLanguageCode, '') != code) {
          throw StateError('Could not persist language preference');
        }
      } catch (_) {
        if (revision == _selectionRevision) {
          _preferenceCode = _readPreferenceCode();
        }
        rethrow;
      }
      // Once persisted, retain the requested mode if translation loading fails
      // so retry and restart both use the same preference.
      await _apply(_resolveLocale(code, _deviceLocales()));
    });
  }

  Future<void> handleDeviceLocalesChanged(List<Locale>? locales) {
    if (_preferenceCode != ApSupportLanguageConstants.system ||
        locales == null) {
      return Future<void>.value();
    }
    final int revision = _selectionRevision;
    final Locale locale = _resolveLocale(
      ApSupportLanguageConstants.system,
      locales,
    );
    return _enqueue(() async {
      if (_preferenceCode != ApSupportLanguageConstants.system ||
          revision != _selectionRevision) {
        return;
      }
      await _apply(locale);
    });
  }

  Future<void> _apply(Locale requestedLocale) async {
    final Locale resolvedLocale = await _applyLocale(requestedLocale);
    _locale = resolvedLocale;
    try {
      await _analytics.setUserProperty(
        AnalyticsConstants.language,
        resolvedLocale.languageCode,
      );
    } catch (error, stackTrace) {
      // Telemetry failure must not prevent startup or a language change.
      _onError(error, stackTrace);
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final Future<void> operation = _pending.then((_) => action());
    // The caller receives this operation's error; later selections can retry.
    _pending = operation.catchError((Object _, StackTrace _) {});
    return operation;
  }

  static bool _isSupportedCode(String code) => ApSupportLanguage.values.any(
    (ApSupportLanguage language) => language.code == code,
  );

  static Locale _resolveLocale(String code, List<Locale> deviceLocales) {
    if (code == ApSupportLanguageConstants.system) {
      return deviceLocales.firstWhere(
        (Locale locale) => ap_l10n.AppLocale.values.any(
          (ap_l10n.AppLocale supported) =>
              supported.languageCode == locale.languageCode,
        ),
        orElse: () =>
            deviceLocales.isEmpty ? const Locale('en') : deviceLocales.first,
      );
    }
    return Locale(code, code == ApSupportLanguageConstants.zh ? 'TW' : null);
  }

  /// Keeps both translation packages ready before exposing the selected locale.
  static Future<Locale> applyAppLocale(Locale locale) async {
    final ap_l10n.AppLocale commonLocale = await ap_l10n.setApLocaleFromFlutter(
      locale,
    );
    final AppLocale appLocale = AppLocaleUtils.instance.parseLocaleParts(
      languageCode: locale.languageCode,
      scriptCode: locale.scriptCode,
      countryCode: locale.countryCode,
    );
    // Both setters disable device listeners by default; the app owns updates.
    await LocaleSettings.setLocale(appLocale);
    // Slang shares global state across packages. Preserve the resolved common
    // locale here, including Japanese when the app translations fall back.
    return commonLocale.flutterLocale;
  }

  static void _reportError(Object error, StackTrace stackTrace) {
    developer.log(
      'Unable to update the language user property',
      name: 'AppLocaleController',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
