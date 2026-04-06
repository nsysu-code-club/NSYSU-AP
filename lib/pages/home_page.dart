import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:ap_common_plugin/ap_common_plugin.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/api/graduation_helper.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/api/tuition_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/bus/bus_list_page.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/guide/admission_guide_page.dart';
import 'package:nsysu_ap/pages/guide/school_map_page.dart';
import 'package:nsysu_ap/pages/info/shcool_info_page.dart';
import 'package:nsysu_ap/pages/login/login_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/study/course_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/pages/user_info_page.dart';
import 'package:nsysu_ap/resources/image_assets.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  static const String routerName = '/home';

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();

  bool get isTablet => MediaQuery.of(context).size.shortestSide > 680;

  HomeState state = HomeState.loading;

  bool get isLogin => ShareDataWidget.of(context)?.data.isLogin ?? false;

  UserInfo? get userInfo => ShareDataWidget.of(context)?.data.userInfo;

  Widget? content;

  List<Announcement> announcements = <Announcement>[];

  CourseData? courseData;

  bool isStudyExpanded = false;
  bool isSchoolNavigationExpanded = false;

  String get drawerIcon {
    switch (Theme.of(context).brightness) {
      case Brightness.light:
        return ImageAssets.nsysu;
      case Brightness.dark:
      default:
        return ImageAssets.nsysu;
    }
  }

  @override
  void initState() {
    super.initState();
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
      } else {
        _checkLoginState();
      }
      if (FirebaseRemoteConfigUtils.isSupported) {
        _checkUpdate();
      }
      if (await AppStoreUtil.instance.trackingAuthorizationStatus ==
          GeneralPermissionStatus.notDetermined) {
        //ignore: use_build_context_synchronously
        if (!mounted) return;
        AppTrackingUtils.show(context: context);
      }
    });
    if (Intl.defaultLocale != null) {
      AnalyticsUtil.instance.setUserProperty(
        AnalyticsConstants.language,
        Locale(Intl.defaultLocale!).languageCode,
      );
    }
    FirebaseMessagingUtils.instance.init(
      onClick: (RemoteMessage message) {
        if (kDebugMode) {
          print(message.data);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return HomePageScaffold(
      key: _homeKey,
      isLogin: isLogin,
      state: state,
      title: app.appName,
      content: content,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.post_add),
          tooltip: ap.announcementReviewSystem,
          onPressed: () async {
            AnnouncementHelper.instance.organization = 'nsysu';
            AnnouncementHelper.instance.appleBundleId = 'com.nsysu.ap';
            ApUtils.pushCupertinoStyle(
              context,
              const AnnouncementHomePage(
                organizationDomain: '@g-mail.nsysu.edu.tw',
              ),
            );
            if (FirebaseMessagingUtils.isSupported) {
              try {
                final FirebaseMessaging messaging = FirebaseMessaging.instance;
                final NotificationSettings settings = await messaging
                    .getNotificationSettings();
                if (settings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional) {
                  final String? token = await messaging.getToken();
                  AnnouncementHelper.instance.fcmToken = token;
                }
              } catch (_) {}
            }
          },
        ),
      ],
      onImageTapped: (Announcement announcement) {
        ApUtils.pushCupertinoStyle(
          context,
          AnnouncementContentPage(announcement: announcement),
        );
      },
      drawer: _buildDrawer(),
      dashboardWidgets: _buildDashboardWidgets(),
      announcements: announcements,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: <NavigationDestination>[
        NavigationDestination(icon: Icon(ApIcon.directionsBus), label: ap.bus),
        NavigationDestination(icon: Icon(ApIcon.classIcon), label: ap.course),
        NavigationDestination(icon: Icon(ApIcon.assignment), label: ap.score),
      ],
    );
  }

  Future<void> onTabTapped(int index) async {
    setState(() {
      switch (index) {
        case 0:
          ApUtils.pushCupertinoStyle(
            context,
            BusListPage(locale: Locale(Intl.defaultLocale!)),
          );
        case 1:
          if (isLogin) {
            ApUtils.pushCupertinoStyle(context, CoursePage());
          } else {
            UiUtil.instance.showToast(context, ap.notLoginHint);
          }
        case 2:
          if (isLogin) {
            ApUtils.pushCupertinoStyle(context, ScorePage());
          } else {
            UiUtil.instance.showToast(context, ap.notLoginHint);
          }
      }
    });
  }

  Future<void> _getAllAnnouncement() async {
    final result = await AnnouncementHelper.instance.getAnnouncements(
      tags: <String>['nsysu'],
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<Announcement>>(:final data):
        announcements = data;
        setState(() {
          state =
              announcements.isEmpty ? HomeState.empty : HomeState.finish;
        });
      case ApiError<List<Announcement>>():
      case ApiFailure<List<Announcement>>():
        setState(() => state = HomeState.error);
    }
  }

  Future<void> _checkLoginState() async {
    if (!mounted) return;
    if (isLogin) {
      _homeKey.currentState!.hideSnackBar();
    } else {
      _homeKey.currentState!
          .showSnackBar(
            text: ap.notLogin,
            actionText: ap.login,
            onSnackBarTapped: openLoginPage,
          )
          ?.closed
          .then((SnackBarClosedReason reason) {
            _checkLoginState();
          });
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
        _homeKey.currentState!.showBasicHint(text: ap.loginSuccess);
        setState(() {
          ShareDataWidget.of(context)!.data.isLogin = true;
        });
        ShareDataWidget.of(context)!.data.getUserInfo();
        _loadCourseData();
      case ApiError<GeneralResponse>(:final GeneralResponse response):
        if (response.statusCode == 400) {
          _homeKey.currentState!.showBasicHint(text: ap.loginFail);
        } else if (response.statusCode == 401) {
          UiUtil.instance.showToast(
            context,
            app.pleaseConfirmForm,
          );
          Utils.openConfirmForm(
            context,
            mounted: mounted,
            username: username,
          );
        } else {
          _homeKey.currentState!.showBasicHint(text: ap.unknownError);
        }
      case ApiFailure<GeneralResponse>(:final DioException exception):
        _homeKey.currentState!.showBasicHint(text: exception.i18nMessage!);
    }
  }

  Future<void> _checkUpdate() async {
    if (kIsWeb) return;
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = PreferenceUtil.instance.getString(
      Constants.prefCurrentVersion,
      '',
    );
    if (currentVersion != packageInfo.buildNumber) {
      final Map<String, dynamic>? rawData = await FileAssets.changelogData;
      //TODO: improve by object
      final Map<String, dynamic>? map =
          rawData?[packageInfo.buildNumber] as Map<String, dynamic>?;
      if (map == null) return;
      final String? updateNoteContent =
          map[ap.locale] as String?;
      if (!mounted) return;
      DialogUtils.showUpdateContent(
        context,
        'v${packageInfo.version}\n'
        '$updateNoteContent',
      );
      PreferenceUtil.instance.setString(
        Constants.prefCurrentVersion,
        packageInfo.buildNumber,
      );
    }
    if (!Constants.isInDebugMode) {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      final VersionInfo versionInfo = remoteConfig.versionInfo;
      //ignore: use_build_context_synchronously
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
      ShareDataWidget.of(context)!.data.isLogin = true;
      ShareDataWidget.of(context)!.data.getUserInfo();
      _homeKey.currentState!.hideSnackBar();
    } else {
      _checkLoginState();
    }
  }

  Widget _buildDrawer() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ApDrawer(
      userInfo: userInfo,
      displayPicture: PreferenceUtil.instance.getBool(
        Constants.prefDisplayPicture,
        true,
      ),
      imageAsset: drawerIcon,
      onTapHeader: () {
        if (isLogin) {
          if (userInfo != null) {
            ApUtils.pushCupertinoStyle(
              context,
              UserInfoPage(userInfo: userInfo!),
            );
          }
        } else {
          if (!isTablet) Navigator.of(context).pop();
          openLoginPage();
        }
      },
      widgets: <Widget>[
        if (isTablet)
          DrawerMenuItem(
            icon: ApIcon.home,
            title: ap.home,
            onTap: () => setState(() => content = null),
          ),
        _buildStudySection(),
        DrawerMenuItem(
          icon: ApIcon.directionsBus,
          title: ap.bus,
          onTap: () =>
              _openPage(BusListPage(locale: Locale(Intl.defaultLocale!))),
        ),
        _buildSchoolNavigationSection(),
        DrawerMenuItem(
          icon: ApIcon.school,
          title: app.graduationCheckChecklist,
          onTap: () =>
              _openPage(const GraduationReportPage(), needLogin: true),
        ),
        DrawerMenuItem(
          icon: ApIcon.monetizationOn,
          title: app.tuitionAndFees,
          onTap: () =>
              _openPage(const TuitionAndFeesPage(), needLogin: true),
        ),
        DrawerMenuItem(
          icon: ApIcon.info,
          title: ap.schoolInfo,
          onTap: () =>
              _openPage(SchoolInfoPage(), useCupertinoRoute: false),
        ),
        DrawerMenuItem(
          icon: ApIcon.face,
          title: ap.about,
          onTap: () => _openPage(
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
          ),
        ),
        DrawerMenuItem(
          icon: ApIcon.settings,
          title: ap.settings,
          onTap: () => _openPage(SettingPage()),
        ),
        if (isLogin) ...<Widget>[
          const DrawerDivider(),
          DrawerMenuItem(
            icon: ApIcon.powerSettingsNew,
            title: ap.logout,
            iconColor: colorScheme.error,
            onTap: () async {
              await PreferenceUtil.instance.setBool(
                Constants.prefAutoLogin,
                false,
              );
              SelcrsHelper.instance.logout();
              GraduationHelper.instance.logout();
              TuitionHelper.instance.logout();
              await ApCommonPlugin.clearCourseWidget();
              setState(() {
                ShareDataWidget.of(context)!.data.isLogin = false;
                ShareDataWidget.of(context)!.data.userInfo = null;
                courseData = null;
              });
              content = null;
              if (!isTablet) {
                if (!context.mounted) return;
                Navigator.of(context).pop();
              }
              _checkLoginState();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStudySection() {
    return DrawerMenuSection(
      icon: ApIcon.school,
      title: ap.courseInfo,
      initiallyExpanded: isStudyExpanded,
      onExpansionChanged: (bool value) {
        setState(() {
          isStudyExpanded = value;
        });
      },
      children: <DrawerSubMenuItem>[
        DrawerSubMenuItem(
          icon: ApIcon.classIcon,
          title: ap.course,
          onTap: () => _openPage(CoursePage(), needLogin: true),
        ),
        DrawerSubMenuItem(
          icon: ApIcon.assignment,
          title: ap.score,
          onTap: () => _openPage(ScorePage(), needLogin: true),
        ),
      ],
    );
  }

  Widget _buildSchoolNavigationSection() {
    return DrawerMenuSection(
      icon: ApIcon.navigation,
      title: ap.schoolNavigation,
      initiallyExpanded: isSchoolNavigationExpanded,
      onExpansionChanged: (bool value) {
        setState(() {
          isSchoolNavigationExpanded = value;
        });
      },
      children: <DrawerSubMenuItem>[
        DrawerSubMenuItem(
          icon: ApIcon.map,
          title: ap.schoolMap,
          onTap: () =>
              _openPage(SchoolMapPage(), useCupertinoRoute: false),
        ),
        DrawerSubMenuItem(
          icon: ApIcon.accessibilityNew,
          title: ap.admissionGuide,
          onTap: () {
            if (kIsWeb ||
                Platform.isAndroid ||
                Platform.isIOS ||
                Platform.isMacOS ||
                Platform.isWindows) {
              _openPage(AdmissionGuidePage(), useCupertinoRoute: false);
            } else {
              openDesktopWebViewPage(
                Constants.admissionGuideUrl,
                title: ap.admissionGuide,
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _openPage(
    Widget page, {
    bool needLogin = false,
    bool useCupertinoRoute = true,
  }) async {
    if (!isTablet) Navigator.of(context).pop();
    if (needLogin && !isLogin) {
      UiUtil.instance.showToast(
        context,
        ap.notLoginHint,
      );
    } else {
      if (isTablet) {
        setState(() => content = page);
      } else {
        if (useCupertinoRoute) {
          ApUtils.pushCupertinoStyle(context, page);
        } else {
          await Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(builder: (_) => page),
          );
        }
        _checkLoginState();
      }
    }
  }

  List<Widget> _buildDashboardWidgets() {
    return <Widget>[
      QuickInfoRow(
        items: <QuickInfoItem>[
          QuickInfoItem(
            icon: Icons.newspaper_outlined,
            label: '${announcements.length}',
            subtitle: ap.news,
            onTap: () {},
          ),
        ],
      ),
      if (courseData != null) ...<Widget>[
        const SizedBox(height: 16),
        TodayScheduleCard(
          courseData: courseData!,
          onTap: () {
            if (isLogin) {
              ApUtils.pushCupertinoStyle(context, CoursePage());
            }
          },
        ),
      ],
    ];
  }

  Future<void> _loadCourseData() async {
    final CourseData? cached = CourseData.load(
      PreferenceUtil.instance.getString(
        ApConstants.currentSemesterCode,
        ApConstants.semesterLatest,
      ),
    );
    if (cached != null && cached.courses.isNotEmpty) {
      setState(() => courseData = cached);
    }
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
