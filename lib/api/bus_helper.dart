import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';

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

  Future<List<BusInfo>> getBusInfoList({
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
      if (response.data case final String data?) {
        if (BusInfo.fromRawList(data) case final List<BusInfo> list?) {
          return list;
        } else {
          CrashlyticsUtil.instance.recordError(
            GeneralResponse.unknownError(),
            StackTrace.current,
            information: <Object>[
              data,
            ],
          );
          throw GeneralResponse.unknownError();
        }
      } else {
        CrashlyticsUtil.instance.recordError(
          GeneralResponse.unknownError(),
          StackTrace.current,
          information: <Object>[
            response.statusMessage ?? response.toString(),
          ],
        );
        throw response.statusMessage ?? response.toString();
      }
    } on DioException catch (_) {
      rethrow;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<List<BusTime>> getBusTime({
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
      if (response.data case final String data?) {
        if (BusTime.fromRawList(data) case final List<BusTime> list?) {
          return list;
        } else {
          CrashlyticsUtil.instance.recordError(
            GeneralResponse.unknownError(),
            StackTrace.current,
            information: <Object>[
              data,
            ],
          );
          throw GeneralResponse.unknownError();
        }
      } else {
        throw response.statusMessage ?? response.toString();
      }
    } on DioException catch (_) {
      rethrow;
    } on Exception catch (_) {
      rethrow;
    }
  }
}
