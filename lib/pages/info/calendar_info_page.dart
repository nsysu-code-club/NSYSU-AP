import 'package:ap_common/ap_common.dart';
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

class _CalendarPageState extends State<CalendarPage> {
  List<CalendarEvent> _allEvents = <CalendarEvent>[];
  List<CalendarEvent> _filteredEvents = <CalendarEvent>[];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSearching = false;
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _eventScrollController = ScrollController();
  final GlobalKey _eventListKey = GlobalKey();
  final Map<DateTime, GlobalKey> _dateKeys = <DateTime, GlobalKey>{};
  final Map<DateTime, GlobalKey> _scrollDateKeys = <DateTime, GlobalKey>{};
  List<DateTime> _orderedAgendaDates = <DateTime>[];
  DateTime _selectedDate = _dateOnly(DateTime.now());
  DateTime? _highlightedDate;
  DateTime? _transientEmptyDate;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isProgrammaticScroll = false;
  bool _isScrollSyncEnabled = false;
  bool _isRemovingTransientDate = false;
  bool _hasPendingTransientRemoval = false;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    AnalyticsUtil.instance.setCurrentScreen(
      'CalendarInfoPage',
      'calendar_info_page.dart',
    );
    super.initState();
    _eventScrollController.addListener(_syncSelectedDateToScroll);
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      _isLoading = false;
      _hasError = false;
    });
    _applyFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialDate());
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = CalendarParsing.filterAndSortEvents(
        _allEvents,
        keyword: _searchKeyword,
      );
    });
  }

  void _performSearch(String keyword) {
    _searchKeyword = keyword;
    _applyFilters();
  }

  void _toggleSearch() {
    if (_isSearching) {
      _searchController.clear();
      _searchKeyword = '';
      _isSearching = false;
      _applyFilters();
      return;
    }
    setState(() => _isSearching = true);
  }

  Map<DateTime, List<CalendarEvent>> _eventsByDate() {
    final Map<DateTime, List<CalendarEvent>> result =
        <DateTime, List<CalendarEvent>>{};
    for (final CalendarEvent event in _filteredEvents) {
      final DateTime? start = CalendarParsing.parseEventDate(event.dtstart);
      if (start == null) continue;
      result.putIfAbsent(_dateOnly(start), () => <CalendarEvent>[]).add(event);
    }
    return result;
  }

  Map<DateTime, Set<CalendarEventCategory>> _eventCategoriesByDate() {
    final Map<DateTime, Set<CalendarEventCategory>> result =
        <DateTime, Set<CalendarEventCategory>>{};
    for (final CalendarEvent event in _filteredEvents) {
      final DateTime? start = CalendarParsing.parseEventDate(event.dtstart);
      if (start == null) continue;
      result
          .putIfAbsent(_dateOnly(start), () => <CalendarEventCategory>{})
          .add(CalendarParsing.classifyEventSummary(event.summary));
    }
    return result;
  }

  Future<void> _scrollToInitialDate() async {
    if (!mounted) {
      _isScrollSyncEnabled = true;
      return;
    }
    final DateTime today = _dateOnly(DateTime.now());
    setState(() => _highlightedDate = today);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final BuildContext? targetContext = _scrollDateKeys[today]?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      _isProgrammaticScroll = true;
      await _scrollDateIntoView(targetContext, animate: false);
      _isProgrammaticScroll = false;
    }
    _isScrollSyncEnabled = true;
  }

  Future<void> _selectDate(DateTime date, {bool animate = true}) async {
    final DateTime normalized = _dateOnly(date);
    final bool hasEvents = _eventsByDate().containsKey(normalized);
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
    if (!mounted) return;
    final BuildContext? targetContext =
        _scrollDateKeys[normalized]?.currentContext;
    if (targetContext == null || !targetContext.mounted) return;
    _isProgrammaticScroll = true;
    await _scrollDateIntoView(targetContext, animate: animate);
    _isProgrammaticScroll = false;
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
    final double offset = (_eventScrollController.offset + targetY - 24).clamp(
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
    _selectDate(today);
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
    for (final DateTime date in _orderedAgendaDates) {
      final RenderBox? box =
          _dateKeys[date]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final double y = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
      final double bottom = y + box.size.height;
      if (bottom > 8) {
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

    Widget buildCalendar({bool expandVertically = false}) =>
        CalendarMonthOverview(
          visibleMonth: _visibleMonth,
          selectedDate: _selectedDate,
          eventCategoriesByDate: _eventCategoriesByDate(),
          onDateSelected: _selectDate,
          onMonthChanged: _changeVisibleMonth,
          expandVertically: expandVertically,
        );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (isLandscape) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 5, child: buildCalendar(expandVertically: true)),
              Expanded(flex: 6, child: _wAgendaPane(colorScheme)),
            ],
          );
        }
        return Column(
          children: <Widget>[
            buildCalendar(),
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
          child: _filteredEvents.isEmpty && _searchKeyword.isNotEmpty
              ? _wEmptyView(colorScheme)
              : _wMonthList(colorScheme),
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

  Widget _wMonthList(ColorScheme colorScheme) {
    final Map<DateTime, List<CalendarEvent>> eventGroups = _eventsByDate();
    final DateTime today = _dateOnly(DateTime.now());
    eventGroups.putIfAbsent(today, () => <CalendarEvent>[]);
    final DateTime? transientDate = _transientEmptyDate;
    if (transientDate != null) {
      eventGroups.putIfAbsent(transientDate, () => <CalendarEvent>[]);
    }
    final List<MapEntry<DateTime, List<CalendarEvent>>> sortedEntries =
        eventGroups.entries.toList()..sort(
          (
            MapEntry<DateTime, List<CalendarEvent>> a,
            MapEntry<DateTime, List<CalendarEvent>> b,
          ) => a.key.compareTo(b.key),
        );
    final Map<DateTime, List<CalendarEvent>> eventsByDate =
        Map<DateTime, List<CalendarEvent>>.fromEntries(sortedEntries);
    _orderedAgendaDates = eventsByDate.keys.toList();
    _dateKeys.removeWhere(
      (DateTime date, GlobalKey _) => !eventsByDate.containsKey(date),
    );
    _scrollDateKeys.removeWhere(
      (DateTime date, GlobalKey _) => !eventsByDate.containsKey(date),
    );
    for (final DateTime date in eventsByDate.keys) {
      _dateKeys.putIfAbsent(date, GlobalKey.new);
      _scrollDateKeys.putIfAbsent(date, GlobalKey.new);
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
          children: eventsByDate.entries.map((
            MapEntry<DateTime, List<CalendarEvent>> entry,
          ) {
            final MaterialLocalizations localizations =
                MaterialLocalizations.of(context);
            final bool isActive = entry.key == _highlightedDate;
            final bool isToday = entry.key == today;
            final String weekday = DateFormat.EEEE().format(entry.key);
            final String monthYear = DateFormat('MMM y').format(entry.key);
            return Container(
              key: _scrollDateKeys[entry.key],
              margin: const EdgeInsets.only(bottom: 20),
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
                key: _dateKeys[entry.key],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () => _selectDate(entry.key),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              '${entry.key.day}',
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
                  ...entry.value.map(
                    (CalendarEvent event) => CalendarEventCard(event: event),
                  ),
                ],
              ),
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
