@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:nsysu_crawler/src/parsers/bus_parser.dart';
import 'package:test/test.dart';

Map<String, dynamic> _readFixture(String name) =>
    json.decode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('parseIbusRouteList', () {
    test(
      'keeps route order and deduplicates vehicle IDs across directions',
      () {
        final List<BusInfo> routes = parseIbusRouteList(
          _readFixture('ibus_route_list.json'),
          languageCode: 'zh',
        );
        expect(
          routes.map((BusInfo route) => route.routeId),
          supportedBusRouteIds,
        );
        expect(routes.first.busIds, <String>['BUS-2', 'BUS-1', 'BUS-3']);
        expect(routes.first.carId, 'BUS-2,BUS-1,BUS-3');
        expect(routes.first.isOperating, isTrue);
        expect(routes.last.isOperating, isFalse);
        expect(routes.last.stopName, '未行駛');
      },
    );

    test('localizes endpoints from stop names across both directions', () {
      final List<BusInfo> routes = parseIbusRouteList(
        _readFixture('ibus_route_list.json'),
        languageCode: 'en-US',
      );
      expect(routes.first.name, 'Orange 1');
      expect(routes.first.departure, 'Hamasen');
      expect(routes.first.destination, 'College of Liberal Arts');
      expect(routes.last.stopName, 'Out of service');
    });

    test('rejects application errors and partial batches', () {
      final Map<String, dynamic> response = _readFixture(
        'ibus_route_list.json',
      );
      response['status'] = 1;
      expect(
        () => parseIbusRouteList(response, languageCode: 'zh'),
        throwsFormatException,
      );
      response['status'] = 0;
      (response['data'] as List<dynamic>).removeLast();
      expect(
        () => parseIbusRouteList(response, languageCode: 'zh'),
        throwsFormatException,
      );
    });
  });

  group('parseIbusRouteTimes', () {
    late List<BusTime> times;

    setUp(() {
      times = parseIbusRouteTimes(
        _readFixture('ibus_route_times.json'),
        routeId: 901,
        languageCode: 'en',
        taipeiNow: DateTime(2026, 7, 14, 12),
      );
    });

    test('sorts by direction and sequence and skips malformed stops', () {
      expect(
        times.map((BusTime time) => '${time.direction.name}:${time.seqNo}'),
        <String>['go:1', 'go:2', 'go:3', 'go:4', 'back:1', 'back:2', 'back:3'],
      );
      expect(times[1].stopId, 'shared');
      expect(times[1].name, 'Outbound shared stop');
      expect(times[4].stopId, 'shared');
      expect(times[4].name, '返程共用站');
      expect(times[1].isGoBack, 'N');
      expect(times[4].isGoBack, 'Y');
    });

    test(
      'prefers valid per-vehicle ETAs and falls back to stop ETA or time',
      () {
        expect(
          times.map((BusTime time) => time.arrivalStatus),
          <BusArrivalStatus>[
            BusArrivalStatus.arriving,
            BusArrivalStatus.comingSoon,
            BusArrivalStatus.minutes,
            BusArrivalStatus.scheduled,
            BusArrivalStatus.departed,
            BusArrivalStatus.notOperating,
            BusArrivalStatus.notOperating,
          ],
        );
        expect(times[0].etaMinutes, 0);
        expect(times[1].etaMinutes, 1);
        expect(times[2].etaMinutes, 3);
        expect(times[3].scheduledTime, '13:00');
        expect(times[5].scheduledTime, isNull);
        expect(times[6].etaMinutes, isNull);
        expect(times[6].scheduledTime, isNull);
      },
    );
  });
}
