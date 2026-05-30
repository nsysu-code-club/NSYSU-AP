import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

SemesterUIConfig get semesterPickerUiConfig => SemesterUIConfig(
  getName: (String value) {
    switch (value) {
      case '0':
        return app.continuingSummerEducationProgram;
      case '1':
        return app.fallSemester;
      case '2':
        return app.springSemester;
      case '3':
        return app.summerSemester;
      default:
        return '';
    }
  },
  getShortName: (String value) {
    switch (value) {
      case '0':
        return app.continuingSummerEducationProgramShort;
      case '1':
        return app.fallSemesterShort;
      case '2':
        return app.springSemesterShort;
      case '3':
        return app.summerSemesterShort;
      default:
        return '';
    }
  },
  getIcon: (String value) {
    switch (value) {
      case '0':
      case '3':
        return Icons.wb_sunny_rounded;
      case '1':
        return Icons.looks_one_rounded;
      case '2':
        return Icons.looks_two_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  },
  getColor: (String value, ColorScheme colorScheme) {
    switch (value) {
      case '0':
      case '3':
        return colorScheme.tertiaryContainer.withAlpha(179);
      case '1':
        return colorScheme.primaryContainer.withAlpha(179);
      case '2':
        return colorScheme.secondaryContainer.withAlpha(179);
      default:
        return colorScheme.surfaceContainerHighest;
    }
  },
);
