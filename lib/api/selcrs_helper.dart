import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/options.dart';
import 'package:nsysu_ap/models/pre_score.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/utils/big5/big5.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class SelcrsHelper {
  static const String baseUrl = 'https://selcrs.nsysu.edu.tw';

  static const String courseTimeoutText = '請重新登錄';
  static const String scoreTimeoutText = '請重新登錄';

  static SelcrsHelper? _instance;

  // ignore: prefer_constructors_over_static_methods
  static SelcrsHelper get instance {
    return _instance ??= SelcrsHelper();
  }

  SelcrsHelper() {
    initCookiesJar();
  }

  Dio dio = Dio(
    BaseOptions(
      responseType: ResponseType.bytes,
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  CookieJar cookieJar = CookieJar();

  String username = '';
  String password = '';

  bool isLogin = false;

  int reLoginCount = 0;

  bool get canReLogin => reLoginCount < 5;

  String? get selcrsUrl => sprintf(baseUrl, <int>[index]);

  int index = 1;
  int error = 0;

  String get language {
    switch (Locale(Intl.defaultLocale!).languageCode) {
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
      );

  Options get _scoreOption => Options(
        responseType: ResponseType.bytes,
        contentType: Headers.formUrlEncodedContentType,
      );

  void changeSelcrsUrl() {
    index++;
    if (index == 5) index = 1;
    if (kDebugMode) {
      print(selcrsUrl);
    }
    cookieJar.loadForRequest(Uri.parse('$selcrsUrl'));
  }

  void initCookiesJar() {
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse('$selcrsUrl'));
  }

  void logout() {
    username = '';
    password = '';
    index = 1;
    error = 0;
    isLogin = false;
    cookieJar = CookieJar();
    initCookiesJar();
  }

  /*
  * 選課系統&成績系統登入
  * error status code
  * 400: 帳號密碼錯誤
  * 401: 需要填寫表單
  * 1000: 未知錯誤
  * */
  Future<GeneralResponse> login({
    required String username,
    required String password,
  }) async {
    final String base64md5Password = Utils.base64md5(password);
    dio.options.contentType = Headers.formUrlEncodedContentType;
    try {
      final Response<Uint8List> scoreResponse = await dio.post(
        '$selcrsUrl/scoreqry/sco_query_prs_sso2.asp',
        data: <String, String>{
          'SID': username,
          'PASSWD': base64md5Password,
          'ACTION': '0',
          'INTYPE': '1',
        },
      );
      final String text = const Utf8Decoder().convert(scoreResponse.data!);
//      debugPrint(text);
      if (text.contains('資料錯誤請重新輸入')) {
        throw GeneralResponse(statusCode: 400, message: 'score error');
      } else {
        dumpError('score', text);
        throw GeneralResponse.unknownError();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
      } else {
        error++;
        if (error > 5) {
          rethrow;
        } else {
          changeSelcrsUrl();
          return login(
            username: username,
            password: password,
          );
        }
      }
    }
    try {
      final Response<Uint8List> courseResponse = await dio.post(
        '$selcrsUrl/menu4/Studcheck_sso2.asp',
        data: <String, String>{
          'stuid': username,
          'SPassword': base64md5Password,
        },
      );
      final String text = const Utf8Decoder().convert(courseResponse.data!);
//      debugPrint('course =  $text');
      if (text.contains('學號碼密碼不符')) {
        throw GeneralResponse(statusCode: 400, message: 'course error');
      } else if (text.contains('請先填寫')) {
        ///https://regweb.nsysu.edu.tw/webreg/confirm_wuhan_pneumonia.asp?STUID=%s&STAT_COD=1&STATUS_COD=1&LOGINURL=https://selcrs.nsysu.edu.tw/
        throw GeneralResponse(
          statusCode: 401,
          message: 'need to fill out form',
        );
      } else {
        dumpError('course', text);
        throw GeneralResponse.unknownError();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
//        debugPrint('text =  $text');
        this.username = username;
        this.password = password;
        isLogin = true;
        return GeneralResponse.success();
      } else {
        error++;
        if (error > 5) {
          rethrow;
        } else {
          changeSelcrsUrl();
          return login(
            username: username,
            password: password,
          );
        }
      }
    }
  }

  Future<GeneralResponse?> reLogin() async {
    reLoginCount++;
    return await login(username: username, password: password);
  }

  /*
  * 取得使用者資訊
  * error status code
  * 400: 帳號密碼錯誤
  * */
  Future<UserInfo> getUserInfo() async {
    final Response<Uint8List> response = await dio.get<Uint8List>(
      '$selcrsUrl/menu4/tools/changedat.asp',
    );
    final String text = const Utf8Decoder().convert(response.data!);
    if (text.contains(courseTimeoutText) && canReLogin) {
      await reLogin();
      return getUserInfo();
    }
    if (!canReLogin) {
      dumpError('getUserInfo', text);
      throw GeneralResponse.unknownError();
    }
    reLoginCount = 0;
    return parserUserInfo(text);
  }

  UserInfo parserUserInfo(String text) {
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

  Future<SemesterData> getCourseSemesterData({
    required Semester defaultSemester,
  }) async {
    final String url = '$selcrsUrl/menu4/query/stu_slt_up.asp';
    final Response<Uint8List> response = await dio.post(url);
    final String text = const Utf8Decoder().convert(response.data!);
//      print('text =  ${text}');
    if (text.contains(courseTimeoutText) && canReLogin) {
      await reLogin();
      return getCourseSemesterData(
        defaultSemester: defaultSemester,
      );
    }
    if (!canReLogin) {
      dumpError('getCourseSemesterData', text);
      throw GeneralResponse.unknownError();
    }
    reLoginCount = 0;
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

  Future<CourseData> getCourseData({
    required String username,
    required TimeCodeConfig timeCodeConfig,
    required String semester,
  }) async {
    final String url = '$selcrsUrl/menu4/query/stu_slt_data.asp';
    final Response<Uint8List> response = await dio.post(
      url,
      data: <String, String>{
        'stuact': 'B',
        'YRSM': semester,
        'Stuid': username,
        'B1': '%BDT%A9w%B0e%A5X',
      },
      options: _courseOption,
    );
    final String text = const Utf8Decoder().convert(response.data!);
//      debugPrint('text =  ${text}');
    if (text.contains(courseTimeoutText) && canReLogin) {
      await reLogin();
      return getCourseData(
        username: username,
        timeCodeConfig: timeCodeConfig,
        semester: semester,
      );
    }
    if (!canReLogin) {
      dumpError('getCourseData', text);
      throw GeneralResponse.unknownError();
    }
    reLoginCount = 0;
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

  Future<ScoreSemesterData> getScoreSemesterData() async {
    final String url =
        '$selcrsUrl/scoreqry/sco_query.asp?ACTION=702&KIND=2&LANGS=$language';
    try {
      final Response<Uint8List> response = await dio.post(
        url,
        options: _scoreOption,
      );
      final String text = const Utf8Decoder().convert(response.data!);
      //print('text =  ${text}');
      final dom.Document document = parse(text, encoding: 'BIG-5');
      final List<dom.Element> selectDoc =
          document.getElementsByTagName('select');
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        final String text =
            const Utf8Decoder().convert(e.response!.data as Uint8List);
        if (text.contains(scoreTimeoutText) && canReLogin) {
          await reLogin();
          return getScoreSemesterData();
        }
        reLoginCount = 0;
        if (!canReLogin) {
          dumpError('getScoreSemesterData', text);
          throw GeneralResponse.unknownError();
        }
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<ScoreData> getScoreData({
    required String? year,
    required String? semester,
    bool searchPreScore = false,
  }) async {
    final String url =
        '$selcrsUrl/scoreqry/sco_query.asp?ACTION=804&KIND=2&LANGS=$language';
    try {
      final Response<Uint8List> response = await dio.post(
        url,
        options: _scoreOption,
        data: <String, String?>{
          'SYEAR': year,
          'SEM': semester,
        },
      );
      final String text = const Utf8Decoder().convert(response.data!);
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
          final List<dom.Element> fontDoc =
              trDoc[i].getElementsByTagName('font');
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
                (score.finalScore == null ||
                    (score.finalScore ?? '') == '--')) {
              final PreScore? preScore =
                  await getPreScoreData(score.courseNumber);
              if (preScore != null) {
                score = score.copyWith(
                  finalScore: preScore.grades,
                  isPreScore: true,
                );
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        final String text =
            const Utf8Decoder().convert(e.response!.data as Uint8List);
        if (text.contains(scoreTimeoutText) && canReLogin) {
          await reLogin();
          return getScoreData(
            year: year,
            semester: semester,
            searchPreScore: searchPreScore,
          );
        }
        reLoginCount = 0;
        if (!canReLogin) {
          dumpError('getScoreData', text);
          throw GeneralResponse.unknownError();
        }
      }
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<PreScore?> getPreScoreData(String? courseNumber) async {
    final String url =
        '$selcrsUrl/scoreqry/sco_query.asp?ACTION=814&KIND=1&LANGS=$language';
    final Response<Uint8List> response = await dio.post(
      url,
      options: _scoreOption,
      data: <String, String?>{
        'CRSNO': courseNumber,
      },
    );
    final String text = const Utf8Decoder().convert(response.data!);
    //print('text = $text}');
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

  Future<String> getUsername({
    required String name,
    required String id,
  }) async {
    final String url = '$selcrsUrl/newstu/stu_new.asp?action=16';
    final String encoded = Utils.uriEncodeBig5(name);
    final Response<Uint8List> response = await dio.post(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        contentType: Headers.formUrlEncodedContentType,
      ),
      data: <String, String>{
        'CNAME': encoded,
        'T_CID': id,
        'B1': '%BDT%A9w%B0e%A5X',
      },
    );
    final String text = big5.decode(response.data!);
    final dom.Document document = parse(text, encoding: 'BIG-5');
    final List<dom.Element> elements = document.getElementsByTagName('b');
    return elements.isNotEmpty ? elements[0].text : '';
  }

  Future<UserInfo> changeMail({
    required String mail,
  }) async {
    try {
      final Response<Uint8List> response = await dio.post(
        '$selcrsUrl/menu4/tools/changedat.asp',
        options: _courseOption,
        data: <String, String>{
          'T1': mail,
        },
      );
      final String text = const Utf8Decoder().convert(response.data!);
      if (text.contains(courseTimeoutText) && canReLogin) {
        await reLogin();
        return changeMail(mail: mail);
      }
      if (!canReLogin) {
        dumpError('changeMail', text);
        throw GeneralResponse.unknownError();
      }
      reLoginCount = 0;
      return parserUserInfo(text);
    } on DioException catch (_) {
      rethrow;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> dumpError(
    String feature,
    String text,
  ) async {
    reLoginCount = 0;
    if (FirebaseCrashlyticsUtils.isSupported) {
      FirebaseCrashlytics.instance.setCustomKey('crawler_error_$feature', text);
    }
  }
}
