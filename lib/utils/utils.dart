import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
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
}
