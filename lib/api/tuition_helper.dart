import 'package:ap_common/callback/general_callback.dart';
import 'package:big5/big5.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';

class TuitionHelper {
  static const BASE_PATH = 'https://tfstu.nsysu.edu.tw';

  static Dio dio;
  static CookieJar cookieJar;

  static TuitionHelper _instance;

  static bool isLogin = false;

  static TuitionHelper get instance {
    if (_instance == null) {
      _instance = TuitionHelper();
      cookieJar = CookieJar();
      dio = Dio();
      dio.interceptors.add(CookieManager(cookieJar));
      cookieJar.loadForRequest(Uri.parse(BASE_PATH));
    }
    return _instance;
  }

  Options get _tfOption => Options(
        responseType: ResponseType.bytes,
      );

  void logout() {
    isLogin = false;
    dio.interceptors.clear();
  }

  Future<GeneralResponse> login({
    @required String username,
    @required String password,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      var response = await dio.post(
        '$BASE_PATH/tfstu/tfstu_login_chk.asp',
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
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        isLogin = true;
        return callback?.onSuccess(GeneralResponse.success());
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
    return null;
  }

  Future<List<TuitionAndFees>> getData({
    GeneralCallback<List<TuitionAndFees>> callback,
  }) async {
    var url = '$BASE_PATH/tfstu/tfstudata.asp?act=11';
    try {
      var response = await dio.get(
        url,
        options: _tfOption,
      );
      String text = big5.decode(response.data);
      debugPrint('text =  ${text}');
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
      return callback?.onSuccess(list);
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

  Future<List<int>> downloadFdf({
    String serialNumber,
    GeneralCallback callback,
  }) async {
    try {
      var response = await dio.get(
        '$BASE_PATH/tfstu/$serialNumber',
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
}
