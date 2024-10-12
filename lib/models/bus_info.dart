// To parse this JSON data, do
//
//     final busInfo = busInfoFromJson(jsonString);

import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/bus_time.dart';

part 'bus_info.g.dart';

@JsonSerializable(explicitToJson: true)
class BusInfo {
  BusInfo({
    this.carId,
    required this.stopName,
    required this.routeId,
    required this.name,
    required this.isOpenData,
    required this.departure,
    required this.destination,
    required this.updateTime,
  });

  @JsonKey(name: 'CarID')
  String? carId;
  @JsonKey(name: 'StopName')
  String stopName;
  @JsonKey(name: 'RouteID')
  int routeId;
  @JsonKey(name: 'Name')
  String name;
  @JsonKey(name: 'isOpenData')
  String isOpenData;
  @JsonKey(name: 'Departure')
  String departure;
  @JsonKey(name: 'Destination')
  String destination;
  @JsonKey(name: 'UpdateTime')
  String? updateTime;

  BusInfo copyWith({
    String? carId,
    String? stopName,
    int? routeId,
    String? name,
    String? isOpenData,
    String? departure,
    String? destination,
    String? updateTime,
  }) =>
      BusInfo(
        carId: carId ?? this.carId,
        stopName: stopName ?? this.stopName,
        routeId: routeId ?? this.routeId,
        name: name ?? this.name,
        isOpenData: isOpenData ?? this.isOpenData,
        departure: departure ?? this.departure,
        destination: destination ?? this.destination,
        updateTime: updateTime ?? this.updateTime,
      );

  factory BusInfo.fromJson(Map<String, dynamic> json) =>
      _$CustomBusInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BusInfoToJson(this);

  factory BusInfo.fromRawJson(String str) => BusInfo.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());

  static List<BusInfo>? fromRawList(String rawString) {
    final List<dynamic>? rawStringList =
        json.decode(rawString) as List<dynamic>?;
    if (rawStringList == null) {
      return null;
    } else {
      return List<BusInfo>.from(
        rawStringList.map(
          (dynamic x) => BusInfo.fromJson(x as Map<String, dynamic>),
        ),
      );
    }
  }

  static List<BusInfo>? load() {
    final List<String> rawStringList = PreferenceUtil.instance.getStringList(
      Constants.busInfoData,
      <String>[],
    );
    if (rawStringList.isEmpty) {
      return null;
    } else {
      return List<BusInfo>.from(
        rawStringList.map(
          (String x) => BusInfo.fromRawJson(x),
        ),
      );
    }
  }
}

BusInfo _$CustomBusInfoFromJson(Map<String, dynamic> json) => BusInfo(
      carId: json['CarID'] as String?,
      stopName: json['StopName'] as String,
      routeId: json['RouteID'] as int,
      name: json['Name'] == null
          ? json['NameEn'] as String
          : json['Name'] as String,
      isOpenData: json['isOpenData'] as String,
      departure: json['Departure'] == null
          ? json['DepartureEn'] as String
          : json['Departure'] as String,
      destination: json['Destination'] == null
          ? json['DestinationEn'] as String
          : json['Destination'] as String,
      updateTime: json['UpdateTime'] as String?,
    );

extension BusInfoExtension on List<BusTime> {
  void save() {
    PreferenceUtil.instance.setStringList(
      Constants.busInfoData,
      List<String>.from(
        map(
          (BusTime x) => x.toRawJson(),
        ),
      ),
    );
  }
}
