import 'dart:convert';

import 'package:flutter/services.dart';

class ImageAssets {
  static const String basePath = 'assets/images';

  static const String nsysu = '$basePath/nsysu.webp';

  static const String schoolMap = '$basePath/map.webp';
}

class FileAssets {
  static const String basePath = 'assets';

  static const String changelog = 'changelog.json';
  static const String carParkArea = '$basePath/car_park_area.json';

  static Future<Map<String, dynamic>?> get changelogData async {
    return jsonDecode(await rootBundle.loadString(changelog))
        as Map<String, dynamic>?;
  }

  static Map<String, dynamic>? changelogForVersion(
    Map<String, dynamic>? data,
    String version,
  ) {
    final dynamic versionEntry = data?[version];
    if (versionEntry is Map<String, dynamic>) return versionEntry;

    // Accept previously bundled files that used build numbers as their keys.
    for (final dynamic entry in data?.values ?? <dynamic>[]) {
      if (entry is Map<String, dynamic> && entry['version'] == version) {
        return entry;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> get carParkAreaData async {
    return jsonDecode(await rootBundle.loadString(carParkArea))
        as Map<String, dynamic>?;
  }
}
