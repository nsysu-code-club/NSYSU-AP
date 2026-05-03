import 'package:ap_common_core/ap_common_core.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:nsysu_crawler/src/models/graduation_report_data.dart';
import 'package:nsysu_crawler/src/models/options.dart';
import 'package:nsysu_crawler/src/models/score_semester_data.dart';
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

/// Parse course semester data HTML into [SemesterData].
SemesterData parseCourseSemesterData(
  String html, {
  required Semester defaultSemester,
}) {
  final dom.Document document = parse(html);
  final List<dom.Element> optionElements =
      document.getElementsByTagName('option');
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
  return SemesterData(
    data: semesters,
    defaultSemester: defaultSemester,
  );
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
    final dom.Element titleElement = tdDoc[4]
        .getElementsByTagName('a')
        .first;
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
  return CourseData(
    courses: courses,
    timeCodes: timeCodeConfig.timeCodes,
  );
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
  Detail detail = Detail();
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
