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
    test('keeps supported order and maps active bus ids', () {
      final List<BusInfo> routes = parseIbusRouteList(
        _readFixture('ibus_route_list.json'),
        languageCode: 'zh',
      );

      expect(routes.map((BusInfo route) => route.routeId), <int>[901, 9011]);
      expect(routes.first.busIds, <String>['BUS-2', 'BUS-1']);
      expect(routes.first.carId, 'BUS-2,BUS-1');
      expect(routes.first.isOperating, isTrue);
      expect(routes.last.isOperating, isFalse);
      expect(routes.last.stopName, '未行駛');
    });

    test('uses english out-of-service text', () {
      final List<BusInfo> routes = parseIbusRouteList(
        _readFixture('ibus_route_list.json'),
        languageCode: 'en',
      );

      expect(routes.last.stopName, 'Out of service');
    });

    test('rejects GraphQL errors and empty supported data', () {
      expect(
        () => parseIbusRouteList(<String, dynamic>{
          'errors': <dynamic>[
            <String, dynamic>{'message': 'failed'},
          ],
        }, languageCode: 'zh'),
        throwsFormatException,
      );
      expect(
        () => parseIbusRouteList(<String, dynamic>{
          'data': <String, dynamic>{},
        }, languageCode: 'zh'),
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
        taipeiNow: DateTime(2026, 7, 14, 12),
      );
    });

    test('joins by stop and direction, then sorts by direction and order', () {
      expect(times, hasLength(6));
      expect(
        times.map((BusTime time) => '${time.direction.name}:${time.seqNo}'),
        <String>['go:1', 'go:2', 'go:3', 'go:4', 'back:1', 'back:2'],
      );
      expect(times[1].stopId, 'shared');
      expect(times[1].name, '去程共用站');
      expect(times[4].stopId, 'shared');
      expect(times[4].name, '返程共用站');
    });

    test('maps nearest ETA and all arrival states', () {
      expect(times[0].arrivalStatus, BusArrivalStatus.arriving);
      expect(times[0].etaMinutes, 0);
      expect(times[0].arrivedTime, '進站中');
      expect(times[1].arrivalStatus, BusArrivalStatus.comingSoon);
      expect(times[1].etaMinutes, 1);
      expect(times[2].arrivalStatus, BusArrivalStatus.minutes);
      expect(times[2].etaMinutes, 3);
      expect(times[2].arrivedTime, '3');
      expect(times[3].arrivalStatus, BusArrivalStatus.scheduled);
      expect(times[3].scheduledTime, '13:00');
      expect(times[4].arrivalStatus, BusArrivalStatus.departed);
      expect(times[5].arrivalStatus, BusArrivalStatus.notOperating);
    });

    test('rejects malformed station data', () {
      expect(
        () => parseIbusRouteTimes(<String, dynamic>{
          'data': <String, dynamic>{
            'route': <String, dynamic>{
              'estimateTimes': <String, dynamic>{'edges': <dynamic>[]},
              'stations': <String, dynamic>{
                'edges': <dynamic>[
                  <String, dynamic>{
                    'goBack': 3,
                    'orderNo': 1,
                    'node': <String, dynamic>{'id': 'x', 'name': 'bad'},
                  },
                ],
              },
            },
          },
        }, routeId: 901),
        throwsFormatException,
      );
    });
  });
}
