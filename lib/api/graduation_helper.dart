import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:nsysu_ap/api/exception/graduation_login_exception.dart';
import 'package:nsysu_ap/api/parser/graduation_parser.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/utils/utils.dart';

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

  final GraduationParser parser = GraduationParser();

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
  Future<GeneralResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final String base64md5Password = Utils.base64md5(password);
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
//          print('Response =  $text');
      //    print('response.statusCode = ${response.statusCode}');
      if (text.contains('資料錯誤請重新輸入')) {
        throw GraduationLoginPasswordException();
      } else {
        throw GraduationLoginUnknownException();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 302) {
        isLogin = true;
        return GeneralResponse.success();
      } else {
        rethrow;
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<GraduationReportData?> getGraduationReport({
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
      return parser.graduationReport(text);
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
