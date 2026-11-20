import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:ap_common_plugin/ap_common_plugin.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/guide/school_map_page.dart';
import 'package:nsysu_ap/pages/info/shcool_info_page.dart';
import 'package:nsysu_ap/pages/login/login_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/study/course_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/pages/tabs/bus_tab.dart';
import 'package:nsysu_ap/pages/tabs/campus_tab.dart';
import 'package:nsysu_ap/pages/tabs/home_tab.dart';
import 'package:nsysu_ap/pages/tabs/study_tab.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/pages/user_info_page.dart';
import 'package:nsysu_ap/resources/image_assets.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enrollment_certificate_session.dart';
import 'package:nsysu_ap/utils/enroll_certificate/registration_cookie_store.dart';
import 'package:nsysu_ap/utils/new_feature_discovery.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/account_sheet.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_tab_bar.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  static const String routerName = '/home';

  /// Reserved trailing circular Liquid Glass button on the bottom bar
  /// (matching the Apple Store 4+1 geometry). Hidden (`null`) by default.
  final LiquidGlassTabAction? trailingAction;

  /// Controls whether startup network/plugin side effects run in `initState`.
  final bool enableStartupSideEffects;

  /// Optional initial bus state for deterministic testing.
  final DataState<List<BusInfo>>? initialBusState;

  const HomePage({
    super.key,
    this.trailingAction,
    this.enableStartupSideEffects = true,
    this.initialBusState,
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;
  late final NewFeatureDiscovery _featureDiscovery;

  HomeState state = HomeState.loading;

  bool get isLogin => ShareDataWidget.of(context)?.data.isLogin ?? false;

  UserInfo? get userInfo => ShareDataWidget.of(context)?.data.userInfo;

  List<Announcement> announcements = <Announcement>[];

  CourseData? courseData;

  bool get displayPicture =>
      PreferenceUtil.instance.getBool(Constants.prefDisplayPicture, true);

  @override
  void initState() {
    super.initState();
    _featureDiscovery = NewFeatureDiscovery(PreferenceUtil.instance)
      ..addListener(_refreshFeatureLabels);
    if (!widget.enableStartupSideEffects) {
      state = HomeState.empty;
      return;
    }
    AnalyticsUtil.instance.setCurrentScreen('HomePage', 'home_page.dart');
    Future<void>.microtask(() async {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarContrastEnforced: true,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _getAllAnnouncement();
      _loadCourseData();
      if (PreferenceUtil.instance.getBool(Constants.prefAutoLogin, false)) {
        _login();
      }
      if (FirebaseRemoteConfigUtils.isSupported) {
        _checkUpdate();
      }
      if (await AppStoreUtil.instance.trackingAuthorizationStatus ==
          GeneralPermissionStatus.notDetermined) {
        // ignore: use_build_context_synchronously
        if (!mounted) return;
        AppTrackingUtils.show(context: context);
      }
    });
    FirebaseMessagingUtils.instance.init(
      onClick: (RemoteMessage message) {
        if (kDebugMode) {
          print(message.data);
        }
      },
    );
  }

  void _refreshFeatureLabels() => setState(() {});

  @override
  void dispose() {
    _featureDiscovery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Locale currentLocale = Locale(
      Intl.defaultLocale ?? Localizations.localeOf(context).toLanguageTag(),
    );

    final List<Widget> tabs = <Widget>[
      HomeTab(
        isLogin: isLogin,
        userInfo: userInfo,
        displayPicture: displayPicture,
        announcementState: state,
        announcements: announcements,
        courseData: courseData,
        onAvatarTap: _handleAvatarTap,
        onLoginTap: openLoginPage,
        onOpenCourse: () => _openPage(CoursePage(), needLogin: true),
        onOpenAnnouncementReview: _openAnnouncementReview,
        onAnnouncementTap: (Announcement announcement) {
          ApUtils.pushCupertinoStyle(
            context,
            AnnouncementContentPage(announcement: announcement),
          );
        },
        onRefreshAnnouncements: _getAllAnnouncement,
      ),
      StudyTab(
        isLogin: isLogin,
        userInfo: userInfo,
        displayPicture: displayPicture,
        onAvatarTap: _handleAvatarTap,
        onOpenCourse: () => _openPage(CoursePage(), needLogin: true),
        onOpenScore: () => _openPage(ScorePage(), needLogin: true),
        onOpenGraduationCheck: () =>
            _openPage(const GraduationReportPage(), needLogin: true),
        showNewTuitionFeature: _featureDiscovery.showsLabelAt(
          NewFeatureLocation.tuitionAndFees,
        ),
        onOpenTuitionAndCert: () => _openPage(
          TuitionAndFeesPage(featureDiscovery: _featureDiscovery),
          needLogin: true,
        ),
        onOpenCourseSelector: _openCourseSelector,
      ),
      BusTab(
        locale: currentLocale,
        isLogin: isLogin,
        userInfo: userInfo,
        displayPicture: displayPicture,
        onAvatarTap: _handleAvatarTap,
        initialState: widget.initialBusState,
      ),
      CampusTab(
        isLogin: isLogin,
        userInfo: userInfo,
        displayPicture: displayPicture,
        onAvatarTap: _handleAvatarTap,
        onOpenSchoolMap: () =>
            _openPage(SchoolMapPage(), useCupertinoRoute: true),
        onOpenSchoolInfo: () =>
            _openPage(SchoolInfoPage(), useCupertinoRoute: true),
        onOpenAnnouncementReview: _openAnnouncementReview,
        onOpenSettings: () => _openPage(SettingPage()),
        onOpenAbout: _openAboutPage,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          IndexedStack(index: _currentTabIndex, children: tabs),
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassTabBar(
              currentIndex: _currentTabIndex,
              onTap: (int index) {
                setState(() => _currentTabIndex = index);
                if (index == 0 && isLogin) {
                  _loadCourseData();
                }
              },
              trailingAction: widget.trailingAction,
              items: <LiquidGlassTabItem>[
                LiquidGlassTabItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: ap.home,
                ),
                LiquidGlassTabItem(
                  icon: Icons.school_outlined,
                  activeIcon: Icons.school_rounded,
                  label: app.tabStudy,
                  showNewFeature: _featureDiscovery.showsLabelAt(
                    NewFeatureLocation.studyTab,
                  ),
                ),
                LiquidGlassTabItem(
                  icon: Icons.directions_bus_outlined,
                  activeIcon: Icons.directions_bus_rounded,
                  label: ap.bus,
                ),
                LiquidGlassTabItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: app.tabCampus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAvatarTap() {
    if (!isLogin) {
      openLoginPage();
      return;
    }
    AccountSheet.show(
      context: context,
      userInfo: userInfo,
      displayPicture: displayPicture,
      onOpenProfile: () {
        if (userInfo != null) {
          ApUtils.pushCupertinoStyle(
            context,
            UserInfoPage(userInfo: userInfo!),
          );
        }
      },
      onOpenSettings: () => _openPage(SettingPage()),
      onOpenAbout: _openAboutPage,
      onLogout: _logout,
    );
  }

  void _openAboutPage() {
    _openPage(
      AboutUsPage(
        assetImage: ImageAssets.nsysu,
        githubName: 'nsysu-code-club',
        email: 'nsysu.gdsc@gmail.com',
        appLicense: app.aboutOpenSourceContent,
        fbFanPageId: '100906232372556',
        instagramUsername: 'gdsc_nsysu',
        fbFanPageUrl: 'https://www.facebook.com/NSYSUGDSC',
        githubUrl: 'https://github.com/nsysu-code-club',
      ),
    );
  }

  Future<void> _openAnnouncementReview() async {
    AnnouncementHelper.instance.organization = 'nsysu';
    AnnouncementHelper.instance.appleBundleId = 'com.nsysu.ap';
    ApUtils.pushCupertinoStyle(
      context,
      const AnnouncementHomePage(organizationDomain: '@g-mail.nsysu.edu.tw'),
    );
    if (FirebaseMessagingUtils.isSupported) {
      try {
        final FirebaseMessaging messaging = FirebaseMessaging.instance;
        final NotificationSettings settings = await messaging
            .getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          final String? token = await messaging.getToken();
          AnnouncementHelper.instance.fcmToken = token;
        }
      } catch (_) {}
    }
  }

  Future<void> _openCourseSelector() async {
    final Uri uri = Uri.parse(Constants.courseSelectorUrl);
    if (uri.scheme == 'https') {
      final bool? shouldLaunch = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(app.openingBrowserTitle),
          content: Text(
            '${app.openingBrowserContent}:\n'
            '${Constants.courseSelectorUrl}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(app.optionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(app.optionComfirm),
            ),
          ],
        ),
      );
      if (!mounted || shouldLaunch != true) return;
      PlatformUtil.instance.launchUrl(uri.toString());
    } else {
      UiUtil.instance.showToast(context, app.visitingUnSafeLink);
      debugPrint(
        'Attempted to launch an insecure URL: '
        '${Constants.courseSelectorUrl}',
      );
    }
  }

  Future<void> _getAllAnnouncement() async {
    final ApiResult<List<Announcement>> result = await AnnouncementHelper
        .instance
        .getAnnouncements(tags: <String>['nsysu']);
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<Announcement>>(:final List<Announcement> data):
        announcements = data;
        setState(() {
          state = announcements.isEmpty ? HomeState.empty : HomeState.finish;
        });
      case ApiError<List<Announcement>>():
      case ApiFailure<List<Announcement>>():
        setState(() => state = HomeState.error);
    }
  }

  Future<void> _login() async {
    final String username = PreferenceUtil.instance
        .getString(Constants.prefUsername, '')
        .toUpperCase();
    final String password = PreferenceUtil.instance.getStringSecurity(
      Constants.prefPassword,
      '',
    );
    final ApiResult<GeneralResponse> result = await SelcrsHelper.instance.login(
      username: username,
      password: password,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<GeneralResponse>():
        UiUtil.instance.showToast(context, ap.loginSuccess);
        setState(() {
          ShareDataWidget.of(context)!.data.isLogin = true;
        });
        ShareDataWidget.of(context)!.data.getUserInfo();
        _loadCourseData();
      case ApiError<GeneralResponse>(:final GeneralResponse response):
        if (response.statusCode == 400) {
          UiUtil.instance.showToast(context, ap.loginFail);
        } else if (response.statusCode == 401) {
          UiUtil.instance.showToast(context, app.pleaseConfirmForm);
          Utils.openConfirmForm(context, mounted: mounted, username: username);
        } else {
          UiUtil.instance.showToast(context, ap.unknownError);
        }
      case ApiFailure<GeneralResponse>(:final DioException exception):
        if (exception.i18nMessage != null) {
          UiUtil.instance.showToast(context, exception.i18nMessage!);
        }
    }
  }

  Future<void> _logout() async {
    final String activeUsername = SelcrsHelper.instance.username.trim();
    final String username = activeUsername.isNotEmpty
        ? activeUsername
        : PreferenceUtil.instance.getString(Constants.prefUsername, '').trim();
    // Revoke active pages before the first await, then drain any
    // write already in progress before removing account data.
    final Future<void> enrollmentStopped =
        EnrollmentCertificateSession.cancelAll();
    final Future<void> cookiesCleared = RegistrationCookieStore.clear(
      beforeClear: () => enrollmentStopped,
    );
    SelcrsHelper.instance.logout();
    GraduationHelper.instance.logout();
    TuitionHelper.instance.logout();
    setState(() {
      ShareDataWidget.of(context)!.data.isLogin = false;
      ShareDataWidget.of(context)!.data.userInfo = null;
      courseData = null;
    });
    await PreferenceUtil.instance.setBool(Constants.prefAutoLogin, false);
    await enrollmentStopped;
    await cookiesCleared;
    await _clearEnrollmentCertificateCache(username);
    await ApCommonPlugin.clearCourseWidget();
  }

  Future<void> _checkUpdate() async {
    if (kIsWeb) return;
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String lastChangelogVersion = PreferenceUtil.instance.getString(
      Constants.prefLastChangelogVersion,
      '',
    );
    if (lastChangelogVersion != packageInfo.version) {
      final Map<String, dynamic>? rawData = await FileAssets.changelogData;
      final Map<String, dynamic>? map = FileAssets.changelogForVersion(
        rawData,
        packageInfo.version,
      );
      if (!mounted) return;
      final String? updateNoteContent = FileAssets.changelogContent(
        map,
        ap.locale,
      );
      final bool visible = map?['visible'] as bool? ?? true;
      if (visible &&
          updateNoteContent != null &&
          updateNoteContent.isNotEmpty) {
        DialogUtils.showUpdateContent(
          context,
          'v${packageInfo.version}\n'
          '$updateNoteContent',
        );
      }
      if (!visible || updateNoteContent != null) {
        await PreferenceUtil.instance.setString(
          Constants.prefLastChangelogVersion,
          packageInfo.version,
        );
      }
    }
    if (!Constants.isInDebugMode) {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      final VersionInfo versionInfo = remoteConfig.versionInfo;
      // ignore: use_build_context_synchronously
      if (!mounted) return;
      DialogUtils.showNewVersionContent(
        context: context,
        iOSAppId: '146752219',
        defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
        githubRepositoryName: 'nsysu-code-club/NSYSU-AP',
        windowsPath:
            'https://github.com/NKUST-ITC/nsysu-code-club/NSYSU-AP/releases/download/%s/nsysu_ap_windows.zip',
        appName: app.appName,
        versionInfo: versionInfo,
      );
    }
  }

  Future<void> openLoginPage() async {
    final bool? result = await Navigator.of(
      context,
    ).push(MaterialPageRoute<bool>(builder: (_) => LoginPage()));
    if (result ?? false) {
      if (state != HomeState.finish) {
        _getAllAnnouncement();
      }
      if (!mounted) return;
      setState(() {
        ShareDataWidget.of(context)!.data.isLogin = true;
      });
      ShareDataWidget.of(context)!.data.getUserInfo();
      _loadCourseData();
    }
  }

  Future<void> _clearEnrollmentCertificateCache(String username) async {
    if (username.isEmpty) return;

    try {
      await EnrollCertificateCache(username: username).clear();
    } on Exception catch (error) {
      debugPrint(
        'Failed to clear enrollment certificate cache during logout: '
        '${error.runtimeType}',
      );
    }
  }

  Future<void> _openPage(
    Widget page, {
    bool needLogin = false,
    bool useCupertinoRoute = false,
  }) async {
    if (needLogin && !isLogin) {
      UiUtil.instance.showToast(context, ap.notLoginHint);
      await openLoginPage();
      return;
    }
    if (useCupertinoRoute) {
      await Navigator.push(
        context,
        CupertinoPageRoute<dynamic>(builder: (_) => page),
      );
    } else {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<dynamic>(builder: (_) => page));
    }
    if (!mounted) return;
    if (isLogin) {
      _loadCourseData();
    }
    setState(() {});
  }

  Future<void> _loadCourseData() async {
    if (!mounted) return;
    final CourseData? cached = CourseData.load(
      PreferenceUtil.instance.getString(
        ApConstants.currentSemesterCode,
        ApConstants.semesterLatest,
      ),
    );
    setState(() => courseData = cached);
  }

  Future<void> openDesktopWebViewPage(
    String url, {
    required String title,
  }) async {
    final Webview webView = await WebviewWindow.create(
      configuration: CreateConfiguration(title: title),
    );
    webView.launch(url);
  }
}
