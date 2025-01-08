import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:nsysu_ap/api/exception/selcrs_exception.dart';
import 'package:nsysu_ap/api/parser/selcrs_parser.dart';
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

  SelcrsParser parser = SelcrsParser();

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
      if (text.contains('資料錯誤請重新輸入')) {
        throw SelcrsLoginScorePasswordException();
      } else {
        dumpError('score', text);
        throw SelcrsLoginUnknownException();
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
        throw SelcrsLoginCoursePasswordException();
      } else if (text.contains('請先填寫')) {
        ///https://regweb.nsysu.edu.tw/webreg/confirm_wuhan_pneumonia.asp?STUID=%s&STAT_COD=1&STATUS_COD=1&LOGINURL=https://selcrs.nsysu.edu.tw/
        throw SelcrsLoginConfirmFormException();
      } else {
        dumpError('course', text);
        throw SelcrsLoginUnknownException();
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
    return parser.userInfo(text);
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
    return parser.courseSemesterData(defaultSemester, text);
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
    return parser.courseData(timeCodeConfig, text);
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
      return parser.scoreSemesterData(text);
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
      return parser.scoreData(text, searchPreScore, getPreScoreData);
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

  Future<PreScore?> getPreScoreData(String courseNumber) async {
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
    return parser.preScore(text);
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
    return parser.username(text);
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
      return parser.userInfo(text);
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
