@Tags(<String>['live-anonymous'])
@TestOn('vm')
library;

import 'package:ap_common_core/ap_common_core.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

import '_dio_logging.dart';

/// Bus endpoints don't need credentials. Run with:
///
///     dart test -P live-anonymous -r expanded
void main() {
  group('BusHelper', () {
    setUpAll(() {
      enableRequestLogging(BusHelper.instance.dio);
    });

    test(
      'getBusInfoList(zh) returns a non-empty list of routes',
      () async {
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        expect(list, isNotNull);
        expect(list, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusInfoList(en) returns english route names',
      () async {
        final ApiResult<List<BusInfo>?> result = await BusHelper.instance
            .getBusInfoList(languageCode: 'en');
        expect(result, isA<ApiSuccess<List<BusInfo>?>>());
        final List<BusInfo>? list = (result as ApiSuccess<List<BusInfo>?>).data;
        expect(list, isNotNull);
        expect(list, isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'getBusTime returns a list for the first route',
      () async {
        final ApiResult<List<BusInfo>?> infoResult = await BusHelper.instance
            .getBusInfoList(languageCode: 'zh');
        final List<BusInfo> list =
            (infoResult as ApiSuccess<List<BusInfo>?>).data!;
        final ApiResult<List<BusTime>?> result = await BusHelper.instance
            .getBusTime(languageCode: 'zh', busInfo: list.first);
        expect(result, isA<ApiSuccess<List<BusTime>?>>());
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
