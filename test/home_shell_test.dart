import 'dart:convert';

import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_flutter_core/ap_common_flutter_core.dart'
    as ap_l10n
    show AppLocale, TranslationProvider, registerApCommonFlutter, setApLocale;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/app.dart';
import 'package:nsysu_ap/app_navigation.dart';
import 'package:nsysu_ap/pages/campus_page.dart';
import 'package:nsysu_ap/pages/enroll_certificate/enroll_certificate_page.dart';
import 'package:nsysu_ap/pages/login/login_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/new_feature_discovery.dart';
import 'package:nsysu_ap/widgets/account_sheet.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class _FakePreferences extends Fake implements PreferenceUtil {
  final Map<String, Object> store = <String, Object>{};

  @override
  bool getBool(String key, bool def) => (store[key] as bool?) ?? def;

  @override
  Future<void> setBool(String key, bool data) async {
    store[key] = data;
  }

  @override
  String getString(String key, String def) => (store[key] as String?) ?? def;

  @override
  Future<void> setString(String key, String data) async {
    store[key] = data;
  }

  @override
  int getInt(String key, int def) => (store[key] as int?) ?? def;

  @override
  String getStringSecurity(String key, String def) =>
      (store[key] as String?) ?? def;
}

class _FakeMyAppState extends Fake implements MyAppState {
  @override
  bool isLogin;

  @override
  UserInfo? userInfo;

  _FakeMyAppState({required this.isLogin, required this.userInfo});

  @override
  Future<void> getUserInfo() async {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeMyAppState';
}

class _TestAppHost extends StatelessWidget {
  final TargetPlatform platform;
  final bool isLogin;
  final UserInfo? userInfo;
  final Widget child;

  const _TestAppHost({
    this.platform = TargetPlatform.iOS,
    this.isLogin = false,
    this.userInfo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData light = AppleLiquidTheme.harmonize(
      ApTheme.light(const Color(0xFF007AFF)).copyWith(platform: platform),
    );
    final ThemeData dark = AppleLiquidTheme.harmonize(
      ApTheme.dark(const Color(0xFF007AFF)).copyWith(platform: platform),
    );
    return ShareDataWidget(
      data: _FakeMyAppState(isLogin: isLogin, userInfo: userInfo),
      child: ApTheme(
        themeMode: ThemeMode.system,
        preferences: PreferenceUtil.instance,
        child: ap_l10n.TranslationProvider(
          child: TranslationProvider(
            child: MaterialApp(
              theme: light,
              darkTheme: dark,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocaleUtils.supportedLocales,
              home: child,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  late _FakePreferences preferences;

  setUpAll(() async {
    preferences = _FakePreferences();
    registerApCommonCore(preference: preferences);
    registerApCommonService();
    ap_l10n.registerApCommonFlutter(
      ui: ApUiUtil(),
      platform: ApPlatformUtil(),
      media: ApMediaUtil(),
      platformCalendar: ApPlatformCalendarUtil(),
      notification: ApNotificationUtil(),
      appStore: ApAppStoreUtil(),
    );
    await ap_l10n.setApLocale(ap_l10n.AppLocale.zhHantTw);
    await LocaleSettings.setLocale(AppLocale.zhHantTw);
  });

  setUp(() => preferences.store.clear());

  testWidgets('homepage post button opens carousel submissions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestAppHost(
        child: AppNavigation(
          enableStartupSideEffects: false,
          initialBusState: DataLoaded<List<BusInfo>>(<BusInfo>[]),
        ),
      ),
    );
    final Finder post = find.text(app.postAnnouncement);
    await tester.ensureVisible(post);
    await tester.pumpAndSettle();
    await tester.tap(post);
    await tester.pumpAndSettle();
    expect(find.text(ap.announcementSubmissionSystem), findsOneWidget);
    expect(find.text(ap.announcementReviewSystem), findsNothing);
  });

  testWidgets('campus review entry shows and announces the pending total', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(
          highContrast: true,
          disableAnimations: true,
        );
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    int opens = 0;
    Widget screen({required bool isLogin, required int? count}) => _TestAppHost(
      child: Scaffold(
        body: CampusPage(
          isLogin: isLogin,
          pendingAnnouncementCount: count,
          userInfo: null,
          displayPicture: false,
          onAvatarTap: () {},
          onOpenSchoolMap: () {},
          onOpenSchoolInfo: () {},
          onOpenAnnouncementReview: () => opens++,
          onOpenSettings: () {},
          onOpenAbout: () {},
          onOpenGraduationCheck: () {},
          onOpenTuitionAndCert: () {},
          onOpenCourseSelector: () {},
          showNewTuitionFeature: false,
        ),
      ),
    );

    await tester.pumpWidget(screen(isLogin: true, count: 7));
    final Finder tile = find.widgetWithText(
      AppleGroupedTile,
      ap.announcementReviewSystem,
    );
    final Finder badge = find.text(ap.pendingAnnouncementCount(count: 7));
    await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(badge.hitTestable(), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(
          '${RegExp.escape(ap.announcementReviewSystem)}.*'
          '${RegExp.escape(ap.pendingAnnouncementCount(count: 7))}',
          dotAll: true,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    Focus.of(tester.element(badge)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opens, 1);

    await tester.pumpWidget(screen(isLogin: true, count: 0));
    expect(find.text(ap.pendingAnnouncementCount(count: 0)), findsOneWidget);
    await tester.pumpWidget(screen(isLogin: false, count: 7));
    expect(badge, findsNothing);
  });

  testWidgets('keeps app-provided home dashboard widgets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestAppHost(
        child: AppNavigation(
          enableStartupSideEffects: false,
          dashboardWidgets: <Widget>[Text('Dashboard extension')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard extension'), findsOneWidget);
    expect(find.byKey(ApHomeContent.loginCardKey), findsOneWidget);
  });

  testWidgets('Android detail pages have toolbar and system back navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestAppHost(
        platform: TargetPlatform.android,
        child: AppNavigation(enableStartupSideEffects: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(ap.course),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final AppBar loginBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(loginBar.backgroundColor, Colors.transparent);
    expect(loginBar.title, isA<SizedBox>());
    expect(loginBar.flexibleSpace, isNull);
    expect(find.byIcon(ApIcon.chevronLeft), findsOneWidget);
    await tester.tap(find.byIcon(ApIcon.chevronLeft));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(ap.score),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switches across 5 tabs without Drawer or SnackBar '
      'and shows inline login card when logged out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const _TestAppHost(
        child: AppNavigation(
          enableStartupSideEffects: false,
          initialBusState: DataLoaded<List<BusInfo>>(<BusInfo>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No legacy Drawer or bottom SnackBar
    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(LiquidGlassTabBar), findsOneWidget);
    expect(
      tester
          .widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar))
          .items
          .length,
      5,
    );

    // Logged out Home tab shows inline Login Prompt Card
    expect(find.byKey(ApHomeContent.loginCardKey), findsOneWidget);

    // Switch to Tab 2: 課業 (Study)
    await tester.tap(
      find.descendant(
        of: find.byType(LiquidGlassTabBar),
        matching: find.text(app.tabCampus),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(app.studyToolsSection), findsOneWidget);
    expect(find.text(app.graduationCheckChecklist), findsOneWidget);

    // Switch to Tab 3: 校車 (Bus)
    await tester.tap(
      find.descendant(
        of: find.byType(LiquidGlassTabBar),
        matching: find.text(ap.bus),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(app.busRoutesSection), findsOneWidget);

    // Switch to Tab 4: 校園 (Campus)
    await tester.tap(
      find.descendant(
        of: find.byType(LiquidGlassTabBar),
        matching: find.text(app.tabCampus),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(app.campusServicesSection), findsOneWidget);
    expect(find.text(ap.settings), findsOneWidget);
    expect(find.text(ap.about), findsOneWidget);
  });

  testWidgets('guides all three levels until the certificate is opened', (
    WidgetTester tester,
  ) async {
    final TuitionHelper tuition = TuitionHelper.instance;
    final Dio originalDio = tuition.dio;
    final bool originalLogin = tuition.isLogin;
    tuition
      ..isLogin = true
      ..dio = (Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
                  handler.resolve(
                    Response<Uint8List>(
                      requestOptions: options,
                      data: Uint8List.fromList(utf8.encode('沒有合乎查詢條件的資料')),
                    ),
                  );
                },
          ),
        ));
    addTearDown(() {
      tuition.dio.close();
      tuition
        ..dio = originalDio
        ..isLogin = originalLogin;
    });

    const Widget home = _TestAppHost(
      isLogin: true,
      child: AppNavigation(
        enableStartupSideEffects: false,
        initialBusState: DataEmpty<List<BusInfo>>(),
      ),
    );
    const NewFeature feature = NewFeature.enrollmentCertificate;
    final Finder studyTab = find.descendant(
      of: find.byType(LiquidGlassTabBar),
      matching: find.text(app.tabCampus),
    );
    final Finder markedStudyTab = find.bySemanticsLabel(
      '${app.tabCampus}, ${app.newFeature}',
    );
    final Finder tuitionTile = find.widgetWithText(
      AppleGroupedTile,
      app.tuitionAndCert,
    );
    final Finder certificateTile = find.widgetWithText(
      ListTile,
      app.enrollCertificate.action,
    );
    final Finder tuitionLabel = find.descendant(
      of: tuitionTile,
      matching: find.text(app.newFeature),
    );
    final Finder certificateLabel = find.descendant(
      of: certificateTile,
      matching: find.text(app.newFeature),
    );

    await tester.pumpWidget(home);
    await tester.pumpAndSettle();
    expect(find.text('快速捷徑'), findsNothing);
    expect(find.text(app.enrollCertificate.action), findsNothing);
    expect(markedStudyTab, findsOneWidget);
    expect(
      tester
          .getSemantics(markedStudyTab)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(studyTab);
    await tester.pumpAndSettle();
    expect(tuitionLabel, findsOneWidget);
    expect(preferences.store[feature.preferenceKey], isNull);
    await Scrollable.ensureVisible(tester.element(tuitionTile), alignment: 0.5);
    await tester.tap(tuitionTile);
    await tester.pumpAndSettle();
    expect(find.byType(TuitionAndFeesPage), findsOneWidget);
    expect(find.byType(LiquidGlassTabBar), findsNothing);
    expect(certificateLabel, findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(
          '${RegExp.escape(app.enrollCertificate.action)}.*'
          '${RegExp.escape(app.newFeature)}',
          dotAll: true,
        ),
      ),
      findsOneWidget,
    );
    expect(preferences.store[feature.preferenceKey], isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tuitionLabel, findsOneWidget);
    await tester.tap(tuitionTile);
    await tester.pumpAndSettle();
    await tester.tap(certificateTile);
    await tester.pumpAndSettle();
    expect(find.byType(EnrollCertificatePage), findsOneWidget);
    expect(preferences.store[feature.preferenceKey], isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(certificateLabel, findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tuitionLabel, findsNothing);
    expect(markedStudyTab, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(home);
    await tester.pumpAndSettle();
    expect(markedStudyTab, findsNothing);
    await tester.tap(studyTab);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(tuitionTile), alignment: 0.5);
    expect(tuitionLabel, findsNothing);
    await tester.tap(tuitionTile);
    await tester.pumpAndSettle();
    expect(certificateTile, findsOneWidget);
    expect(certificateLabel, findsNothing);
  });

  testWidgets(
    'new feature guidance fits large text and survives canceled login',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            highContrast: true,
            disableAnimations: true,
          );
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(
        const _TestAppHost(
          child: AppNavigation(
            enableStartupSideEffects: false,
            initialBusState: DataEmpty<List<BusInfo>>(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder study = find.descendant(
        of: find.byType(LiquidGlassTabBar),
        matching: find.text(app.tabCampus),
      );
      Focus.of(tester.element(study)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final Finder tile = find.widgetWithText(
        AppleGroupedTile,
        app.tuitionAndCert,
      );
      await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: tile, matching: find.text(app.newFeature)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(tile), alignment: 0.5);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      Navigator.of(tester.element(find.byType(LoginPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text(app.newFeature), findsOneWidget);
      expect(
        preferences.store[NewFeature.enrollmentCertificate.preferenceKey],
        isNull,
      );
    },
  );

  testWidgets(
    'tapping top-right avatar opens LoginPage directly when logged out',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const _TestAppHost(
          child: AppNavigation(
            enableStartupSideEffects: false,
            initialBusState: DataEmpty<List<BusInfo>>(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ProfileAvatarButton.buttonKey).first);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    },
  );

  testWidgets('tapping top-right avatar opens AccountSheet when logged in', (
    WidgetTester tester,
  ) async {
    const UserInfo sampleUser = UserInfo(
      id: 'B123040001',
      name: '王小明',
      className: '資工三',
      department: '資訊工程學系',
    );

    await tester.pumpWidget(
      const _TestAppHost(
        isLogin: true,
        userInfo: sampleUser,
        child: AppNavigation(
          enableStartupSideEffects: false,
          initialBusState: DataEmpty<List<BusInfo>>(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ProfileAvatarButton.buttonKey).first);
    await tester.pumpAndSettle();

    expect(find.byType(AccountSheet), findsOneWidget);
    expect(find.text('王小明'), findsWidgets);
    expect(find.textContaining('B123040001'), findsOneWidget);
    expect(find.text(ap.logout), findsOneWidget);
  });

  testWidgets(
    'wide-screen tablet layout centers content and tab bar without left drawer',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const _TestAppHost(
          child: AppNavigation(
            enableStartupSideEffects: false,
            initialBusState: DataEmpty<List<BusInfo>>(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      final Size tabBarSize = tester.getSize(find.byType(LiquidGlassTabBar));
      expect(tabBarSize.width, lessThanOrEqualTo(1200));
      expect(tester.takeException(), isNull);
    },
  );
}
