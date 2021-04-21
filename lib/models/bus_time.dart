// To parse this JSON data, do
//
//     final busTime = busTimeFromJson(jsonString);

import 'dart:convert';

class BusTime {
  BusTime({
    this.routeId,
    this.stopId,
    this.name,
    this.arrivedTime,
    this.realArrivedTime,
    this.isGoBack,
    this.seqNo,
  });

  int routeId;
  String stopId;
  String name;
  String arrivedTime;
  String realArrivedTime;
  String isGoBack;
  int seqNo;

  BusTime copyWith({
    int routeId,
    String stopId,
    String name,
    String arrivedTime,
    String realArrivedTime,
    String isGoBack,
    int seqNo,
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

  factory BusTime.fromRawJson(String str) => BusTime.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusTime.fromJson(Map<String, dynamic> json) => BusTime(
        routeId: json["RouteID"] == null ? null : json["RouteID"],
        stopId: json["StopID"] == null ? null : json["StopID"],
        name: json["Name"] == null ? json["NameEn"] : json["Name"],
        arrivedTime: json["ArrivedTime"] == null ? null : json["ArrivedTime"],
        realArrivedTime:
            json["RealArrivedTime"] == null ? null : json["RealArrivedTime"],
        isGoBack: json["isGoBack"] == null ? null : json["isGoBack"],
        seqNo: json["SeqNo"] == null ? null : json["SeqNo"],
      );

  Map<String, dynamic> toJson() => {
        "RouteID": routeId == null ? null : routeId,
        "StopID": stopId == null ? null : stopId,
        "Name": name == null ? null : name,
        "ArrivedTime": arrivedTime == null ? null : arrivedTime,
        "RealArrivedTime": realArrivedTime == null ? null : realArrivedTime,
        "isGoBack": isGoBack == null ? null : isGoBack,
        "SeqNo": seqNo == null ? null : seqNo,
      };

  static List<BusTime> fromRawList(String rawString) {
    final rawStringList = json.decode(rawString);
    if (rawStringList == null)
      return null;
    else
      return List<BusTime>.from(
        rawStringList.map(
          (Map<String, dynamic> x) => BusTime.fromJson(x),
        ),
      );
  }
}
