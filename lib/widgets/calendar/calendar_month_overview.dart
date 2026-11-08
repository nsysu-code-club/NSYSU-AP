import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_event_visuals.dart';

class CalendarMonthOverview extends StatefulWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Map<DateTime, Set<CalendarEventCategory>> eventCategoriesByDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;
  final bool expandVertically;
  final bool allowMonthSwipe;

  const CalendarMonthOverview({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.eventCategoriesByDate,
    required this.onDateSelected,
    required this.onMonthChanged,
    this.expandVertically = false,
    this.allowMonthSwipe = true,
  });

  @override
  State<CalendarMonthOverview> createState() => _CalendarMonthOverviewState();
}

class _CalendarMonthOverviewState extends State<CalendarMonthOverview> {
  static const int _anchorPage = 12000;
  late final PageController _pageController;
  late DateTime _anchorMonth;
  late DateTime _displayedMonth;
  bool _isSyncingExternalMonth = false;
  DateTime? _externalTargetMonth;
  int _externalSyncRevision = 0;

  DateTime _monthOnly(DateTime date) => DateTime(date.year, date.month);

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    _anchorMonth = _monthOnly(widget.visibleMonth);
    _displayedMonth = _anchorMonth;
    _pageController = PageController(initialPage: _anchorPage);
  }

  @override
  void didUpdateWidget(CalendarMonthOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime requestedMonth = _monthOnly(widget.visibleMonth);
    if (requestedMonth == _displayedMonth ||
        requestedMonth == _externalTargetMonth) {
      return;
    }
    final int revision = ++_externalSyncRevision;
    _isSyncingExternalMonth = true;
    _externalTargetMonth = requestedMonth;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageController.hasClients) return;
      await _pageController.animateToPage(
        _pageForMonth(requestedMonth),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || revision != _externalSyncRevision) return;
      _displayedMonth = requestedMonth;
      _externalTargetMonth = null;
      _isSyncingExternalMonth = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      DateTime(_anchorMonth.year, _anchorMonth.month + page - _anchorPage);

  int _pageForMonth(DateTime month) =>
      _anchorPage +
      (month.year - _anchorMonth.year) * 12 +
      month.month -
      _anchorMonth.month;

  void _handlePageChanged(int page) {
    final DateTime month = _monthForPage(page);
    _displayedMonth = month;
    if (!_isSyncingExternalMonth) {
      widget.onMonthChanged(month);
    }
  }

  Future<void> _moveByPage(int offset) async {
    if (!_pageController.hasClients) return;
    final int currentPage = _pageController.page?.round() ?? _anchorPage;
    await _pageController.animateToPage(
      currentPage + offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  double _compactHeight(double width) {
    final double cellWidth = math.max(0, width - 24) / 7;
    return 64 + (cellWidth / 1.4 * 6);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final int firstWeekday = localizations.firstDayOfWeekIndex;
    final Widget pager = PageView.builder(
      physics: widget.allowMonthSwipe
          ? null
          : const NeverScrollableScrollPhysics(),
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _handlePageChanged,
      itemBuilder: (BuildContext context, int page) => _buildMonthPage(
        context,
        _monthForPage(page),
        theme.colorScheme,
        localizations,
        firstWeekday,
      ),
    );

    return Semantics(
      label: localizations.formatMonthYear(_displayedMonth),
      onIncrease: () => _moveByPage(1),
      onDecrease: () => _moveByPage(-1),
      child: Material(
        color: theme.colorScheme.surface,
        child: widget.expandVertically
            ? pager
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SizedBox(
                    height: _compactHeight(constraints.maxWidth),
                    child: pager,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMonthPage(
    BuildContext context,
    DateTime month,
    ColorScheme colors,
    MaterialLocalizations localizations,
    int firstWeekday,
  ) {
    final int leadingDays =
        (DateTime(month.year, month.month).weekday % 7 - firstWeekday) % 7;
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int rowCount = ((leadingDays + daysInMonth) / 7).ceil();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            localizations.formatMonthYear(month),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List<Widget>.generate(7, (int index) {
              final int weekdayIndex = (firstWeekday + index) % 7;
              return Expanded(
                child: Text(
                  localizations.narrowWeekdays[weekdayIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return _buildGrid(
                  context,
                  month,
                  colors,
                  leadingDays,
                  daysInMonth,
                  rowCount,
                  rowExtent: constraints.maxHeight / rowCount,
                );
              },
            ),
          ),
        ),
        if (!widget.expandVertically)
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    DateTime month,
    ColorScheme colors,
    int leadingDays,
    int daysInMonth,
    int rowCount, {
    required double rowExtent,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: rowExtent,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (BuildContext context, int index) {
        final int day = index - leadingDays + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }
        final DateTime date = DateTime(month.year, month.month, day);
        final DateTime normalized = _dateOnly(date);
        final bool isSelected = normalized == _dateOnly(widget.selectedDate);
        final List<CalendarEventCategory> categories =
            (widget.eventCategoriesByDate[normalized] ??
                    <CalendarEventCategory>{})
                .toList()
              ..sort(
                (CalendarEventCategory a, CalendarEventCategory b) =>
                    a.index.compareTo(b.index),
              );
        final bool isToday = normalized == _dateOnly(DateTime.now());
        return InkWell(
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onTap: () => widget.onDateSelected(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: categories
                      .map(
                        (CalendarEventCategory category) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: calendarEventAccentColor(
                              category,
                              Theme.of(context),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
