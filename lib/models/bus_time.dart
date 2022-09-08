// To parse this JSON data, do
//
//     final busTime = busTimeFromJson(jsonString);

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'bus_time.g.dart';

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
  });

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

  BusTime copyWith({
    int? routeId,
    String? stopId,
    String? name,
    String? arrivedTime,
    String? realArrivedTime,
    String? isGoBack,
    int? seqNo,
  }) =>
      BusTime(
        routeId: routeId ?? this.routeId,
        stopId: stopId ?? this.stopId,
        name: name ?? this.name,
        arrivedTime: arrivedTime ?? this.arrivedTime,
        realArrivedTime: realArrivedTime ?? this.realArrivedTime,
        isGoBack: isGoBack ?? this.isGoBack,
        seqNo: seqNo ?? this.seqNo,
      );

  factory BusTime.fromJson(Map<String, dynamic> json) =>
      _$BusTimeFromJson(json);

  Map<String, dynamic> toJson() => _$BusTimeToJson(this);

  factory BusTime.fromRawJson(String str) => BusTime.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

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
