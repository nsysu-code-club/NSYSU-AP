import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class CalendarInfoBanner extends StatelessWidget {
  final int eventCount;
  final bool ascending;
  final VoidCallback onToggleSort;

  const CalendarInfoBanner({
    super.key,
    required this.eventCount,
    required this.ascending,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.school_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                app.calendarEventCounts(allEvents: eventCount),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onToggleSort,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: colorScheme.onPrimary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ascending
                        ? app.calendarSortAscending
                        : app.calendarSortDescending,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
