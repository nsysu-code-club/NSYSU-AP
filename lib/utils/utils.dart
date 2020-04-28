import 'dart:convert';

import 'package:big5/big5.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static String base64md5(String text) {
    var bytes = utf8.encode(text);
    var digest = md5.convert(bytes);
    return base64.encode(digest.bytes);
  }

  static Future<void> launchUrl(var url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static String uriEncodeBig5(String text) {
    var list = big5.encode(text);
    var result = '';
    for (var value in list) {
      result += '%${value.toRadixString(16)}';
    }
    return result;
  }
}
