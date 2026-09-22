import 'dart:async';

import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_flutter_core/ap_common_flutter_core.dart' as ap_l10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_locale_controller.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'initialization waits for locale application and the language property',
    () async {
      final _MemoryPreferences preferences = _MemoryPreferences('zh');
      final Completer<void> applyStarted = Completer<void>();
      final Completer<Locale> applied = Completer<Locale>();
      final Completer<void> analyticsStarted = Completer<void>();
      final Completer<void> analyticsFinished = Completer<void>();
      final _RecordingAnalytics analytics = _RecordingAnalytics(
        onSetProperty: (_) {
          analyticsStarted.complete();
          return analyticsFinished.future;
        },
      );
      final AppLocaleController controller = AppLocaleController(
        preferences: preferences,
        analytics: analytics,
        deviceLocales: () => <Locale>[const Locale('en', 'US')],
        applyLocale: (Locale locale) {
          expect(locale, const Locale('zh', 'TW'));
          applyStarted.complete();
          return applied.future;
        },
      );
      bool initialized = false;
      final Future<void> initialization = controller.initialize().then((_) {
        initialized = true;
      });

      await applyStarted.future;
      expect(analytics.values, isEmpty);
      expect(initialized, isFalse);
      applied.complete(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
      await analyticsStarted.future;
      expect(analytics.values, <String>['zh']);
      expect(analytics.names, <String>[AnalyticsConstants.language]);
      expect(initialized, isFalse);
      analyticsFinished.complete();
      await initialization;
      expect(initialized, isTrue);
      expect(controller.locale!.languageCode, 'zh');
    },
  );

  test(
    'production locale parsing normalizes region and preserves Japanese',
    () async {
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      List<Locale> deviceLocales = <Locale>[
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ];
      final AppLocaleController controller = AppLocaleController(
        preferences: _MemoryPreferences('system'),
        analytics: analytics,
        deviceLocales: () => deviceLocales,
      );

      await controller.initialize();
      expect(controller.locale!.toLanguageTag(), 'zh-Hant-TW');
      expect(Intl.defaultLocale, 'zh_Hant_TW');
      expect(LocaleSettings.currentLocale, AppLocale.zhHantTw);
      expect(ap_l10n.LocaleSettings.instance.listenToDeviceLocale, isFalse);
      expect(LocaleSettings.instance.listenToDeviceLocale, isFalse);

      deviceLocales = <Locale>[const Locale('en', 'US')];
      await controller.handleDeviceLocalesChanged(deviceLocales);
      expect(controller.locale, const Locale('en'));
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(Intl.defaultLocale, 'en');

      await controller.selectLanguage('ja');
      expect(controller.locale, const Locale('ja'));
      expect(analytics.values, <String>['zh', 'en', 'ja']);
      // The shared UI supports Japanese; NSYSU's own messages retain their
      // existing fallback. Analytics must keep the resolved common selection.
      expect(LocaleSettings.currentLocale, AppLocale.en);
    },
  );

  test('invalid saved preference follows the system locale', () async {
    final _MemoryPreferences preferences = _MemoryPreferences('invalid');
    final _RecordingAnalytics analytics = _RecordingAnalytics();
    final AppLocaleController controller = AppLocaleController(
      preferences: preferences,
      analytics: analytics,
      deviceLocales: () => <Locale>[const Locale('en', 'US')],
      applyLocale: (Locale locale) async => locale,
    );

    await controller.initialize();

    expect(controller.preferenceCode, 'system');
    expect(controller.locale, const Locale('en', 'US'));
    expect(analytics.values, <String>['en']);
  });

  test(
    'system selection persists and explicit selection ignores device events',
    () async {
      final _MemoryPreferences preferences = _MemoryPreferences('en');
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      final AppLocaleController controller = AppLocaleController(
        preferences: preferences,
        analytics: analytics,
        deviceLocales: () => <Locale>[const Locale('zh', 'TW')],
        applyLocale: (Locale locale) async => locale,
      );

      await controller.initialize();
      await controller.handleDeviceLocalesChanged(<Locale>[const Locale('ja')]);
      expect(analytics.values, <String>['en']);

      await controller.selectLanguage('system');
      expect(preferences.code, 'system');
      expect(controller.locale, const Locale('zh', 'TW'));
      await controller.handleDeviceLocalesChanged(<Locale>[
        const Locale('en', 'GB'),
      ]);
      expect(controller.locale, const Locale('en', 'GB'));
      await controller.handleDeviceLocalesChanged(null);
      expect(analytics.values, <String>['en', 'zh', 'en']);

      await controller.selectLanguage('zh');
      await controller.handleDeviceLocalesChanged(<Locale>[const Locale('en')]);
      expect(preferences.code, 'zh');
      expect(controller.locale, const Locale('zh', 'TW'));
      expect(analytics.values, <String>['en', 'zh', 'en', 'zh']);
    },
  );

  test(
    'rapid selections are serialized through locale and analytics writes',
    () async {
      final _MemoryPreferences preferences = _MemoryPreferences('system');
      final Completer<void> firstWriteStarted = Completer<void>();
      final Completer<void> finishFirstWrite = Completer<void>();
      final List<String> applied = <String>[];
      final _RecordingAnalytics analytics = _RecordingAnalytics(
        onSetProperty: (_) {
          if (!firstWriteStarted.isCompleted) {
            firstWriteStarted.complete();
            return finishFirstWrite.future;
          }
          return Future<void>.value();
        },
      );
      final AppLocaleController controller = AppLocaleController(
        preferences: preferences,
        analytics: analytics,
        deviceLocales: () => <Locale>[const Locale('en')],
        applyLocale: (Locale locale) async {
          applied.add(locale.languageCode);
          return locale;
        },
      );

      final Future<void> first = controller.selectLanguage('zh');
      await firstWriteStarted.future;
      final Future<void> second = controller.selectLanguage('en');
      final Future<void> third = controller.selectLanguage('zh');
      await controller.handleDeviceLocalesChanged(<Locale>[const Locale('en')]);
      expect(controller.preferenceCode, 'zh');
      expect(applied, <String>['zh']);
      expect(preferences.writes, <String>['zh']);
      finishFirstWrite.complete();
      await Future.wait(<Future<void>>[first, second, third]);

      expect(applied, <String>['zh', 'en', 'zh']);
      expect(analytics.values, <String>['zh', 'en', 'zh']);
      expect(preferences.writes, <String>['zh', 'en', 'zh']);
      expect(controller.locale!.languageCode, 'zh');
      expect(preferences.code, 'zh');
    },
  );

  test(
    'a queued system event cannot override a newer explicit selection',
    () async {
      final Completer<Locale> initialLocale = Completer<Locale>();
      final Completer<void> initializeStarted = Completer<void>();
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      final List<String> applied = <String>[];
      final AppLocaleController controller = AppLocaleController(
        preferences: _MemoryPreferences('system'),
        analytics: analytics,
        deviceLocales: () => <Locale>[const Locale('en')],
        applyLocale: (Locale locale) {
          applied.add(locale.languageCode);
          if (!initializeStarted.isCompleted) {
            initializeStarted.complete();
            return initialLocale.future;
          }
          return Future<Locale>.value(locale);
        },
      );

      final Future<void> initialization = controller.initialize();
      await initializeStarted.future;
      final Future<void> deviceEvent = controller.handleDeviceLocalesChanged(
        <Locale>[const Locale('ja')],
      );
      final Future<void> selection = controller.selectLanguage('zh');
      initialLocale.complete(const Locale('en'));
      await Future.wait(<Future<void>>[initialization, deviceEvent, selection]);

      expect(applied, <String>['en', 'zh']);
      expect(analytics.values, <String>['en', 'zh']);
      expect(controller.preferenceCode, 'zh');
    },
  );

  test(
    'analytics failure is reported without blocking later selections',
    () async {
      final StateError failure = StateError('Analytics unavailable');
      final List<Object> errors = <Object>[];
      final _RecordingAnalytics analytics = _RecordingAnalytics(
        onSetProperty: (String value) async {
          if (value == 'zh') throw failure;
        },
      );
      final AppLocaleController controller = AppLocaleController(
        preferences: _MemoryPreferences('zh'),
        analytics: analytics,
        deviceLocales: () => <Locale>[],
        applyLocale: (Locale locale) async => locale,
        onError: (Object error, StackTrace stackTrace) => errors.add(error),
      );

      await controller.initialize();
      expect(controller.locale!.languageCode, 'zh');
      expect(errors, <Object>[failure]);
      await controller.selectLanguage('en');
      expect(controller.locale!.languageCode, 'en');
      expect(analytics.values, <String>['zh', 'en']);
    },
  );

  test('initialization can retry after translation loading fails', () async {
    final StateError failure = StateError('Translation unavailable');
    final _RecordingAnalytics analytics = _RecordingAnalytics();
    int attempts = 0;
    final AppLocaleController controller = AppLocaleController(
      preferences: _MemoryPreferences('en'),
      analytics: analytics,
      deviceLocales: () => <Locale>[],
      applyLocale: (Locale locale) async {
        if (attempts++ == 0) throw failure;
        return locale;
      },
    );

    await expectLater(controller.initialize(), throwsA(same(failure)));
    expect(controller.locale, isNull);
    expect(analytics.values, isEmpty);
    await controller.initialize();
    expect(attempts, 2);
    expect(controller.locale, const Locale('en'));
    expect(analytics.values, <String>['en']);
  });

  test(
    'a failed preference write does not poison subsequent selections',
    () async {
      final _MemoryPreferences preferences = _MemoryPreferences('en');
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      final AppLocaleController controller = AppLocaleController(
        preferences: preferences,
        analytics: analytics,
        deviceLocales: () => <Locale>[],
        applyLocale: (Locale locale) async => locale,
      );

      preferences.failNextWrite = true;
      await expectLater(controller.selectLanguage('zh'), throwsStateError);
      await controller.selectLanguage('ja');
      expect(preferences.code, 'ja');
      expect(controller.locale, const Locale('ja'));
      expect(analytics.values, <String>['ja']);
    },
  );

  test('failed persistence restores system mode and device tracking', () async {
    final _MemoryPreferences preferences = _MemoryPreferences('system');
    final _RecordingAnalytics analytics = _RecordingAnalytics();
    final AppLocaleController controller = AppLocaleController(
      preferences: preferences,
      analytics: analytics,
      deviceLocales: () => <Locale>[const Locale('en')],
      applyLocale: (Locale locale) async => locale,
    );

    await controller.initialize();
    preferences.failNextWrite = true;
    await expectLater(controller.selectLanguage('en'), throwsStateError);
    expect(controller.preferenceCode, 'system');
    expect(preferences.code, 'system');
    await controller.handleDeviceLocalesChanged(<Locale>[const Locale('zh')]);
    expect(controller.locale, const Locale('zh'));
    expect(analytics.values, <String>['en', 'zh']);
  });

  test(
    'older failed persistence cannot roll back a newer queued choice',
    () async {
      final Completer<void> firstWriteStarted = Completer<void>();
      final Completer<void> failFirstWrite = Completer<void>();
      final _MemoryPreferences preferences = _MemoryPreferences(
        'system',
        onSetString: (String code) async {
          if (code == 'zh') {
            firstWriteStarted.complete();
            await failFirstWrite.future;
            throw StateError('Preference write failed');
          }
        },
      );
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      final AppLocaleController controller = AppLocaleController(
        preferences: preferences,
        analytics: analytics,
        deviceLocales: () => <Locale>[],
        applyLocale: (Locale locale) async => locale,
      );

      final Future<void> first = controller.selectLanguage('zh');
      final Future<void> failedWrite = expectLater(first, throwsStateError);
      await firstWriteStarted.future;
      final Future<void> second = controller.selectLanguage('en');
      expect(controller.preferenceCode, 'en');
      failFirstWrite.complete();
      await failedWrite;
      expect(controller.preferenceCode, 'en');
      await second;
      expect(preferences.code, 'en');
      expect(controller.locale, const Locale('en'));
      expect(analytics.values, <String>['en']);
    },
  );

  test('translation failure retains a persisted selection for retry', () async {
    final _MemoryPreferences preferences = _MemoryPreferences('system');
    final _RecordingAnalytics analytics = _RecordingAnalytics();
    bool fail = true;
    final AppLocaleController controller = AppLocaleController(
      preferences: preferences,
      analytics: analytics,
      deviceLocales: () => <Locale>[],
      applyLocale: (Locale locale) async {
        if (fail) throw StateError('Translation unavailable');
        return locale;
      },
    );

    await expectLater(controller.selectLanguage('en'), throwsStateError);
    expect(controller.preferenceCode, 'en');
    expect(preferences.code, 'en');
    expect(analytics.values, isEmpty);
    fail = false;
    await controller.initialize();
    expect(controller.locale, const Locale('en'));
    expect(analytics.values, <String>['en']);
  });

  test(
    'empty and unsupported system locales resolve to the existing fallback',
    () async {
      final _RecordingAnalytics analytics = _RecordingAnalytics();
      final AppLocaleController controller = AppLocaleController(
        preferences: _MemoryPreferences('system'),
        analytics: analytics,
        deviceLocales: () => <Locale>[],
      );

      await controller.initialize();
      expect(controller.locale, const Locale('en'));
      expect(LocaleSettings.currentLocale, AppLocale.en);
      await controller.handleDeviceLocalesChanged(<Locale>[const Locale('fr')]);
      expect(controller.locale, const Locale('en'));
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(analytics.values, <String>['en', 'en']);
    },
  );

  test(
    'production parser preserves prior country-code fallback behavior',
    () async {
      for (final Locale requested in <Locale>[
        const Locale('ja'),
        const Locale('fr'),
        const Locale('ja', 'JP'),
        const Locale('fr', 'FR'),
      ]) {
        // This is the parser used by the previous _initLocale/loadLocale paths.
        // An unmatched language with a null country matches English's null
        // country; a nonmatching country falls back to the app's base Chinese.
        final AppLocale previousAppLocale = AppLocaleUtils.instance
            .parseLocaleParts(
              languageCode: requested.languageCode,
              scriptCode: requested.scriptCode,
              countryCode: requested.countryCode,
            );
        expect(
          previousAppLocale,
          requested.countryCode == null ? AppLocale.en : AppLocale.zhHantTw,
        );

        await AppLocaleController.applyAppLocale(requested);

        expect(LocaleSettings.currentLocale, previousAppLocale);
        expect(LocaleSettings.instance.listenToDeviceLocale, isFalse);
        expect(ap_l10n.LocaleSettings.instance.listenToDeviceLocale, isFalse);
      }
    },
  );
}

class _MemoryPreferences implements PreferenceUtil {
  _MemoryPreferences(this.code, {this.onSetString});

  String code;
  final Future<void> Function(String)? onSetString;
  bool failNextWrite = false;
  final List<String> writes = <String>[];

  @override
  String getString(String key, String defaultValue) {
    expect(key, Constants.prefLanguageCode);
    return code;
  }

  @override
  Future<void> setString(String key, String data) async {
    expect(key, Constants.prefLanguageCode);
    await onSetString?.call(data);
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Preference write failed');
    }
    code = data;
    writes.add(data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingAnalytics implements AnalyticsUtil {
  _RecordingAnalytics({this.onSetProperty});

  final Future<void> Function(String)? onSetProperty;
  final List<String> names = <String>[];
  final List<String> values = <String>[];

  @override
  Future<void> setUserProperty(String name, String value) async {
    names.add(name);
    values.add(value);
    await onSetProperty?.call(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
