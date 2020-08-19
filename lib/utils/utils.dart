import 'dart:convert';

import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:big5/big5.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static String base64md5(String text) {
    var bytes = utf8.encode(text);
    var digest = md5.convert(bytes);
    return base64.encode(digest.bytes);
  }

  static String uriEncodeBig5(String text) {
    var list = big5.encode(text);
    var result = '';
    for (var value in list) {
      result += '%${value.toRadixString(16)}';
    }
    return result;
  }

  static void openConfirmForm(String username) async {
    String confirmFormUrl = '';
    try {
      RemoteConfig remoteConfig = await RemoteConfig.instance;
      await remoteConfig.fetch(expiration: const Duration(seconds: 10));
      await remoteConfig.activateFetched();
      confirmFormUrl = remoteConfig.getString(Constants.CONFIRM_FORM_URL);
      Preferences.getString(
        Constants.CONFIRM_FORM_URL,
        confirmFormUrl,
      );
    } catch (e) {
      confirmFormUrl = Preferences.getString(
        Constants.CONFIRM_FORM_URL,
        'https://regweb.nsysu.edu.tw/webreg/confirm_wuhan_pneumonia.asp?STUID=%s&STAT_COD=1&STATUS_COD=1&LOGINURL=https://selcrs.nsysu.edu.tw/',
      );
    }
    await Future.delayed(Duration(seconds: 1));
    await launch(sprintf(confirmFormUrl, [username]));
  }
}
