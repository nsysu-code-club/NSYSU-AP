import 'package:ap_common/utils/ap_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'dart:convert';

class TowCarAlertData {
  TowCarAlertData({
    this.data,
  });

  List<TowCarAlert> data;

  TowCarAlertData copyWith({
    List<TowCarAlert> data,
  }) =>
      TowCarAlertData(
        data: data ?? this.data,
      );

  factory TowCarAlertData.fromRawJson(String str) =>
      TowCarAlertData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TowCarAlertData.fromJson(Map<String, dynamic> json) =>
      TowCarAlertData(
        data: json["data"] == null
            ? null
            : List<TowCarAlert>.from(
                json["data"].map((x) => TowCarAlert.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? null
            : List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class TowCarAlert {
  TowCarAlert({
    this.topic,
    this.title,
    this.message,
    this.imageUrl,
    this.viewCounts,
    this.time,
    this.reviewStatus,
  });

  String topic;
  String title;
  String message;
  String imageUrl;
  int viewCounts;
  DateTime time;
  bool reviewStatus;

  String get ago => timeago.format(
        time,
        locale: ApLocalizations.current.dateTimeLocale,
      );

  TowCarAlert copyWith({
    String topic,
    String title,
    String message,
    String imageUrl,
    DateTime time,
    bool reviewStatus,
  }) =>
      TowCarAlert(
        topic: topic ?? this.topic,
        title: title ?? this.title,
        message: message ?? this.message,
        imageUrl: imageUrl ?? this.imageUrl,
        time: time ?? this.time,
        reviewStatus: reviewStatus ?? this.reviewStatus,
      );

  factory TowCarAlert.fromRawJson(String str) =>
      TowCarAlert.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TowCarAlert.fromJson(Map<String, dynamic> json) => TowCarAlert(
        topic: json["topic"] == null ? null : json["topic"],
        title: json["title"] == null ? null : json["title"],
        message: json["message"] == null ? null : json["message"],
        imageUrl: json["imageUrl"] == null ? null : json["imageUrl"],
        time: json["time"] == null ? null : DateTime.parse(json["time"]),
        reviewStatus: json['review_status'],
      );

  Map<String, dynamic> toJson() => {
        "topic": topic == null ? null : topic,
        "title": title == null ? null : title,
        "message": message == null ? null : message,
        "imageUrl": imageUrl == null ? null : imageUrl,
        "time": time == null ? null : time.toIso8601String(),
        "review_status": reviewStatus,
      };

  Map<String, dynamic> toUpdateJson() => {
        "title": title,
        "topic": topic,
        "imageUrl": imageUrl,
        "message": message,
        "time": time,
      };
}
