import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/login_page.dart';
import 'package:nsysu_ap/pages/score_page.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  FirebaseAnalytics analytics;
  FirebaseMessaging _firebaseMessaging;
  Brightness brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      analytics = FirebaseAnalytics();
      //_firebaseMessaging = FirebaseMessaging();
      //_initFCM();
      FA.analytics = analytics;
    }
    return MaterialApp(
      localeResolutionCallback:
          (Locale locale, Iterable<Locale> supportedLocales) {
        return locale;
      },
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        Navigator.defaultRouteName: (context) => LoginPage(),
        ScorePage.routerName: (context) => ScorePage(),
      },
      theme: ThemeData(
        brightness: brightness,
        hintColor: Colors.white,
        accentColor: Resource.Colors.blue,
        unselectedWidgetColor: Resource.Colors.grey,
        backgroundColor: Colors.black12,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          border:
              UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
      navigatorObservers: (Platform.isIOS || Platform.isAndroid)
          ? [
              FirebaseAnalyticsObserver(analytics: analytics),
            ]
          : [],
      localizationsDelegates: [
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        CupertinoEnDefaultLocalizationsDelegate(),
      ],
      supportedLocales: [
        const Locale('en', 'US'), // English
        const Locale('zh', 'TW'), // Chinese
      ],
    );
  }

  void _initFCM() {
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onMessage: $message");
//        Utils.showFCMNotification(message['notification']['title'],
//            message['notification']['title'], message['notification']['body']);
      },
      onLaunch: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onLaunch: $message");
        //_navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onResume: $message");
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      if (token == null) return;
      if (Constants.isInDebugMode) {
        print("Push Messaging token: $token");
      }
      if (Platform.isAndroid)
        _firebaseMessaging.subscribeToTopic("Android");
      else if (Platform.isIOS) _firebaseMessaging.subscribeToTopic("IOS");
    });
  }
}
