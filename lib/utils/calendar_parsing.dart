import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/fetch_selcrs.dart' as fs;

enum CalendarEventCategory { general, courseSelection, holiday, examination }

class CalendarParsing {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime? eventEndDateInclusive(CalendarEvent event) {
    final DateTime? start = parseEventDate(event.dtstart);
    final DateTime? end = parseEventDate(event.dtend);
    if (start == null || end == null) return null;
    final DateTime inclusiveEnd = event.dtend.contains('T')
        ? dateOnly(end)
        : dateOnly(end.subtract(const Duration(days: 1)));
    return inclusiveEnd.isBefore(dateOnly(start))
        ? dateOnly(start)
        : inclusiveEnd;
  }

  static bool eventCoversDate(CalendarEvent event, DateTime date) {
    final DateTime? start = parseEventDate(event.dtstart);
    final DateTime? end = eventEndDateInclusive(event);
    if (start == null || end == null) return false;
    final DateTime day = dateOnly(date);
    return !day.isBefore(dateOnly(start)) && !day.isAfter(end);
  }

  static CalendarEventCategory classifyEventSummary(String summary) {
    final String normalized = summary.trim().toLowerCase();

    if (normalized.startsWith('【選課】') ||
        normalized.startsWith('[course selection]') ||
        normalized.startsWith('【履修登録】')) {
      return CalendarEventCategory.courseSelection;
    }
    if (normalized.contains('放假') ||
        normalized.contains('補假') ||
        normalized.contains('暑假開始') ||
        normalized.contains('寒假開始') ||
        normalized.contains('national holiday') ||
        normalized.contains('make-up day') ||
        normalized.contains('compensatory holiday') ||
        normalized.contains('summer vacation begins') ||
        normalized.contains('winter vacation begins')) {
      return CalendarEventCategory.holiday;
    }
    if (normalized.contains('期中考試') ||
        normalized.contains('期末考試') ||
        normalized.contains('midterm examination') ||
        normalized.contains('final examination')) {
      return CalendarEventCategory.examination;
    }
    return CalendarEventCategory.general;
  }

  static DateTime? parseEventDate(String raw) {
    if (raw.isEmpty || raw == '未知') {
      return null;
    }
    try {
      if (raw.length >= 8 && !raw.contains('-')) {
        final String clean = raw.replaceAll(RegExp('[^0-9TZ]'), '');
        final String y = clean.substring(0, 4);
        final String m = clean.substring(4, 6);
        final String d = clean.substring(6, 8);
        String formatted = '$y-$m-$d';
        if (clean.contains('T') && clean.length >= 15) {
          final String h = clean.substring(9, 11);
          final String min = clean.substring(11, 13);
          final String s = clean.substring(13, 15);
          formatted += 'T$h:$min:$s';
          if (clean.endsWith('Z')) {
            formatted += 'Z';
          }
        }
        return DateTime.tryParse(formatted)?.toLocal();
      }
    } catch (_) {}
    return DateTime.tryParse(raw)?.toLocal();
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

      final List<CalendarEvent> result = events.map((
        Map<String, dynamic> event,
      ) {
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
          final DateTime endDate = DateTime(
            endYear,
            em,
            ed,
          ).add(const Duration(days: 1));
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

  static void sortEvents(List<CalendarEvent> events, {bool ascending = true}) {
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
    List<CalendarEvent> events,
    String keyword,
  ) {
    final String cleanKeyword = keyword.trim().toLowerCase();
    if (cleanKeyword.isEmpty) return events;
    return events.where((CalendarEvent event) {
      return event.summary.toLowerCase().contains(cleanKeyword);
    }).toList();
  }

  static List<CalendarEvent> filterAndSortEvents(
    List<CalendarEvent> events, {
    String keyword = '',
    bool ascending = true,
  }) {
    final List<CalendarEvent> results = filterEvents(
      List<CalendarEvent>.from(events),
      keyword,
    );
    sortEvents(results, ascending: ascending);
    return results;
  }

  static Future<String> _getCalendarIcsUrl() async {
    String icsUrl =
        'https://raw.githubusercontent.com/nsysu-code-club/NSYSU-AP/master/school_schedule_115.ics';

    if (FirebaseRemoteConfigUtils.isSupported) {
      try {
        final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetch();
        await remoteConfig.activate();
        final String scheduleUrl =
            LocaleSettings.currentLocale == AppLocale.zhHantTw
            ? Constants.scheduleIcsUrlZh
            : Constants.scheduleIcsUrlEn;
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
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
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
