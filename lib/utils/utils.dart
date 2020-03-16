import 'dart:io';

import 'package:big5/big5.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
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
                    AppLocalizations.locale = Localizations.localeOf(context);
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
                    preference.setString(Constants.PREF_LANGUAGE_CODE, 'zh');
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
                    preference.setString(Constants.PREF_LANGUAGE_CODE, 'en');
                    AppLocalizations.locale = Locale('en');
                  }
                  function();
                })
          ]),
    ).then<void>((int position) {});
  }

  static void showFCMNotification(
      String title, String body, String payload) async {
    //limit Android and iOS system
    if (Platform.isAndroid || Platform.isIOS) {
      var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      var initializationSettings = InitializationSettings(
        AndroidInitializationSettings(
            Constants.ANDROID_DEFAULT_NOTIFICATION_NAME),
        IOSInitializationSettings(
          onDidReceiveLocalNotification: (id, title, body, payload) {},
        ),
      );
      flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (text) {});
      var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
          Constants.NOTIFICATION_FCM_ID.toString(), '系統通知', '系統通知',
          largeIconBitmapSource: BitmapSource.Drawable,
          importance: Importance.Default,
          largeIcon: '@drawable/ic_launcher',
          style: AndroidNotificationStyle.BigText,
          enableVibration: false);
      var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
      var platformChannelSpecifics = new NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        Constants.NOTIFICATION_FCM_ID,
        title,
        payload,
        platformChannelSpecifics,
        payload: payload,
      );
    } else {
      //TODO implement other platform system local notification
    }
  }

  static Future<void> cancelCourseNotify() async {
    var flutterLocalNotificationsPlugin = initFlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .cancel(Constants.NOTIFICATION_COURSE_ID);
  }

  static FlutterLocalNotificationsPlugin initFlutterLocalNotificationsPlugin() {
    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettings = InitializationSettings(
      AndroidInitializationSettings(
          Constants.ANDROID_DEFAULT_NOTIFICATION_NAME),
      IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) {},
      ),
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (text) {});
    return flutterLocalNotificationsPlugin;
  }

  static String uriEncodeBig5(String text) {
    var list = big5.encode(text);
    var result = '';
    for (var value in list) {
      result += '%${value.toRadixString(16)}';
    }
    return result;
  }

  static pushCupertinoStyle(BuildContext context, Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (BuildContext context) {
        return page;
      }),
    );
  }
}
