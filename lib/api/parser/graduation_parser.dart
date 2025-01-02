import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';

class GraduationParser {
  GraduationReportData? graduationReport(String text) {
    final GraduationReportData graduationReportData = GraduationReportData(
      missingRequiredCourse: <MissingRequiredCourse>[],
      generalEducationCourse: <GeneralEducationCourse>[],
      otherEducationsCourse: <OtherEducationsCourse>[],
    );
    final int startTime = DateTime.now().millisecondsSinceEpoch;
//      debugPrint('text = $text');
//      debugPrint(DateTime.now().toString());
    final Document document = parse(text);
    final List<Element> tableDoc = document.getElementsByTagName('tbody');
    if (tableDoc.length >= 2) {
      for (int i = 0; i < tableDoc.length; i++) {
        //print('i => ${tableDoc[i].text}');
        final List<Element> trDoc = tableDoc[i].getElementsByTagName('tr');
        if (i == 4) {
          //缺修學系必修課程
          if (trDoc.length > 3) {
            for (int j = 2; j < trDoc.length; j++) {
              final List<Element> tdDoc = trDoc[j].getElementsByTagName('td');
              if (tdDoc.length == 3) {
                graduationReportData.missingRequiredCourse.add(
                  MissingRequiredCourse(
                    name: tdDoc[0].text,
                    credit: tdDoc[1].text,
                    description: tdDoc[2].text,
                  ),
                );
              }
              //              for (var k = 0; k < tdDoc.length; k++) {
              //                print("i $i j $j k $k => ${tdDoc[k].text}");
              //              }
            }
          }
          if (trDoc.isNotEmpty) {
            graduationReportData.missingRequiredCoursesCredit =
                trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
          }
        } else if (i == 5) {
          //通識課程
          for (int j = 2; j < trDoc.length; j++) {
            final List<Element> tdDoc = trDoc[j].getElementsByTagName('td');
            //print('td lengh = ${tdDoc.length}');
            int base = 0;
            if (tdDoc.length == 7) {
              base = 1;
              graduationReportData.generalEducationCourse.add(
                GeneralEducationCourse(
                  type: tdDoc[0].text,
                  generalEducationItem: <GeneralEducationItem>[],
                ),
              );
            }
            if (tdDoc.length > 5) {
              graduationReportData
                  .generalEducationCourse.last.generalEducationItem!
                  .add(
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
          if (graduationReportData.generalEducationCourse.isNotEmpty) {
            graduationReportData.generalEducationCourseDescription =
                trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
          }
        } else if (i == 6) {
          //其他
          if (trDoc.length > 3) {
            for (int j = 2; j < trDoc.length; j++) {
              final List<Element> tdDoc = trDoc[j].getElementsByTagName('td');
              if (tdDoc.length == 3) {
                graduationReportData.otherEducationsCourse.add(
                  OtherEducationsCourse(
                    name: tdDoc[0].text,
                    semester: tdDoc[1].text,
                    credit: tdDoc[2].text,
                  ),
                );
              }
              //              for (var k = 0; k < tdDoc.length; k++) {
              //                print("i $i j $j k $k => ${tdDoc[k].text}");
              //              }
            }
          }
          if (trDoc.isNotEmpty) {
            graduationReportData.otherEducationsCourseCredit =
                trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
          }
        }
      }
      final List<Element> tdDoc = document.getElementsByTagName('td');
      for (int i = 0; i < tdDoc.length; i++) {
        if (tdDoc[i].text.contains('目前累計學分數')) {
          graduationReportData.totalDescription =
              tdDoc[i].text.replaceAll(RegExp(r'[※\n]'), '');
        }
      }
      if (kDebugMode) {
        print(DateTime.now());
      }
    } else {
      return null;
    }
    //    graduationReportData.generalEducationCourse.forEach((i) {
    //      print('type = ${i.type}');
    //    });
    final int endTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint(((endTime - startTime) / 1000.0).toString());
    return graduationReportData;
  }
}
