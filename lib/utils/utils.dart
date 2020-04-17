import 'dart:convert';
import 'dart:io';

import 'package:big5/big5.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nsysu_ap/config/constants.dart';
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
}
