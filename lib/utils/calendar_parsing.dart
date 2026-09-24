import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/calendar_event.dart';

class CalendarParsing {
  static DateTime? parseEventDate(String raw) {
    if (raw.isEmpty || raw == '未知') {
      return null;
    }
    try {
      // if contains -, then jump to the last part
      if (raw.length >= 8 && !raw.contains('-')) {
        final String clean = raw.replaceAll(RegExp('[^0-9T]'), '');
        // 20260901
        final String y = clean.substring(0, 4); // 2026
        final String m = clean.substring(4, 6); // 09
        final String d = clean.substring(6, 8); // 01
        String formatted = '$y-$m-$d'; // 2026-09-01
        if (clean.contains('T') && clean.length >= 15) { // if it contains h:m:s
          final String h = clean.substring(9, 11);
          final String min = clean.substring(11, 13);
          final String s = clean.substring(13, 15);
          formatted += 'T$h:$min:$s';
        }
        // parse formatString to DateTime format
        return DateTime.tryParse(formatted);
      }
    } catch (_) {}
    return DateTime.tryParse(raw);
  }

  // Dealing with single raw String of DateTime
  static Future<List<CalendarEvent>> getCleanEvents({
    bool ascending = true
  }) async {
    try {
      final String icsUrl = await _getCalendarIcsUrl();
      final String content = await _downloadIcs(icsUrl);
      final ICalendar icp = ICalendar.fromString(content);
      final List<Map<String, dynamic>> events = icp.data
          .where((Map<String, dynamic> item) => item['type'] == 'VEVENT')
          .toList();

      final List<CalendarEvent> result =
      // like Java map stream
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
            dtend: endTime
        );
        return calendarEvent;
      }).toList();

      return CalendarParsing.sortEvents(result, ascending: ascending);
    } catch (e) {
      return <CalendarEvent>[];
    }
  }

  static List<CalendarEvent> sortEvents(
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
      // Using comparator to compare two DateTime
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return events;
  }

  static List<CalendarEvent> filterEvents(
      List<CalendarEvent> events, String keyword){
    final String cleanKeyword = keyword.trim().toLowerCase();
    if (cleanKeyword.isEmpty) return events;
    return events.where((CalendarEvent event){
      return event.summary.toLowerCase().contains(cleanKeyword);
    }).toList();
  }

  // Split events base on the pageNumber
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

  static Future<String> _getCalendarIcsUrl() async {
    String icsUrl = 'https://raw.githubusercontent.com/abc873693/NSYSU-AP/master/school_schedule_115.ics';

    if (FirebaseRemoteConfigUtils.isSupported) {
      try {
        final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetch();
        await remoteConfig.activate();
        final String remoteUrl = remoteConfig.getString(
            Constants.scheduleIcsUrl);
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
          options: Options(responseType: ResponseType.plain)
      );

      return response.data ?? '';
    } catch (_) {
      return '';
    }
  }
}
