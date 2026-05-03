import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nsysu_crawler/src/build_mode.dart';
import 'package:nsysu_crawler/src/helpers/selcrs_helper.dart';
import 'package:nsysu_crawler/src/models/graduation_report_data.dart';
import 'package:nsysu_crawler/src/parsers/html_parser.dart';
import 'package:nsysu_crawler/src/utils/codec_utils.dart';

class GraduationHelper {
  static GraduationHelper? _instance;

  //ignore: prefer_constructors_over_static_methods
  static GraduationHelper get instance {
    return _instance ??= GraduationHelper();
  }

  GraduationHelper() {
    initCookiesJar();
  }

  Dio dio = Dio();
  CookieJar cookieJar = CookieJar();

  bool isLogin = false;

  void initCookiesJar() {
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse('${SelcrsHelper.instance.selcrsUrl}'));
  }

  void logout() {
    isLogin = false;
    initCookiesJar();
  }

  /*
  * 畢業審查系統登入
  * error status code
  * 401: 帳號密碼錯誤
  * */
  Future<ApiResult<GeneralResponse>> login({
    required String username,
    required String password,
  }) async {
    try {
      final String base64md5Password = base64md5(password);
      final Response<Uint8List> response = await dio.post<Uint8List>(
        '${SelcrsHelper.instance.selcrsUrl}/gadchk/gad_chk_login_prs_sso2.asp',
        options: Options(
          responseType: ResponseType.bytes,
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: <String, String>{
          'SID': username,
          'PASSWD': base64md5Password,
          'PGKIND': 'GAD_CHK',
          'ACTION': '0',
        },
      );
      final String text = const Utf8Decoder().convert(response.data!);
      if (text.contains('資料錯誤請重新輸入')) {
        return ApiError<GeneralResponse>(
          GeneralResponse(statusCode: 401, message: 'graduation login error'),
        );
      } else {
        return ApiError<GeneralResponse>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        isLogin = true;
        return ApiSuccess<GeneralResponse>(GeneralResponse.success());
      } else {
        return ApiFailure<GeneralResponse>(e);
      }
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<GeneralResponse>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<GraduationReportData?>> getGraduationReport({
    required String username,
  }) async {
    final String url =
        '${SelcrsHelper.instance.selcrsUrl}/gadchk/gad_chk_stu_list.asp?'
        'stno=$username&KIND=5&frm=1';
    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      final String text = const Utf8Decoder().convert(response.data!);
      final int startTime = DateTime.now().millisecondsSinceEpoch;
      final GraduationReportData? data = parseGraduationReport(text);
      final int endTime = DateTime.now().millisecondsSinceEpoch;
      if (kCrawlerDebugMode) {
        final double seconds = (endTime - startTime) / 1000.0;
        developer.log(
          'parsed graduation report in ${seconds}s',
          name: 'nsysu_crawler.graduation',
        );
      }
      return ApiSuccess<GraduationReportData?>(data);
    } on DioException catch (e) {
      return ApiFailure<GraduationReportData?>(e);
    } catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<GraduationReportData?>(GeneralResponse.unknownError());
    }
  }
}
