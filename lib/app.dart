import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';

import 'api/selcrs_helper.dart';
import 'pages/study/course_page.dart';
import 'pages/home_page.dart';
import 'pages/setting_page.dart';

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseAnalytics _analytics;

  Brightness brightness = Brightness.light;

  ThemeMode themeMode = ThemeMode.system;

  Locale locale;

  bool isLogin = false;

  UserInfo userInfo;

  @override
  void initState() {
    _analytics = FirebaseUtils.init();
    themeMode = ThemeMode
        .values[Preferences.getInt(Constants.PREF_THEME_MODE_INDEX, 0)];
    FirebaseAnalyticsUtils.instance?.logThemeEvent(themeMode);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
    FirebaseAnalyticsUtils.instance.logThemeEvent(themeMode);
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return ShareDataWidget(
      this,
      child: ApTheme(
        themeMode,
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            Navigator.defaultRouteName: (context) => HomePage(),
            HomePage.routerName: (context) => HomePage(),
            CoursePage.routerName: (context) => CoursePage(),
            ScorePage.routerName: (context) => ScorePage(),
            GraduationReportPage.routerName: (context) =>
                GraduationReportPage(),
            SettingPage.routerName: (context) => SettingPage(),
          },
          theme: ApTheme.light,
          darkTheme: ApTheme.dark,
          themeMode: themeMode,
          locale: locale,
          navigatorObservers: [
            if (FirebaseAnalyticsUtils.isSupported)
              FirebaseAnalyticsObserver(analytics: _analytics),
          ],
          localeResolutionCallback:
              (Locale locale, Iterable<Locale> supportedLocales) {
            String languageCode = Preferences.getString(
              Constants.PREF_LANGUAGE_CODE,
              ApSupportLanguageConstants.system,
            );
            if (languageCode == ApSupportLanguageConstants.system)
              this.locale = ApLocalizations.delegate.isSupported(locale)
                  ? locale
                  : Locale('en');
            else
              this.locale = Locale(
                languageCode,
                languageCode == ApSupportLanguageConstants.zh ? 'TW' : null,
              );
            AnnouncementHelper.instance.setLocale(this.locale);
            return this.locale;
          },
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            ApLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', 'US'), // English
            const Locale('zh', 'TW'), // Chinese
          ],
        ),
      ),
    );
  }

  void update() {
    setState(() {});
  }

  void loadTheme(ThemeMode mode) {
    setState(() {
      themeMode = mode;
    });
  }

  void loadLocale(Locale locale) {
    this.locale = locale;
    AnnouncementHelper.instance.setLocale(this.locale);
    setState(() {
      AppLocalizationsDelegate().load(locale);
      ApLocalizations.load(locale);
    });
  }

  void getUserInfo() {
    SelcrsHelper.instance.getUserInfo(
      callback: GeneralCallback<UserInfo>(
        onFailure: (DioError e) => ApUtils.showToast(context, e.i18nMessage),
        onError: (GeneralResponse e) =>
            ApUtils.showToast(context, ApLocalizations.current.somethingError),
        onSuccess: (UserInfo data) {
          setState(() {
            userInfo = data;
          });
          if (userInfo != null) {
            FirebaseAnalyticsUtils.instance.logUserInfo(userInfo);
          }
        },
      ),
    );
  }
}
