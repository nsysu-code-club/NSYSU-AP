import 'dart:convert';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';

class TuitionHelper {
  static const String basePATH = 'https://tfstu.nsysu.edu.tw';

  static TuitionHelper? _instance;

  // ignore: prefer_constructors_over_static_methods
  static TuitionHelper get instance {
    return _instance ??= TuitionHelper();
  }

  TuitionHelper() {
    dio = Dio();
    initCookiesJar();
  }

  late Dio dio;
  late CookieJar cookieJar;

  bool isLogin = false;

  void initCookiesJar() {
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(basePATH));
  }

  Options get _tfOption => Options(
        responseType: ResponseType.bytes,
      );

  void logout() {
    isLogin = false;
    initCookiesJar();
  }

  Future<void> login({
    required String username,
    required String password,
    required GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      final Response<Int8List> response = await dio.post<Int8List>(
        '$basePATH/tfstu/tfstu_login_chk.asp',
        options: Options(
          responseType: ResponseType.bytes,
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: <String, String>{
          'ID': username,
          'passwd': password,
        },
      );
      final String _ = const Utf8Decoder().convert(response.data!);
      // debugPrint('Request =  ${response.request.data}');
      // debugPrint('Response =  $text');
      //    debugPrint('response.statusCode = ${response.statusCode}');
    } on DioError catch (e) {
      if (e.type == DioErrorType.badResponse && e.response!.statusCode == 302) {
        isLogin = true;
        return callback.onSuccess(GeneralResponse.success());
      } else {
        callback.onFailure(e);
        // debugPrint(big5.decode(e.response.data));
      }
    } on Exception catch (_) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }

  Future<void> getData({
    required GeneralCallback<List<TuitionAndFees>> callback,
  }) async {
    const String url = '$basePATH/tfstu/tfstudata.asp?act=11';
    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        url,
        options: _tfOption,
      );
      final String text = const Utf8Decoder().convert(response.data!);
      // debugPrint('text =  ${text}');
      if (text.contains('沒有合乎查詢條件的資料')) {
        callback.onSuccess(<TuitionAndFees>[]);
      }
      final Document document = parse(text, encoding: 'BIG-5');
      final List<Element> tbody = document.getElementsByTagName('tbody');
      List<TuitionAndFees> list = <TuitionAndFees>[];
      final List<Element> trElements = tbody[1].getElementsByTagName('tr');
      for (int i = 1; i < trElements.length; i++) {
        final List<Element> tdDoc = trElements[i].getElementsByTagName('td');
        final List<Element> aTag = tdDoc[4].getElementsByTagName('a');
        String? serialNumber;
        if (aTag.isNotEmpty) {
          serialNumber = aTag[0]
              .attributes['onclick']!
              .split("javascript:window.location.href='")
              .last;
          serialNumber = serialNumber.substring(0, serialNumber.length - 1);
        }
        String paymentStatus = '';
        String paymentStatusEn = '';
        for (final int charCode in tdDoc[2].text.codeUnits) {
          if (charCode < 200) {
            if (charCode == 32) {
              paymentStatusEn += '\n';
            } else {
              paymentStatusEn += String.fromCharCode(charCode);
            }
          } else {
            paymentStatus += String.fromCharCode(charCode);
          }
        }
        final String titleEN = tdDoc[0].getElementsByTagName('span')[0].text;
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
      list = list.reversed.toList();
      callback.onSuccess(list);
    } on DioError catch (e) {
      callback.onFailure(e);
    } on Exception catch (_) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }

  Future<void> downloadFdf({
    required String serialNumber,
    required GeneralCallback<Uint8List?> callback,
  }) async {
    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        '$basePATH/tfstu/$serialNumber',
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
      return callback.onSuccess(response.data) ?? response.data;
    } on DioError catch (e) {
      callback.onFailure(e);
    } on Exception {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }
}
