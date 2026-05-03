import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:nsysu_crawler/src/abstractions/analytics_logger.dart';
import 'package:nsysu_crawler/src/abstractions/crash_reporter.dart';
import 'package:nsysu_crawler/src/build_mode.dart';
import 'package:nsysu_crawler/src/models/pre_score.dart';
import 'package:nsysu_crawler/src/models/score_semester_data.dart';
import 'package:nsysu_crawler/src/parsers/html_parser.dart';
import 'package:nsysu_crawler/src/utils/big5/big5.dart';
import 'package:nsysu_crawler/src/utils/codec_utils.dart';
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

  CrashReporter crashReporter = const NoOpCrashReporter();
  AnalyticsLogger analyticsLogger = const NoOpAnalyticsLogger();

  /// Returns the active locale language code (e.g. `'zh'` or `'en'`).
  /// Defaults to `'zh'`; host app should override at bootstrap.
  String Function() languageProvider = _defaultLanguageProvider;

  static String _defaultLanguageProvider() => 'zh';

  bool get canReLogin => reLoginCount < 5;

  String? get selcrsUrl => sprintf(baseUrl, <int>[index]);

  int index = 1;
  int error = 0;

  String get language => languageProvider() == 'en' ? 'eng' : 'cht';

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
    if (kCrawlerDebugMode) {
      developer.log('selcrsUrl=$selcrsUrl', name: 'nsysu_crawler.selcrs');
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
  Future<ApiResult<GeneralResponse>> login({
    required String username,
    required String password,
  }) async {
    final String base64md5Password = base64md5(password);
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
        return ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 400, message: 'score error'),
        );
      } else {
        _dumpError('score', text);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
      } else {
        error++;
        if (error > 5) {
          return ApiFailure<GeneralResponse>(e);
        } else {
          changeSelcrsUrl();
          return login(username: username, password: password);
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
      if (text.contains('學號碼密碼不符')) {
        return ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 400, message: 'course error'),
        );
      } else if (text.contains('請先填寫')) {
        return ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 401, message: 'need to fill out form'),
        );
      } else {
        _dumpError('course', text);
        return ApiError<GeneralResponse>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        this.username = username;
        this.password = password;
        isLogin = true;
        return ApiSuccess<GeneralResponse>(GeneralResponse.success());
      } else {
        error++;
        if (error > 5) {
          return ApiFailure<GeneralResponse>(e);
        } else {
          changeSelcrsUrl();
          return login(username: username, password: password);
        }
      }
    }
  }

  Future<GeneralResponse?> reLogin() async {
    reLoginCount++;
    final ApiResult<GeneralResponse> result = await login(
      username: username,
      password: password,
    );
    return switch (result) {
      ApiSuccess<GeneralResponse>(:final GeneralResponse data) => data,
      _ => null,
    };
  }

  /*
  * 取得使用者資訊
  * error status code
  * 400: 帳號密碼錯誤
  * */
  Future<ApiResult<UserInfo>> getUserInfo() async {
    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        '$selcrsUrl/menu4/tools/changedat.asp',
      );
      final String text = const Utf8Decoder().convert(response.data!);
      if (text.contains(courseTimeoutText) && canReLogin) {
        await reLogin();
        return getUserInfo();
      }
      if (!canReLogin) {
        _dumpError('getUserInfo', text);
        return ApiError<UserInfo>(GeneralResponse.unknownError());
      }
      reLoginCount = 0;
      return ApiSuccess<UserInfo>(parseUserInfo(text));
    } on DioException catch (e) {
      return ApiFailure<UserInfo>(e);
    } on Exception {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<UserInfo>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<SemesterData>> getCourseSemesterData({
    required Semester defaultSemester,
  }) async {
    final String url = '$selcrsUrl/menu4/query/stu_slt_up.asp';
    try {
      final Response<Uint8List> response = await dio.post(url);
      final String text = const Utf8Decoder().convert(response.data!);
      if (text.contains(courseTimeoutText) && canReLogin) {
        await reLogin();
        return getCourseSemesterData(defaultSemester: defaultSemester);
      }
      if (!canReLogin) {
        _dumpError('getCourseSemesterData', text);
        return ApiError<SemesterData>(GeneralResponse.unknownError());
      }
      reLoginCount = 0;
      return ApiSuccess<SemesterData>(
        parseCourseSemesterData(text, defaultSemester: defaultSemester),
      );
    } on DioException catch (e) {
      return ApiFailure<SemesterData>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<SemesterData>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<CourseData>> getCourseData({
    required String username,
    required TimeCodeConfig timeCodeConfig,
    required String semester,
  }) async {
    final String url = '$selcrsUrl/menu4/query/stu_slt_data.asp';
    try {
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
      if (text.contains(courseTimeoutText) && canReLogin) {
        await reLogin();
        return getCourseData(
          username: username,
          timeCodeConfig: timeCodeConfig,
          semester: semester,
        );
      }
      if (!canReLogin) {
        _dumpError('getCourseData', text);
        return ApiError<CourseData>(GeneralResponse.unknownError());
      }
      reLoginCount = 0;
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final CourseData courseData = parseCourseData(
        text,
        timeCodeConfig: timeCodeConfig,
        languageCode: languageProvider(),
      );
      if (courseData.courses.isNotEmpty) {
        final int endTime = DateTime.now().millisecondsSinceEpoch;
        analyticsLogger.logTimeEvent(
          'course_html_parser',
          (endTime - startTime) / 1000.0,
        );
      }
      return ApiSuccess<CourseData>(courseData);
    } on DioException catch (e) {
      return ApiFailure<CourseData>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<CourseData>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<ScoreSemesterData>> getScoreSemesterData() async {
    final String url =
        '$selcrsUrl/scoreqry/sco_query.asp?ACTION=702&KIND=2&LANGS=$language';
    try {
      final Response<Uint8List> response = await dio.post(
        url,
        options: _scoreOption,
      );
      final String text = const Utf8Decoder().convert(response.data!);
      return ApiSuccess<ScoreSemesterData>(parseScoreSemesterData(text));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        final String text = const Utf8Decoder().convert(
          e.response!.data as Uint8List,
        );
        if (text.contains(scoreTimeoutText) && canReLogin) {
          await reLogin();
          return getScoreSemesterData();
        }
        if (!canReLogin) {
          _dumpError('getScoreSemesterData', text);
          return ApiError<ScoreSemesterData>(GeneralResponse.unknownError());
        }
        reLoginCount = 0;
      }
      return ApiFailure<ScoreSemesterData>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<ScoreSemesterData>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<ScoreData>> getScoreData({
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
        data: <String, String?>{'SYEAR': year, 'SEM': semester},
      );
      final String text = const Utf8Decoder().convert(response.data!);
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final ParsedScoreResult parsed = parseScoreData(text);
      final List<Score> list = <Score>[...parsed.scores];
      if (searchPreScore) {
        for (int i = 0; i < list.length; i++) {
          final Score score = list[i];
          if (score.finalScore == null || (score.finalScore ?? '') == '--') {
            final PreScore? preScore = await getPreScoreData(
              score.courseNumber,
            );
            if (preScore != null) {
              list[i] = score.copyWith(
                finalScore: preScore.grades,
                isPreScore: true,
              );
            }
          }
        }
      }
      if (list.isNotEmpty) {
        final int endTime = DateTime.now().millisecondsSinceEpoch;
        analyticsLogger.logTimeEvent(
          'score_html_parser',
          (endTime - startTime) / 1000.0,
        );
      }
      final ScoreData scoreData = ScoreData(
        scores: list,
        detail: parsed.detail,
        scoreType: resolveScoreType(list),
      );
      return ApiSuccess<ScoreData>(scoreData);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        final String text = const Utf8Decoder().convert(
          e.response!.data as Uint8List,
        );
        if (text.contains(scoreTimeoutText) && canReLogin) {
          await reLogin();
          return getScoreData(
            year: year,
            semester: semester,
            searchPreScore: searchPreScore,
          );
        }
        if (!canReLogin) {
          _dumpError('getScoreData', text);
          return ApiError<ScoreData>(GeneralResponse.unknownError());
        }
        reLoginCount = 0;
      }
      return ApiFailure<ScoreData>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<ScoreData>(GeneralResponse.unknownError());
    }
  }

  Future<PreScore?> getPreScoreData(String? courseNumber) async {
    final String url =
        '$selcrsUrl/scoreqry/sco_query.asp?ACTION=814&KIND=1&LANGS=$language';
    final Response<Uint8List> response = await dio.post(
      url,
      options: _scoreOption,
      data: <String, String?>{'CRSNO': courseNumber},
    );
    final String text = const Utf8Decoder().convert(response.data!);
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

  Future<ApiResult<String>> getUsername({
    required String name,
    required String id,
  }) async {
    final String url = '$selcrsUrl/newstu/stu_new.asp?action=16';
    try {
      final String encoded = uriEncodeBig5(name);
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
      return ApiSuccess<String>(elements.isNotEmpty ? elements[0].text : '');
    } on DioException catch (e) {
      return ApiFailure<String>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<String>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<UserInfo>> changeMail({required String mail}) async {
    try {
      final Response<Uint8List> response = await dio.post(
        '$selcrsUrl/menu4/tools/changedat.asp',
        options: _courseOption,
        data: <String, String>{'T1': mail},
      );
      final String text = const Utf8Decoder().convert(response.data!);
      if (text.contains(courseTimeoutText) && canReLogin) {
        await reLogin();
        return changeMail(mail: mail);
      }
      if (!canReLogin) {
        _dumpError('changeMail', text);
        return ApiError<UserInfo>(GeneralResponse.unknownError());
      }
      reLoginCount = 0;
      return ApiSuccess<UserInfo>(parseUserInfo(text));
    } on DioException catch (e) {
      return ApiFailure<UserInfo>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<UserInfo>(GeneralResponse.unknownError());
    }
  }

  void _dumpError(String feature, String text) {
    reLoginCount = 0;
    crashReporter.setCustomKey('crawler_error_$feature', text);
  }
}
