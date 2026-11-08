import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class CalendarInfoBanner extends StatelessWidget {
  final int eventCount;

  const CalendarInfoBanner({super.key, required this.eventCount});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: <Widget>[
          Icon(Icons.school_rounded, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              app.calendarEventCounts(allEvents: eventCount),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
