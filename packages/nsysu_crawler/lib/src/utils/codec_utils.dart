import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nsysu_crawler/src/utils/big5/big5.dart';

String base64md5(String text) {
  final List<int> bytes = utf8.encode(text);
  final Digest digest = md5.convert(bytes);
  return base64.encode(digest.bytes);
}

String uriEncodeBig5(String text) {
  final List<int> list = big5.encode(text);
  final StringBuffer buffer = StringBuffer();
  for (final int value in list) {
    buffer.write('%${value.toRadixString(16)}');
  }
  return buffer.toString();
}
