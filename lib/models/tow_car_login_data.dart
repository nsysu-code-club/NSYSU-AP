import 'dart:convert';

import 'package:ap_common/utils/preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum PermissionLevel { user, editor, admin }

class TowCarLoginData {
  TowCarLoginData({
    this.key,
  });

  String key;

  TowCarLoginData copyWith({
    String key,
  }) =>
      TowCarLoginData(
        key: key ?? this.key,
      );

  factory TowCarLoginData.fromRawJson(String str) =>
      TowCarLoginData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TowCarLoginData.fromJson(Map<String, dynamic> json) =>
      TowCarLoginData(
        key: json["key"] == null ? null : json["key"],
      );

  Map<String, dynamic> toJson() => {
        "key": key == null ? null : key,
      };

  Map<String, dynamic> get decodedToken => JwtDecoder.decode(key);

  bool get isExpired => JwtDecoder.isExpired(key);

  PermissionLevel get level =>
      PermissionLevel.values[decodedToken['user']['permission_level']];

  String get loginType => decodedToken['user']['login_type'];

  String get username => decodedToken['user']['username'];

  static const KEY_NAME = 'tow_car_login_data';

  void save() {
    Preferences.setStringSecurity(
      KEY_NAME,
      this.toRawJson(),
    );
  }

  factory TowCarLoginData.load() {
    String rawString = Preferences.getStringSecurity(
      KEY_NAME,
      '',
    );
    if (rawString == '')
      return null;
    else
      return TowCarLoginData.fromRawJson(rawString);
  }
}
