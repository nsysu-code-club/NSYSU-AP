import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/calendar_parsing.dart';

void main() {
  group('CalendarParsing.classifyEventSummary', () {
    test('recognizes only generated course-selection prefixes', () {
      expect(
        CalendarParsing.classifyEventSummary('【選課】課程初選 (09:00)'),
        CalendarEventCategory.courseSelection,
      );
      expect(
        CalendarParsing.classifyEventSummary(
          '[Course Selection] Add/drop round 1',
        ),
        CalendarEventCategory.courseSelection,
      );
      expect(
        CalendarParsing.classifyEventSummary('【履修登録】履修登録期間'),
        CalendarEventCategory.courseSelection,
      );
      expect(
        CalendarParsing.classifyEventSummary('導師輔導學生選課'),
        CalendarEventCategory.general,
      );
      expect(
        CalendarParsing.classifyEventSummary(
          'Application for Exceptional Circumstances in Course Selection',
        ),
        CalendarEventCategory.general,
      );
    });

    test('recognizes holidays and vacation starts without matching exams', () {
      for (final String summary in <String>[
        '教師節放假',
        '國慶紀念日補假',
        '暑假開始',
        '寒假開始',
        'Dragon Boat Festival (National Holiday), no classes',
        "Children's Day (National Holiday)(make-up day)",
        'Compensatory holiday for the first day of Lunar New Year',
        'Summer vacation begins',
        'Winter vacation begins',
      ]) {
        expect(
          CalendarParsing.classifyEventSummary(summary),
          CalendarEventCategory.holiday,
        );
      }
      expect(
        CalendarParsing.classifyEventSummary('前一學期學期考試請假學生補考'),
        CalendarEventCategory.general,
      );
    });

    test('recognizes midterm and final exam periods only', () {
      for (final String summary in <String>[
        '期中考試(授課教師另有規定者，依其規定)',
        '期末考試開始',
        'Midterm examinations',
        'Final examinations ends',
      ]) {
        expect(
          CalendarParsing.classifyEventSummary(summary),
          CalendarEventCategory.examination,
        );
      }
      expect(
        CalendarParsing.classifyEventSummary('學位考試結束'),
        CalendarEventCategory.general,
      );
      expect(
        CalendarParsing.classifyEventSummary('Faculty submit final grades'),
        CalendarEventCategory.general,
      );
    });
  });
}
