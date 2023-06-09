import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/utils/big5/big5.dart';
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
  Future<void> login({
    required String username,
    required String password,
    required GeneralCallback<GeneralResponse> callback,
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
      final String text = big5.decode(response.data!);
//          print('Response =  $text');
      //    print('response.statusCode = ${response.statusCode}');
      if (text.contains('資料錯誤請重新輸入')) {
        callback.onError(
          GeneralResponse(statusCode: 401, message: 'graduation login error'),
        );
      } else {
        callback.onError(
          GeneralResponse.unknownError(),
        );
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.badResponse && e.response!.statusCode == 302) {
        isLogin = true;
        callback.onSuccess(GeneralResponse.success());
      } else {
        callback.onFailure(e);
        rethrow;
      }
    } on Exception catch (_) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }

  Future<void> getGraduationReport({
    required String username,
    required GeneralCallback<GraduationReportData?> callback,
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
      final GraduationReportData graduationReportData = GraduationReportData(
        missingRequiredCourse: <MissingRequiredCourse>[],
        generalEducationCourse: <GeneralEducationCourse>[],
        otherEducationsCourse: <OtherEducationsCourse>[],
      );
      final String text = big5.decode(response.data!);
      final int startTime = DateTime.now().millisecondsSinceEpoch;
//      debugPrint('text = $text');
//      debugPrint(DateTime.now().toString());
      final Document document = parse(text, encoding: 'BIG-5');
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
        callback.onSuccess(null);
        return;
      }
      //    graduationReportData.generalEducationCourse.forEach((i) {
      //      print('type = ${i.type}');
      //    });
      final int endTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint(((endTime - startTime) / 1000.0).toString());
      callback.onSuccess(graduationReportData);
    } on DioError catch (e) {
      callback.onFailure(e);
      rethrow;
    } catch (e) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }
}
