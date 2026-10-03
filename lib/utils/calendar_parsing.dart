import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/fetch_selcrs.dart' as fs;

class CalendarParsing {
  static DateTime? parseEventDate(String raw) {
    if (raw.isEmpty || raw == '未知') {
      return null;
    }
    try {
      if (raw.length >= 8 && !raw.contains('-')) {
        final String clean = raw.replaceAll(RegExp('[^0-9T]'), '');
        final String y = clean.substring(0, 4);
        final String m = clean.substring(4, 6);
        final String d = clean.substring(6, 8);
        String formatted = '$y-$m-$d';
        if (clean.contains('T') && clean.length >= 15) {
          final String h = clean.substring(9, 11);
          final String min = clean.substring(11, 13);
          final String s = clean.substring(13, 15);
          formatted += 'T$h:$min:$s';
        }
        return DateTime.tryParse(formatted);
      }
    } catch (_) {}
    return DateTime.tryParse(raw);
  }

  static Future<List<CalendarEvent>?> getCleanEvents({
    bool ascending = true,
  }) async {
    try {
      final String icsUrl = await _getCalendarIcsUrl();
      final String content = await _downloadIcs(icsUrl);
      if (content.isEmpty) {
        return null;
      }
      final ICalendar icp = ICalendar.fromString(content);
      final List<Map<String, dynamic>> events = icp.data
          .where((Map<String, dynamic> item) => item['type'] == 'VEVENT')
          .toList();

      final List<CalendarEvent> result =
          events.map((Map<String, dynamic> event) {
        final dynamic summary = event['summary'] ?? '無標題';
        final Object? dtstart = event['dtstart'];
        final Object? dtend = event['dtend'];

        String startTime = '未知';
        if (dtstart is IcsDateTime) {
          startTime = dtstart.dt;
        } else if (dtstart != null) {
          startTime = dtstart.toString();
        }

        String endTime = '未知';
        if (dtend is IcsDateTime) {
          endTime = dtend.dt;
        } else if (dtend != null) {
          endTime = dtend.toString();
        }
        final CalendarEvent calendarEvent = CalendarEvent(
          summary: summary.toString(),
          dtstart: startTime,
          dtend: endTime,
        );
        return _normalizeEventDates(calendarEvent);
      }).toList();

      CalendarParsing.sortEvents(result, ascending: ascending);
      return result;
    } catch (e) {
      return null;
    }
  }

  static CalendarEvent _normalizeEventDates(CalendarEvent event) {
    final DateTime? start = parseEventDate(event.dtstart);
    if (start == null) {
      return event;
    }
    final DateTime? end = parseEventDate(event.dtend);
    final bool isOneDayOrLess =
        end == null || end.difference(start).inDays <= 1;
    if (isOneDayOrLess) {
      final RegExp matchRange = RegExp(
        r'\((\d{1,2})/(\d{1,2})[~～](\d{1,2})/(\d{1,2})\)',
      );
      final RegExpMatch? match = matchRange.firstMatch(event.summary);
      if (match != null) {
        final int sm = int.parse(match.group(1)!);
        final int em = int.parse(match.group(3)!);
        final int ed = int.parse(match.group(4)!);
        if (sm == start.month) {
          final int endYear = (em >= sm) ? start.year : start.year + 1;
          final DateTime endDate = DateTime(endYear, em, ed).add(
            const Duration(days: 1),
          );
          final String newEnd =
              '${endDate.year.toString().padLeft(4, '0')}'
              '${endDate.month.toString().padLeft(2, '0')}'
              '${endDate.day.toString().padLeft(2, '0')}';
          return CalendarEvent(
            summary: event.summary,
            dtstart: event.dtstart,
            dtend: newEnd,
          );
        }
      }
    }
    return event;
  }

  static void sortEvents(
      List<CalendarEvent> events,
      {bool ascending = true}){
    events.sort((CalendarEvent a, CalendarEvent b) {
      final DateTime? dateA = parseEventDate(a.dtstart);
      final DateTime? dateB = parseEventDate(b.dtstart);

      if (dateA == null && dateB == null) {
        return 0;
      }
      if (dateA == null) {
        return 1;
      }
      if (dateB == null) {
        return -1;
      }
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  static List<CalendarEvent> filterEvents(
      List<CalendarEvent> events, String keyword){
    final String cleanKeyword = keyword.trim().toLowerCase();
    if (cleanKeyword.isEmpty) return events;
    return events.where((CalendarEvent event){
      return event.summary.toLowerCase().contains(cleanKeyword);
    }).toList();
  }

  static List<CalendarEvent> filterEventsByDateRange(
    List<CalendarEvent> events,
    DateTimeRange range,
  ) {
    final DateTime rangeStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final DateTime rangeEndExclusive = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
    ).add(const Duration(days: 1));

    return events.where((CalendarEvent event) {
      final DateTime? start = parseEventDate(event.dtstart);
      if (start == null) {
        return false;
      }
      DateTime? end = parseEventDate(event.dtend);
      final bool isAllDay = !event.dtstart.contains('T');
      if (end == null || end == start) {
        end = isAllDay ? start.add(const Duration(days: 1)) : start;
      }
      return start.isBefore(rangeEndExclusive) && end.isAfter(rangeStart);
    }).toList();
  }

  static List<CalendarEvent> getPagedEvents(List<CalendarEvent> allEvents, {
    required int page,
    int pageSize = 10,
  }) {
    final int startIndex = (page - 1) * pageSize;
    if (startIndex < 0 || startIndex >= allEvents.length) {
      return <CalendarEvent>[];
    }
    int endIndex = startIndex + pageSize;
    if (endIndex > allEvents.length) {
      endIndex = allEvents.length;
    }
    return allEvents.sublist(startIndex, endIndex);
  }

  static List<CalendarEvent> filterAndSortEvents(
    List<CalendarEvent> events, {
    String keyword = '',
    DateTimeRange? dateRange,
    bool ascending = true,
  }) {
    List<CalendarEvent> results = events;
    if (keyword.trim().isNotEmpty) {
      results = filterEvents(results, keyword);
    }
    if (dateRange != null) {
      results = filterEventsByDateRange(results, dateRange);
    } else {
      results = List<CalendarEvent>.from(results);
    }
    sortEvents(results, ascending: ascending);
    return results;
  }

  static String formatEventDate(String raw) {
    if (raw.isEmpty || raw == '未知') {
      return raw;
    }
    final DateTime? parsed = parseEventDate(raw);
    if (parsed != null) {
      final String y = parsed.year.toString().padLeft(4, '0');
      final String m = parsed.month.toString().padLeft(2, '0');
      final String d = parsed.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return raw;
  }

  static String formatEventDisplayDate(CalendarEvent event) {
    final DateTime? start = parseEventDate(event.dtstart);
    if (start == null) {
      return event.dtstart;
    }
    final String startStr = formatEventDate(event.dtstart);
    final DateTime? end = parseEventDate(event.dtend);
    if (end == null || event.dtend.isEmpty || event.dtend == '未知') {
      return startStr;
    }

    final bool isAllDay = !event.dtstart.contains('T');
    if (isAllDay) {
      if (end.isBefore(start) || end.difference(start).inDays <= 1) {
        return startStr;
      }
      final DateTime lastIncluded = end.subtract(const Duration(days: 1));
      final String endStr = formatEventDate(
        '${lastIncluded.year.toString().padLeft(4, '0')}'
        '${lastIncluded.month.toString().padLeft(2, '0')}'
        '${lastIncluded.day.toString().padLeft(2, '0')}',
      );
      return '$startStr ~ $endStr';
    } else {
      final String endStr = formatEventDate(event.dtend);
      if (startStr == endStr) {
        return startStr;
      }
      return '$startStr ~ $endStr';
    }
  }

  static String formatDateRange(DateTimeRange range) {
    final String startM = range.start.month.toString().padLeft(2, '0');
    final String startD = range.start.day.toString().padLeft(2, '0');
    final String startStr = '${range.start.year}/$startM/$startD';
    final String endM = range.end.month.toString().padLeft(2, '0');
    final String endD = range.end.day.toString().padLeft(2, '0');
    final String endStr = '${range.end.year}/$endM/$endD';
    return '$startStr ~ $endStr';
  }

  static int getTotalPages(int totalCount, {int pageSize = 10}) {
    if (totalCount <= 0) {
      return 1;
    }
    return (totalCount / pageSize).ceil();
  }

  static Future<String> _getCalendarIcsUrl() async {
    String icsUrl = 'https://raw.githubusercontent.com/abc873693/NSYSU-AP/master/school_schedule_115.ics';

    if (FirebaseRemoteConfigUtils.isSupported) {
      try {
        final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetch();
        await remoteConfig.activate();
        final String scheduleUrl =
          LocaleSettings.currentLocale == AppLocale.zhHantTw ?
            Constants.scheduleIcsUrlZh : Constants.scheduleIcsUrlEn;
        final String remoteUrl = remoteConfig.getString(scheduleUrl);
        if (remoteUrl.isNotEmpty) {
          icsUrl = remoteUrl;
        }
      } catch (_) {}
    }
    return icsUrl;
  }

  static Future<String> _downloadIcs(String icsUrl) async {
    try {
      final Response<String> response = await Dio().get<String>(
        icsUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final String content = response.data ?? '';
      final String selcrsBlocks = await _fetchSelcrsIcsBlocks();
      return fs.mergeIcsContent(content, selcrsBlocks);
    } catch (_) {
      return '';
    }
  }

  static Future<String> _fetchSelcrsIcsBlocks() async {
    try {
      final bool isZh = LocaleSettings.currentLocale == AppLocale.zhHantTw;
      final String selcrsUrl = isZh
          ? 'https://selcrs.nsysu.edu.tw/'
          : 'https://selcrs.nsysu.edu.tw/smain.asp?eng=1';
      final Response<String> response = await Dio().get<String>(
        selcrsUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: <String, dynamic>{
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final String html = response.data ?? '';
      if (html.isEmpty) {
        return '';
      }
      final List<Map<String, String>> rawSelcrs = fs.parseCourseEvents(html);
      return fs.generateIcsBlocks(rawSelcrs);
    } catch (_) {
      return '';
    }
  }
}
