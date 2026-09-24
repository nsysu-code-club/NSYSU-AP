import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';

class CalendarPage extends StatefulWidget {
  // static const String routerName = "/Calendar";
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

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('CalendarInfoPage', 'calendar_info_page.dart');
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    final List<CalendarEvent> events =
        await CalendarParsing.getCleanEvents(ascending: _ascending);
    setState(() {
      _filteredEvents = _allEvents = events;
      _isLoading = false;
    });
  }

  void _performSearch(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _currentPage = 1;
      _filteredEvents = CalendarParsing.filterEvents(
        _allEvents,
        _searchKeyword,
      );
      CalendarParsing.sortEvents(_filteredEvents, ascending: _ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return ColoredBox(
        color: const Color(0xFFF4F6F9),
        child: _wContent(),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _wAppbar(),
      body: _wContent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _wSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (String value) {
          setState(() {
            _searchKeyword = value;
          });
        },
        onSubmitted: (String value) {
          _performSearch(value);
        },
        decoration: InputDecoration(
          hintText: app.calendarSearchBarHint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF003D79),
              size: 22,
            ),
            onPressed: () => _performSearch(_searchController.text),
          ),
          suffixIcon: _searchKeyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    _ascending = true;
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _wAppbar() {
    return AppBar(
      backgroundColor: const Color(0xFF003D79),
      elevation: 0,
      title: Text(app.calendarPage),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
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
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _ascending = !_ascending;
              _currentPage = 1;
              CalendarParsing.sortEvents(_allEvents, ascending: _ascending);
              CalendarParsing.sortEvents(
                _filteredEvents,
                ascending: _ascending,
              );
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _wContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003D79)),
        ),
      );
    }

    // round up pages
    final int totalPages = (_filteredEvents.length / _pageSize).ceil();
    final List<CalendarEvent> pagedEvents = CalendarParsing.getPagedEvents(
      _filteredEvents,
      page: _currentPage,
      pageSize: _pageSize,
    );

    return Column(
      children: <Widget>[
        // 頂部 NSYSU 資訊欄
        _wInfoBanner(),

        _wSearchBar(),

        // 活動卡片列表 / 無搜尋結果提示
        Expanded(
          child: _filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.event_busy_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        app.calendarEventIsEmpty,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: pagedEvents.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final CalendarEvent event = pagedEvents[index];
                    final String startStr = _formatDate(event.dtstart);
                    final String endStr = _formatDate(event.dtend);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // 圖示區塊
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF003D79)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF003D79),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 內容區塊
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    event.summary,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 15,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '$startStr ~ $endStr',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 底部分頁導航列（僅在有活動時顯示）
        if (_filteredEvents.isNotEmpty) _wPaginationBar(totalPages),
      ],
    );
  }

  Widget _wInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF003D79).withValues(alpha: 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.school_rounded,
                size: 20,
                color: Color(0xFF003D79),
              ),
              const SizedBox(width: 8),
              Text(
                app.calendarEventCounts(allEvents: _filteredEvents.length),
                style: const TextStyle(
                  color: Color(0xFF003D79),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              setState(() {
                _ascending = !_ascending;
                _currentPage = 1;
                CalendarParsing.sortEvents(_allEvents, ascending: _ascending);
                CalendarParsing.sortEvents(
                  _filteredEvents,
                  ascending: _ascending,
                );
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF003D79),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _ascending ?
                    app.calendarSortAscending : app.calendarSortDescending ,
                    style: const TextStyle(
                      color: Colors.white,
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

  Widget _wPaginationBar(int totalPages) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                backgroundColor: const Color(0xFF003D79),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: _currentPage > 1
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: Text(app.calendarPreviousPage),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF003D79).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                app.calendarPageFormat(
                    current: _currentPage, total: totalPages),
                style: const TextStyle(
                  color: Color(0xFF003D79),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003D79),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: _currentPage < totalPages
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: Text(app.calendarNextPage),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.length >= 8) {
      final String y = raw.substring(0, 4);
      final String m = raw.substring(4, 6);
      final String d = raw.substring(6, 8);
      return '$y-$m-$d';
    }
    return raw;
  }
}
