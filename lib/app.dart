import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/home_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/study/course_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseAnalytics? _analytics;

  Brightness brightness = Brightness.light;

  ThemeMode themeMode = ThemeMode.system;

  Locale? locale;

  bool isLogin = false;

  UserInfo? userInfo;

  @override
  void initState() {
    _analytics = FirebaseUtils.init();
    themeMode =
        ThemeMode.values[Preferences.getInt(Constants.prefThemeModeIndex, 0)];
    FirebaseAnalyticsUtils.instance.logThemeEvent(themeMode);
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
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            Navigator.defaultRouteName: (BuildContext context) => HomePage(),
            HomePage.routerName: (BuildContext context) => HomePage(),
            CoursePage.routerName: (BuildContext context) => CoursePage(),
            ScorePage.routerName: (BuildContext context) => ScorePage(),
            GraduationReportPage.routerName: (BuildContext context) =>
                const GraduationReportPage(),
            SettingPage.routerName: (BuildContext context) => SettingPage(),
          },
          theme: ApTheme.light,
          darkTheme: ApTheme.dark,
          themeMode: themeMode,
          locale: locale,
          navigatorObservers: <FirebaseAnalyticsObserver>[
            if (FirebaseAnalyticsUtils.isSupported && _analytics != null)
              FirebaseAnalyticsObserver(analytics: _analytics!),
          ],
          localeResolutionCallback:
              (Locale? locale, Iterable<Locale> supportedLocales) {
            final String languageCode = Preferences.getString(
              Constants.prefLanguageCode,
              ApSupportLanguageConstants.system,
            );
            if (languageCode == ApSupportLanguageConstants.system) {
              this.locale = ApLocalizations.delegate.isSupported(locale!)
                  ? locale
                  : const Locale('en');
            } else {
              this.locale = Locale(
                languageCode,
                languageCode == ApSupportLanguageConstants.zh ? 'TW' : null,
              );
            }
            AnnouncementHelper.instance.setLocale(this.locale!);
            return this.locale;
          },
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            apLocalizationsDelegate,
            appDelegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[
            Locale('en', 'US'), // English
            Locale('zh', 'TW'), // Chinese
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
    AnnouncementHelper.instance.setLocale(this.locale!);
    setState(() {
      apLocalizationsDelegate.load(locale);
      appDelegate.load(locale);
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
