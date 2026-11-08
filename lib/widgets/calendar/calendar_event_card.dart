import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_event_visuals.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const CalendarEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final CalendarEventCategory category = CalendarParsing.classifyEventSummary(
      event.summary,
    );
    final Color accentColor = calendarEventAccentColor(
      category,
      Theme.of(context),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                calendarEventCategoryIcon(category),
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                event.summary,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
