import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/widgets/app_language_setting_item.dart';

class _RecordingAnalytics extends Fake implements AnalyticsUtil {
  final List<String> events = <String>[];
  final List<Map<String, Object>?> parameters = <Map<String, Object>?>[];
  final List<String> properties = <String>[];
  bool failEvents = false;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
    this.parameters.add(parameters);
    if (failEvents) throw StateError('Analytics unavailable');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    properties.add('$name=$value');
  }
}

class _RecordingPreferences extends Fake implements PreferenceUtil {
  final List<String> writes = <String>[];

  @override
  Future<void> setString(String key, String data) async {
    writes.add('$key=$data');
  }
}

Future<void> _pumpItem(
  WidgetTester tester, {
  required AnalyticsUtil analytics,
  required Future<void> Function(String) onChanged,
  String preferenceCode = 'system',
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: AppLanguageSettingItem(
            preferenceCode: preferenceCode,
            onChanged: onChanged,
            analytics: analytics,
          ),
        ),
      ),
    ),
  );
}

Future<void> _selectOption(WidgetTester tester, String label) async {
  await tester.tap(find.byType(SettingItem));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(SimpleOptionDialog),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _RecordingAnalytics analytics;
  late _RecordingPreferences preferences;

  setUpAll(() {
    preferences = _RecordingPreferences();
    registerApCommonCore(preference: preferences);
  });

  setUp(() async {
    await setApLocale(AppLocale.en);
    analytics = _RecordingAnalytics();
    preferences.writes.clear();
  });

  for (final String code in <String>['system', 'zh', 'en', 'ja']) {
    testWidgets('selecting $code delegates once without extra writes', (
      WidgetTester tester,
    ) async {
      final List<String> selections = <String>[];
      final Map<String, String> labels = <String, String>{
        'system': ap.systemLanguage,
        'zh': ap.traditionalChinese,
        'en': ap.english,
        'ja': ap.japanese,
      };
      await _pumpItem(
        tester,
        analytics: analytics,
        preferenceCode: 'zh',
        onChanged: (String value) async => selections.add(value),
      );

      expect(find.text(ap.traditionalChinese), findsOneWidget);
      await _selectOption(tester, labels[code]!);

      expect(selections, <String>[code]);
      expect(analytics.events, <String>[
        'language_setting_click',
        'change_language',
      ]);
      expect(analytics.parameters.last, <String, String>{'code': code});
      expect(analytics.properties, isEmpty);
      expect(preferences.writes, isEmpty);
      expect(find.byType(SimpleOptionDialog), findsNothing);
    });
  }

  testWidgets('Analytics event failures do not block selection', (
    WidgetTester tester,
  ) async {
    analytics.failEvents = true;
    final List<String> selections = <String>[];
    await _pumpItem(
      tester,
      analytics: analytics,
      onChanged: (String code) async => selections.add(code),
    );

    await _selectOption(tester, ap.japanese);

    expect(selections, <String>['ja']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for the change before logging its completion', (
    WidgetTester tester,
  ) async {
    final Completer<void> change = Completer<void>();
    await _pumpItem(
      tester,
      analytics: analytics,
      onChanged: (String code) => change.future,
    );

    await _selectOption(tester, ap.english);
    expect(analytics.events, <String>['language_setting_click']);

    change.complete();
    await tester.pump();
    expect(analytics.events.last, 'change_language');
  });

  testWidgets('handles a failed pending change after the item is removed', (
    WidgetTester tester,
  ) async {
    final Completer<void> change = Completer<void>();
    await _pumpItem(
      tester,
      analytics: analytics,
      onChanged: (String code) => change.future,
    );
    await _selectOption(tester, ap.english);
    await tester.pumpWidget(const SizedBox());

    change.completeError(StateError('Locale unavailable'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(analytics.events, <String>['language_setting_click']);
  });
}
