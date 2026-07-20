import 'package:ap_common_core/ap_common_core.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:nsysu_crawler/src/models/graduation_report_data.dart';
import 'package:nsysu_crawler/src/models/options.dart';
import 'package:nsysu_crawler/src/models/score_semester_data.dart';
import 'package:nsysu_crawler/src/models/student_leave.dart';
import 'package:nsysu_crawler/src/models/tuition_and_fees.dart';

/// Parse user info HTML page into [UserInfo].
UserInfo parseUserInfo(String html) {
  final dom.Document document = parse(html);
  final List<dom.Element> tdDoc = document.getElementsByTagName('td');
  if (tdDoc.isEmpty) return UserInfo.empty();
  return UserInfo(
    department: tdDoc[1].text,
    className: tdDoc[3].text.replaceAll(' ', ''),
    id: tdDoc[5].text,
    name: tdDoc[7].text,
    email: tdDoc[9].text,
  );
}

StudentLeaveConfirmation parseStudentLeaveConfirmation(String html) {
  final dom.Document document = parse(html, encoding: 'BIG-5');
  document
      .querySelectorAll('script, style, noscript')
      .forEach((dom.Element element) => element.remove());

  final List<StudentLeaveConfirmationSection> sections =
      <StudentLeaveConfirmationSection>[];
  final Set<String> seenFields = <String>{};

  for (final dom.Element table in document.getElementsByTagName('table')) {
    final String tableTitle = _cleanText(
      table.getElementsByTagName('caption').isNotEmpty
          ? table.getElementsByTagName('caption').first.text
          : '',
    );
    String currentTitle = tableTitle;
    final List<StudentLeaveConfirmationField> fields =
        <StudentLeaveConfirmationField>[];
    List<String>? courseHeaderLabels;
    int courseRowCount = 0;

    for (final dom.Element row in table.getElementsByTagName('tr')) {
      final List<String> cells = row.children
          .where((dom.Element cell) {
            final String tag = cell.localName ?? '';
            return tag == 'td' || tag == 'th';
          })
          .map((dom.Element cell) => _cleanText(cell.text))
          .where((String text) => text.isNotEmpty)
          .toList();
      if (cells.isEmpty) continue;
      if (cells.length == 1) {
        if (currentTitle.isEmpty || _isLeaveCourseSection(cells.first)) {
          currentTitle = cells.first;
        }
        continue;
      }
      if (_isLeaveCourseSection(currentTitle)) {
        if (_isLeaveCourseHeader(cells)) {
          courseHeaderLabels = cells.map(_cleanLabel).toList();
          continue;
        }
        final List<String>? labels = courseHeaderLabels;
        if (labels != null && cells.length == labels.length) {
          for (int i = 0; i < labels.length; i++) {
            final String label = labels[i];
            final String value = cells[i].isEmpty ? '空' : cells[i];
            final String key = '$currentTitle:$label=$value';
            if (!seenFields.add(key)) continue;
            fields.add(
              StudentLeaveConfirmationField(label: label, value: value),
            );
          }
          courseRowCount++;
          continue;
        }
      }
      for (int i = 0; i + 1 < cells.length; i += 2) {
        final String label = _cleanLabel(cells[i]);
        final String value = cells[i + 1];
        if (label.isEmpty || value.isEmpty || label == value) continue;
        final String key = '$label=$value';
        if (!seenFields.add(key)) continue;
        fields.add(StudentLeaveConfirmationField(label: label, value: value));
      }
    }

    if (courseHeaderLabels != null && courseRowCount == 0) {
      for (final String label in courseHeaderLabels) {
        final String key = '$currentTitle:$label=空';
        if (!seenFields.add(key)) continue;
        fields.add(StudentLeaveConfirmationField(label: label, value: '空'));
      }
    }

    if (fields.isNotEmpty) {
      sections.add(
        StudentLeaveConfirmationSection(title: currentTitle, fields: fields),
      );
    }
  }

  final List<String> lines = _extractTextLines(document.body?.text ?? '');
  final List<String> messages = lines
      .where(
        (String line) =>
            line.contains('成功') ||
            line.contains('完成') ||
            line.contains('確認') ||
            line.contains('假單') ||
            line.contains('錯誤') ||
            line.contains('失敗'),
      )
      .take(6)
      .toList();
  return StudentLeaveConfirmation(
    sections: sections,
    messages: messages,
    rawText: lines.join('\n'),
    noticeLines: _extractLeaveNoticeLines(document),
  );
}

List<StudentLeaveRecord> parseStudentLeaveRecords(String html) {
  final dom.Document document = parse(html, encoding: 'BIG-5');
  final List<StudentLeaveRecord> records = <StudentLeaveRecord>[];
  for (final dom.Element table in document.getElementsByTagName('table')) {
    final List<dom.Element> rows = table.getElementsByTagName('tr');
    if (rows.isEmpty || !rows.first.text.contains('請假單編號')) continue;
    for (int i = 1; i < rows.length; i++) {
      final List<dom.Element> cells = rows[i].getElementsByTagName('td');
      if (cells.length < 10) continue;
      final dom.Element proofCell = cells[8];
      final dom.Element maintenanceCell = cells[9];
      records.add(
        StudentLeaveRecord(
          number: _cleanText(cells[0].text),
          schoolYear: _cleanText(cells[1].text),
          semester: _cleanText(cells[2].text),
          category: _cleanText(cells[3].text),
          dateRange: _cleanText(cells[4].text),
          tutorStatus: _cleanText(cells[5].text),
          chairStatus: _cleanText(cells[6].text),
          instructorStatus: _cleanText(cells[7].text),
          proofText: _cleanText(proofCell.text),
          proofUrl: _proofHref(proofCell),
          printUrl: _hrefByText(maintenanceCell, '列印'),
        ),
      );
    }
  }
  return records;
}

StudentLeaveConfirmForm? parseStudentLeaveConfirmForm(String html) {
  final dom.Document document = parse(html, encoding: 'BIG-5');
  final List<dom.Element> forms = document.getElementsByTagName('form');
  for (final dom.Element form in forms) {
    final String action = form.attributes['action'] ?? '';
    if (action.contains('SLAMS_stuLeave_add_act.php')) {
      return StudentLeaveConfirmForm(
        action: action,
        fields: _extractFormFields(form),
      );
    }
  }
  for (final dom.Element form in forms) {
    final Map<String, String> fields = _extractFormFields(form);
    if (<String>{
      'Lclass',
      'sub_Lclass',
      's_date',
      's_time',
      'e_date',
      'e_time',
    }.every(fields.containsKey)) {
      return StudentLeaveConfirmForm(
        action: form.attributes['action'] ?? '',
        fields: fields,
      );
    }
  }
  return null;
}

/// Parse course semester data HTML into [SemesterData].
SemesterData parseCourseSemesterData(
  String html, {
  required Semester defaultSemester,
}) {
  final dom.Document document = parse(html);
  final List<dom.Element> optionElements = document.getElementsByTagName(
    'option',
  );
  final List<Semester> semesters = <Semester>[];
  for (int i = 0; i < optionElements.length; i++) {
    semesters.add(
      Semester(
        text: optionElements[i].text,
        year: optionElements[i].attributes['value']!.substring(0, 3),
        value: optionElements[i].attributes['value']!.substring(3),
      ),
    );
  }
  return SemesterData(data: semesters, defaultSemester: defaultSemester);
}

/// Parse course data HTML into [CourseData].
///
/// `languageCode` selects which title to pick when a course's `<a>` element
/// embeds both Chinese and English titles separated by `<br>`. Pass the raw
/// locale code (e.g. `'zh'`, `'en'`).
CourseData parseCourseData(
  String html, {
  required TimeCodeConfig timeCodeConfig,
  required String languageCode,
}) {
  final dom.Document document = parse(html);
  final List<dom.Element> trDoc = document.getElementsByTagName('tr');
  final List<Course> courses = <Course>[];

  for (int i = 1; i < trDoc.length; i++) {
    final List<dom.Element> tdDoc = trDoc[i].getElementsByTagName('td');
    final dom.Element titleElement = tdDoc[4].getElementsByTagName('a').first;
    final List<String> titles = titleElement.innerHtml.split('<br>');
    String title = titleElement.text;
    if (titles.length >= 2) {
      title = languageCode.startsWith('en') ? titles[1] : titles[0];
    }
    final String instructors = tdDoc[8].text;
    final Location location = Location(building: '', room: tdDoc[9].text);
    final List<SectionTime> times = <SectionTime>[];
    for (int j = 10; j < tdDoc.length; j++) {
      if (tdDoc[j].text.isNotEmpty) {
        final List<String> sections = tdDoc[j].text.split('');
        if (sections.isNotEmpty && sections[0] != ' ') {
          for (final String section in sections) {
            final int index = timeCodeConfig.indexOf(section);
            if (index == -1) continue;
            times.add(SectionTime(weekday: j - 9, index: index));
          }
        }
      }
    }
    courses.add(
      Course(
        code: tdDoc[2].text,
        className: '${tdDoc[1].text} ${tdDoc[3].text}',
        title: title,
        units: tdDoc[5].text,
        required: tdDoc[7].text.length == 1
            ? '${tdDoc[7].text}修'
            : tdDoc[7].text,
        location: location,
        instructors: <String>[instructors],
        times: times,
      ),
    );
  }
  return CourseData(courses: courses, timeCodes: timeCodeConfig.timeCodes);
}

/// Parse score semester data HTML into [ScoreSemesterData].
ScoreSemesterData parseScoreSemesterData(String html) {
  final dom.Document document = parse(html, encoding: 'BIG-5');
  final List<dom.Element> selectDoc = document.getElementsByTagName('select');
  final ScoreSemesterData data = ScoreSemesterData(
    semesters: <SemesterOptions>[],
    years: <SemesterOptions>[],
  );
  if (selectDoc.length >= 2) {
    List<dom.Element> options = selectDoc[0].getElementsByTagName('option');
    for (int i = 0; i < options.length; i++) {
      data.years.add(
        SemesterOptions(
          text: options[i].text,
          value: options[i].attributes['value']!,
        ),
      );
      if (options[i].attributes['selected'] != null) {
        data.selectYearsIndex = i;
      }
    }
    options = selectDoc[1].getElementsByTagName('option');
    for (int i = 0; i < options.length; i++) {
      data.semesters.add(
        SemesterOptions(
          text: options[i].text,
          value: options[i].attributes['value']!,
        ),
      );
      if (options[i].attributes['selected'] != null) {
        data.selectSemesterIndex = i;
      }
    }
  }
  return data;
}

/// Result of parsing score HTML — scores list, detail, and the list of
/// course numbers whose `finalScore` is missing or `'--'`. The caller
/// decides whether to do an async pre-score lookup for each missing
/// course before composing the final [ScoreData].
class ParsedScoreResult {
  const ParsedScoreResult({
    required this.scores,
    required this.detail,
    this.missingFinalScoreCourseNumbers = const <String?>[],
  });

  final List<Score> scores;
  final Detail detail;
  final List<String?> missingFinalScoreCourseNumbers;
}

/// Parse score data HTML into [ParsedScoreResult]. Pure: does not perform
/// the pre-score lookup.
ParsedScoreResult parseScoreData(String html) {
  final dom.Document document = parse(html, encoding: 'BIG-5');
  final List<Score> list = <Score>[];
  Detail detail = const Detail();
  final List<String?> missingCourseNumbers = <String?>[];
  final List<dom.Element> tableDoc = document.getElementsByTagName('tbody');
  if (tableDoc.length >= 2) {
    if (tableDoc.length == 3) {
      final List<dom.Element> fontDoc = tableDoc[1].getElementsByTagName(
        'font',
      );
      double percentage =
          double.parse(fontDoc[4].text.split('：')[1]) /
          double.parse(fontDoc[5].text.split('：')[1]);
      percentage = 1.0 - percentage;
      percentage *= 100;
      detail = Detail(
        creditTaken: double.parse(fontDoc[0].text.split('：')[1]),
        creditEarned: double.parse(fontDoc[1].text.split('：')[1]),
        average: double.parse(fontDoc[2].text.split('：')[1]),
        classRank:
            '${fontDoc[4].text.split('：')[1]}/${fontDoc[5].text.split('：')[1]}',
        classPercentage: double.parse(percentage.toStringAsFixed(2)),
      );
    }
    final List<dom.Element> trDoc = tableDoc[0].getElementsByTagName('tr');
    for (int i = 0; i < trDoc.length; i++) {
      final List<dom.Element> fontDoc = trDoc[i].getElementsByTagName('font');
      if (fontDoc.length != 6) continue;
      if (i != 0) {
        final Score score = Score(
          courseNumber: fontDoc[2].text.substring(
            1,
            fontDoc[2].text.length - 1,
          ),
          title: fontDoc[3].text,
          middleScore: fontDoc[4].text,
          finalScore: fontDoc[5].text,
          units: '',
          hours: '',
          required: '',
          at: '',
          generalScore: '',
          semesterScore: '',
          remark: '',
        );
        if (score.finalScore == null || (score.finalScore ?? '') == '--') {
          missingCourseNumbers.add(score.courseNumber);
        }
        list.add(score);
      }
    }
  }
  return ParsedScoreResult(
    scores: list,
    detail: detail,
    missingFinalScoreCourseNumbers: missingCourseNumbers,
  );
}

/// Inspect a list of [Score]s and decide whether the transcript uses
/// letter grades (e.g. `A+`, `B`) instead of numeric scores. Used by the
/// helper to pick the [ScoreType] without re-walking the HTML.
ScoreType resolveScoreType(List<Score> scores) {
  final bool hasLetterGrades = scores.any((Score score) {
    final String? s = score.finalScore;
    if (s == null || s.isEmpty || s == '--') return false;
    return double.tryParse(s) == null;
  });
  return hasLetterGrades ? ScoreType.gradePoint : ScoreType.numeric;
}

String _cleanLabel(String text) {
  return _cleanText(text).replaceAll(RegExp(r'[:：]\s*$'), '');
}

bool _isLeaveCourseSection(String title) {
  return title.contains('請假期間課程名稱') || title.toLowerCase().contains('course');
}

bool _isLeaveCourseHeader(List<String> cells) {
  return cells.length == 4 &&
      cells[0].contains('日期') &&
      cells[1].contains('節次') &&
      cells[2].contains('任課教師') &&
      cells[3].contains('課目名稱');
}

String _cleanText(String text) {
  return text.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _extractTextLines(String text) {
  final List<String> lines = text
      .replaceAll('\u00a0', ' ')
      .split(RegExp(r'[\r\n]+'))
      .map(_cleanText)
      .where((String line) => line.isNotEmpty)
      .toList();
  final Set<String> seen = <String>{};
  return <String>[
    for (final String line in lines)
      if (seen.add(line)) line,
  ];
}

List<String> _extractLeaveNoticeLines(dom.Document document) {
  List<dom.Element> candidates = document
      .querySelectorAll('td, div, font, span, p')
      .where((dom.Element element) => element.text.contains('請同學注意以下說明'))
      .toList();
  if (candidates.isEmpty) {
    candidates = document
        .querySelectorAll('*')
        .where((dom.Element element) => element.text.contains('請同學注意以下說明'))
        .toList();
  }
  if (candidates.isEmpty) return const <String>[];

  candidates.sort(
    (dom.Element a, dom.Element b) =>
        _cleanText(a.text).length.compareTo(_cleanText(b.text).length),
  );
  final String html = candidates.first.innerHtml.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
  final List<String> lines = _extractTextLines(parseFragment(html).text ?? '');
  final int startIndex = lines.indexWhere(
    (String line) => line.contains('請同學注意以下說明'),
  );
  if (startIndex == -1) return const <String>[];

  final List<String> noticeLines = <String>[lines[startIndex]];
  for (final String line in lines.skip(startIndex + 1)) {
    if (!RegExp(r'^\(\d+\)').hasMatch(line)) break;
    noticeLines.add(line);
  }
  return noticeLines;
}

Map<String, String> _extractFormFields(dom.Element form) {
  final Map<String, String> fields = <String, String>{};
  for (final dom.Element input in form.getElementsByTagName('input')) {
    final String? name = input.attributes['name'];
    if (name == null || name.isEmpty) continue;
    fields[name] = input.attributes['value'] ?? '';
  }
  for (final dom.Element textarea in form.getElementsByTagName('textarea')) {
    final String? name = textarea.attributes['name'];
    if (name == null || name.isEmpty) continue;
    fields[name] = textarea.text;
  }
  for (final dom.Element select in form.getElementsByTagName('select')) {
    final String? name = select.attributes['name'];
    if (name == null || name.isEmpty) continue;
    final List<dom.Element> selectedOptions = select
        .getElementsByTagName('option')
        .where((dom.Element option) => option.attributes['selected'] != null)
        .toList();
    final List<dom.Element> options = select.getElementsByTagName('option');
    final dom.Element? option = selectedOptions.isNotEmpty
        ? selectedOptions.first
        : options.isNotEmpty
        ? options.first
        : null;
    fields[name] = option?.attributes['value'] ?? option?.text ?? '';
  }
  return fields;
}

String? _firstHref(dom.Element element) {
  final List<dom.Element> links = element.getElementsByTagName('a');
  if (links.isEmpty) return null;
  return links.first.attributes['href'];
}

String? _proofHref(dom.Element element) {
  final String text = _cleanText(element.text);
  if (text == '無' || text.isEmpty) return null;
  return _resolveSisUrl(_firstHref(element));
}

String? _hrefByText(dom.Element element, String text) {
  for (final dom.Element link in element.getElementsByTagName('a')) {
    if (link.text.contains(text)) {
      return _resolveSisUrl(link.attributes['href']);
    }
  }
  return null;
}

String? _resolveSisUrl(String? href) {
  if (href == null || href.isEmpty) return null;
  if (href.startsWith('http')) return href;
  return Uri.parse('https://sis.nsysu.edu.tw/SLAMS/').resolve(href).toString();
}

/// Parse graduation report HTML into [GraduationReportData].
/// Returns null when the page does not contain a valid report (e.g.
/// freshman / non-degree student).
GraduationReportData? parseGraduationReport(String html) {
  final dom.Document document = parse(html);
  final List<dom.Element> tableDoc = document.getElementsByTagName('tbody');
  if (tableDoc.length < 2) return null;

  final GraduationReportData data = GraduationReportData(
    missingRequiredCourse: <MissingRequiredCourse>[],
    generalEducationCourse: <GeneralEducationCourse>[],
    otherEducationsCourse: <OtherEducationsCourse>[],
  );

  for (int i = 0; i < tableDoc.length; i++) {
    final List<dom.Element> trDoc = tableDoc[i].getElementsByTagName('tr');
    if (i == 4) {
      if (trDoc.length > 3) {
        for (int j = 2; j < trDoc.length; j++) {
          final List<dom.Element> tdDoc = trDoc[j].getElementsByTagName('td');
          if (tdDoc.length == 3) {
            data.missingRequiredCourse.add(
              MissingRequiredCourse(
                name: tdDoc[0].text,
                credit: tdDoc[1].text,
                description: tdDoc[2].text,
              ),
            );
          }
        }
      }
      if (trDoc.isNotEmpty) {
        data.missingRequiredCoursesCredit = trDoc.last.text.replaceAll(
          RegExp(r'[※\n]'),
          '',
        );
      }
    } else if (i == 5) {
      for (int j = 2; j < trDoc.length; j++) {
        final List<dom.Element> tdDoc = trDoc[j].getElementsByTagName('td');
        int base = 0;
        if (tdDoc.length == 7) {
          base = 1;
          data.generalEducationCourse.add(
            GeneralEducationCourse(
              type: tdDoc[0].text,
              generalEducationItem: <GeneralEducationItem>[],
            ),
          );
        }
        if (tdDoc.length > 5) {
          data.generalEducationCourse.last.generalEducationItem!.add(
            GeneralEducationItem(
              name: tdDoc[base + 0].text,
              credit: tdDoc[base + 1].text,
              check: tdDoc[base + 2].text,
              actualCredits: tdDoc[base + 3].text,
              totalCredits: tdDoc[base + 4].text,
              practiceSituation: tdDoc[base + 5].text,
            ),
          );
        }
      }
      if (data.generalEducationCourse.isNotEmpty) {
        data.generalEducationCourseDescription = trDoc.last.text.replaceAll(
          RegExp(r'[※\n]'),
          '',
        );
      }
    } else if (i == 6) {
      if (trDoc.length > 3) {
        for (int j = 2; j < trDoc.length; j++) {
          final List<dom.Element> tdDoc = trDoc[j].getElementsByTagName('td');
          if (tdDoc.length == 3) {
            data.otherEducationsCourse.add(
              OtherEducationsCourse(
                name: tdDoc[0].text,
                semester: tdDoc[1].text,
                credit: tdDoc[2].text,
              ),
            );
          }
        }
      }
      if (trDoc.isNotEmpty) {
        data.otherEducationsCourseCredit = trDoc.last.text.replaceAll(
          RegExp(r'[※\n]'),
          '',
        );
      }
    }
  }

  final List<dom.Element> tdDoc = document.getElementsByTagName('td');
  for (int i = 0; i < tdDoc.length; i++) {
    if (tdDoc[i].text.contains('目前累計學分數')) {
      data.totalDescription = tdDoc[i].text.replaceAll(RegExp(r'[※\n]'), '');
    }
  }

  return data;
}

/// Parse tuition and fees HTML into a list of [TuitionAndFees].
/// Returns null when the page reports no records.
List<TuitionAndFees>? parseTuitionData(String html) {
  if (html.contains('沒有合乎查詢條件的資料')) return null;

  final dom.Document document = parse(html, encoding: 'BIG-5');
  final List<dom.Element> tbody = document.getElementsByTagName('tbody');
  final List<TuitionAndFees> list = <TuitionAndFees>[];
  final List<dom.Element> trElements = tbody[1].getElementsByTagName('tr');
  for (int i = 1; i < trElements.length; i++) {
    final List<dom.Element> tdDoc = trElements[i].getElementsByTagName('td');
    final List<dom.Element> aTag = tdDoc[4].getElementsByTagName('a');
    String? serialNumber;
    if (aTag.isNotEmpty) {
      serialNumber = aTag[0].attributes['onclick']!
          .split("javascript:window.location.href='")
          .last;
      serialNumber = serialNumber.substring(0, serialNumber.length - 1);
    }
    String paymentStatus = '';
    String paymentStatusEn = '';
    for (final int charCode in tdDoc[2].text.codeUnits) {
      if (charCode < 200) {
        if (charCode == 32) {
          paymentStatusEn += '\n';
        } else {
          paymentStatusEn += String.fromCharCode(charCode);
        }
      } else {
        paymentStatus += String.fromCharCode(charCode);
      }
    }
    final String titleEN = tdDoc[0].getElementsByTagName('span')[0].text;
    list.add(
      TuitionAndFees(
        titleZH: tdDoc[0].text.replaceAll(titleEN, ''),
        titleEN: titleEN,
        amount: tdDoc[1].text,
        paymentStatusZH: paymentStatus,
        paymentStatusEN: paymentStatusEn,
        dateOfPayment: tdDoc[3].text,
        serialNumber: serialNumber ?? '',
      ),
    );
  }
  return list.reversed.toList();
}
