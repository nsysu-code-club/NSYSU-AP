import 'package:ap_common/ap_common.dart'
    hide LocaleSettings, AppLocale, AppLocaleUtils, TranslationProvider;
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class _FirebaseCrashReporter implements CrashReporter {
  const _FirebaseCrashReporter();

  @override
  void recordError(Object error, StackTrace stack, {String? reason}) {
    if (!FirebaseCrashlyticsUtils.isSupported) return;
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }

  @override
  void setCustomKey(String key, Object value) {
    if (!FirebaseCrashlyticsUtils.isSupported) return;
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}

class _FirebaseAnalyticsLogger implements AnalyticsLogger {
  const _FirebaseAnalyticsLogger();

  @override
  void logTimeEvent(String name, double seconds) {
    AnalyticsUtil.instance.logTimeEvent(name, seconds);
  }
}

String _resolveLanguageCode() =>
    LocaleSettings.currentLocale == AppLocale.zhHantTw ? 'zh' : 'en';

void bootstrapCrawler() {
  SelcrsHelper.instance
    ..crashReporter = const _FirebaseCrashReporter()
    ..analyticsLogger = const _FirebaseAnalyticsLogger()
    ..languageProvider = _resolveLanguageCode;
}
