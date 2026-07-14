// To parse this JSON data, do
//
//     final busTime = busTimeFromJson(jsonString);

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'bus_time.g.dart';

enum BusDirection { go, back }

enum BusArrivalStatus {
  arriving,
  comingSoon,
  minutes,
  scheduled,
  departed,
  notOperating,
}

@JsonSerializable(explicitToJson: true)
class BusTime {
  BusTime({
    required this.routeId,
    required this.stopId,
    required this.name,
    required this.arrivedTime,
    required this.realArrivedTime,
    required this.isGoBack,
    required this.seqNo,
    BusDirection? direction,
    BusArrivalStatus? arrivalStatus,
    int? etaMinutes,
    String? scheduledTime,
  }) : direction =
           direction ?? (isGoBack == 'Y' ? BusDirection.back : BusDirection.go),
       arrivalStatus =
           arrivalStatus ?? _legacyArrivalStatus(arrivedTime, realArrivedTime),
       etaMinutes = etaMinutes ?? int.tryParse(arrivedTime ?? ''),
       scheduledTime = scheduledTime ?? realArrivedTime;

  @JsonKey(name: 'RouteID')
  int routeId;
  @JsonKey(name: 'StopID')
  String stopId;
  @JsonKey(name: 'Name')
  String name;
  @JsonKey(name: 'ArrivedTime')
  String? arrivedTime;
  @JsonKey(name: 'RealArrivedTime')
  String? realArrivedTime;
  @JsonKey(name: 'isGoBack')
  String isGoBack;
  @JsonKey(name: 'SeqNo')
  int seqNo;
  @JsonKey(name: 'Direction')
  BusDirection direction;
  @JsonKey(name: 'ArrivalStatus')
  BusArrivalStatus arrivalStatus;
  @JsonKey(name: 'EtaMinutes')
  int? etaMinutes;
  @JsonKey(name: 'ScheduledTime')
  String? scheduledTime;

  BusTime copyWith({
    int? routeId,
    String? stopId,
    String? name,
    String? arrivedTime,
    String? realArrivedTime,
    String? isGoBack,
    int? seqNo,
    BusDirection? direction,
    BusArrivalStatus? arrivalStatus,
    int? etaMinutes,
    String? scheduledTime,
  }) => BusTime(
    routeId: routeId ?? this.routeId,
    stopId: stopId ?? this.stopId,
    name: name ?? this.name,
    arrivedTime: arrivedTime ?? this.arrivedTime,
    realArrivedTime: realArrivedTime ?? this.realArrivedTime,
    isGoBack: isGoBack ?? this.isGoBack,
    seqNo: seqNo ?? this.seqNo,
    direction: direction ?? this.direction,
    arrivalStatus: arrivalStatus ?? this.arrivalStatus,
    etaMinutes: etaMinutes ?? this.etaMinutes,
    scheduledTime: scheduledTime ?? this.scheduledTime,
  );

  factory BusTime.fromJson(Map<String, dynamic> json) =>
      _$CustomBusTimeFromJson(json);

  Map<String, dynamic> toJson() => _$BusTimeToJson(this);

  factory BusTime.fromRawJson(String str) =>
      BusTime.fromJson(json.decode(str) as Map<String, dynamic>);

  String toRawJson() => jsonEncode(toJson());

  static List<BusTime>? fromRawList(String rawString) {
    final List<dynamic>? rawStringList =
        json.decode(rawString) as List<dynamic>?;
    if (rawStringList == null) {
      return null;
    } else {
      return List<BusTime>.from(
        rawStringList.map(
          (dynamic x) => BusTime.fromJson(x as Map<String, dynamic>),
        ),
      );
    }
  }
}

BusTime _$CustomBusTimeFromJson(Map<String, dynamic> json) => BusTime(
  routeId: json['RouteID'] as int,
  stopId: json['StopID'] as String,
  name: json['Name'] == null
      ? json['NameEn'] as String
      : json['Name'] as String,
  arrivedTime: json['ArrivedTime'] as String?,
  realArrivedTime: json['RealArrivedTime'] as String?,
  isGoBack: json['isGoBack'] as String,
  seqNo: json['SeqNo'] as int,
  direction: _busDirectionFromJson(json['Direction']),
  arrivalStatus: _busArrivalStatusFromJson(json['ArrivalStatus']),
  etaMinutes: json['EtaMinutes'] as int?,
  scheduledTime: json['ScheduledTime'] as String?,
);

BusDirection? _busDirectionFromJson(dynamic value) {
  if (value is! String) return null;
  for (final BusDirection direction in BusDirection.values) {
    if (direction.name == value) return direction;
  }
  return null;
}

BusArrivalStatus? _busArrivalStatusFromJson(dynamic value) {
  if (value is! String) return null;
  for (final BusArrivalStatus status in BusArrivalStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

BusArrivalStatus _legacyArrivalStatus(
  String? arrivedTime,
  String? realArrivedTime,
) {
  if (arrivedTime == '進站中') return BusArrivalStatus.arriving;
  if (arrivedTime == '將到站') return BusArrivalStatus.comingSoon;
  if (int.tryParse(arrivedTime ?? '') != null) {
    return BusArrivalStatus.minutes;
  }
  if (arrivedTime != null || realArrivedTime != null) {
    return BusArrivalStatus.scheduled;
  }
  return BusArrivalStatus.departed;
}
