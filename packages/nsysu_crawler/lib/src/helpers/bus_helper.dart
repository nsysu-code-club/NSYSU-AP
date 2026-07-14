import 'package:ap_common_core/ap_common_core.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:nsysu_crawler/src/build_mode.dart';
import 'package:nsysu_crawler/src/models/bus_info.dart';
import 'package:nsysu_crawler/src/models/bus_time.dart';
import 'package:nsysu_crawler/src/parsers/bus_parser.dart';

class BusHelper {
  static const String basePath = 'https://ibus.tbkc.gov.tw/ibus/graphql';

  static const String _routeListQuery = r'''
    query QUERY_NSYSU_ROUTES($lang: String!) {
      route901: route(xno: 901, lang: $lang) {
        name
        departure
        destination
        buses { edges { node { id } } }
      }
      route9011: route(xno: 9011, lang: $lang) {
        name
        departure
        destination
        buses { edges { node { id } } }
      }
      route50: route(xno: 50, lang: $lang) {
        name
        departure
        destination
        buses { edges { node { id } } }
      }
      route219: route(xno: 219, lang: $lang) {
        name
        departure
        destination
        buses { edges { node { id } } }
      }
      route2192: route(xno: 2192, lang: $lang) {
        name
        departure
        destination
        buses { edges { node { id } } }
      }
    }
  ''';

  static const String _routeTimesQuery = r'''
    query QUERY_ROUTE_TIMES($routeId: Int!, $lang: String!) {
      route(xno: $routeId, lang: $lang) {
        estimateTimes {
          edges {
            node {
              id
              goBack
              comeTime
              etas {
                busId
                etaTime
              }
            }
          }
        }
        stations {
          edges {
            goBack
            orderNo
            node {
              id
              name
            }
          }
        }
      }
    }
  ''';

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
    required String languageCode,
  }) async {
    try {
      final String language = _normalizeLanguage(languageCode);
      final Response<dynamic> response = await dio.post<dynamic>(
        basePath,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
        data: <String, dynamic>{
          'query': _routeListQuery,
          'variables': <String, dynamic>{'lang': language},
        },
      );
      if (response.data != null) {
        final List<BusInfo> list = parseIbusRouteList(
          _asJsonMap(response.data),
          languageCode: language,
        );
        return ApiSuccess<List<BusInfo>?>(list);
      } else {
        return ApiError<List<BusInfo>?>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      return ApiFailure<List<BusInfo>?>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<List<BusInfo>?>(GeneralResponse.unknownError());
    }
  }

  Future<ApiResult<List<BusTime>?>> getBusTime({
    required String languageCode,
    required BusInfo busInfo,
  }) async {
    try {
      final Response<dynamic> response = await dio.post<dynamic>(
        basePath,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
        data: <String, dynamic>{
          'query': _routeTimesQuery,
          'variables': <String, dynamic>{
            'routeId': busInfo.routeId,
            'lang': _normalizeLanguage(languageCode),
          },
        },
      );
      if (response.data != null) {
        final List<BusTime> list = parseIbusRouteTimes(
          _asJsonMap(response.data),
          routeId: busInfo.routeId,
        );
        return ApiSuccess<List<BusTime>?>(list);
      } else {
        return ApiError<List<BusTime>?>(GeneralResponse.unknownError());
      }
    } on DioException catch (e) {
      return ApiFailure<List<BusTime>?>(e);
    } on Exception catch (_) {
      if (kCrawlerDebugMode) rethrow;
      return ApiError<List<BusTime>?>(GeneralResponse.unknownError());
    }
  }

  static String _normalizeLanguage(String languageCode) =>
      languageCode.startsWith('en') ? 'en' : 'zh';

  static Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is! Map) {
      throw const FormatException('iBus response is not a JSON object');
    }
    return Map<String, dynamic>.from(data);
  }
}
