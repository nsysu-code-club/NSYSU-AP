import 'dart:async';
import 'dart:developer' as developer;

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';

/// Leaves locale resolution, persistence and user properties to the App.
class AppLanguageSettingItem extends StatelessWidget {
  const AppLanguageSettingItem({
    super.key,
    required this.preferenceCode,
    required this.onChanged,
    this.analytics,
  });

  final String preferenceCode;
  final Future<void> Function(String code) onChanged;
  final AnalyticsUtil? analytics;

  @override
  Widget build(BuildContext context) {
    final List<String> languageLabels = <String>[
      context.ap.systemLanguage,
      context.ap.traditionalChinese,
      context.ap.english,
      context.ap.japanese,
    ];
    final int languageIndex = ApSupportLanguageExtension.fromCode(
      preferenceCode,
    );

    return SettingItem(
      text: context.ap.language,
      subText: languageLabels[languageIndex],
      icon: Icons.language_outlined,
      onTap: () {
        unawaited(_logEvent('language_setting_click'));
        unawaited(
          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) => SimpleOptionDialog(
              title: context.ap.language,
              items: languageLabels,
              index: languageIndex,
              onSelected: (int index) {
                unawaited(
                  _changeLanguage(
                    context,
                    ApSupportLanguage.values[index].code,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeLanguage(BuildContext context, String code) async {
    try {
      await onChanged(code);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to change App language',
        name: 'AppLanguageSettingItem',
        error: error,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        UiUtil.instance.showToast(context, ap.somethingError);
      }
      return;
    }
    await _logEvent(
      'change_language',
      parameters: <String, String>{'code': code},
    );
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await (analytics ?? AnalyticsUtil.instance).logEvent(
        name,
        parameters: parameters,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to log $name',
        name: 'AppLanguageSettingItem',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
