import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/models/calendar_event.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';
import 'package:nsysu_ap/utils/fetch_selcrs.dart';

void main() {
  group('CalendarParsing.parseEventDate', () {
    test('parses compact yyyyMMdd date', () {
      final DateTime? date = CalendarParsing.parseEventDate('20260801');
      expect(date, equals(DateTime(2026, 8)));
    });

    test('parses compact yyyyMMddTHHmmss datetime', () {
      final DateTime? date = CalendarParsing.parseEventDate('20260801T093000');
      expect(date, equals(DateTime(2026, 8, 1, 9, 30)));
    });

    test('parses ISO formatted yyyy-MM-dd date', () {
      final DateTime? date = CalendarParsing.parseEventDate('2026-08-01');
      expect(date, equals(DateTime(2026, 8)));
    });

    test('returns null for empty or unknown date', () {
      expect(CalendarParsing.parseEventDate(''), isNull);
      expect(CalendarParsing.parseEventDate('未知'), isNull);
    });
  });

  group('CalendarParsing.formatEventDate', () {
    test('formats compact yyyyMMdd to yyyy-MM-dd', () {
      expect(CalendarParsing.formatEventDate('20260801'), '2026-08-01');
    });

    test('formats already hyphenated date without corruption', () {
      expect(CalendarParsing.formatEventDate('2026-08-01'), '2026-08-01');
    });

    test('formats compact datetime to yyyy-MM-dd', () {
      expect(CalendarParsing.formatEventDate('20260801T143000'), '2026-08-01');
    });
  });

  group('CalendarParsing.formatEventDisplayDate', () {
    test(
      'displays single date for 1-day all-day event (DTEND is next day)',
      () {
      final CalendarEvent event = CalendarEvent(
        summary: '單日活動',
        dtstart: '20260801',
        dtend: '20260802',
      );
      expect(CalendarParsing.formatEventDisplayDate(event), '2026-08-01');
    });

    test('displays inclusive range for multi-day all-day event', () {
      final CalendarEvent event = CalendarEvent(
        summary: '多日活動',
        dtstart: '20260803',
        dtend: '20260815',
      );
      // DTEND 20260815 exclusive -> last included date is 2026-08-14
      expect(
        CalendarParsing.formatEventDisplayDate(event),
        '2026-08-03 ~ 2026-08-14',
      );
    });
  });

  group(
    'CalendarParsing.filterEventsByDateRange (RFC 5545 exclusive DTEND)',
    () {
      final CalendarEvent oneDayEvent = CalendarEvent(
        summary: '8/1 活動',
        dtstart: '20260801',
        dtend: '20260802',
      );
      final CalendarEvent multiDayEvent = CalendarEvent(
        summary: '8/3~8/14 活動',
        dtstart: '20260803',
        dtend: '20260815',
      );

      test('single-day event matches on its day', () {
        final List<CalendarEvent> filtered =
            CalendarParsing.filterEventsByDateRange(
          <CalendarEvent>[oneDayEvent],
          DateTimeRange(
            start: DateTime(2026, 8),
            end: DateTime(2026, 8),
          ),
        );
        expect(filtered.length, 1);
      });

      test('single-day event does not match next day (DTEND is exclusive)', () {
        final List<CalendarEvent> filtered =
            CalendarParsing.filterEventsByDateRange(
          <CalendarEvent>[oneDayEvent],
          DateTimeRange(
            start: DateTime(2026, 8, 2),
            end: DateTime(2026, 8, 5),
          ),
        );
        expect(filtered, isEmpty);
      });

      test('multi-day event matches intermediate and last included dates', () {
        final List<CalendarEvent> filtered10 =
            CalendarParsing.filterEventsByDateRange(
          <CalendarEvent>[multiDayEvent],
          DateTimeRange(
            start: DateTime(2026, 8, 10),
            end: DateTime(2026, 8, 10),
          ),
        );
        expect(filtered10.length, 1);

        final List<CalendarEvent> filtered14 =
            CalendarParsing.filterEventsByDateRange(
          <CalendarEvent>[multiDayEvent],
          DateTimeRange(
            start: DateTime(2026, 8, 14),
            end: DateTime(2026, 8, 14),
          ),
        );
        expect(filtered14.length, 1);
      });

      test('multi-day event does not match after last day', () {
        final List<CalendarEvent> filtered15 =
            CalendarParsing.filterEventsByDateRange(
          <CalendarEvent>[multiDayEvent],
          DateTimeRange(
            start: DateTime(2026, 8, 15),
            end: DateTime(2026, 8, 20),
          ),
        );
        expect(filtered15, isEmpty);
      });
    },
  );

  group('fetch_selcrs single-date parsing', () {
    test('parseCourseEvents leaves dtend empty for single date', () {
      const String html =
          '<!--newsbegin--><tr><td>選課公告</td><td>115.09.10</td></tr><!--newsend-->';
      final List<Map<String, String>> events = parseCourseEvents(html);
      expect(events.length, 1);
      expect(events[0]['dtstart'], '20260910T000000');
      expect(events[0]['dtend'], isEmpty);

      final String ics = generateIcsBlocks(events);
      expect(ics, contains('DTSTART:20260910T000000'));
      expect(ics.contains('DTEND:'), isFalse);
    });
  });
}
