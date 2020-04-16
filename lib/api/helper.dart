import 'dart:convert';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/new_response.dart';
import 'package:ap_common/models/time_code.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:big5/big5.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/course_semester_data.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/models/options.dart';
import 'package:nsysu_ap/models/pre_score.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

import '../utils/app_localizations.dart';
import '../utils/firebase_analytics_utils.dart';

class Helper {
  static const selcrsUrlFormat = 'selcrs%i.nsysu.edu.tw';
  static const tfUrl = 'tfstu.nsysu.edu.tw';

  static Helper _instance;

  static Dio dio;

  static String courseCookie = '';
  static String scoreCookie = '';
  static String graduationCookie = '';
  static String tsfCookie = '';

  static String username = '';

  static String get selcrsUrl => sprintf(selcrsUrlFormat, [index]);

  static int index = 1;
  static int error = 0;

  static Helper get instance {
    if (_instance == null) {
      _instance = Helper();
      dio = Dio(
        BaseOptions(
          responseType: ResponseType.bytes,
          sendTimeout: 10000,
          receiveTimeout: 10000,
        ),
      );
    }
    return _instance;
  }

  String get language {
    switch (AppLocalizations.locale.languageCode) {
      case 'en':
        return 'eng';
      case 'zh':
      default:
        return 'cht';
    }
  }

  Options get _courseOption => Options(
        responseType: ResponseType.bytes,
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Cookie': courseCookie},
      );

  Options get _scoreOption => Options(
        responseType: ResponseType.bytes,
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Cookie': scoreCookie},
      );

  Options get _graduationOption => Options(
        responseType: ResponseType.bytes,
        headers: {'Cookie': graduationCookie},
      );

  Options get _tfOption => Options(
        responseType: ResponseType.bytes,
        headers: {'Cookie': tsfCookie},
      );

  static changeSelcrsUrl() {
    index++;
    if (index == 5) index = 1;
    print(selcrsUrl);
  }

  clearSession() {
    courseCookie = '';
    scoreCookie = '';
    graduationCookie = '';
    tsfCookie = '';
    username = '';
    index = 1;
    error = 0;
  }

  String base64md5(String text) {
    var bytes = utf8.encode(text);
    var digest = md5.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /*
  * 選課系統&成績系統登入
  * error status code
  * 400: 帳號密碼錯誤
  * */
  Future<void> selcrsLogin({
    @required String username,
    @required String password,
    @required GeneralCallback<GeneralResponse> callback,
  }) async {
    var base64md5Password = base64md5(password);
    dio.options.contentType = Headers.formUrlEncodedContentType;
    try {
      var scoreResponse = await dio.post(
        'http://$selcrsUrl/scoreqry/sco_query_prs_sso2.asp',
        data: {
          'SID': username,
          'PASSWD': base64md5Password,
          'ACTION': '0',
          'INTYPE': '1',
        },
      );
      String text = big5.decode(scoreResponse.data);
      if (text.contains("資料錯誤請重新輸入")) {
        callback?.onError(
          GeneralResponse(statusCode: 400, message: 'score error'),
        );
      }
      scoreCookie = scoreResponse.headers.value('set-cookie');
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        scoreCookie = e.response.headers.value('set-cookie');
      } else
        callback?.onFailure(e);
    }
    try {
      var courseResponse = await dio.post(
        'http://$selcrsUrl/menu4/Studcheck_sso2.asp',
        data: {
          'stuid': username,
          'SPassword': base64md5Password,
        },
      );
      String text = big5.decode(courseResponse.data);
      print('text =  $text');
      if (text.contains("學號碼密碼不符")) {
        callback?.onError(
          GeneralResponse(statusCode: 400, message: 'course error'),
        );
      }
      courseCookie = courseResponse.headers.value('set-cookie');
      print(DateTime.now());
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        courseCookie = e.response.headers.value('set-cookie');
        callback?.onSuccess(GeneralResponse.success());
      } else {
        callback?.onFailure(e);
      }
    }
  }

  /*
  * 畢業審查系統登入
  * error status code
  * 400: 帳號密碼錯誤
  * */
  Future<GeneralResponse> graduationLogin({
    @required String username,
    @required String password,
    GeneralCallback callback,
  }) async {
    try {
      var base64md5Password = base64md5(password);
      var response = await Dio().post(
        'http://$selcrsUrl/gadchk/gad_chk_login_prs_sso2.asp',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: {
          'SID': username,
          'PASSWD': base64md5Password,
          'PGKIND': 'GAD_CHK',
          'ACTION': '0',
        },
      );
      String text = big5.decode(response.data);
      //    print('Response =  $text');
      //    print('response.statusCode = ${response.statusCode}');
      if (text.contains("資料錯誤請重新輸入"))
        callback?.onError(
          GeneralResponse(statusCode: 400, message: 'graduation login error'),
        );
      graduationCookie = response.headers.value('set-cookie');
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        graduationCookie = e.response.headers.value('set-cookie');
      } else {
        callback?.onFailure(e);
        return null;
      }
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return GeneralResponse.success();
  }

  /*
  * 取得使用者資訊
  * error status code
  * 400: 帳號密碼錯誤
  * */
  Future<UserInfo> getUserInfo({
    GeneralCallback<UserInfo> callback,
  }) async {
    try {
      dio.options.headers = {
        'Cookie': courseCookie,
      };
      var response = await dio.get(
        'http://$selcrsUrl/menu4/tools/changedat.asp',
      );
      String text = big5.decode(response.data);
      return callback?.onSuccess(parserUserInfo(text));
    } on DioError catch (e) {
      callback?.onFailure(e);
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  UserInfo parserUserInfo(String text) {
    var document = parse(text, encoding: 'BIG-5');
    var tdDoc = document.getElementsByTagName('td');
    var userInfo = UserInfo();
    if (tdDoc.length > 0)
      userInfo = UserInfo(
        department: tdDoc[1].text,
        className: tdDoc[3].text.replaceAll(' ', ''),
        id: tdDoc[5].text,
        name: tdDoc[7].text,
        email: tdDoc[9].text,
      );
    return userInfo;
  }

  Future<CourseSemesterData> getCourseSemesterData({
    GeneralCallback callback,
  }) async {
    var url = 'http://$selcrsUrl/menu4/query/stu_slt_up.asp';
    try {
      dio.options.headers = {'Cookie': courseCookie};
      var response = await dio.post(url);
      String text = big5.decode(response.data);
      //print('text =  ${text}');
      var document = parse(text, encoding: 'BIG-5');
      var options = document.getElementsByTagName('option');
      var courseSemesterData = CourseSemesterData(semesters: []);
      for (var i = 0; i < options.length; i++) {
        //print('$i => ${tdDoc[i].text}');
        courseSemesterData.semesters.add(
          SemesterOptions(
            text: options[i].text,
            value: options[i].attributes['value'],
          ),
        );
      }
      return courseSemesterData;
    } on DioError catch (e) {
      if (callback != null)
        callback.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<CourseData> getCourseData({
    @required String username,
    @required TimeCodeConfig timeCodeConfig,
    @required String semester,
    GeneralCallback callback,
  }) async {
    var url = 'http://$selcrsUrl/menu4/query/stu_slt_data.asp';
    try {
      var response = await Dio().post(
        url,
        data: {
          'stuact': 'B',
          'YRSM': semester,
          'Stuid': username,
          'B1': '%BDT%A9w%B0e%A5X',
        },
        options: _courseOption,
      );
      String text = big5.decode(response.data);
      //    print('text =  ${text}');
      var startTime = DateTime.now().millisecondsSinceEpoch;
      var document = parse(text, encoding: 'BIG-5');
      var trDoc = document.getElementsByTagName('tr');
      var courseData =
          CourseData(courseTables: (trDoc.length == 0) ? null : CourseTables());
      if (courseData.courseTables != null)
        courseData.courseTables.timeCode = timeCodeConfig.textList;
      //print(DateTime.now());
      for (var i = 0; i < trDoc.length; i++) {
        var tdDoc = trDoc[i].getElementsByTagName('td');
        if (i == 0) continue;
        final title = tdDoc[4].text;
        final instructors = tdDoc[8].text;
        final location = Location(
          building: '',
          room: tdDoc[9].text,
        );
        String time = '';
        for (var j = 10; j < tdDoc.length; j++) {
          if (tdDoc[j].text.length > 0) {
            List<String> sections = tdDoc[j].text.split('');
            if (sections.length > 0 && sections[0] != ' ') {
              String tmp = '';
              for (var section in sections) {
                int index = timeCodeConfig.indexOf(section);
                if (index == -1) continue;
                TimeCode timeCode = timeCodeConfig.timeCodes[index];
                tmp += '$section';
                var course = Course(
                  title: title,
                  instructors: [instructors],
                  location: location,
                  date: Date(
                    weekday: 'T',
                    section: section,
                    startTime: timeCode?.startTime ?? '',
                    endTime: timeCode?.endTime ?? '',
                  ),
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
              if (tmp.isNotEmpty) {
                time += '${trDoc[0].getElementsByTagName('td')[j].text}$tmp';
              }
            }
          }
        }
        courseData.courses.add(
          CourseDetail(
            code: tdDoc[2].text,
            className: '${tdDoc[1].text} ${tdDoc[3].text}',
            title: title,
            units: tdDoc[5].text,
            required:
                tdDoc[7].text.length == 1 ? '${tdDoc[7].text}修' : tdDoc[7].text,
            location: location,
            instructors: [instructors],
            times: time,
          ),
        );
      }
      if (trDoc.length != 0) {
        if (courseData.courseTables.saturday.length == 0)
          courseData.courseTables.saturday = null;
        if (courseData.courseTables.sunday.length == 0)
          courseData.courseTables.sunday = null;
        var endTime = DateTime.now().millisecondsSinceEpoch;
        FA.logTimeEvent(FA.COURSE_HTML_PARSER, (endTime - startTime) / 1000.0);
      }
      //print(DateTime.now());
      return courseData;
    } on DioError catch (e) {
      if (callback != null)
        callback.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<ScoreSemesterData> getScoreSemesterData({
    GeneralCallback callback,
  }) async {
    var url =
        'http://$selcrsUrl/scoreqry/sco_query.asp?ACTION=702&KIND=2&LANGS=$language';
    try {
      var response = await Dio().post(
        url,
        options: _scoreOption,
      );
      String text = big5.decode(response.data);
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
            SemesterOptions(
              text: options[i].text,
              value: options[i].attributes['value'],
            ),
          );
        }
        options = selectDoc[1].getElementsByTagName('option');
        for (var i = 0; i < options.length; i++) {
          scoreSemesterData.semesters.add(
            SemesterOptions(
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
    } on DioError catch (e) {
      if (callback != null)
        callback.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<ScoreData> getScoreData({
    @required String year,
    @required String semester,
    bool searchPreScore = false,
    GeneralCallback callback,
  }) async {
    var url =
        'http://$selcrsUrl/scoreqry/sco_query.asp?ACTION=804&KIND=2&LANGS=$language';
    try {
      var response = await Dio().post(
        url,
        options: _scoreOption,
        data: {
          'SYEAR': year,
          'SEM': semester,
        },
      );
      String text = big5.decode(response.data);
      var startTime = DateTime.now().millisecondsSinceEpoch;
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
          detail.creditTaken = double.parse(fontDoc[0].text.split('：')[1]);
          detail.creditEarned = double.parse(fontDoc[1].text.split('：')[1]);
          detail.average = double.parse(fontDoc[2].text.split('：')[1]);
          detail.classRank =
              '${fontDoc[4].text.split('：')[1]}/${fontDoc[5].text.split('：')[1]}';
          var percentage = double.parse(fontDoc[4].text.split('：')[1]) /
              double.parse(fontDoc[5].text.split('：')[1]);
          percentage = 1.0 - percentage;
          percentage *= 100;
          detail.classPercentage = double.parse(percentage.toStringAsFixed(2));
        }
        var trDoc = tableDoc[0].getElementsByTagName('tr');
        for (var i = 0; i < trDoc.length; i++) {
          var fontDoc = trDoc[i].getElementsByTagName('font');
          if (fontDoc.length != 6) continue;
          if (i != 0) {
            final score = Score(
              courseNumber:
                  '${fontDoc[2].text.substring(1, fontDoc[2].text.length - 1)}',
              title: //'${trDoc[i].getElementsByTagName('font')[2].text}'
                  '${fontDoc[3].text}',
              middleScore: '${fontDoc[4].text}',
              finalScore: fontDoc[5].text,
            );
            if (searchPreScore &&
                (score.finalScore == null ||
                    (score.finalScore ?? '') == '--')) {
              final preScore = await getPreScoreData(score.courseNumber);
              if (preScore != null) {
                score.finalScore = preScore.grades;
                score.isPreScore = true;
              }
            }
            list.add(score);
          }
        }
        var endTime = DateTime.now().millisecondsSinceEpoch;
        FA.logTimeEvent(FA.SCORE_HTML_PARSER, (endTime - startTime) / 1000.0);
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
        scores: list,
        detail: detail,
      );
      return scoreData;
    } on DioError catch (e) {
      if (callback != null)
        callback.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<PreScore> getPreScoreData(String courseNumber) async {
    var url =
        'http://$selcrsUrl/scoreqry/sco_query.asp?ACTION=814&KIND=1&LANGS=$language';
    var response = await Dio().post(
      url,
      options: _scoreOption,
      data: {
        'CRSNO': courseNumber,
      },
    );
    String text = big5.decode(response.data);
    //print('text = $text}');
    var document = parse(text, encoding: 'BIG-5');
    PreScore detail;
    var tableDoc = document.getElementsByTagName('table');
    if (tableDoc.length >= 1) {
      for (var i = 0; i < tableDoc.length; i++) {
        var trDoc = tableDoc[i].getElementsByTagName('tr');
        if (trDoc.length >= 2) {
          var tdDoc = trDoc[1].getElementsByTagName('td');
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

  Future<GraduationReportData> getGraduationReport({
    GeneralCallback callback,
  }) async {
    var url =
        'http://$selcrsUrl/gadchk/gad_chk_stu_list.asp?stno=$username&KIND=5&frm=1';
    try {
      var response = await dio.get(
        url,
        options: _graduationOption,
      );
      var graduationReportData = GraduationReportData(
        missingRequiredCourse: [],
        generalEducationCourse: [],
        otherEducationsCourse: [],
      );
      String text = big5.decode(response.data);
      var startTime = DateTime.now().millisecondsSinceEpoch;
      //print('text = $text');
      print(DateTime.now());
      var document = parse(text, encoding: 'BIG-5');
      var tableDoc = document.getElementsByTagName('tbody');
      if (tableDoc.length >= 2) {
        for (var i = 0; i < tableDoc.length; i++) {
          //print('i => ${tableDoc[i].text}');
          var trDoc = tableDoc[i].getElementsByTagName('tr');
          if (i == 4) {
            //缺修學系必修課程
            if (trDoc.length > 3) {
              for (var j = 2; j < trDoc.length; j++) {
                var tdDoc = trDoc[j].getElementsByTagName('td');
                if (tdDoc.length == 3)
                  graduationReportData.missingRequiredCourse.add(
                    MissingRequiredCourse(
                      name: tdDoc[0].text,
                      credit: tdDoc[1].text,
                      description: tdDoc[2].text,
                    ),
                  );
                //              for (var k = 0; k < tdDoc.length; k++) {
                //                print("i $i j $j k $k => ${tdDoc[k].text}");
                //              }
              }
            }
            if (trDoc.length > 0) {
              graduationReportData.missingRequiredCoursesCredit =
                  trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
            }
          } else if (i == 5) {
            //通識課程
            for (var j = 2; j < trDoc.length; j++) {
              var tdDoc = trDoc[j].getElementsByTagName('td');
              //print('td lengh = ${tdDoc.length}');
              int base = 0;
              if (tdDoc.length == 7) {
                base = 1;
                graduationReportData.generalEducationCourse.add(
                  GeneralEducationCourse(
                    type: tdDoc[0].text,
                    generalEducationItem: [],
                  ),
                );
              }
              if (tdDoc.length > 5)
                graduationReportData
                    .generalEducationCourse.last.generalEducationItem
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
            if (graduationReportData.generalEducationCourse.length > 0) {
              graduationReportData.generalEducationCourseDescription =
                  trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
            }
          } else if (i == 6) {
            //其他
            if (trDoc.length > 3) {
              for (var j = 2; j < trDoc.length; j++) {
                var tdDoc = trDoc[j].getElementsByTagName('td');
                if (tdDoc.length == 3)
                  graduationReportData.otherEducationsCourse.add(
                    OtherEducationsCourse(
                      name: tdDoc[0].text,
                      semester: tdDoc[1].text,
                      credit: tdDoc[2].text,
                    ),
                  );
                //              for (var k = 0; k < tdDoc.length; k++) {
                //                print("i $i j $j k $k => ${tdDoc[k].text}");
                //              }
              }
            }
            if (trDoc.length > 0) {
              graduationReportData.otherEducationsCourseCredit =
                  trDoc.last.text.replaceAll(RegExp(r'[※\n]'), '');
            }
          }
        }
        var tdDoc = document.getElementsByTagName('td');
        for (var i = 0; i < tdDoc.length; i++) {
          if (tdDoc[i].text.contains('目前累計學分數'))
            graduationReportData.totalDescription =
                tdDoc[i].text.replaceAll(RegExp(r'[※\n]'), '');
        }
        print(DateTime.now());
      } else {
        return null;
      }
      //    graduationReportData.generalEducationCourse.forEach((i) {
      //      print('type = ${i.type}');
      //    });
      var endTime = DateTime.now().millisecondsSinceEpoch;
      print((endTime - startTime) / 1000.0);
      return graduationReportData;
    } on DioError catch (e) {
      if (callback != null)
        callback.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<String> getUsername(String name, String id) async {
    var url = 'http://$selcrsUrl/newstu/stu_new.asp?action=16';
    var encoded = Utils.uriEncodeBig5(name);
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'CNAME': encoded,
        'T_CID': id,
        'B1': '%BDT%A9w%B0e%A5X',
      },
    );
    String text = big5.decode(response.bodyBytes);
    var document = parse(text, encoding: 'BIG-5');
    var elements = document.getElementsByTagName('b');
    if (elements.length > 0)
      return elements[0].text;
    else
      return '';
  }

  Future<GeneralResponse> tfLogin({
    @required String username,
    @required String password,
    GeneralCallback callback,
  }) async {
    try {
      var response = await dio.post(
        'https://$tfUrl/tfstu/tfstu_login_chk.asp',
        options: Options(
          responseType: ResponseType.bytes,
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: {
          'ID': username,
          'passwd': password,
        },
      );
      String text = big5.decode(response.data);
      print('Request =  ${response.request.data}');
      print('Response =  $text');
      //    print('response.statusCode = ${response.statusCode}');
      tsfCookie = response.headers.value('set-cookie');
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        tsfCookie = e.response.headers.value('set-cookie');
      } else {
        if (callback != null) {
          callback.onFailure(e);
          print(big5.decode(e.response.data));
          return null;
        } else
          throw e;
      }
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return GeneralResponse.success();
  }

  Future<List<TuitionAndFees>> getTfData({
    GeneralCallback callback,
  }) async {
    var url = 'https://$tfUrl/tfstu/tfstudata.asp?act=11';
    try {
      var response = await Dio().get(
        url,
        options: _tfOption,
      );
      String text = big5.decode(response.data);
      //print('text =  ${text}');
      if (text.contains('沒有合乎查詢條件的資料')) {
        return [];
      }
      var document = parse(text, encoding: 'BIG-5');
      var tbody = document.getElementsByTagName('tbody');
      List<TuitionAndFees> list = [];
      var trElements = tbody[1].getElementsByTagName('tr');
      for (var i = 1; i < trElements.length; i++) {
        var tdDoc = trElements[i].getElementsByTagName('td');
        var aTag = tdDoc[4].getElementsByTagName('a');
        String serialNumber;
        if (aTag.length > 0) {
          serialNumber = aTag[0]
              .attributes['onclick']
              .split('javascript:window.location.href=\'')
              .last;
          serialNumber = serialNumber.substring(0, serialNumber.length - 1);
        }
        String paymentStatus = '', paymentStatusEn = '';
        for (var charCode in tdDoc[2].text.codeUnits) {
          if (charCode < 200) {
            if (charCode == 32)
              paymentStatusEn += '\n';
            else
              paymentStatusEn += String.fromCharCode(charCode);
          } else
            paymentStatus += String.fromCharCode(charCode);
        }
        final titleEN = tdDoc[0].getElementsByTagName('span')[0].text;
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
      return list;
    } on DioError catch (e) {
      if (callback != null) {
        callback.onFailure(e);
        return null;
      } else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
  }

  Future<List<int>> downloadFile({
    String serialNumber,
    GeneralCallback callback,
  }) async {
    try {
      var response = await Dio().get(
        'https://$tfUrl/tfstu/$serialNumber',
        options: _tfOption,
      );
      //    var bytes = response.bodyBytes;
      //    await Printing.sharePdf(bytes: bytes, filename: filename);
      //    await Printing.layoutPdf(
      //      onLayout: (format) async => response.bodyBytes,
      //    );
      //    String dir = (await getApplicationDocumentsDirectory()).path;
      //    File file = new File('$dir/$filename');
      //    await file.writeAsBytes(bytes);
      return response.data;
    } on DioError catch (e) {
      if (callback != null) {
        callback.onFailure(e);
        return null;
      } else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
  }

  Future<List<News>> getNews({GeneralCallback callback}) async {
    try {
      var response = await Dio().get(
        'https://raw.githubusercontent.com/abc873693/NSYSU-AP/master/assets/news_data.json',
      );
      return NewsResponse.fromRawJson(response.data).data;
    } on DioError catch (e) {
      if (callback != null)
        callback?.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<UserInfo> changeMail({
    @required String mail,
    @required GeneralCallback<UserInfo> callback,
  }) async {
    try {
      var response = await Dio().post(
        'http://$selcrsUrl/menu4/tools/changedat.asp',
        options: _courseOption,
        data: {
          'T1': mail,
        },
      );
      String text = big5.decode(response.data);
      return callback?.onSuccess(parserUserInfo(text));
    } on DioError catch (e) {
      if (callback != null)
        callback?.onFailure(e);
      else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }
}
