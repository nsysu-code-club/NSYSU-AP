import 'dart:convert';

class CarParkAreaData {
  CarParkAreaData({
    this.version,
    this.data,
  });

  int version;
  List<CarParkArea> data;

  CarParkAreaData copyWith({
    int version,
    List<CarParkArea> data,
  }) =>
      CarParkAreaData(
        version: version ?? this.version,
        data: data ?? this.data,
      );

  factory CarParkAreaData.fromRawJson(String str) =>
      CarParkAreaData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CarParkAreaData.fromJson(Map<String, dynamic> json) =>
      CarParkAreaData(
        version: json["version"] == null ? null : json["version"],
        data: json["data"] == null
            ? null
            : List<CarParkArea>.from(
                json["data"].map((x) => CarParkArea.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "version": version == null ? null : version,
        "data": data == null
            ? null
            : List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class CarParkArea {
  CarParkArea({
    this.fcmTopic,
    this.name,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.enable = false,
  });

  String fcmTopic;
  String name;
  String imageUrl;
  double latitude;
  double longitude;
  bool enable;

  CarParkArea copyWith({
    String fcmTopic,
    String name,
    String imageUrl,
    double latitude,
    double longitude,
  }) =>
      CarParkArea(
        fcmTopic: fcmTopic ?? this.fcmTopic,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );

  factory CarParkArea.fromRawJson(String str) =>
      CarParkArea.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CarParkArea.fromJson(Map<String, dynamic> json) => CarParkArea(
        fcmTopic: json["fcmTopic"] == null ? null : json["fcmTopic"],
        name: json["name"] == null ? null : json["name"],
        imageUrl: json["imageUrl"] == null ? null : json["imageUrl"],
        latitude: json["latitude"] == null ? null : json["latitude"].toDouble(),
        longitude:
            json["longitude"] == null ? null : json["longitude"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "fcmTopic": fcmTopic == null ? null : fcmTopic,
        "name": name == null ? null : name,
        "imageUrl": imageUrl == null ? null : imageUrl,
        "latitude": latitude == null ? null : latitude,
        "longitude": longitude == null ? null : longitude,
      };
}
