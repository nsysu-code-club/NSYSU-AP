import 'package:nsysu_crawler/src/models/bus_info.dart';
import 'package:nsysu_crawler/src/models/bus_time.dart';

const List<int> supportedBusRouteIds = <int>[901, 9011, 50, 219, 2192];

List<BusInfo> parseIbusRouteList(
  Map<String, dynamic> response, {
  required String languageCode,
}) {
  final Map<String, dynamic> data = _readData(response);
  final bool isEnglish = languageCode.startsWith('en');
  final List<BusInfo> routes = <BusInfo>[];

  for (final int routeId in supportedBusRouteIds) {
    final dynamic rawRoute = data['route$routeId'];
    if (rawRoute is! Map) continue;
    final Map<String, dynamic> route = Map<String, dynamic>.from(rawRoute);
    final String? name = route['name'] as String?;
    final String? departure = route['departure'] as String?;
    final String? destination = route['destination'] as String?;
    if (name == null || departure == null || destination == null) continue;

    final List<String> busIds = _readBusIds(route['buses']);
    routes.add(
      BusInfo(
        carId: busIds.isEmpty ? null : busIds.join(','),
        busIds: busIds,
        stopName: busIds.isEmpty ? (isEnglish ? 'Out of service' : '未行駛') : '',
        routeId: routeId,
        name: name,
        isOpenData: 'Y',
        departure: departure,
        destination: destination,
        updateTime: null,
      ),
    );
  }

  if (routes.isEmpty) {
    throw const FormatException('iBus returned no supported routes');
  }
  return routes;
}

List<BusTime> parseIbusRouteTimes(
  Map<String, dynamic> response, {
  required int routeId,
  DateTime? taipeiNow,
}) {
  final Map<String, dynamic> data = _readData(response);
  final dynamic rawRoute = data['route'];
  if (rawRoute is! Map) {
    throw const FormatException('iBus route is missing');
  }
  final Map<String, dynamic> route = Map<String, dynamic>.from(rawRoute);
  final List<dynamic> stationEdges = _readEdges(route['stations']);
  if (stationEdges.isEmpty) {
    throw const FormatException('iBus route has no stations');
  }

  final Map<String, _EstimateTime> estimates = <String, _EstimateTime>{};
  for (final dynamic rawEdge in _readEdges(route['estimateTimes'])) {
    if (rawEdge is! Map) continue;
    final dynamic rawNode = rawEdge['node'];
    if (rawNode is! Map) continue;
    final Map<String, dynamic> node = Map<String, dynamic>.from(rawNode);
    final String? stopId = node['id'] as String?;
    final int? goBack = node['goBack'] as int?;
    if (stopId == null || goBack == null) continue;
    estimates[_stopKey(stopId, goBack)] = _EstimateTime(
      comeTime: node['comeTime'] as String? ?? '',
      etaMinutes: _readEtaMinutes(node['etas']),
    );
  }

  final DateTime now =
      taipeiNow ?? DateTime.now().toUtc().add(const Duration(hours: 8));
  final int currentMinutes = now.hour * 60 + now.minute;
  final List<BusTime> times = <BusTime>[];

  for (final dynamic rawEdge in stationEdges) {
    if (rawEdge is! Map) continue;
    final Map<String, dynamic> edge = Map<String, dynamic>.from(rawEdge);
    final dynamic rawNode = edge['node'];
    if (rawNode is! Map) continue;
    final Map<String, dynamic> node = Map<String, dynamic>.from(rawNode);
    final String? stopId = node['id'] as String?;
    final String? name = node['name'] as String?;
    final int? goBack = edge['goBack'] as int?;
    final int? orderNo = edge['orderNo'] as int?;
    if (stopId == null ||
        name == null ||
        goBack == null ||
        orderNo == null ||
        (goBack != 1 && goBack != 2)) {
      continue;
    }

    final _EstimateTime estimate =
        estimates[_stopKey(stopId, goBack)] ??
        const _EstimateTime(comeTime: '', etaMinutes: <int>[]);
    final int? nearestEta = estimate.etaMinutes.isEmpty
        ? null
        : estimate.etaMinutes.reduce(
            (int current, int next) => current < next ? current : next,
          );
    final BusArrivalStatus status = _resolveStatus(
      nearestEta: nearestEta,
      comeTime: estimate.comeTime,
      currentMinutes: currentMinutes,
    );
    final String? scheduledTime = estimate.comeTime.trim().isEmpty
        ? null
        : estimate.comeTime.trim();

    times.add(
      BusTime(
        routeId: routeId,
        stopId: stopId,
        name: name,
        arrivedTime: _legacyArrivedTime(status, nearestEta, scheduledTime),
        realArrivedTime: scheduledTime,
        isGoBack: goBack == 2 ? 'Y' : 'N',
        seqNo: orderNo,
        direction: goBack == 2 ? BusDirection.back : BusDirection.go,
        arrivalStatus: status,
        etaMinutes: nearestEta,
        scheduledTime: scheduledTime,
      ),
    );
  }

  times.sort((BusTime a, BusTime b) {
    final int directionOrder = a.direction.index.compareTo(b.direction.index);
    return directionOrder != 0 ? directionOrder : a.seqNo.compareTo(b.seqNo);
  });
  return times;
}

Map<String, dynamic> _readData(Map<String, dynamic> response) {
  final dynamic errors = response['errors'];
  if (errors is List && errors.isNotEmpty) {
    throw const FormatException('iBus returned GraphQL errors');
  }
  final dynamic data = response['data'];
  if (data is! Map) {
    throw const FormatException('iBus data is missing');
  }
  return Map<String, dynamic>.from(data);
}

List<dynamic> _readEdges(dynamic connection) {
  if (connection is! Map) return <dynamic>[];
  final dynamic edges = connection['edges'];
  return edges is List ? edges : <dynamic>[];
}

List<String> _readBusIds(dynamic buses) {
  final List<String> ids = <String>[];
  for (final dynamic rawEdge in _readEdges(buses)) {
    if (rawEdge is! Map || rawEdge['node'] is! Map) continue;
    final dynamic id = (rawEdge['node'] as Map)['id'];
    if (id is String && id.isNotEmpty) ids.add(id);
  }
  return ids;
}

List<int> _readEtaMinutes(dynamic etas) {
  if (etas is! List) return <int>[];
  return etas
      .whereType<Map>()
      .map((Map<dynamic, dynamic> eta) => eta['etaTime'])
      .whereType<num>()
      .map((num eta) => eta.toInt())
      .toList(growable: false);
}

BusArrivalStatus _resolveStatus({
  required int? nearestEta,
  required String comeTime,
  required int currentMinutes,
}) {
  if (nearestEta != null) {
    if (nearestEta <= 0) return BusArrivalStatus.arriving;
    if (nearestEta == 1) return BusArrivalStatus.comingSoon;
    return BusArrivalStatus.minutes;
  }
  if (comeTime.trim().isEmpty) return BusArrivalStatus.notOperating;

  final RegExpMatch? match = RegExp(
    r'^(\d{1,2}):(\d{2})$',
  ).firstMatch(comeTime.trim());
  if (match == null) {
    return BusArrivalStatus.notOperating;
  }
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    return BusArrivalStatus.notOperating;
  }
  return hour * 60 + minute > currentMinutes
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

String _stopKey(String stopId, int goBack) => '$goBack:$stopId';

class _EstimateTime {
  const _EstimateTime({required this.comeTime, required this.etaMinutes});

  final String comeTime;
  final List<int> etaMinutes;
}
