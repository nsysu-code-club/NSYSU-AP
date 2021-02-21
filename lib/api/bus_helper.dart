import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:big5/big5.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';

class BusHelper {
  static const BASE_PATH = 'https://ibus.nsysu.edu.tw';

  static Dio dio;
  static CookieJar cookieJar;

  static BusHelper _instance;

  static bool isLogin = false;

  static BusHelper get instance {
    if (_instance == null) {
      _instance = BusHelper();
      dio = Dio();
      initCookiesJar();
    }
    return _instance;
  }

  Options get _tfOption => Options(
        responseType: ResponseType.bytes,
      );

  static initCookiesJar() {
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(BASE_PATH));
  }

  Future<List<BusInfo>> getBusInfoList({
    GeneralCallback<List<BusInfo>> callback,
    Locale locale,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode == 'zh' || locale.languageCode == 'en')
        languageCode = locale.languageCode;
      else
        languageCode = 'en';
      final path = 'https://abc873693.github.io/nsysu-bus/bus_info_data_$languageCode.json';
      var response = await dio.get(
        path,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      final list = BusInfo.fromRawList(response.data);
      callback.onSuccess(list);
    } on DioError catch (e) {
      if (callback != null) {
        callback.onFailure(e);
        // debugPrint(big5.decode(e.response.data));
        return null;
      } else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<List<BusTime>> getBusTime({
    BusInfo busInfo,
    GeneralCallback<List<BusTime>> callback,
    Locale locale,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode == 'zh' || locale.languageCode == 'en')
        languageCode = locale.languageCode;
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
          },
        ),
      );
      final list = BusTime.fromRawList(response.data);
      callback.onSuccess(list);
    } on DioError catch (e) {
      if (callback != null) {
        callback.onFailure(e);
        // debugPrint(big5.decode(e.response.data));
        return null;
      } else
        throw e;
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }
}
