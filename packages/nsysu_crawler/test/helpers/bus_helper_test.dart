import 'dart:convert';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:dio/dio.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  late BusHelper bus;
  late BusInfo route;
  late int tokenRequests;
  late int estimateRequests;
  late int expiredTokens;
  late bool incomplete;
  late bool failTokenRequest;
  late bool issueExpiredToken;

  setUp(() {
    bus = BusHelper();
    route = BusInfo(
      stopName: '',
      routeId: 901,
      name: 'Orange 1',
      isOpenData: 'Y',
      departure: 'Hamasen',
      destination: 'College of Liberal Arts',
      updateTime: null,
    );
    tokenRequests = 0;
    estimateRequests = 0;
    expiredTokens = 0;
    incomplete = false;
    failTokenRequest = false;
    issueExpiredToken = false;
    bus.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions request, RequestInterceptorHandler handler) async {
              expect(request.method, 'POST');
              expect(request.headers['X-Api-Version'], '1');
              if (request.path == BusHelper.tokenPath) {
                tokenRequests++;
                expect(request.headers['Authorization'], isNull);
                expect(request.data, isNull);
                // Allow other callers to join the in-flight token request.
                await Future<void>.delayed(Duration.zero);
                if (failTokenRequest) {
                  handler.reject(_httpError(request, 503));
                  return;
                }
                final int expiry =
                    DateTime.now()
                        .add(Duration(hours: issueExpiredToken ? -1 : 1))
                        .millisecondsSinceEpoch ~/
                    1000;
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: request,
                    statusCode: 200,
                    data: jsonEncode(<String, dynamic>{
                      'access_token': 'token-$tokenRequests',
                      'expires_in': expiry,
                    }),
                  ),
                );
                return;
              }

              estimateRequests++;
              expect(
                request.uri.path,
                '/bsuper/Extended/Dal/CustomEstimateTime',
              );
              expect(request.uri.queryParameters['extraType'], 'All');
              expect(request.data, <Map<String, dynamic>>[
                <String, dynamic>{'id': '901', 'direction': 0},
                <String, dynamic>{'id': '901', 'direction': 1},
              ]);
              final String authorization =
                  request.headers['Authorization'] as String;
              final int token = int.parse(authorization.split('-').last);
              if (token <= expiredTokens) {
                handler.reject(_httpError(request, 401));
                return;
              }
              handler.resolve(
                Response<dynamic>(
                  requestOptions: request,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'status': 0,
                    'data': <List<Map<String, dynamic>>>[
                      for (final int direction in <int>[0, if (!incomplete) 1])
                        <Map<String, dynamic>>[
                          <String, dynamic>{
                            'routeid': '901',
                            'direction': direction,
                            'stopsequence': 1,
                            'stopID': '123',
                            'stopname_En': 'Hamasen',
                          },
                        ],
                    ],
                  },
                ),
              );
            },
      ),
    );
  });

  tearDown(() => bus.dio.close());

  Future<ApiResult<List<BusTime>?>> getTimes() =>
      bus.getBusTime(languageCode: 'en', busInfo: route);

  test(
    'shares an in-flight guest token and reuses it on later calls',
    () async {
      final List<ApiResult<List<BusTime>?>> results = await Future.wait(
        <Future<ApiResult<List<BusTime>?>>>[getTimes(), getTimes()],
      );
      expect(results, everyElement(isA<ApiSuccess<List<BusTime>?>>()));
      expect(await getTimes(), isA<ApiSuccess<List<BusTime>?>>());
      expect(tokenRequests, 1);
      expect(estimateRequests, 3);
    },
  );

  test('concurrent 401s share a refresh', () async {
    expiredTokens = 1;
    final List<ApiResult<List<BusTime>?>> results = await Future.wait(
      <Future<ApiResult<List<BusTime>?>>>[getTimes(), getTimes()],
    );
    expect(results, everyElement(isA<ApiSuccess<List<BusTime>?>>()));
    expect(tokenRequests, 2);
    expect(estimateRequests, 4);
  });

  test('a second 401 returns failure', () async {
    expiredTokens = 2;
    expect(await getTimes(), isA<ApiFailure<List<BusTime>?>>());
    expect(tokenRequests, 2);
    expect(estimateRequests, 2);
  });

  test('refreshes a cached token past its server expiry', () async {
    issueExpiredToken = true;
    expect(await getTimes(), isA<ApiSuccess<List<BusTime>?>>());
    issueExpiredToken = false;
    expect(await getTimes(), isA<ApiSuccess<List<BusTime>?>>());
    expect(tokenRequests, 2);
  });

  test('retries token acquisition on a later call after a failure', () async {
    failTokenRequest = true;
    expect(await getTimes(), isA<ApiFailure<List<BusTime>?>>());
    failTokenRequest = false;
    expect(await getTimes(), isA<ApiSuccess<List<BusTime>?>>());
    expect(tokenRequests, 2);
    expect(estimateRequests, 1);
  });

  test('a missing direction returns an API error', () async {
    incomplete = true;
    expect(await getTimes(), isA<ApiError<List<BusTime>?>>());
  });
}

DioException _httpError(RequestOptions request, int status) =>
    DioException.badResponse(
      statusCode: status,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: status),
    );
