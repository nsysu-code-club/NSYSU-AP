// To parse this JSON data, do
//
//     final busInfo = busInfoFromJson(jsonString);

import 'dart:convert';

import 'package:ap_common/utils/preferences.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/bus_time.dart';

class BusInfo {
  BusInfo({
    this.carId,
    this.stopName,
    this.routeId,
    this.name,
    this.isOpenData,
    this.departure,
    this.destination,
    this.updateTime,
  });

  String carId;
  String stopName;
  int routeId;
  String name;
  String isOpenData;
  String departure;
  String destination;
  String updateTime;

  BusInfo copyWith({
    String carId,
    String stopName,
    int routeId,
    String name,
    String isOpenData,
    String departure,
    String destination,
    String updateTime,
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

  factory BusInfo.fromRawJson(String str) => BusInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusInfo.fromJson(Map<String, dynamic> json) => BusInfo(
        carId: json["CarID"] == null ? null : json["CarID"],
        stopName: json["StopName"] == null ? null : json["StopName"],
        routeId: json["RouteID"] == null ? null : json["RouteID"],
        name: json["Name"] == null ? json["NameEn"] : json["Name"],
        isOpenData: json["isOpenData"] == null ? null : json["isOpenData"],
        departure:
            json["Departure"] == null ? json["DepartureEn"] : json["Departure"],
        destination: json["Destination"] == null
            ? json["DestinationEn"]
            : json["Destination"],
        updateTime: json["UpdateTime"] == null ? null : json["UpdateTime"],
      );

  Map<String, dynamic> toJson() => {
        "CarID": carId == null ? null : carId,
        "StopName": stopName == null ? null : stopName,
        "RouteID": routeId == null ? null : routeId,
        "Name": name == null ? null : name,
        "isOpenData": isOpenData == null ? null : isOpenData,
        "Departure": departure == null ? null : departure,
        "Destination": destination == null ? null : destination,
        "UpdateTime": updateTime == null ? null : updateTime,
      };

  static List<BusInfo> fromRawList(String rawString) {
    final rawStringList = json.decode(rawString);
    if (rawStringList == null)
      return null;
    else
      return List<BusInfo>.from(
        rawStringList.map(
          (x) => BusInfo.fromJson(x),
        ),
      );
  }

  static List<BusInfo> load() {
    final rawStringList = Preferences.getStringList(
      Constants.BUS_INFO_DATA,
      null,
    );
    if (rawStringList == null)
      return null;
    else
      return List<BusInfo>.from(
        rawStringList.map(
          (x) => BusInfo.fromRawJson(x),
        ),
      );
  }
}

extension BusInfoExtension on List<BusTime> {
  void save() {
    Preferences.setStringList(
      Constants.BUS_INFO_DATA,
      List<String>.from(
        this.map(
          (x) => x.toRawJson(),
        ),
      ),
    );
  }
}
