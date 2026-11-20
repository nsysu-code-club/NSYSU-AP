import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:ap_common_plugin/ap_common_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/bus_page.dart';
import 'package:nsysu_ap/pages/campus_page.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/guide/school_map_page.dart';
import 'package:nsysu_ap/pages/home_page.dart';
import 'package:nsysu_ap/pages/info/shcool_info_page.dart';
import 'package:nsysu_ap/pages/login/login_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/study/course_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/pages/user_info_page.dart';
import 'package:nsysu_ap/resources/image_assets.dart';
import 'package:nsysu_ap/utils/announcement_review_session.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_cache.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enrollment_certificate_session.dart';
import 'package:nsysu_ap/utils/enroll_certificate/registration_cookie_store.dart';
import 'package:nsysu_ap/utils/new_feature_discovery.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/account_sheet.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppNavigation extends StatefulWidget {
  static const String routerName = '/home';

  /// Controls whether startup network/plugin side effects run in `initState`.
  final bool enableStartupSideEffects;

  /// Optional initial bus state for deterministic testing.
  final DataState<List<BusInfo>>? initialBusState;
  final List<Widget> dashboardWidgets;

  const AppNavigation({
    super.key,
    this.dashboardWidgets = const <Widget>[],
    this.enableStartupSideEffects = true,
    this.initialBusState,
  });

  @override
  AppNavigationState createState() => AppNavigationState();
}

class AppNavigationState extends State<AppNavigation> {
  int _homeRevision = 0;
  int _shellRevision = 0;
  int _sessionGeneration = 0;
  Future<void>? _loginRequest;
  late final NewFeatureDiscovery _featureDiscovery;

  late final AnnouncementReviewSession _announcementReview;
  AppLifecycleListener? _announcementLifecycle;

  bool get isLogin => ShareDataWidget.of(context)?.data.isLogin ?? false;

  UserInfo? get userInfo => ShareDataWidget.of(context)?.data.userInfo;

  bool get displayPicture =>
      PreferenceUtil.instance.getBool(Constants.prefDisplayPicture, true);

  @override
  void initState() {
    super.initState();
    _featureDiscovery = NewFeatureDiscovery(PreferenceUtil.instance)
      ..addListener(_refreshFeatureLabels);
    _announcementReview = AnnouncementReviewSession(
      preferences: PreferenceUtil.instance,
    )..addListener(_refreshFeatureLabels);
    if (!widget.enableStartupSideEffects) {
      return;
    }
    _announcementLifecycle = AppLifecycleListener(
      onResume: () => unawaited(_announcementReview.refresh()),
    );
    AnalyticsUtil.instance.setCurrentScreen('HomePage', 'home_page.dart');
    Future<void>.microtask(() async {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarContrastEnforced: true,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _refreshHome();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enableStartupSideEffects) {
      _announcementReview.setSchoolAccount(
        isLogin ? SelcrsHelper.instance.username : null,
      );
    }
  }

  @override
  void dispose() {
    _announcementLifecycle?.dispose();
    _announcementReview.dispose();
    _featureDiscovery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Locale currentLocale = Localizations.localeOf(context);
    return ApAppShell(
      key: ValueKey<int>(_shellRevision),
      canSelectDestination: _canSelectDestination,
      destinations: <ApDestination>[
        ApDestination(
          id: 'home',
          label: ap.home,
          icon: ApIcon.home,
          selectedIcon: ApIcon.home,
          builder: (BuildContext pageContext) => HomePage(
            isLogin: isLogin,
            userInfo: userInfo,
            displayPicture: displayPicture,
            enableStartupSideEffects: widget.enableStartupSideEffects,
            refreshRevision: _homeRevision,
            dashboardWidgets: widget.dashboardWidgets,
            onAvatarTap: _handleAvatarTap,
            onLoginTap: openLoginPage,
            onOpenCourse: () => ApAppShell.select(pageContext, 'sch'),
            onOpenAnnouncementSubmission: () =>
                _openAnnouncementReview(submissionOnly: true),
          ),
        ),
        ApDestination(
          id: 'bus',
          label: ap.bus,
          icon: ApIcon.directionsBus,
          selectedIcon: ApIcon.directionsBus,
          builder: (_) => BusPage(
            locale: currentLocale,
            isLogin: isLogin,
            userInfo: userInfo,
            displayPicture: displayPicture,
            onAvatarTap: _handleAvatarTap,
            initialState: widget.initialBusState,
          ),
        ),
        ApDestination(
          id: 'sch',
          label: ap.course,
          icon: ApIcon.classIcon,
          selectedIcon: ApIcon.classIcon,
          builder: (_) => CoursePage(),
        ),
        ApDestination(
          id: 'score',
          label: ap.score,
          icon: ApIcon.assignment,
          selectedIcon: ApIcon.assignment,
          builder: (_) => ScorePage(),
        ),
        ApDestination(
          id: 'more',
          label: app.tabCampus,
          icon: ApIcon.school,
          selectedIcon: ApIcon.school,
          showBadge: _featureDiscovery.showsLabelAt(
            NewFeatureLocation.campusTab,
          ),
          badgeLabel: app.newFeature,
          builder: (_) => CampusPage(
            isLogin: isLogin,
            pendingAnnouncementCount: _announcementReview.pendingCount,
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
            onOpenGraduationCheck: () =>
                _openPage(const GraduationReportPage(), needLogin: true),
            onOpenTuitionAndCert: () => _openPage(
              TuitionAndFeesPage(featureDiscovery: _featureDiscovery),
              needLogin: true,
            ),
            onOpenCourseSelector: _openCourseSelector,
            showNewTuitionFeature: _featureDiscovery.showsLabelAt(
              NewFeatureLocation.tuitionAndFees,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _canSelectDestination(String id) async {
    if (id == 'home') _refreshHome();
    if (id == 'more') unawaited(_announcementReview.refresh());
    if (id != 'sch' && id != 'score') return true;
    if (isLogin) return true;
    await openLoginPage();
    return mounted && isLogin;
  }

  void _refreshHome() {
    if (mounted) setState(() => _homeRevision++);
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

  Future<void> _openAnnouncementReview({bool submissionOnly = false}) async {
    AnnouncementHelper.instance.organization = 'nsysu';
    AnnouncementHelper.instance.appleBundleId = 'com.nsysu.ap';
    await _announcementReview.openPage(() async {
      if (!mounted) return;
      unawaited(_loadAnnouncementFcmToken());
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => AnnouncementReviewPage(
            organizationDomain: '@g-mail.nsysu.edu.tw',
            accountLinkHint: isLogin && !submissionOnly
                ? app.announcementReviewLinkHint
                : null,
            submissionGuidelines: app.carouselGuidelines,
            coverImageHint: app.carouselImageHint,
            submissionOnly: submissionOnly,
          ),
        ),
      );
    }, linkReviewer: !submissionOnly);
  }

  Future<void> _loadAnnouncementFcmToken() async {
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

  Future<void> _login() async {
    final int generation = _sessionGeneration;
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
    if (!mounted || generation != _sessionGeneration) return;
    switch (result) {
      case ApiSuccess<GeneralResponse>():
        UiUtil.instance.showToast(context, ap.loginSuccess);
        setState(() {
          ShareDataWidget.of(context)!.data.isLogin = true;
        });
        _announcementReview.setSchoolAccount(SelcrsHelper.instance.username);
        ShareDataWidget.of(context)!.data.getUserInfo();
        _refreshHome();
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
    _sessionGeneration++;
    _announcementReview.setSchoolAccount(null);
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
      ShareDataWidget.of(context)!.data.logout();
      _shellRevision++;
      _homeRevision++;
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

  Future<void> openLoginPage() {
    if (_loginRequest != null) return _loginRequest!;
    final Future<void> request = _showLoginPage();
    _loginRequest = request;
    return request.whenComplete(() {
      if (identical(_loginRequest, request)) _loginRequest = null;
    });
  }

  Future<void> _showLoginPage() async {
    final bool? result = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => LoginPage()));
    if (!mounted || result != true) return;
    setState(() {
      ShareDataWidget.of(context)!.data.isLogin = true;
      _homeRevision++;
    });
    _announcementReview.setSchoolAccount(SelcrsHelper.instance.username);
    await ShareDataWidget.of(context)!.data.getUserInfo();
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
      if (!mounted || !isLogin) return;
    }
    if (useCupertinoRoute) {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(CupertinoPageRoute<dynamic>(builder: (_) => page));
    } else {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(MaterialPageRoute<dynamic>(builder: (_) => page));
    }
    if (!mounted) return;
    if (isLogin) {
      _refreshHome();
    }
    setState(() {});
  }
}
