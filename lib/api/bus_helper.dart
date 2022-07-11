import 'package:ap_common/callback/general_callback.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';

class BusHelper {
  static const BASE_PATH = 'https://ibus.nsysu.edu.tw';

  static BusHelper? _instance;

  static BusHelper get instance {
    return _instance ??= BusHelper();
  }

  BusHelper() {
    initCookiesJar();
  }

  Dio dio = Dio();
  CookieJar cookieJar = CookieJar();

  bool isLogin = false;

  void initCookiesJar() {
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(BASE_PATH));
  }

  Future<void> getBusInfoList({
    required GeneralCallback<List<BusInfo>?> callback,
    required Locale locale,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode.contains('zh'))
        languageCode = 'zh';
      else
        languageCode = 'en';
      final path =
          'https://nsysu-code-club.github.io/nsysu-bus/bus_info_data_$languageCode.json';
      var response = await dio.get(
        path,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      final list = BusInfo.fromRawList(response.data);
      callback.onSuccess(list);
    } on DioError catch (e) {
      callback.onFailure(e);
      // debugPrint(big5.decode(e.response.data));
      rethrow;
    } on Exception catch (_) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
  }

  Future<void> getBusTime({
    required Locale locale,
    required BusInfo busInfo,
    required GeneralCallback<List<BusTime>?> callback,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode.contains('zh'))
        languageCode = 'zh';
      else
        languageCode = 'en';
      var response = await dio.post(
        '$BASE_PATH/API/RoutePathStop.aspx?${DateTime.now().millisecondsSinceEpoch}',
        options: Options(
          responseType: ResponseType.plain,
        ),
        data: FormData.fromMap(
          {
            "RID": busInfo.routeId,
            "C": languageCode,
            "CID": busInfo.carId,
          },
        ),
      );
      final list = BusTime.fromRawList(response.data);
      callback.onSuccess(list);
    } on DioError catch (e) {
      callback.onFailure(e);
      // debugPrint(big5.decode(e.response.data));
      rethrow;
    } on Exception catch (e) {
      callback.onError(GeneralResponse.unknownError());
      rethrow;
    }
    return null;
  }
}
