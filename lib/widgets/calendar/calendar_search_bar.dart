import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';

class CalendarSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchKeyword;
  final DateTimeRange? selectedDateRange;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDateFilter;

  const CalendarSearchBar({
    super.key,
    required this.controller,
    required this.searchKeyword,
    required this.selectedDateRange,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClearSearch,
    required this.onPickDateRange,
    required this.onClearDateFilter,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool hasDateFilter = selectedDateRange != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: colorScheme.onSurface),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: app.calendarSearchBarHint,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                      prefixIcon: IconButton(
                        icon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        onPressed: () => onSubmitted(controller.text),
                      ),
                      suffixIcon: searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: onClearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: hasDateFilter
                      ? colorScheme.primaryContainer
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasDateFilter
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: app.calendarFilterDate,
                  icon: Icon(
                    Icons.date_range_rounded,
                    color: hasDateFilter
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  onPressed: onPickDateRange,
                ),
              ),
            ],
          ),
          if (hasDateFilter) ...<Widget>[
            const SizedBox(height: 8),
            _buildDateFilterChip(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.event_available_rounded,
            size: 15,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            CalendarParsing.formatDateRange(selectedDateRange!),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClearDateFilter,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 15,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
