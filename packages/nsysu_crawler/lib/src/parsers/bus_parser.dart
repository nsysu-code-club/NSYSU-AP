import 'package:nsysu_crawler/src/models/bus_info.dart';
import 'package:nsysu_crawler/src/models/bus_time.dart';

const List<int> supportedBusRouteIds = <int>[901, 9011, 50, 219, 2192];

List<BusInfo> parseIbusRouteList(
  Map<String, dynamic> response, {
  required String languageCode,
}) {
  final Map<int, List<_Stop>> routes = _readRoutes(
    response,
    supportedBusRouteIds,
  );
  final bool english = languageCode.startsWith('en');
  return <BusInfo>[
    for (final int routeId in supportedBusRouteIds)
      _routeInfo(routeId, routes[routeId]!, english),
  ];
}

BusInfo _routeInfo(int routeId, List<_Stop> stops, bool english) {
  final Set<String> ids = <String>{};
  final Map<String, String> englishNames = <String, String>{};
  String? name;
  String? departure;
  String? destination;
  for (final _Stop stop in stops) {
    final Map<String, dynamic> data = stop.data;
    name ??= _localizedName(data, 'routename', english);
    final String? zhName = _text(data['stopname_Zh_Tw']);
    final String? enName = _text(data['stopname_En']);
    if (zhName != null && enName != null) englishNames[zhName] = enName;
    final dynamic endpoints = data['routeStop'];
    if (stop.direction == BusDirection.go && endpoints is Map) {
      departure ??= _text(endpoints['departureStopName']);
      destination ??= _text(endpoints['destinationStopName']);
    }
    _addVehicleIds(ids, data['carId']);
    for (final Map<String, dynamic> eta in _etas(data)) {
      _addVehicleIds(ids, eta['busId']);
    }
  }
  if (name == null || departure == null || destination == null) {
    throw FormatException('iBus+ route $routeId has incomplete metadata');
  }
  return BusInfo(
    carId: ids.isEmpty ? null : ids.join(','),
    busIds: ids.toList(),
    stopName: ids.isEmpty ? (english ? 'Out of service' : '未行駛') : '',
    routeId: routeId,
    name: name,
    isOpenData: 'Y',
    departure: english ? englishNames[departure] ?? departure : departure,
    destination: english
        ? englishNames[destination] ?? destination
        : destination,
    updateTime: null,
  );
}

List<BusTime> parseIbusRouteTimes(
  Map<String, dynamic> response, {
  required int routeId,
  required String languageCode,
  DateTime? taipeiNow,
}) {
  final List<_Stop> stops = _readRoutes(response, <int>[routeId])[routeId]!;
  final DateTime now =
      taipeiNow ?? DateTime.now().toUtc().add(const Duration(hours: 8));
  final int currentMinutes = now.hour * 60 + now.minute;
  final bool english = languageCode.startsWith('en');
  final List<BusTime> times = <BusTime>[];
  for (final _Stop stop in stops) {
    final Map<String, dynamic> data = stop.data;
    final String name = _localizedName(data, 'stopname', english)!;
    // The existing model has no dedicated suspended or skipped-stop state.
    final bool unavailable =
        _integer(data['issusPended']) == 1 ||
        _integer(data['isConstruction']) == 1 ||
        _integer(data['isEvent']) == 1;
    final int? eta = unavailable ? null : _nearestEta(data);
    final String? scheduledTime = unavailable
        ? null
        : _text(data['nextbustime']);
    final int? scheduledMinutes = _clockMinutes(scheduledTime);
    final String? validSchedule = scheduledMinutes == null
        ? null
        : scheduledTime;
    final BusArrivalStatus status = _resolveStatus(
      eta,
      scheduledMinutes,
      currentMinutes,
    );
    times.add(
      BusTime(
        routeId: routeId,
        stopId: stop.id,
        name: name,
        arrivedTime: _legacyArrivedTime(status, eta, validSchedule),
        realArrivedTime: validSchedule,
        isGoBack: stop.direction == BusDirection.back ? 'Y' : 'N',
        seqNo: stop.sequence,
        direction: stop.direction,
        arrivalStatus: status,
        etaMinutes: eta,
        scheduledTime: validSchedule,
      ),
    );
  }
  return times;
}

Map<int, List<_Stop>> _readRoutes(
  Map<String, dynamic> response,
  List<int> routeIds,
) {
  final dynamic groups = response['data'];
  if (_integer(response['status']) != 0 || groups is! List<dynamic>) {
    throw const FormatException('iBus+ returned an invalid estimate response');
  }
  final Map<int, List<_Stop>> routes = <int, List<_Stop>>{
    for (final int id in routeIds) id: <_Stop>[],
  };
  for (final List<dynamic> group in groups.whereType<List<dynamic>>()) {
    for (final Map<String, dynamic> data
        in group.whereType<Map<String, dynamic>>()) {
      final List<_Stop>? stops = routes[_integer(data['routeid'])];
      final int? direction = _integer(data['direction']);
      final int? sequence = _integer(data['stopsequence']);
      final String? id = _text(data['stopID']);
      if (stops == null ||
          (direction != 0 && direction != 1) ||
          sequence == null ||
          sequence < 0 ||
          id == null ||
          _localizedName(data, 'stopname', false) == null) {
        continue;
      }
      stops.add(
        _Stop(
          data,
          id,
          direction == 0 ? BusDirection.go : BusDirection.back,
          sequence,
        ),
      );
    }
  }
  for (final MapEntry<int, List<_Stop>> route in routes.entries) {
    final List<_Stop> stops = route.value;
    stops.sort((_Stop a, _Stop b) {
      final int directionOrder = a.direction.index.compareTo(b.direction.index);
      return directionOrder == 0
          ? a.sequence.compareTo(b.sequence)
          : directionOrder;
    });
    if (stops.isEmpty ||
        stops.first.direction != BusDirection.go ||
        stops.last.direction != BusDirection.back) {
      throw FormatException('iBus+ route ${route.key} is missing a direction');
    }
  }
  return routes;
}

String? _text(dynamic value) {
  if (value is! String && value is! int) return null;
  final String text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

int? _integer(dynamic value) => int.tryParse(_text(value) ?? '');

String? _localizedName(Map<String, dynamic> data, String key, bool english) {
  final String? zh = _text(data['${key}_Zh_Tw']);
  final String? en = _text(data['${key}_En']);
  return english ? en ?? zh : zh ?? en;
}

Iterable<Map<String, dynamic>> _etas(Map<String, dynamic> data) {
  final dynamic etas = data['etas'];
  return etas is List<dynamic>
      ? etas.whereType<Map<String, dynamic>>()
      : const <Map<String, dynamic>>[];
}

void _addVehicleIds(Set<String> ids, dynamic value) {
  for (final String candidate in (_text(value) ?? '').split(',')) {
    final String? id = _text(candidate);
    if (id != null) ids.add(id);
  }
}

int? _validEta(dynamic value) {
  final int? eta = _integer(value);
  return eta != null && eta >= 0 ? eta : null;
}

int? _nearestEta(Map<String, dynamic> data) {
  int? nearest;
  for (final Map<String, dynamic> eta in _etas(data)) {
    final int? minutes = _validEta(eta['etaTime']);
    if (minutes != null && (nearest == null || minutes < nearest)) {
      nearest = minutes;
    }
  }
  return nearest ?? _validEta(data['estimatetime']);
}

int? _clockMinutes(String? time) {
  if (time == null) return null;
  final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time);
  if (match == null) return null;
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  return hour < 24 && minute < 60 ? hour * 60 + minute : null;
}

BusArrivalStatus _resolveStatus(int? eta, int? schedule, int now) {
  if (eta != null) {
    if (eta == 0) return BusArrivalStatus.arriving;
    if (eta == 1) return BusArrivalStatus.comingSoon;
    return BusArrivalStatus.minutes;
  }
  if (schedule == null) return BusArrivalStatus.notOperating;
  // iBus+ supplies a clock time without a date. Keep the same-day comparison.
  return schedule > now
      ? BusArrivalStatus.scheduled
      : BusArrivalStatus.departed;
}

String? _legacyArrivedTime(
  BusArrivalStatus status,
  int? etaMinutes,
  String? scheduledTime,
) {
  switch (status) {
    case BusArrivalStatus.arriving:
      return '進站中';
    case BusArrivalStatus.comingSoon:
      return '將到站';
    case BusArrivalStatus.minutes:
      return etaMinutes?.toString();
    case BusArrivalStatus.scheduled:
      return scheduledTime;
    case BusArrivalStatus.departed:
    case BusArrivalStatus.notOperating:
      return null;
  }
}

class _Stop {
  const _Stop(this.data, this.id, this.direction, this.sequence);

  final Map<String, dynamic> data;
  final String id;
  final BusDirection direction;
  final int sequence;
}
