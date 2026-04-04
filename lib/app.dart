import 'package:ap_common/ap_common.dart'
    hide TranslationProvider, LocaleSettings, AppLocaleUtils, AppLocale;
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:ap_common_flutter_core/src/l10n/strings.g.dart' as ap_l10n;
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
    _initLocale();
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

  Future<void> _initLocale() async {
    final String languageCode = PreferenceUtil.instance.getString(
      Constants.prefLanguageCode,
      ApSupportLanguageConstants.system,
    );
    if (languageCode == ApSupportLanguageConstants.system) {
      await useApDeviceLocale();
      await LocaleSettings.useDeviceLocale();
    } else {
      final Locale locale = Locale(
        languageCode,
        languageCode == ApSupportLanguageConstants.zh ? 'TW' : null,
      );
      await setApLocaleFromFlutter(locale);
      final AppLocale appLocale = AppLocaleUtils.instance.parseLocaleParts(
        languageCode: locale.languageCode,
        scriptCode: locale.scriptCode,
        countryCode: locale.countryCode,
      );
      await LocaleSettings.setLocale(appLocale);
    }
    if (mounted) setState(() {});
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
            return ap_l10n.TranslationProvider(
              child: TranslationProvider(
                child: Builder(
                  builder: (BuildContext context) {
                    return MaterialApp(
                      onGenerateTitle: (BuildContext context) =>
                          context.app.appName,
                      debugShowCheckedModeBanner: false,
                      routes: <String, WidgetBuilder>{
                        Navigator.defaultRouteName: (BuildContext context) =>
                            HomePage(),
                        HomePage.routerName: (BuildContext context) =>
                            HomePage(),
                        CoursePage.routerName: (BuildContext context) =>
                            CoursePage(),
                        ScorePage.routerName: (BuildContext context) =>
                            ScorePage(),
                        GraduationReportPage.routerName:
                            (BuildContext context) =>
                                const GraduationReportPage(),
                        SettingPage.routerName: (BuildContext context) =>
                            SettingPage(),
                      },
                      theme: ApTheme.light(seedColor),
                      darkTheme: ApTheme.dark(seedColor),
                      themeMode: themeMode,
                      locale: TranslationProvider.of(context).flutterLocale,
                      navigatorObservers: <NavigatorObserver>[
                        if (FirebaseAnalyticsUtils.isSupported &&
                            _analytics != null)
                          FirebaseAnalyticsObserver(analytics: _analytics!),
                      ],
                      localizationsDelegates:
                          const <LocalizationsDelegate<dynamic>>[
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: AppLocaleUtils.supportedLocales,
                    );
                  },
                ),
              ),
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
    setApLocaleFromFlutter(locale);
    final AppLocale appLocale = AppLocaleUtils.instance.parseLocaleParts(
      languageCode: locale.languageCode,
      scriptCode: locale.scriptCode,
      countryCode: locale.countryCode,
    );
    LocaleSettings.setLocale(appLocale);
  }

  Future<void> getUserInfo() async {
    final ApiResult<UserInfo> result =
        await SelcrsHelper.instance.getUserInfo();
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<UserInfo>(:final UserInfo data):
        setState(() {
          userInfo = data;
        });
        if (userInfo != null) {
          AnalyticsUtil.instance.logUserInfo(userInfo!);
        }
      case ApiFailure<UserInfo>(:final DioException exception):
        if (exception.i18nMessage != null) {
          UiUtil.instance.showToast(context, exception.i18nMessage!);
        }
      case ApiError<UserInfo>():
        UiUtil.instance.showToast(context, ap.somethingError);
    }
  }
}
