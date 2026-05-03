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
        // ignore: avoid_print
        print('[live] GET nsysu-bus/bus_info_data_zh.json');
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        // ignore: avoid_print
        print(
          '[live]   ← ${list?.length ?? 0} routes; '
          'first="${list?.firstOrNull?.name ?? '<none>'}"',
        );
        expect(list, isNotNull);
        expect(list, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusInfoList(en) returns english route names',
      () async {
        // ignore: avoid_print
        print('[live] GET nsysu-bus/bus_info_data_en.json');
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'en');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        // ignore: avoid_print
        print(
          '[live]   ← ${list?.length ?? 0} routes; '
          'first="${list?.firstOrNull?.name ?? '<none>'}"',
        );
        expect(list, isNotNull);
        expect(list, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusTime returns arrival times for the first route',
      () async {
        // ignore: avoid_print
        print('[live] GET bus info to pick a route, then POST RoutePathStop');
        final ApiResult<List<BusInfo>?> infoResult = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        final List<BusInfo> list =
            (infoResult as ApiSuccess<List<BusInfo>?>).data!;
        final BusInfo first = list.first;
        // ignore: avoid_print
        print('[live]   route: "${first.name}" (RID=${first.routeId})');
        final ApiResult<List<BusTime>?> result = await BusHelper.instance
            .getBusTime(languageCode: 'zh', busInfo: first);
        expect(result, isA<ApiSuccess<List<BusTime>?>>());
        final List<BusTime>? times = (result as ApiSuccess<List<BusTime>?>).data;
        // ignore: avoid_print
        print('[live]   ← ${times?.length ?? 0} arrival entries');
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
