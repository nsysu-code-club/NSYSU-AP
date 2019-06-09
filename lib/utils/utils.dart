import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static void showToast(BuildContext context, String message) {
    Toast.show(
      message,
      context,
      duration: Toast.LENGTH_LONG,
      gravity: Toast.BOTTOM,
    );
  }

  static String getPlatformUpdateContent(AppLocalizations app) {
    if (Platform.isAndroid)
      return app.updateAndroidContent;
    else if (Platform.isIOS)
      return app.updateIOSContent;
    else
      return app.updateContent;
  }

  static void showSnackBarBar(
    ScaffoldState scaffold,
    String contentText,
    String actionText,
    Color actionTextColor,
  ) {
    scaffold.showSnackBar(
      SnackBar(
        content: Text(contentText),
        duration: Duration(days: 1),
        action: SnackBarAction(
          label: actionText,
          onPressed: () {},
          textColor: actionTextColor,
        ),
      ),
    );
  }

  static Future<void> launchUrl(var url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static void showChoseLanguageDialog(BuildContext context, Function function) {
    var app = AppLocalizations.of(context);
    showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
              title: Text(app.choseLanguageTitle),
              children: <SimpleDialogOption>[
                SimpleDialogOption(
                    child: Text(app.systemLanguage),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (Platform.isAndroid || Platform.isIOS) {
                        SharedPreferences preference =
                            await SharedPreferences.getInstance();
                        preference.setString(
                            Constants.PREF_LANGUAGE_CODE, 'system');
                        AppLocalizations.locale =
                            Localizations.localeOf(context);
                      }
                      function();
                    }),
                SimpleDialogOption(
                    child: Text(app.traditionalChinese),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (Platform.isAndroid || Platform.isIOS) {
                        SharedPreferences preference =
                            await SharedPreferences.getInstance();
                        preference.setString(
                            Constants.PREF_LANGUAGE_CODE, 'zh');
                        AppLocalizations.locale = Locale('zh');
                      }
                      function();
                    }),
                SimpleDialogOption(
                    child: Text(app.english),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (Platform.isAndroid || Platform.isIOS) {
                        SharedPreferences preference =
                            await SharedPreferences.getInstance();
                        preference.setString(
                            Constants.PREF_LANGUAGE_CODE, 'en');
                        AppLocalizations.locale = Locale('en');
                      }
                      function();
                    })
              ]),
    ).then<void>((int position) {});
  }
}
