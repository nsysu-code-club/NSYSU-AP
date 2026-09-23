import 'dart:async';
import 'dart:developer' as developer;

import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:ap_common_flutter_core/ap_common_flutter_core.dart'
    as ap_l10n
    show TranslationProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/home_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/study/course_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/utils/app_locale_controller.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/locale_initialization_gate.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseAnalytics? _analytics;
  late final AppLocaleController _localeController;
  late Future<void> _localeInitialization;

  String get languagePreference => _localeController.preferenceCode;

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
    super.initState();
    _analytics = FirebaseUtils.init();
    _localeController = AppLocaleController();
    themeMode =
        ThemeMode.values[PreferenceUtil.instance.getInt(
          Constants.prefThemeModeIndex,
          0,
        )];
    currentColorIndex = PreferenceUtil.instance.getInt(
      ApTheme.PREF_COLOR_INDEX,
      0,
    );
    final int customColorValue = PreferenceUtil.instance.getInt(
      ApTheme.PREF_CUSTOM_COLOR,
      0,
    );
    if (currentColorIndex == ApTheme.customColorIndex &&
        customColorValue != 0) {
      customColor = Color(customColorValue);
    }
    _localeInitialization = _initializeLocale();
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
  }

  Future<void> _initializeLocale() async {
    try {
      await _localeController.initialize();
      _updateLocale();
    } catch (error, stackTrace) {
      developer.log(
        'Locale initialization failed',
        name: 'nsysu_ap.locale',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _retryLocaleInitialization() {
    setState(() => _localeInitialization = _initializeLocale());
  }

  void _updateLocale() {
    if (!mounted) return;
    locale = _localeController.locale;
    if (locale != null) AnnouncementHelper.instance.setLocale(locale!);
    setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    unawaited(_handleDeviceLocalesChanged(locales));
  }

  Future<void> _handleDeviceLocalesChanged(List<Locale>? locales) async {
    try {
      await _localeController.handleDeviceLocalesChanged(locales);
      _updateLocale();
    } catch (error, stackTrace) {
      developer.log(
        'System locale update failed',
        name: 'nsysu_ap.locale',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
            return LocaleInitializationGate(
              initialization: _localeInitialization,
              onRetry: _retryLocaleInitialization,
              theme: ApTheme.light(seedColor),
              darkTheme: ApTheme.dark(seedColor),
              themeMode: themeMode,
              builder: (_) => _buildLocalizedApp(seedColor),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocalizedApp(Color seedColor) {
    return ap_l10n.TranslationProvider(
      child: TranslationProvider(
        child: Builder(
          builder: (BuildContext context) {
            return MaterialApp(
              onGenerateTitle: (BuildContext context) => context.app.appName,
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
              locale: TranslationProvider.of(context).flutterLocale,
              navigatorObservers: <NavigatorObserver>[
                if (FirebaseAnalyticsUtils.isSupported && _analytics != null)
                  FirebaseAnalyticsObserver(analytics: _analytics!),
              ],
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
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

  Future<void> loadLanguage(String preferenceCode) async {
    await _localeController.selectLanguage(preferenceCode);
    _updateLocale();
  }

  Future<void> getUserInfo() async {
    final ApiResult<UserInfo> result = await SelcrsHelper.instance
        .getUserInfo();
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
