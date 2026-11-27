import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_event_visuals.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final bool compact;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.compact = false,
  });

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
    final DateTime? start = CalendarParsing.parseEventDate(event.dtstart);
    final DateTime? end = CalendarParsing.eventEndDateInclusive(event);
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final String? rangeLabel =
        start != null && end != null && end.isAfter(start)
        ? '${localizations.formatShortDate(start)} → '
              '${localizations.formatShortDate(end)}'
        : null;

    return Container(
      height: compact ? 84 : null,
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
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
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
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
            SizedBox(width: compact ? 10 : 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.summary,
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 16,
                      height: 1.25,
                    ),
                  ),
                  if (rangeLabel != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      rangeLabel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
