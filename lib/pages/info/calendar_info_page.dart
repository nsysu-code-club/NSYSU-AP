import 'dart:math' as math;

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_event_card.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_month_overview.dart';

class CalendarPage extends StatefulWidget {
  final bool showAppBar;

  const CalendarPage({super.key, this.showAppBar = false});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  static const double _stickyBarHeight = 100;
  List<CalendarEvent> _allEvents = <CalendarEvent>[];
  List<CalendarEvent> _filteredEvents = <CalendarEvent>[];
  final Map<DateTime, List<CalendarEvent>> _eventsByDate =
      <DateTime, List<CalendarEvent>>{};
  final Map<DateTime, Set<CalendarEventCategory>> _categoriesByDate =
      <DateTime, Set<CalendarEventCategory>>{};
  final Map<DateTime, Map<CalendarEvent, DateTime>> _spanningEventsByDate =
      <DateTime, Map<CalendarEvent, DateTime>>{};
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSearching = false;
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _eventScrollController = ScrollController();
  final GlobalKey _eventListKey = GlobalKey();
  final Map<DateTime, GlobalKey> _dateKeys = <DateTime, GlobalKey>{};
  final Map<DateTime, GlobalKey> _scrollDateKeys = <DateTime, GlobalKey>{};
  final Map<CalendarEvent, GlobalKey> _eventCardKeys =
      <CalendarEvent, GlobalKey>{};
  final ValueNotifier<Map<CalendarEvent, double>> _stickyEventProgress =
      ValueNotifier<Map<CalendarEvent, double>>(<CalendarEvent, double>{});
  late final AnimationController _stickyBarFactor;
  List<DateTime> _orderedAgendaDates = <DateTime>[];
  DateTime _selectedDate = _dateOnly(DateTime.now());
  DateTime? _highlightedDate;
  DateTime? _transientEmptyDate;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isProgrammaticScroll = false;
  bool _isScrollSyncEnabled = false;
  bool _isRemovingTransientDate = false;
  bool _hasPendingTransientRemoval = false;
  int _scrollRequestId = 0;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime? _eventStartDate(CalendarEvent event) =>
      CalendarParsing.parseEventDate(event.dtstart);

  @override
  void initState() {
    AnalyticsUtil.instance.setCurrentScreen(
      'CalendarInfoPage',
      'calendar_info_page.dart',
    );
    super.initState();
    _stickyBarFactor = AnimationController(vsync: this, value: 0);
    _eventScrollController.addListener(_syncSelectedDateToScroll);
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stickyEventProgress.dispose();
    _stickyBarFactor.dispose();
    _eventScrollController
      ..removeListener(_syncSelectedDateToScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final List<CalendarEvent>? events = await CalendarParsing.getCleanEvents();
    if (!mounted) {
      return;
    }
    if (events == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    setState(() {
      _allEvents = events;
      final DateTime today = _dateOnly(DateTime.now());
      _selectedDate = today;
      _highlightedDate = today;
      _visibleMonth = DateTime(today.year, today.month);
      _isLoading = false;
      _hasError = false;
    });
    _applyFilters();
    final Map<CalendarEvent, double> ongoingToday = <CalendarEvent, double>{
      for (final MapEntry<CalendarEvent, DateTime> entry
          in _spanningEventsByDate[_selectedDate]?.entries ??
              const <MapEntry<CalendarEvent, DateTime>>[])
        if (entry.value.isBefore(_selectedDate)) entry.key: 1,
    };
    _publishStickyEvents(ongoingToday);
    _stickyBarFactor.value = ongoingToday.isEmpty ? 0 : 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialDate());
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = CalendarParsing.filterAndSortEvents(
        _allEvents,
        keyword: _searchKeyword,
      );
      _indexFilteredEvents();
    });
  }

  void _performSearch(String keyword) {
    _searchKeyword = keyword;
    _applyFilters();
    if (_filteredEvents.isEmpty) {
      _stickyBarFactor.value = 0;
      _publishStickyEvents(const <CalendarEvent, double>{});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchKeyword == keyword) {
        _syncSelectedDateToScroll();
      }
    });
  }

  void _toggleSearch() {
    if (_isSearching) {
      _searchController.clear();
      _isSearching = false;
      _performSearch('');
      return;
    }
    setState(() => _isSearching = true);
  }

  void _indexFilteredEvents() {
    _eventsByDate.clear();
    _categoriesByDate.clear();
    _spanningEventsByDate.clear();
    for (final CalendarEvent event in _filteredEvents) {
      final DateTime? start = CalendarParsing.parseEventDate(event.dtstart);
      if (start == null) continue;
      final DateTime startDay = _dateOnly(start);
      _eventsByDate.putIfAbsent(startDay, () => <CalendarEvent>[]).add(event);
      final DateTime end =
          CalendarParsing.eventEndDateInclusive(event) ?? _dateOnly(start);
      final CalendarEventCategory category =
          CalendarParsing.classifyEventSummary(event.summary);
      DateTime day = _dateOnly(start);
      while (!day.isAfter(end)) {
        _categoriesByDate
            .putIfAbsent(day, () => <CalendarEventCategory>{})
            .add(category);
        if (end.isAfter(startDay)) {
          _spanningEventsByDate.putIfAbsent(
            day,
            () => <CalendarEvent, DateTime>{},
          )[event] = startDay;
        }
        day = day.add(const Duration(days: 1));
      }
    }
  }

  Future<void> _scrollToInitialDate() async {
    if (!mounted) return;
    final DateTime today = _selectedDate;
    final BuildContext? targetContext = _scrollDateKeys[today]?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      final int requestId = ++_scrollRequestId;
      _isProgrammaticScroll = true;
      await _scrollDateIntoView(targetContext, animate: false);
      if (!mounted || requestId != _scrollRequestId) return;
      _isProgrammaticScroll = false;
    }
    _isScrollSyncEnabled = true;
    _refreshStickyEventsForSelection(today);
  }

  Future<void> _selectDate(DateTime date, {bool animate = true}) async {
    final int requestId = ++_scrollRequestId;
    _isProgrammaticScroll = true;
    final DateTime normalized = _dateOnly(date);
    final bool hasEvents = _eventsByDate.containsKey(normalized);
    final bool isToday = normalized == _dateOnly(DateTime.now());
    setState(() {
      _selectedDate = normalized;
      _visibleMonth = DateTime(normalized.year, normalized.month);
      _highlightedDate = normalized;
      if (isToday) {
        _transientEmptyDate = null;
        _hasPendingTransientRemoval = false;
      }
      if (!hasEvents && !isToday) {
        _transientEmptyDate = normalized;
        _hasPendingTransientRemoval = false;
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || requestId != _scrollRequestId) return;
    final BuildContext? targetContext =
        _scrollDateKeys[normalized]?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await _scrollDateIntoView(targetContext, animate: animate);
    }
    if (mounted && requestId == _scrollRequestId) {
      _isScrollSyncEnabled = true;
      _isProgrammaticScroll = false;
      _refreshStickyEventsForSelection(normalized, animate: animate);
    }
  }

  void _refreshStickyEventsForSelection(DateTime date, {bool animate = false}) {
    if (!mounted) return;
    final RenderBox? listBox =
        _eventListKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox != null) {
      _updateStickyEvents(date, listBox, null, 0, animate: animate);
    }
  }

  Future<void> _scrollDateIntoView(
    BuildContext targetContext, {
    required bool animate,
  }) async {
    final RenderBox? listBox =
        _eventListKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? targetBox = targetContext.findRenderObject() as RenderBox?;
    if (listBox == null ||
        targetBox == null ||
        !_eventScrollController.hasClients) {
      return;
    }
    final double targetY = targetBox
        .localToGlobal(Offset.zero, ancestor: listBox)
        .dy;
    final double offset = (_eventScrollController.offset + targetY - 12).clamp(
      0.0,
      _eventScrollController.position.maxScrollExtent,
    );
    if (animate) {
      await _eventScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _eventScrollController.jumpTo(offset);
    }
  }

  void _changeVisibleMonth(DateTime month) {
    setState(() => _visibleMonth = DateTime(month.year, month.month));
  }

  void _goToToday() {
    final DateTime today = _dateOnly(DateTime.now());
    final bool isScrolling =
        _eventScrollController.hasClients &&
        _eventScrollController.position.isScrollingNotifier.value;
    _selectDate(today, animate: !isScrolling);
  }

  void _syncSelectedDateToScroll() {
    if (!_isScrollSyncEnabled ||
        _isProgrammaticScroll ||
        _isRemovingTransientDate ||
        !mounted) {
      return;
    }
    final RenderBox? listBox =
        _eventListKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    DateTime? activeDate;
    DateTime? departingDate;
    double departingBottom = 0;
    for (final DateTime date in _orderedAgendaDates) {
      final RenderBox? box =
          _dateKeys[date]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final double y = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
      final double bottom = y + box.size.height;
      if (bottom <= 0) {
        departingDate = date;
        departingBottom = bottom;
      }
      if (bottom > 0) {
        activeDate = date;
        break;
      }
    }
    final DateTime? transientDate = _transientEmptyDate;
    final RenderBox? transientBox = transientDate == null
        ? null
        : _scrollDateKeys[transientDate]?.currentContext?.findRenderObject()
              as RenderBox?;
    if (transientDate != null &&
        transientBox != null &&
        transientBox.attached) {
      final double top = transientBox
          .localToGlobal(Offset.zero, ancestor: listBox)
          .dy;
      final double bottom = top + transientBox.size.height;
      if (bottom <= 0 || top >= listBox.size.height) {
        if (_eventScrollController.position.isScrollingNotifier.value) {
          _hasPendingTransientRemoval = true;
        } else {
          _removeTransientDateWithoutJump(
            activeDate,
            removedExtentAbove: bottom <= 0 ? transientBox.size.height : 0,
          );
          return;
        }
      }
    }
    if (activeDate != null &&
        (activeDate != _selectedDate || activeDate != _highlightedDate)) {
      setState(() {
        _selectedDate = activeDate!;
        _highlightedDate = activeDate;
        _visibleMonth = DateTime(activeDate.year, activeDate.month);
      });
    }
    _updateStickyEvents(activeDate, listBox, departingDate, departingBottom);
  }

  void _updateStickyEvents(
    DateTime? activeDate,
    RenderBox listBox,
    DateTime? departingDate,
    double departingBottom, {
    bool animate = false,
  }) {
    if (departingDate != null && departingBottom > -_stickyBarHeight) {
      final Map<CalendarEvent, DateTime>? departing =
          _spanningEventsByDate[departingDate];
      final Map<CalendarEvent, DateTime>? active =
          _spanningEventsByDate[activeDate];
      if (departing != null &&
          !departing.keys.any(
            (CalendarEvent event) => active?.containsKey(event) ?? false,
          )) {
        _stickyBarFactor.value = 1 + departingBottom / _stickyBarHeight;
        _publishStickyEvents(<CalendarEvent, double>{
          for (final CalendarEvent event in departing.keys) event: 1,
        });
        return;
      }
    }
    if (activeDate == null) {
      _publishStickyEvents(const <CalendarEvent, double>{});
      _stickyBarFactor.value = 0;
      return;
    }
    final Map<CalendarEvent, double> next = <CalendarEvent, double>{};
    final Map<CalendarEvent, DateTime>? spanning =
        _spanningEventsByDate[activeDate];
    for (final MapEntry<CalendarEvent, DateTime> entry
        in spanning?.entries ?? const <MapEntry<CalendarEvent, DateTime>>[]) {
      final CalendarEvent event = entry.key;
      if (entry.value.isBefore(activeDate)) {
        next[event] = 1;
        continue;
      }
      final RenderBox? cardBox =
          _eventCardKeys[event]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (cardBox == null || !cardBox.attached || cardBox.size.height == 0) {
        continue;
      }
      final double top = cardBox
          .localToGlobal(Offset.zero, ancestor: listBox)
          .dy;
      final double progress = (-top / cardBox.size.height).clamp(0.0, 1.0);
      if (progress > 0) next[event] = progress;
    }
    final double barFactor = next.values.fold<double>(
      0,
      (double maximum, double progress) => math.max(maximum, progress),
    );
    if (!animate ||
        MediaQuery.disableAnimationsOf(context) ||
        barFactor == _stickyBarFactor.value) {
      _stickyBarFactor.value = barFactor;
      _publishStickyEvents(next);
      return;
    }

    // Keep the outgoing cards visible until the row has slid out.
    if (next.isNotEmpty) _publishStickyEvents(next);
    _stickyBarFactor
        .animateTo(
          barFactor,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (mounted) _publishStickyEvents(next);
        });
  }

  void _publishStickyEvents(Map<CalendarEvent, double> events) {
    if (!mapEquals(_stickyEventProgress.value, events)) {
      _stickyEventProgress.value = events;
    }
  }

  void _removeTransientDateWithoutJump(
    DateTime? activeDate, {
    required double removedExtentAbove,
  }) {
    _isRemovingTransientDate = true;
    _isProgrammaticScroll = true;
    _hasPendingTransientRemoval = false;
    if (removedExtentAbove > 0 && _eventScrollController.hasClients) {
      final double correctedOffset =
          (_eventScrollController.offset - removedExtentAbove).clamp(
            0.0,
            _eventScrollController.position.maxScrollExtent,
          );
      _eventScrollController.jumpTo(correctedOffset);
    }
    setState(() {
      _transientEmptyDate = null;
      if (activeDate != null) {
        _selectedDate = activeDate;
        _highlightedDate = activeDate;
        _visibleMonth = DateTime(activeDate.year, activeDate.month);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isProgrammaticScroll = false;
      _isRemovingTransientDate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Widget safeContent = SafeArea(
      top: !widget.showAppBar,
      bottom: false,
      child: _wContent(),
    );

    if (!widget.showAppBar) {
      return Material(color: colorScheme.surface, child: safeContent);
    }
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _wAppbar(),
      body: safeContent,
    );
  }

  PreferredSizeWidget _wAppbar() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: app.calendarSearchBarHint,
                hintStyle: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
              cursorColor: colorScheme.onPrimary,
            )
          : Text(ap.events),
      titleTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          tooltip: _isSearching ? app.optionCancel : app.calendarSearchBarHint,
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: colorScheme.onPrimary,
          ),
          onPressed: _toggleSearch,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _wContent() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    if (_hasError) {
      return _wErrorView(colorScheme);
    }

    Widget buildCalendar({
      bool expandVertically = false,
      bool allowMonthSwipe = true,
    }) => CalendarMonthOverview(
      visibleMonth: _visibleMonth,
      selectedDate: _selectedDate,
      eventCategoriesByDate: _categoriesByDate,
      onDateSelected: _selectDate,
      onMonthChanged: _changeVisibleMonth,
      expandVertically: expandVertically,
      allowMonthSwipe: allowMonthSwipe,
    );

    // Scaffold consumes the keyboard inset when it resizes its body.
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isLandscape =
            constraints.maxWidth > constraints.maxHeight + keyboardInset;
        final TextScaler textScaler = MediaQuery.textScalerOf(context);
        // Allow for six rows and the month/weekday labels above them.
        final double minCalendarHeight =
            6 * 35 + 18 + 1.25 * (textScaler.scale(24) + textScaler.scale(11));
        final bool keyboardConstrainsCalendar =
            _isSearching &&
            keyboardInset > 0 &&
            constraints.maxHeight < minCalendarHeight;
        if (isLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: keyboardConstrainsCalendar
                    ? SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: SizedBox(
                          height: minCalendarHeight,
                          child: buildCalendar(
                            expandVertically: true,
                            allowMonthSwipe: false,
                          ),
                        ),
                      )
                    : buildCalendar(expandVertically: true),
              ),
              Expanded(flex: 6, child: _wAgendaPane(colorScheme)),
            ],
          );
        }
        return Column(
          children: <Widget>[
            if (!keyboardConstrainsCalendar) buildCalendar(),
            Expanded(child: _wAgendaPane(colorScheme)),
          ],
        );
      },
    );
  }

  Widget _wAgendaPane(ColorScheme colorScheme) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Column(
            children: <Widget>[
              _wStickyEvents(),
              Expanded(
                child: _filteredEvents.isEmpty && _searchKeyword.isNotEmpty
                    ? _wEmptyView(colorScheme)
                    : _wMonthList(colorScheme),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'calendar-today',
            onPressed: _goToToday,
            icon: const Icon(Icons.today_rounded, size: 20),
            label: Text(MaterialLocalizations.of(context).currentDateLabel),
          ),
        ),
      ],
    );
  }

  Widget _wStickyEvents() {
    return AnimatedBuilder(
      animation: _stickyBarFactor,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double fullWidth = constraints.maxWidth - 32;
          return ValueListenableBuilder<Map<CalendarEvent, double>>(
            valueListenable: _stickyEventProgress,
            builder:
                (
                  BuildContext context,
                  Map<CalendarEvent, double> events,
                  Widget? child,
                ) {
                  final bool singleCard = events.length == 1;
                  return Container(
                    height: _stickyBarHeight,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(context).colorScheme.surface,
                    child: SingleChildScrollView(
                      key: ValueKey<bool>(singleCard),
                      physics: singleCard
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          for (final MapEntry<CalendarEvent, double> entry
                              in events.entries)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: fullWidth * (1 - 0.25 * entry.value),
                              child: Opacity(
                                opacity: entry.value,
                                child: GestureDetector(
                                  onTap: () {
                                    final DateTime? start = _eventStartDate(
                                      entry.key,
                                    );
                                    if (start != null) _selectDate(start);
                                  },
                                  child: CalendarEventCard(
                                    event: entry.key,
                                    compact: true,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
          );
        },
      ),
      builder: (BuildContext context, Widget? child) {
        final double barFactor = _stickyBarFactor.value;
        return ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: barFactor,
            child: Transform.translate(
              offset: Offset(0, -_stickyBarHeight * (1 - barFactor)),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _wMonthList(ColorScheme colorScheme) {
    final Map<DateTime, List<CalendarEvent>> eventGroups =
        Map<DateTime, List<CalendarEvent>>.of(_eventsByDate);
    final DateTime today = _dateOnly(DateTime.now());
    eventGroups.putIfAbsent(today, () => <CalendarEvent>[]);
    final DateTime? transientDate = _transientEmptyDate;
    if (transientDate != null) {
      eventGroups.putIfAbsent(transientDate, () => <CalendarEvent>[]);
    }
    _orderedAgendaDates = eventGroups.keys.toList()..sort();
    final Set<DateTime> stickyExitDates = <DateTime>{};
    for (int index = 0; index + 1 < _orderedAgendaDates.length; index++) {
      final DateTime date = _orderedAgendaDates[index];
      final Map<CalendarEvent, DateTime>? spanning =
          _spanningEventsByDate[date];
      if (spanning == null) continue;
      final Map<CalendarEvent, DateTime>? following =
          _spanningEventsByDate[_orderedAgendaDates[index + 1]];
      if (!spanning.keys.any(
        (CalendarEvent event) => following?.containsKey(event) ?? false,
      )) {
        stickyExitDates.add(date);
      }
    }
    final List<DateTime> previousStickyExits = <DateTime>[];
    _dateKeys.removeWhere(
      (DateTime date, GlobalKey _) => !eventGroups.containsKey(date),
    );
    _scrollDateKeys.removeWhere(
      (DateTime date, GlobalKey _) => !eventGroups.containsKey(date),
    );
    for (final DateTime date in _orderedAgendaDates) {
      _dateKeys.putIfAbsent(date, GlobalKey.new);
      _scrollDateKeys.putIfAbsent(date, GlobalKey.new);
    }
    _eventCardKeys.removeWhere(
      (CalendarEvent event, GlobalKey _) => !_filteredEvents.contains(event),
    );
    for (final CalendarEvent event in _filteredEvents) {
      _eventCardKeys.putIfAbsent(event, GlobalKey.new);
    }
    return NotificationListener<ScrollEndNotification>(
      onNotification: (ScrollEndNotification notification) {
        if (_hasPendingTransientRemoval) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncSelectedDateToScroll();
          });
        }
        return false;
      },
      child: SingleChildScrollView(
        key: _eventListKey,
        controller: _eventScrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          children: _orderedAgendaDates.map((DateTime date) {
            final MaterialLocalizations localizations =
                MaterialLocalizations.of(context);
            final bool isActive = date == _highlightedDate;
            final bool isToday = date == today;
            final String weekday = DateFormat.EEEE().format(date);
            final String monthYear = DateFormat('MMM y').format(date);
            final List<DateTime> exitsBeforeDate = List<DateTime>.of(
              previousStickyExits,
            );
            if (stickyExitDates.contains(date)) {
              previousStickyExits.add(date);
            }
            final Widget section = Container(
              // Give the outgoing row one pixel of travel per scroll pixel.
              margin: EdgeInsets.only(
                bottom: stickyExitDates.contains(date) ? _stickyBarHeight : 20,
              ),
              padding: const EdgeInsets.fromLTRB(12, 16, 10, 2),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isActive ? colorScheme.primary : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                key: _dateKeys[date],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () => _selectDate(date),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                fontSize: 32,
                                height: 0.9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isToday
                                    ? localizations.currentDateLabel
                                    : '$weekday · $monthYear',
                                style: TextStyle(
                                  color: isToday
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...eventGroups[date]!.map(
                    (CalendarEvent event) => CalendarEventCard(
                      key: _eventCardKeys[event],
                      event: event,
                    ),
                  ),
                ],
              ),
            );
            final Widget positionedSection = exitsBeforeDate.isEmpty
                ? section
                : AnimatedBuilder(
                    animation: _eventScrollController,
                    child: section,
                    builder: (BuildContext context, Widget? child) {
                      final RenderBox? listBox =
                          _eventListKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      if (listBox == null) return child!;
                      double remainingSpace = 0;
                      for (final DateTime exitDate in exitsBeforeDate) {
                        final RenderBox? exitBox =
                            _scrollDateKeys[exitDate]?.currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        if (exitBox == null || !exitBox.hasSize) continue;
                        final double gapEnd =
                            exitBox
                                .localToGlobal(Offset.zero, ancestor: listBox)
                                .dy +
                            exitBox.size.height;
                        remainingSpace += gapEnd.clamp(0.0, _stickyBarHeight);
                      }
                      // The scroll offset first consumes the row's exit space.
                      // Hold the agenda at the viewport edge until the
                      // remaining exit space reaches zero.
                      return Transform.translate(
                        offset: Offset(0, -remainingSpace),
                        child: child,
                      );
                    },
                  );
            return SizedBox(
              key: _scrollDateKeys[date],
              child: positionedSection,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _wEmptyView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            app.calendarEventIsEmpty,
            style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _wErrorView(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              app.calendarLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(app.calendarRetry),
            ),
          ],
        ),
      ),
    );
  }
}
