import 'dart:convert';

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:nsysu_ap/models/course_data.dart';
import 'package:nsysu_ap/models/course_semester_data.dart';
import 'package:nsysu_ap/models/login_response.dart';
import 'package:nsysu_ap/models/options.dart';
import 'package:nsysu_ap/models/score_data.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/models/user_info.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'app_localizations.dart';
import 'big5.dart';

const HOST = "nsysu-ap.rainvisitor.me";
const PORT = '8443';
const BASE_URL = 'https://$HOST:$PORT';

class Helper {
  static Helper _instance;
  static String courseCookie = '';
  static String scoreCookie = '';
  static String selcrsUrl = 'selcrs1.nsysu.edu.tw';
  static WebViewController controller;
  static int index = 0;
  static int error = 0;

  static Helper get instance {
    if (_instance == null) {
      _instance = Helper();
    }
    return _instance;
  }

  String get language {
    switch (AppLocalizations.locale.languageCode) {
      case 'zh':
        return 'cht';
        break;
      case 'en':
        return 'eng';
        break;
      default:
        return 'cht';
        break;
    }
  }

  static changeSelcrsUrl() {
    index++;
    if (index == 5) index = 0;
    selcrsUrl = 'selcrs${index == 0 ? '' : index}.nsysu.edu.tw';
    print(selcrsUrl);
  }

  Future<int> selcrsLogin(String username, String password) async {
    print(DateTime.now());
    var base64md5Password =
        await Helper.controller?.evaluateJavascript('base64_md5("$password")');
    base64md5Password = base64md5Password.replaceAll('\"', '');
    bool score = true, course = true;
    var scoreResponse = await http.post(
      'http://$selcrsUrl/scoreqry/sco_query_prs_sso2.asp',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'SID': username,
        'PASSWD': base64md5Password,
        'ACTION': '0',
        'INTYPE': '1',
      },
    ).timeout(Duration(seconds: 2));
    String text = big5.decode(scoreResponse.bodyBytes);
    //print('text =  ${scoreResponse.statusCode}');
    if (text.contains("資料錯誤請重新輸入"))
      score = false;
    else if (scoreResponse.statusCode != 302) throw '';
    scoreCookie = scoreResponse.headers['set-cookie'];
    var courseResponse = await http.post(
      'http://$selcrsUrl/menu4/Studcheck_sso2.asp',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'stuid': username,
        'SPassword': base64md5Password,
      },
    ).timeout(Duration(seconds: 2));
    print('text =  ${courseResponse.statusCode}');
    text = big5.decode(courseResponse.bodyBytes);
    if (text.contains("學號碼密碼不符"))
      course = false;
    else if (courseResponse.statusCode != 200) throw '';
    courseCookie = courseResponse.headers['set-cookie'];
    print('text =  ${courseResponse.headers['set-cookie'] == null}');
    print(DateTime.now());
    if (score && course)
      return 200;
    else
      return 403;
  }

  Future<int> login(String username, String password) async {
    print(DateTime.now());
    var response = await http.post(
      '$BASE_URL/selcrs/login',
      headers: {
        'Content-Type': 'application/json',
      },
      body: '{\"username\": \"$username\",\"password\": \"$password\"}',
    );
    print(DateTime.now());
    var loginResponse = LoginResponse.fromJson(
      jsonDecode(response.body),
    );
    if (loginResponse.data != null) {
      courseCookie =
          '${loginResponse.data[0].name}=${loginResponse.data[0].value}';
      scoreCookie =
          '${loginResponse.data[0].name}=${loginResponse.data[0].value}';
      return 200;
    } else {
      return 500;
    }
  }

  Future<UserInfo> getUserInfo() async {
    var url = 'http://$selcrsUrl/menu4/tools/changedat.asp';
    var response = await http.get(
      url,
      headers: {'Cookie': courseCookie},
    );
    String text = big5.decode(response.bodyBytes);
    //print('text =  ${text}');
    var document = parse(text, encoding: 'BIG-5');
    var tdDoc = document.getElementsByTagName('td');
    var userInfo = UserInfo();
    if (tdDoc.length > 0)
      userInfo = UserInfo(
        department: tdDoc[1].text,
        studentId: tdDoc[5].text,
        studentNameCht: tdDoc[7].text,
        educationSystem: tdDoc[9].text,
      );
    return userInfo;
  }

  Future<CourseSemesterData> getCourseSemesterData() async {
    var url = 'http://$selcrsUrl/menu4/query/stu_slt_up.asp';
    var response = await http.post(
      url,
      headers: {'Cookie': courseCookie},
      encoding: Encoding.getByName('BIG-5'),
    );
    String text = big5.decode(response.bodyBytes);
    //print('text =  ${text}');
    var document = parse(text, encoding: 'BIG-5');
    var options = document.getElementsByTagName('option');
    var courseSemesterData = CourseSemesterData(semesters: []);
    for (var i = 0; i < options.length; i++) {
      //print('$i => ${tdDoc[i].text}');
      courseSemesterData.semesters.add(
        Options(
          text: options[i].text,
          value: options[i].attributes['value'],
        ),
      );
    }
    return courseSemesterData;
  }

  Future<CourseData> getCourseData(String username, String semester) async {
    var url = 'http://$selcrsUrl/menu4/query/stu_slt_data.asp';
    var response = await http.post(
      url,
      headers: {'Cookie': courseCookie},
      body: {
        'stuact': 'B',
        'YRSM': semester,
        'Stuid': username,
        'B1': '%BDT%A9w%B0e%A5X',
      },
      encoding: Encoding.getByName('BIG-5'),
    );
    String text = big5.decode(response.bodyBytes);
    //print('text =  ${text}');
    var document = parse(text, encoding: 'BIG-5');
    var trDoc = document.getElementsByTagName('tr');
    var courseData = CourseData(
        status: (trDoc.length == 0) ? 204 : 200,
        messages: '',
        courseTables: (trDoc.length == 0) ? null : CourseTables());
    //print(DateTime.now());
    for (var i = 0; i < trDoc.length; i++) {
      var tdDoc = trDoc[i].getElementsByTagName('td');
      if (i == 0) continue;
      for (var j = 10; j < tdDoc.length; j++) {
        if (tdDoc[j].text.length > 0) {
          for (var section in tdDoc[j].text.split('')) {
            if (courseData.courseTables.timeCode.indexOf(section) == -1)
              continue;
            var course = Course(
              title: tdDoc[4].text,
              instructors: [tdDoc[8].text],
              location: Location(
                building: '',
                room: tdDoc[9].text,
              ),
              date: Date(weekday: 'T', section: section),
            );
            if (j == 10)
              courseData.courseTables.monday.add(course);
            else if (j == 11)
              courseData.courseTables.tuesday.add(course);
            else if (j == 12)
              courseData.courseTables.wednesday.add(course);
            else if (j == 13)
              courseData.courseTables.thursday.add(course);
            else if (j == 14)
              courseData.courseTables.friday.add(course);
            else if (j == 15)
              courseData.courseTables.saturday.add(course);
            else if (j == 16) courseData.courseTables.sunday.add(course);
          }
        }
      }
    }
    if (trDoc.length != 0) {
      if (courseData.courseTables.saturday.length == 0)
        courseData.courseTables.saturday = null;
      if (courseData.courseTables.sunday.length == 0)
        courseData.courseTables.sunday = null;
    }
    //print(DateTime.now());
    return courseData;
  }

  Future<ScoreSemesterData> getScoreSemesterData() async {
    var url =
        'http://$selcrsUrl/scoreqry/sco_query.asp?ACTION=702&KIND=2&LANGS=$language';
    var response = await http.post(
      url,
      headers: {'Cookie': scoreCookie},
      encoding: Encoding.getByName('BIG-5'),
    );
    String text = big5.decode(response.bodyBytes);
    //print('text =  ${text}');
    var document = parse(text, encoding: 'BIG-5');
    var selectDoc = document.getElementsByTagName('select');
    var scoreSemesterData = ScoreSemesterData(
      semesters: [],
      years: [],
    );
    if (selectDoc.length >= 2) {
      var options = selectDoc[0].getElementsByTagName('option');
      for (var i = 0; i < options.length; i++) {
        scoreSemesterData.years.add(
          Options(
            text: options[i].text,
            value: options[i].attributes['value'],
          ),
        );
      }
      options = selectDoc[1].getElementsByTagName('option');
      for (var i = 0; i < options.length; i++) {
        scoreSemesterData.semesters.add(
          Options(
            text: options[i].text,
            value: options[i].attributes['value'],
          ),
        );
        if (options[i].attributes['selected'] != null)
          scoreSemesterData.selectSemesterIndex = i;
      }
    } else {
      print('document.text = ${document.text}');
    }
    return scoreSemesterData;
  }

  Future<ScoreData> getScoreData(String year, String semester) async {
    var url =
        'http://$selcrsUrl/scoreqry/sco_query.asp?ACTION=804&KIND=2&LANGS=$language';
    var response = await http.post(
      url,
      headers: {'Cookie': scoreCookie},
      body: {
        'SYEAR': year,
        'SEM': semester,
      },
      encoding: Encoding.getByName('BIG-5'),
    );
    String text = big5.decode(response.bodyBytes);
    var document = parse(text, encoding: 'BIG-5');
    List<Score> list = [];
    Detail detail = Detail();
    var tableDoc = document.getElementsByTagName('tbody');
    if (tableDoc.length >= 2) {
//      for (var i = 0; i < tableDoc.length; i++) {
//        //print('i => ${tableDoc[i].text}');
//        var fontDoc = tableDoc[i].getElementsByTagName('tr');
//        for (var j = 0; j < fontDoc.length; j++) {
//          print("i $i j $j => ${fontDoc[j].text}");
//        }
//      }
      if (tableDoc.length == 3) {
        var fontDoc = tableDoc[1].getElementsByTagName('font');
        detail.conduct =
            '${fontDoc[0].text.split('：')[1]}/${fontDoc[1].text.split('：')[1]}';
        detail.average = fontDoc[2].text.split('：')[1];
        detail.classRank =
            '${fontDoc[4].text.split('：')[1]}/${fontDoc[5].text.split('：')[1]}';
        var percentage = double.parse(fontDoc[4].text.split('：')[1]) /
            double.parse(fontDoc[5].text.split('：')[1]);
        percentage = 1.0 - percentage;
        percentage *= 100;
        detail.classPercentage = '${percentage.toStringAsFixed(2)}';
      }
      var trDoc = tableDoc[0].getElementsByTagName('tr');
      for (var i = 0; i < trDoc.length; i++) {
        var fontDoc = trDoc[i].getElementsByTagName('font');
        if (fontDoc.length != 6) continue;
        if (i != 0)
          list.add(Score(
            title: //'${trDoc[i].getElementsByTagName('font')[2].text}'
                '${fontDoc[3].text}',
            middleScore: '${fontDoc[4].text}',
            finalScore: fontDoc[5].text,
          ));
      }
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
    var scoreData = ScoreData(
      status: 200,
      messages: '',
      content: Content(
        scores: list,
        detail: detail,
      ),
    );
    if (list.length == 0) scoreData.status = 204;
    return scoreData;
  }
}
