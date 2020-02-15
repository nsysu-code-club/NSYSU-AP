import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/login_page.dart';
import 'package:nsysu_ap/pages/score_page.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';

import 'pages/about/about_us_page.dart';
import 'pages/about/open_source_page.dart';
import 'pages/course_page.dart';
import 'pages/home_page.dart';
import 'pages/setting_page.dart';

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  FirebaseAnalytics _analytics;
  FirebaseMessaging _firebaseMessaging;
  Brightness brightness = Brightness.light;
  String username;
  String password;

  @override
  void initState() {
    if (kIsWeb) {
    } else if (Platform.isAndroid || Platform.isIOS) {
      _analytics = FirebaseAnalytics();
      _firebaseMessaging = FirebaseMessaging();
      _initFCM(_firebaseMessaging);
      FA.analytics = _analytics;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ShareDataWidget(
      this,
      child: MaterialApp(
        localeResolutionCallback:
            (Locale locale, Iterable<Locale> supportedLocales) {
          return locale;
        },
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        routes: <String, WidgetBuilder>{
          Navigator.defaultRouteName: (context) => LoginPage(),
          HomePage.routerName: (context) => HomePage(),
          CoursePage.routerName: (context) => CoursePage(),
          ScorePage.routerName: (context) => ScorePage(),
          GraduationReportPage.routerName: (context) => GraduationReportPage(),
          SettingPage.routerName: (context) => SettingPage(),
          AboutUsPage.routerName: (context) => AboutUsPage(),
          OpenSourcePage.routerName: (context) => OpenSourcePage(),
        },
        theme: ThemeData(
          brightness: brightness,
          hintColor: Colors.white,
          accentColor: Resource.Colors.blue,
          unselectedWidgetColor: Resource.Colors.grey,
          backgroundColor: Colors.black12,
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.white),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        navigatorObservers: (kIsWeb)
            ? []
            : (Platform.isIOS || Platform.isAndroid)
            ? [
          FirebaseAnalyticsObserver(analytics: _analytics),
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
      ),
    );
  }

  void _initFCM(FirebaseMessaging firebaseMessaging) async {
    await Future.delayed(Duration(seconds: 2));
    firebaseMessaging.requestNotificationPermissions();
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onMessage: $message");
        Utils.showFCMNotification(
            message['notification']['title'] ?? '',
            message['notification']['title'] ?? '',
            message['notification']['body'] ?? '');
      },
      onLaunch: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onLaunch: $message");
        //_navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        if (Constants.isInDebugMode) print("onResume: $message");
      },
    );
    firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    firebaseMessaging.getToken().then((String token) {
      if (token == null) return;
      if (Constants.isInDebugMode) {
        print("Push Messaging token: $token");
      }
      if (Platform.isAndroid)
        firebaseMessaging.subscribeToTopic("Android");
      else if (Platform.isIOS) firebaseMessaging.subscribeToTopic("IOS");
    });
  }
}
