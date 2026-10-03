import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_event_card.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_info_banner.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_pagination_bar.dart';
import 'package:nsysu_ap/widgets/calendar/calendar_search_bar.dart';

class CalendarPage extends StatefulWidget {
  final bool showAppBar;

  const CalendarPage({
    super.key,
    this.showAppBar = false,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _currentPage = 1;
  final int _pageSize = 10;
  List<CalendarEvent> _allEvents = <CalendarEvent>[];
  List<CalendarEvent> _filteredEvents = <CalendarEvent>[];
  bool _isLoading = true;
  bool _ascending = true;
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('CalendarInfoPage', 'calendar_info_page.dart');
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    final List<CalendarEvent> events = await CalendarParsing.getCleanEvents();
    setState(() {
      _allEvents = events;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters({bool resetPage = true}) {
    setState(() {
      if (resetPage) {
        _currentPage = 1;
      }
      _filteredEvents = CalendarParsing.filterAndSortEvents(
        _allEvents,
        keyword: _searchKeyword,
        dateRange: _selectedDateRange,
        ascending: _ascending,
      );
    });
  }

  void _performSearch(String keyword) {
    _searchKeyword = keyword;
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchKeyword = '';
    _applyFilters();
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _selectedDateRange,
      builder: (BuildContext context, Widget? child) {
        final ThemeData theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateRange = picked;
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    _selectedDateRange = null;
    _applyFilters();
  }

  void _toggleSort() {
    _ascending = !_ascending;
    _applyFilters(resetPage: false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (!widget.showAppBar) {
      return ColoredBox(
        color: colorScheme.surface,
        child: _wContent(),
      );
    }
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _wAppbar(),
      body: _wContent(),
    );
  }

  PreferredSizeWidget _wAppbar() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.primary,
      elevation: 0,
      title: Text(app.calendarPage),
      titleTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: _ascending
              ? app.calendarSortAscending
              : app.calendarSortDescending,
          icon: Icon(
            _ascending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: colorScheme.onPrimary,
          ),
          onPressed: _toggleSort,
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

    final int totalPages = CalendarParsing.getTotalPages(
      _filteredEvents.length,
      pageSize: _pageSize,
    );
    final List<CalendarEvent> pagedEvents = CalendarParsing.getPagedEvents(
      _filteredEvents,
      page: _currentPage,
      pageSize: _pageSize,
    );

    return Column(
      children: <Widget>[
        CalendarInfoBanner(
          eventCount: _filteredEvents.length,
          ascending: _ascending,
          onToggleSort: _toggleSort,
        ),
        CalendarSearchBar(
          controller: _searchController,
          searchKeyword: _searchKeyword,
          selectedDateRange: _selectedDateRange,
          onChanged: (String value) {
            setState(() {
              _searchKeyword = value;
            });
          },
          onSubmitted: _performSearch,
          onClearSearch: _clearSearch,
          onPickDateRange: _pickDateRange,
          onClearDateFilter: _clearDateFilter,
        ),
        Expanded(
          child: _filteredEvents.isEmpty
              ? _wEmptyView(colorScheme)
              : ListView.builder(
                  itemCount: pagedEvents.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return CalendarEventCard(event: pagedEvents[index]);
                  },
                ),
        ),
        if (_filteredEvents.isNotEmpty)
          CalendarPaginationBar(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPrevious: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            onNext: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
      ],
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
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
