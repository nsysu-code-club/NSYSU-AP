import 'dart:ui';

import 'package:ap_common/ap_common.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/options.dart';
import 'package:nsysu_ap/models/pre_score.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';

class SelcrsParser {
  UserInfo userInfo(String text) {
    final dom.Document document = parse(text);
    final List<dom.Element> tdDoc = document.getElementsByTagName('td');
    UserInfo userInfo = UserInfo.empty();
    if (tdDoc.isNotEmpty) {
      userInfo = UserInfo(
        department: tdDoc[1].text,
        className: tdDoc[3].text.replaceAll(' ', ''),
        id: tdDoc[5].text,
        name: tdDoc[7].text,
        email: tdDoc[9].text,
      );
    }
    return userInfo;
  }

  SemesterData courseSemesterData(
    Semester defaultSemester,
    String text,
  ) {
    final dom.Document document = parse(text);
    final List<dom.Element> options = document.getElementsByTagName('option');
    final SemesterData courseSemesterData = SemesterData(
      data: <Semester>[],
      defaultSemester: defaultSemester,
    );
    for (int i = 0; i < options.length; i++) {
      //print('$i => ${tdDoc[i].text}');
      courseSemesterData.data.add(
        Semester(
          text: options[i].text,
          year: options[i].attributes['value']!.substring(0, 3),
          value: options[i].attributes['value']!.substring(3),
        ),
      );
    }
    return courseSemesterData;
  }

  CourseData courseData(
    TimeCodeConfig timeCodeConfig,
    String text,
  ) {
    final int startTime = DateTime.now().millisecondsSinceEpoch;
    final dom.Document document = parse(text);
    final List<dom.Element> trDoc = document.getElementsByTagName('tr');
    final CourseData courseData =
        CourseData(courses: <Course>[], timeCodes: timeCodeConfig.timeCodes);

    //print(DateTime.now());
    for (int i = 1; i < trDoc.length; i++) {
      final List<dom.Element> tdDoc = trDoc[i].getElementsByTagName('td');
      final dom.Element titleElement = tdDoc[4].getElementsByTagName('a').first;
      final List<String> titles = titleElement.innerHtml.split('<br>');
      String title = titleElement.text;
      if (titles.length >= 2) {
        switch (Locale(Intl.defaultLocale!).languageCode) {
          case 'en':
            title = titles[1];
          case 'zh':
          default:
            title = titles[0];
        }
      }
      final String instructors = tdDoc[8].text;
      final Location location = Location(
        building: '',
        room: tdDoc[9].text,
      );
      final Course course = Course(
        code: tdDoc[2].text,
        className: '${tdDoc[1].text} ${tdDoc[3].text}',
        title: title,
        units: tdDoc[5].text,
        required:
            tdDoc[7].text.length == 1 ? '${tdDoc[7].text}修' : tdDoc[7].text,
        location: location,
        instructors: <String>[instructors],
        times: <SectionTime>[],
      );
      for (int j = 10; j < tdDoc.length; j++) {
        if (tdDoc[j].text.isNotEmpty) {
          final List<String> sections = tdDoc[j].text.split('');
          if (sections.isNotEmpty && sections[0] != ' ') {
            for (final String section in sections) {
              final int index = timeCodeConfig.indexOf(section);
              if (index == -1) continue;
              course.times.add(SectionTime(weekday: j - 9, index: index));
            }
          }
        }
      }
      courseData.courses.add(course);
    }
    if (trDoc.isNotEmpty) {
      final int endTime = DateTime.now().millisecondsSinceEpoch;
      AnalyticsUtil.instance
          .logTimeEvent('course_html_parser', (endTime - startTime) / 1000.0);
    }
    //print(DateTime.now());
    return courseData;
  }

  ScoreSemesterData scoreSemesterData(String text) {
    final dom.Document document = parse(text, encoding: 'BIG-5');
    final List<dom.Element> selectDoc = document.getElementsByTagName('select');
    final ScoreSemesterData scoreSemesterData = ScoreSemesterData(
      semesters: <SemesterOptions>[],
      years: <SemesterOptions>[],
    );
    if (selectDoc.length >= 2) {
      List<dom.Element> options = selectDoc[0].getElementsByTagName('option');
      for (int i = 0; i < options.length; i++) {
        scoreSemesterData.years.add(
          SemesterOptions(
            text: options[i].text,
            value: options[i].attributes['value']!,
          ),
        );
      }
      options = selectDoc[1].getElementsByTagName('option');
      for (int i = 0; i < options.length; i++) {
        scoreSemesterData.semesters.add(
          SemesterOptions(
            text: options[i].text,
            value: options[i].attributes['value']!,
          ),
        );
        if (options[i].attributes['selected'] != null) {
          scoreSemesterData.selectSemesterIndex = i;
        }
      }
    } else {
      // print('document.text = ${document.text}');
    }
    return scoreSemesterData;
  }

  Future<ScoreData> scoreData(
    String text,
    bool searchPreScore,
    Future<PreScore?> Function(String courseNumber) getPreScoreData,
  ) async {
    final int startTime = DateTime.now().millisecondsSinceEpoch;
    final dom.Document document = parse(text, encoding: 'BIG-5');
    final List<Score> list = <Score>[];
    Detail detail = Detail();
    final List<dom.Element> tableDoc = document.getElementsByTagName('tbody');
    if (tableDoc.length >= 2) {
      //      for (var i = 0; i < tableDoc.length; i++) {
      //        //print('i => ${tableDoc[i].text}');
      //        var fontDoc = tableDoc[i].getElementsByTagName('tr');
      //        for (var j = 0; j < fontDoc.length; j++) {
      //          print("i $i j $j => ${fontDoc[j].text}");
      //        }
      //      }
      if (tableDoc.length == 3) {
        final List<dom.Element> fontDoc =
            tableDoc[1].getElementsByTagName('font');
        double percentage = double.parse(fontDoc[4].text.split('：')[1]) /
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
          Score score = Score(
            courseNumber:
                fontDoc[2].text.substring(1, fontDoc[2].text.length - 1),
            title: //'${trDoc[i].getElementsByTagName('font')[2].text}'
                fontDoc[3].text,
            middleScore: fontDoc[4].text,
            finalScore: fontDoc[5].text,
            units: '',
          );
          if (searchPreScore &&
              (score.finalScore == null || (score.finalScore ?? '') == '--')) {
            if (score.courseNumber case final String courseNumber?) {
              final PreScore? preScore = await getPreScoreData(courseNumber);
              if (preScore != null) {
                score = score.copyWith(
                  finalScore: preScore.grades,
                  isPreScore: true,
                );
              }
            }
          }
          list.add(score);
        }
      }
      final int endTime = DateTime.now().millisecondsSinceEpoch;
      AnalyticsUtil.instance
          .logTimeEvent('score_html_parser', (endTime - startTime) / 1000.0);
    }
    /*var trDoc = document.getElementsByTagName('tr');
      for (var i = 0; i < trDoc.length; i++) {
        if (trDoc[i].getElementsByTagName('font').length != 6) continue;
        if (i != 0)
          list.add(Score(
            title: //'${trDoc[i].getElementsByTagName('font')[2].text}'
                '${trDoc[i].getElementsByTagName('font')[3].text}',
            middleScore: '${trDoc[i].getElementsByTagName('font')[4].text}',
            finalScore: trDoc[i].getElementsByTagName('font')[5].text,
          ));
        for (var j in trDoc[i].getElementsByTagName('font')) {
          //print('${j.text}');
        }
      }*/
    final ScoreData scoreData = ScoreData(
      scores: list,
      detail: detail,
    );
    return scoreData;
  }

  PreScore? preScore(String text) {
    final dom.Document document = parse(text, encoding: 'BIG-5');
    PreScore? detail;
    final List<dom.Element> tableDoc = document.getElementsByTagName('table');
    if (tableDoc.isNotEmpty) {
      for (int i = 0; i < tableDoc.length; i++) {
        final List<dom.Element> trDoc = tableDoc[i].getElementsByTagName('tr');
        if (trDoc.length >= 2) {
          final List<dom.Element> tdDoc = trDoc[1].getElementsByTagName('td');
          if (tdDoc.length >= 6) {
            detail = PreScore(
              item: tdDoc[2].text,
              percentage: tdDoc[3].text,
              originalGrades: tdDoc[4].text,
              grades: tdDoc[5].text,
              remark: tdDoc[6].text,
            );
          }
        }
      }
    }
    return detail;
  }

  String username(String text) {
    final dom.Document document = parse(text, encoding: 'BIG-5');
    final List<dom.Element> elements = document.getElementsByTagName('b');
    return elements.isNotEmpty ? elements[0].text : '';
  }
}
