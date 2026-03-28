import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseAnalytics? _analytics;

  ThemeMode themeMode = ThemeMode.system;
  int currentColorIndex = 0;
  Color? customColor;

  Locale? locale;

  bool isLogin = false;

  UserInfo? userInfo;

  void logout() {
    setState(() {
      isLogin = false;
      userInfo = null;
    });
  }

  @override
  void initState() {
    _analytics = FirebaseUtils.init();
    themeMode = ThemeMode.values[
        PreferenceUtil.instance.getInt(Constants.prefThemeModeIndex, 0)];
    currentColorIndex =
        PreferenceUtil.instance.getInt(ApTheme.PREF_COLOR_INDEX, 0);
    final int customColorValue =
        PreferenceUtil.instance.getInt(ApTheme.PREF_CUSTOM_COLOR, 0);
    if (currentColorIndex == ApTheme.customColorIndex &&
        customColorValue != 0) {
      customColor = Color(customColorValue);
    }
    (AnalyticsUtil.instance as FirebaseAnalyticsUtils).logThemeEvent(themeMode);
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarContrastEnforced: true,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    });
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
    (AnalyticsUtil.instance as FirebaseAnalyticsUtils).logThemeEvent(themeMode);
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return ShareDataWidget(
      data: this,
      child: ApTheme(
        themeMode: themeMode,
        currentColorIndex: currentColorIndex,
        customColor: customColor,
        preferences: PreferenceUtil.instance,
        child: Builder(
          builder: (BuildContext context) {
            final Color seedColor = ApTheme.of(context).seedColor;
            return MaterialApp(
              onGenerateTitle: (BuildContext context) =>
                  AppLocalizations.of(context).appName,
              debugShowCheckedModeBanner: false,
              routes: <String, WidgetBuilder>{
                Navigator.defaultRouteName: (BuildContext context) =>
                    HomePage(),
                HomePage.routerName: (BuildContext context) => HomePage(),
                CoursePage.routerName: (BuildContext context) => CoursePage(),
                ScorePage.routerName: (BuildContext context) => ScorePage(),
                GraduationReportPage.routerName: (BuildContext context) =>
                    const GraduationReportPage(),
                SettingPage.routerName: (BuildContext context) => SettingPage(),
              },
              theme: ApTheme.light(seedColor),
              darkTheme: ApTheme.dark(seedColor),
              themeMode: themeMode,
              locale: locale,
              navigatorObservers: <NavigatorObserver>[
                if (FirebaseAnalyticsUtils.isSupported && _analytics != null)
                  FirebaseAnalyticsObserver(analytics: _analytics!),
              ],
              localeResolutionCallback:
                  (Locale? locale, Iterable<Locale> supportedLocales) {
                final String languageCode = PreferenceUtil.instance.getString(
                  Constants.prefLanguageCode,
                  ApSupportLanguageConstants.system,
                );
                if (languageCode == ApSupportLanguageConstants.system) {
                  return this.locale =
                      ApLocalizations.delegate.isSupported(locale!)
                          ? locale
                          : const Locale('en');
                } else {
                  return this.locale = Locale(
                    languageCode,
                    languageCode == ApSupportLanguageConstants.zh ? 'TW' : null,
                  );
                }
              },
              localizationsDelegates:
                  const <LocalizationsDelegate<dynamic>>[
                apLocalizationsDelegate,
                appDelegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: ApLocalizations.delegate.supportedLocales,
            );
          },
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

  void loadThemeColor(int index, Color? custom) {
    setState(() {
      currentColorIndex = index;
      customColor = custom;
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
        onFailure: (DioException e) {
          if (e.i18nMessage != null) {
            UiUtil.instance.showToast(context, e.i18nMessage!);
          }
        },
        onError: (GeneralResponse e) =>
            UiUtil.instance.showToast(context, ApLocalizations.current.somethingError),
        onSuccess: (UserInfo data) {
          setState(() {
            userInfo = data;
          });
          if (userInfo != null) {
            AnalyticsUtil.instance.logUserInfo(userInfo!);
          }
        },
      ),
    );
  }
}
