import 'package:ap_common/callback/general_callback.dart';
import 'package:big5/big5.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/utils/utils.dart';

class GraduationHelper {
  static Dio dio;
  static CookieJar cookieJar;

  static GraduationHelper _instance;

  static bool isLogin = false;

  static GraduationHelper get instance {
    if (_instance == null) {
      _instance = GraduationHelper();
      cookieJar = CookieJar();
      dio = Dio();
      dio.interceptors.add(CookieManager(cookieJar));
      cookieJar.loadForRequest(Uri.parse('${Helper.selcrsUrl}'));
    }
    return _instance;
  }

  void logout() {
    isLogin = false;
    dio.interceptors.clear();
  }

  /*
  * 畢業審查系統登入
  * error status code
  * 401: 帳號密碼錯誤
  * */
  Future<GeneralResponse> login({
    @required String username,
    @required String password,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      var base64md5Password = Utils.base64md5(password);
      var response = await dio.post(
        '${Helper.selcrsUrl}/gadchk/gad_chk_login_prs_sso2.asp',
        options: Options(
          responseType: ResponseType.bytes,
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
          GeneralResponse(statusCode: 401, message: 'graduation login error'),
        );
      else {
        callback?.onError(
          GeneralResponse.unknownError(),
        );
      }
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        return callback.onSuccess(GeneralResponse.success());
      } else {
        callback?.onFailure(e);
      }
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<GraduationReportData> getGraduationReport({
    @required String username,
    GeneralCallback callback,
  }) async {
    var url = '${Helper.selcrsUrl}/gadchk/gad_chk_stu_list.asp?'
        'stno=$username&KIND=5&frm=1';
    try {
      var response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
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
}
