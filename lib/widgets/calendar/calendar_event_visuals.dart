import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';

Color calendarEventAccentColor(
  CalendarEventCategory category,
  ThemeData theme,
) {
  return switch (category) {
    CalendarEventCategory.courseSelection => Colors.teal.shade700,
    CalendarEventCategory.holiday => Colors.deepOrange.shade400,
    CalendarEventCategory.examination => Colors.amber.shade700,
    CalendarEventCategory.general => theme.colorScheme.primary,
  };
}

IconData calendarEventCategoryIcon(CalendarEventCategory category) {
  return switch (category) {
    CalendarEventCategory.courseSelection => Icons.edit_calendar_rounded,
    CalendarEventCategory.holiday => Icons.celebration_rounded,
    CalendarEventCategory.examination => Icons.assignment_rounded,
    CalendarEventCategory.general => Icons.calendar_month_rounded,
  };
}
