import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class CalendarPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const CalendarPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: Text(app.calendarPreviousPage),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                app.calendarPageFormat(
                  current: currentPage,
                  total: totalPages,
                ),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: Text(app.calendarNextPage),
            ),
          ],
        ),
      ),
    );
  }
}
