import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class BusHelper {
  static const String basePath = 'https://ibus.nsysu.edu.tw';

  static BusHelper? _instance;

  //ignore: prefer_constructors_over_static_methods
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
    cookieJar.loadForRequest(Uri.parse(basePath));
  }

  Future<ApiResult<List<BusInfo>?>> getBusInfoList({
    required Locale locale,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode.contains('zh')) {
        languageCode = 'zh';
      } else {
        languageCode = 'en';
      }
      final String path =
          'https://nsysu-code-club.github.io/nsysu-bus/bus_info_data_$languageCode.json';
      final Response<String> response = await dio.get<String>(
        path,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      if (response.data != null) {
        final List<BusInfo>? list = BusInfo.fromRawList(response.data!);
        return ApiSuccess<List<BusInfo>?>(list);
      } else {
        return ApiError<List<BusInfo>?>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      return ApiFailure<List<BusInfo>?>(e);
    } on Exception catch (_) {
      if (kDebugMode) rethrow;
      return ApiError<List<BusInfo>?>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<List<BusTime>?>> getBusTime({
    required Locale locale,
    required BusInfo busInfo,
  }) async {
    try {
      String languageCode;
      if (locale.languageCode.contains('zh')) {
        languageCode = 'zh';
      } else {
        languageCode = 'en';
      }
      final Response<String> response = await dio.post<String>(
        '$basePath/API/RoutePathStop.aspx?${DateTime.now().millisecondsSinceEpoch}',
        options: Options(
          responseType: ResponseType.plain,
        ),
        data: FormData.fromMap(
          <String, dynamic>{
            'RID': busInfo.routeId,
            'C': languageCode,
            'CID': busInfo.carId,
          },
        ),
      );
      if (response.data != null) {
        final List<BusTime>? list = BusTime.fromRawList(response.data!);
        return ApiSuccess<List<BusTime>?>(list);
      } else {
        return ApiError<List<BusTime>?>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      return ApiFailure<List<BusTime>?>(e);
    } on Exception catch (_) {
      if (kDebugMode) rethrow;
      return ApiError<List<BusTime>?>(GeneralResponse.unknownError());
    }
  }
}
