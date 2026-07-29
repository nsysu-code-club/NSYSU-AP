// ignore_for_file: avoid_print
@Tags(<String>['live-anonymous'])
@TestOn('vm')
library;

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Bus endpoints don't need credentials. Run with:
///
///     dart test -P live-anonymous -r expanded
///
/// Set `NSYSU_HTTP_LOG=1` to also see every dio request URL.
void main() {
  group('BusHelper', () {
    setUpAll(() {
      enableHttpLogging(BusHelper.instance.dio);
    });

    test(
      'getBusInfoList(zh) returns a non-empty list of routes',
      () async {
        logTarget('BusHelper', 'getBusInfoList', <String, dynamic>{
          'lang': 'zh',
          'desc': 'route summaries',
        });
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        logSuccess('BusHelper', 'getBusInfoList', <String, dynamic>{
          'lang': 'zh',
          'count': list?.length ?? 0,
          'first': list?.firstOrNull?.name ?? '<none>',
        });
        expect(list, isNotNull);
        expect(list, isNotEmpty);
        expect(list!.map((BusInfo route) => route.routeId), <int>[
          901,
          9011,
          50,
          219,
          2192,
        ]);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusInfoList(en) returns english route names',
      () async {
        logTarget('BusHelper', 'getBusInfoList', <String, dynamic>{
          'lang': 'en',
          'desc': 'route summaries',
        });
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'en');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        logSuccess('BusHelper', 'getBusInfoList', <String, dynamic>{
          'lang': 'en',
          'count': list?.length ?? 0,
          'first': list?.firstOrNull?.name ?? '<none>',
        });
        expect(list, isNotNull);
        expect(list, isNotEmpty);
        expect(list!.first.routeId, 901);
        expect(list.first.departure, contains('Hamasen'));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusTime returns arrival times for the first route',
      () async {
        logTarget('BusHelper', 'getBusTime', <String, dynamic>{
          'lang': 'zh',
          'desc': 'arrival times',
        });
        final ApiResult<List<BusInfo>?> infoResult = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        final List<BusInfo> list =
            (infoResult as ApiSuccess<List<BusInfo>?>).data!;
        final BusInfo first = list.first;
        logInfo('BusHelper', 'selectRoute', <String, dynamic>{
          'route': first.name,
          'routeId': first.routeId,
        });
        final ApiResult<List<BusTime>?> result = await BusHelper.instance
            .getBusTime(languageCode: 'zh', busInfo: first);
        expect(result, isA<ApiSuccess<List<BusTime>?>>());
        final List<BusTime>? times =
            (result as ApiSuccess<List<BusTime>?>).data;
        logSuccess('BusHelper', 'getBusTime', <String, dynamic>{
          'count': times?.length ?? 0,
        });
        expect(times, isNotNull);
        expect(times, isNotEmpty);
        expect(
          times!.map((BusTime time) => time.direction),
          containsAll(<BusDirection>[BusDirection.go, BusDirection.back]),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
