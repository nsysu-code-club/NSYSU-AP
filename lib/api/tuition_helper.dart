import 'dart:convert';
import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nsysu_ap/api/parser/tuition_parser.dart';
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

  final TuitionParser parser = TuitionParser();

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

  Future<GeneralResponse> login({
    required String username,
    required String password,
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
      final String data = const Utf8Decoder().convert(response.data!);
      // debugPrint('Request =  ${response.request.data}');
      // debugPrint('Response =  $text');
      //    debugPrint('response.statusCode = ${response.statusCode}');
      CrashlyticsUtil.instance.recordError(
        GeneralResponse.unknownError(),
        StackTrace.current,
        information: <Object>[data],
      );
      throw GeneralResponse.unknownError();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse &&
          e.response!.statusCode == 302) {
        isLogin = true;
        return GeneralResponse.success();
      } else {
        // debugPrint(big5.decode(e.response.data));
        rethrow;
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<List<TuitionAndFees>> getData() async {
    const String url = '$basePATH/tfstu/tfstudata.asp?act=11';
    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        url,
        options: _tfOption,
      );
      final String text = const Utf8Decoder().convert(response.data!);
      // debugPrint('text =  ${text}');
      return parser.tuitionAndFeeList(text);
    } on DioException catch (_) {
      rethrow;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<Uint8List?> downloadFdf({
    required String serialNumber,
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
      return response.data;
    } on DioException catch (_) {
      rethrow;
    } on Exception {
      rethrow;
    }
  }
}
