import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:nsysu_ap/utils/app_localizations.dart';

List<Map<String, String>> parseCourseEvents(
  String html, {
  AppLocalizations? translations,
}) {
  final AppLocalizations tr = translations ?? app;
  final RegExp newsRegex =
      RegExp('<!--newsbegin-->(.*?)<!--newsend-->', dotAll: true);
  final RegExpMatch? newsMatch = newsRegex.firstMatch(html);

  final String contentToParse =
      newsMatch != null ? '<table>${newsMatch.group(1)}</table>' : html;

  final Document doc = html_parser.parse(contentToParse);
  final List<Element> rows = doc.querySelectorAll('tr');

  final List<Map<String, String>> result = <Map<String, String>>[];
  int index = 0;
  final String summaryPrefix = tr.calendarCourseSelectionPrefix;

  for (final Element row in rows) {
    final List<Element> tds = row.querySelectorAll('td');
    if (tds.length != 2) {
      continue;
    }

    final String name = tds[0].text.trim();
    final String timeRaw = tds[1]
        .text
        .replaceAll('\u00a0', ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceFirst(RegExp(r'^[：:\s]+'), '')
        .trim();

    if (name.isEmpty || timeRaw.isEmpty) {
      continue;
    }

    String dtstart = '';
    String dtend = '';

    if (timeRaw.contains('~')) {
      final List<String> parts = timeRaw.split('~');
      dtstart = parseRocDateToIcs(parts[0]);
      dtend = parseRocDateToIcs(parts[1]);
    } else {
      dtstart = parseRocDateToIcs(timeRaw);
      dtend = '';
    }

    if (dtstart.isEmpty) {
      continue;
    }

    index++;
    String timeSuffix = '';
    if (dtstart.contains('T') && dtstart.length >= 13) {
      final String hour = dtstart.substring(9, 11);
      final String minute = dtstart.substring(11, 13);
      final String startTime = '$hour:$minute';
      timeSuffix = tr.calendarCourseSelectionStartSuffix(time: startTime);
    }

    result.add(<String, String>{
      'index': index.toString().padLeft(2, '0'),
      'summary': '$summaryPrefix$name$timeSuffix',
      'rawName': name,
      'timeRaw': timeRaw,
      'dtstart': dtstart,
      'dtend': dtend,
    });
  }

  return result;
}

String parseRocDateToIcs(String raw) {
  final RegExp reg = RegExp(
    r'(\d{2,4})\.(\d{1,2})\.(\d{1,2})(?:[\(（](\d{1,2}):(\d{1,2})[\)）])?',
  );
  final RegExpMatch? m = reg.firstMatch(raw.trim());
  if (m == null) {
    return '';
  }

  int year = int.parse(m.group(1)!);
  if (year < 1900) {
    year += 1911;
  }
  final String month = m.group(2)!.padLeft(2, '0');
  final String day = m.group(3)!.padLeft(2, '0');

  final String hour = (m.group(4) ?? '00').padLeft(2, '0');
  final String minute = (m.group(5) ?? '00').padLeft(2, '0');

  return '$year$month${day}T$hour${minute}00';
}

String generateIcsBlocks(
  List<Map<String, String>> events, {
  AppLocalizations? translations,
}) {
  final AppLocalizations tr = translations ?? app;
  final StringBuffer buf = StringBuffer();
  final String datePart = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(RegExp('[-:]'), '')
      .split('.')
      .first;
  final String nowStamp = '${datePart}Z';
  final String descPrefix = tr.calendarCourseSelectionPeriod;

  for (final Map<String, String> e in events) {
    buf.writeln('BEGIN:VEVENT');
    buf.writeln('UID:selcrs-${e['dtstart']}-${e['index']}@nsysu.edu.tw');
    buf.writeln('DTSTAMP:$nowStamp');
    buf.writeln('DTSTART:${e['dtstart']}');
    final String dtend = e['dtend'] ?? '';
    if (dtend.isNotEmpty) {
      buf.writeln('DTEND:$dtend');
    }
    buf.writeln('SUMMARY:${e['summary']}');
    buf.writeln('DESCRIPTION:$descPrefix${e['timeRaw']}');
    buf.writeln('STATUS:CONFIRMED');
    buf.writeln('TRANSP:TRANSPARENT');
    buf.writeln('END:VEVENT');
  }

  return buf.toString();
}

String mergeIcsContent(String baseIcs, String newBlocks) {
  if (newBlocks.isEmpty || !baseIcs.contains('END:VCALENDAR')) {
    return baseIcs;
  }

  final RegExp oldEventsRegex = RegExp(
    r'BEGIN:VEVENT\r?\n(?:(?!BEGIN:VEVENT)[\s\S])*?'
    r'UID:selcrs-(?:(?!BEGIN:VEVENT)[\s\S])*?END:VEVENT\r?\n?',
  );
  final String cleaned = baseIcs.replaceAll(oldEventsRegex, '');

  const String endTag = 'END:VCALENDAR';
  final int endIdx = cleaned.lastIndexOf(endTag);
  if (endIdx == -1) {
    return baseIcs;
  }

  final String before = cleaned.substring(0, endIdx).trimRight();
  return '$before\n$newBlocks\n$endTag\n';
}
