import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
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

  bool get isMobile => MediaQuery.of(context).size.shortestSide < 680;

  late AppLocalizations app;
  late ApLocalizations ap;

  HomeState state = HomeState.loading;

  bool get isLogin => ShareDataWidget.of(context)?.data.isLogin ?? false;

  UserInfo? get userInfo => ShareDataWidget.of(context)?.data.userInfo;

  Widget? content;

  List<Announcement> announcements = <Announcement>[];

  bool isStudyExpanded = false;
  bool isSchoolNavigationExpanded = false;

  TextStyle get _defaultStyle =>
      TextStyle(color: ApTheme.of(context).grey, fontSize: 16.0);

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
    AnalyticsUtil.instance.setUserProperty(
      AnalyticsConstants.language,
      Locale(Intl.defaultLocale!).languageCode,
    );
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
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
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
      drawer: ApDrawer(
        userInfo: userInfo,
        widgets: <Widget>[
          if (!isMobile)
            DrawerItem(
              icon: ApIcon.home,
              title: ap.home,
              onTap: () {
                setState(() => content = null);
              },
            ),
          ExpansionTile(
            initiallyExpanded: isStudyExpanded,
            onExpansionChanged: (bool bool) {
              setState(() => isStudyExpanded = bool);
            },
            leading: Icon(
              ApIcon.collectionsBookmark,
              color: isStudyExpanded
                  ? ApTheme.of(context).blueAccent
                  : ApTheme.of(context).grey,
            ),
            title: Text(ap.courseInfo, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: ApIcon.classIcon,
                title: ap.course,
                onTap: () => _openPage(CoursePage(), needLogin: true),
              ),
              DrawerSubItem(
                icon: ApIcon.assignment,
                title: ap.score,
                onTap: () => _openPage(ScorePage(), needLogin: true),
              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.directionsBus,
            title: ap.bus,
            onTap: () =>
                _openPage(BusListPage(locale: Locale(Intl.defaultLocale!))),
          ),
          ExpansionTile(
            initiallyExpanded: isSchoolNavigationExpanded,
            onExpansionChanged: (bool bool) {
              setState(() => isSchoolNavigationExpanded = bool);
            },
            leading: Icon(
              ApIcon.navigation,
              color: isSchoolNavigationExpanded
                  ? ApTheme.of(context).blueAccent
                  : ApTheme.of(context).grey,
            ),
            title: Text(ap.schoolNavigation, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: ApIcon.map,
                title: ap.schoolMap,
                onTap: () =>
                    _openPage(SchoolMapPage(), useCupertinoRoute: false),
              ),
              DrawerSubItem(
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
          ),
          DrawerItem(
            icon: ApIcon.school,
            title: app.graduationCheckChecklist,
            onTap: () =>
                _openPage(const GraduationReportPage(), needLogin: true),
          ),
          DrawerItem(
            icon: ApIcon.monetizationOn,
            title: app.tuitionAndFees,
            onTap: () => _openPage(const TuitionAndFeesPage(), needLogin: true),
          ),
          // DrawerItem(
          //   icon: Icons.car_repair,
          //   title: app.towCarHelper,
          //   onTap: () => _openPage(
          //     TowCarHomePage(),
          //     useCupertinoRoute: false,
          //   ),
          // ),
          DrawerItem(
            icon: ApIcon.info,
            title: ap.schoolInfo,
            onTap: () => _openPage(SchoolInfoPage(), useCupertinoRoute: false),
          ),
          DrawerItem(
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
          DrawerItem(
            icon: ApIcon.settings,
            title: ap.settings,
            onTap: () => _openPage(SettingPage()),
          ),
          if (isLogin)
            ListTile(
              leading: Icon(
                ApIcon.powerSettingsNew,
                color: ApTheme.of(context).grey,
              ),
              onTap: () async {
                PreferenceUtil.instance.setBool(Constants.prefAutoLogin, false);
                await PreferenceUtil.instance.setBool(
                  Constants.prefAutoLogin,
                  false,
                );
                SelcrsHelper.instance.logout();
                GraduationHelper.instance.logout();
                TuitionHelper.instance.logout();
                setState(() {
                  ShareDataWidget.of(context)!.data.isLogin = false;
                  ShareDataWidget.of(context)!.data.userInfo = null;
                });
                if (isMobile) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                }
                _checkLoginState();
              },
              title: Text(ap.logout, style: _defaultStyle),
            ),
        ],
        onTapHeader: () {
          if (isLogin) {
            if (userInfo != null && isLogin) {
              ApUtils.pushCupertinoStyle(
                context,
                UserInfoPage(userInfo: userInfo!),
              );
            }
          } else {
            if (isMobile) Navigator.of(context).pop();
            openLoginPage();
          }
        },
      ),
      announcements: announcements,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: <Widget>[
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
    AnnouncementHelper.instance.getAnnouncements(
      tags: <String>['nsysu'],
      callback: GeneralCallback<List<Announcement>>(
        onFailure: (_) => setState(() => state = HomeState.error),
        onError: (_) => setState(() => state = HomeState.error),
        onSuccess: (List<Announcement>? data) {
          announcements = data ?? <Announcement>[];
          if (mounted) {
            setState(() {
              if (announcements.isEmpty) {
                state = HomeState.empty;
              } else {
                state = HomeState.finish;
              }
            });
          }
        },
      ),
    );
  }

  Future<void> _checkLoginState() async {
    if (isLogin) {
      _homeKey.currentState!.hideSnackBar();
    } else {
      _homeKey.currentState!
          .showSnackBar(
            text: ApLocalizations.of(context).notLogin,
            actionText: ApLocalizations.of(context).login,
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
    SelcrsHelper.instance.login(
      username: username,
      password: password,
      callback: GeneralCallback<GeneralResponse>(
        onError: (GeneralResponse e) {
          if (e.statusCode == 400) {
            _homeKey.currentState!.showBasicHint(text: ap.loginFail);
          } else if (e.statusCode == 401) {
            UiUtil.instance.showToast(
              context,
              AppLocalizations.of(context).pleaseConfirmForm,
            );
            Utils.openConfirmForm(
              context,
              mounted: mounted,
              username: username,
            );
          } else {
            _homeKey.currentState!.showBasicHint(text: ap.unknownError);
          }
        },
        onFailure: (DioException e) {
          _homeKey.currentState!.showBasicHint(text: e.i18nMessage!);
        },
        onSuccess: (GeneralResponse data) {
          _homeKey.currentState!.showBasicHint(text: ap.loginSuccess);
          setState(() {
            ShareDataWidget.of(context)!.data.isLogin = true;
          });
          ShareDataWidget.of(context)!.data.getUserInfo();
        },
      ),
    );
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
      final Map<String, dynamic> map =
          rawData![packageInfo.buildNumber] as Map<String, dynamic>;
      final String updateNoteContent =
          map[ApLocalizations.current.locale] as String;
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

  Future<void> _openPage(
    Widget page, {
    bool needLogin = false,
    bool useCupertinoRoute = true,
  }) async {
    if (isMobile) Navigator.of(context).pop();
    if (needLogin && !isLogin) {
      UiUtil.instance.showToast(
        context,
        ApLocalizations.of(context).notLoginHint,
      );
    } else {
      if (isMobile) {
        if (useCupertinoRoute) {
          ApUtils.pushCupertinoStyle(context, page);
        } else {
          await Navigator.push(
            context,
            CupertinoPageRoute<dynamic>(builder: (_) => page),
          );
        }
        _checkLoginState();
      } else {
        setState(() => content = page);
      }
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
