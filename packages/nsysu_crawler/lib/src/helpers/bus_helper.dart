import 'dart:convert';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:dio/dio.dart';
import 'package:nsysu_crawler/src/models/bus_info.dart';
import 'package:nsysu_crawler/src/models/bus_time.dart';
import 'package:nsysu_crawler/src/parsers/bus_parser.dart';

class BusHelper {
  static const String basePath = 'https://ibusplus.tbkc.gov.tw/bsuper';
  static const String tokenPath = '$basePath/Token/Web';
  static const String _estimatePath =
      '$basePath/Extended/Dal/CustomEstimateTime?extraType=All';

  static BusHelper? _instance;

  //ignore: prefer_constructors_over_static_methods
  static BusHelper get instance => _instance ??= BusHelper();

  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  _GuestToken? _token;
  Future<_GuestToken>? _pendingToken;

  Future<ApiResult<List<BusInfo>?>> getBusInfoList({
    required String languageCode,
  }) => _request<List<BusInfo>>(
    supportedBusRouteIds,
    (Map<String, dynamic> data) =>
        parseIbusRouteList(data, languageCode: languageCode),
  );

  Future<ApiResult<List<BusTime>?>> getBusTime({
    required String languageCode,
    required BusInfo busInfo,
  }) => _request<List<BusTime>>(
    <int>[busInfo.routeId],
    (Map<String, dynamic> data) => parseIbusRouteTimes(
      data,
      routeId: busInfo.routeId,
      languageCode: languageCode,
    ),
  );

  Future<ApiResult<T?>> _request<T>(
    List<int> routeIds,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final _GuestToken token = await _getToken();
      try {
        return ApiSuccess<T?>(parse(await _fetchEstimates(routeIds, token)));
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        // Another request may already have refreshed this token.
        if (identical(_token, token)) _token = null;
        final _GuestToken refreshed = await _getToken();
        return ApiSuccess<T?>(
          parse(await _fetchEstimates(routeIds, refreshed)),
        );
      }
    } on DioException catch (error) {
      return ApiFailure<T?>(error);
    } on FormatException {
      return ApiError<T?>(GeneralResponse.unknownError());
    }
  }

  Future<_GuestToken> _getToken() async {
    final _GuestToken? cached = _token;
    if (cached != null && cached.isFresh) return cached;
    return _pendingToken ??= _fetchToken().whenComplete(() {
      _pendingToken = null;
    });
  }

  Future<_GuestToken> _fetchToken() async {
    final Response<dynamic> response = await dio.post<dynamic>(
      tokenPath,
      options: _options(),
    );
    final Map<String, dynamic> data = _jsonObject(response.data);
    final dynamic token = data['access_token'];
    if (token is! String || token.trim().isEmpty || token == 'null') {
      throw const FormatException('iBus+ guest token is missing');
    }
    // The guest endpoint's expires_in is a Unix timestamp in seconds.
    final int? expiry = int.tryParse(data['expires_in'].toString());
    return _token = _GuestToken(token, expiry);
  }

  Future<Map<String, dynamic>> _fetchEstimates(
    List<int> routeIds,
    _GuestToken token,
  ) async {
    final Response<dynamic> response = await dio.post<dynamic>(
      _estimatePath,
      options: _options(token.value),
      data: <Map<String, dynamic>>[
        for (final int id in routeIds)
          for (final int direction in <int>[0, 1])
            <String, dynamic>{'id': id.toString(), 'direction': direction},
      ],
    );
    return _jsonObject(response.data);
  }

  static Options _options([String? token]) => Options(
    contentType: 'application/json; charset=utf-8',
    responseType: ResponseType.json,
    validateStatus: (int? status) =>
        status != null && status >= 200 && status < 300,
    headers: <String, dynamic>{
      'X-Api-Version': '1',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  static Map<String, dynamic> _jsonObject(dynamic data) {
    // The guest endpoint can serve JSON with a non-JSON content type.
    final dynamic decoded = data is String ? jsonDecode(data) : data;
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('iBus+ response is not a JSON object');
    }
    return decoded;
  }
}

class _GuestToken {
  _GuestToken(this.value, int? expiry)
    : _refreshAfter =
          expiry != null && expiry >= 1000000000 && expiry < 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(
              expiry * 1000,
              isUtc: true,
            ).subtract(const Duration(seconds: 30))
          : DateTime.now().add(const Duration(minutes: 5));

  final String value;
  final DateTime _refreshAfter;

  bool get isFresh => DateTime.now().isBefore(_refreshAfter);
}
