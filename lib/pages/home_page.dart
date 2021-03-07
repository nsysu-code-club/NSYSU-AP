import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/api/imgur_helper.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/config/analytics_constants.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/announcement/home_page.dart';
import 'package:ap_common/pages/announcement_content_page.dart';
import 'package:ap_common/pages/open_source_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/dialog_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/graduation_helper.dart';
import 'package:nsysu_ap/api/tuition_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:ap_common/models/announcement_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:nsysu_ap/pages/bus/bus_list_page.dart';
import 'package:nsysu_ap/pages/guide/school_map_page.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/pages/user_info_page.dart';
import 'package:nsysu_ap/resources/image_assets.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/utils/utils.dart';

import 'guide/admission_guide_page.dart';
import 'info/shcool_info_page.dart';
import 'study/course_page.dart';
import 'graduation_report_page.dart';
import 'login/login_page.dart';
import 'tow/tow_car_home_page.dart';

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();

  bool get isMobile => MediaQuery.of(context).size.shortestSide < 680;

  AppLocalizations app;
  ApLocalizations ap;

  HomeState state = HomeState.loading;

  bool isLogin = false;

  UserInfo userInfo;

  Widget content;

  List<Announcement> announcements;

  bool isStudyExpanded = false;
  bool isSchoolNavigationExpanded = false;

  TextStyle get _defaultStyle => TextStyle(
        color: ApTheme.of(context).grey,
        fontSize: 16.0,
      );

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("HomePage", "home_page.dart");
    _getAllAnnouncement();
    if (Preferences.getBool(Constants.PREF_AUTO_LOGIN, false))
      _login();
    else
      _checkLoginState();
    if (FirebaseUtils.isSupportRemoteConfig) {
      _checkUpdate();
    }
    FirebaseAnalyticsUtils.instance.setUserProperty(
      AnalyticsConstants.LANGUAGE,
      AppLocalizations.locale.languageCode,
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
          icon: Icon(Icons.fiber_new_rounded),
          tooltip: ap.announcementReviewSystem,
          onPressed: () async {
            AnnouncementHelper.instance.organization = 'nsysu';
            AnnouncementHelper.instance.appleBundleId = 'com.nsysu.ap';
            ApUtils.pushCupertinoStyle(
              context,
              AnnouncementHomePage(
                organizationDomain: '@g-mail.nsysu.edu.tw',
              ),
            );
            if (FirebaseUtils.isSupportCloudMessage) {
              try {
                final messaging = FirebaseMessaging.instance;
                NotificationSettings settings =
                    await messaging.getNotificationSettings();
                if (settings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional) {
                  String token = await messaging.getToken();
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
            onExpansionChanged: (bool) {
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
                onTap: () => _openPage(
                  CoursePage(),
                  needLogin: true,
                ),
              ),
              DrawerSubItem(
                icon: ApIcon.assignment,
                title: ap.score,
                onTap: () => _openPage(
                  ScorePage(),
                  needLogin: true,
                ),
              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.directionsBus,
            title: ap.bus,
            onTap: () => _openPage(
              BusListPage(
                locale: AppLocalizations.locale,
              ),
            ),
          ),
          ExpansionTile(
            initiallyExpanded: isSchoolNavigationExpanded,
            onExpansionChanged: (bool) {
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
                  onTap: () => _openPage(
                        SchoolMapPage(),
                      )),
              DrawerSubItem(
                icon: ApIcon.accessibilityNew,
                title: ap.admissionGuide,
                onTap: () => _openPage(
                  AdmissionGuidePage(),
                ),
              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.school,
            title: app.graduationCheckChecklist,
            onTap: () => _openPage(
              GraduationReportPage(),
              needLogin: true,
            ),
          ),
          DrawerItem(
            icon: ApIcon.monetizationOn,
            title: app.tuitionAndFees,
            onTap: () => _openPage(
              TuitionAndFeesPage(),
              needLogin: true,
            ),
          ),
          DrawerItem(
            icon: Icons.car_repair,
            title: app.towCarHelper,
            onTap: () => _openPage(
              TowCarHomePage(),
              needLogin: true,
              useCupertinoRoute: false,
            ),
          ),
          DrawerItem(
            icon: ApIcon.info,
            title: ap.schoolInfo,
            onTap: () => _openPage(SchoolInfoPage()),
          ),
          DrawerItem(
            icon: ApIcon.face,
            title: ap.about,
            onTap: () => _openPage(AboutUsPage(
              assetImage: ImageAssets.nsysu,
              githubName: 'NKUST-ITC',
              email: 'abc873693@gmail.com',
              appLicense: app.aboutOpenSourceContent,
              fbFanPageId: '735951703168873',
              fbFanPageUrl: 'https://www.facebook.com/NKUST.ITC/',
              githubUrl: 'https://github.com/NKUST-ITC',
              actions: <Widget>[
                IconButton(
                  icon: Icon(ApIcon.codeIcon),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OpenSourcePage(),
                      ),
                    );
                    FirebaseAnalyticsUtils.instance
                        .logAction('open_source', 'click');
                  },
                )
              ],
            )),
          ),
          DrawerItem(
            icon: ApIcon.settings,
            title: ap.settings,
            onTap: () => _openPage(
              SettingPage(),
            ),
          ),
          if (isLogin)
            ListTile(
              leading: Icon(
                ApIcon.powerSettingsNew,
                color: ApTheme.of(context).grey,
              ),
              onTap: () async {
                Preferences.setBool(Constants.PREF_AUTO_LOGIN, false);
                await Preferences.setBool(Constants.PREF_AUTO_LOGIN, false);
                SelcrsHelper.instance.logout();
                GraduationHelper.instance.logout();
                TuitionHelper.instance.logout();
                setState(() {
                  isLogin = false;
                  userInfo = null;
                });
                if (isMobile) Navigator.of(context).pop();
                _checkLoginState();
              },
              title: Text(
                ap.logout,
                style: _defaultStyle,
              ),
            ),
        ],
        onTapHeader: () {
          if (isLogin) {
            if (userInfo != null && isLogin)
              ApUtils.pushCupertinoStyle(
                context,
                UserInfoPage(userInfo: userInfo),
              );
          } else {
            if (isMobile) Navigator.of(context).pop();
            openLoginPage();
          }
        },
      ),
      announcements: announcements,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: [
        BottomNavigationBarItem(
          icon: Icon(ApIcon.directionsBus),
          label: ap.bus,
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.classIcon),
          label: ap.course,
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.assignment),
          label: ap.score,
        ),
      ],
    );
  }

  void onTabTapped(int index) async {
    setState(() {
      switch (index) {
        case 0:
          ApUtils.pushCupertinoStyle(
              context,
              BusListPage(
                locale: AppLocalizations.locale,
              ));
          break;
        case 1:
          if (isLogin)
            ApUtils.pushCupertinoStyle(context, CoursePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
        case 2:
          if (isLogin)
            ApUtils.pushCupertinoStyle(context, ScorePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
      }
    });
  }

  _getAllAnnouncement() async {
    AnnouncementHelper.instance.getAnnouncements(
      tags: ['nsysu'],
      callback: GeneralCallback(
        onFailure: (_) => setState(() => state = HomeState.error),
        onError: (_) => setState(() => state = HomeState.error),
        onSuccess: (List<Announcement> data) {
          announcements = data;
          if (mounted)
            setState(() {
              if (announcements == null || announcements.length == 0)
                state = HomeState.empty;
              else
                state = HomeState.finish;
            });
        },
      ),
    );
  }

  _getUserInfo() {
    SelcrsHelper.instance.getUserInfo(
      callback: GeneralCallback<UserInfo>(
        onFailure: (DioError e) => ApUtils.handleDioError(context, e),
        onError: (GeneralResponse e) =>
            ApUtils.showToast(context, ap.somethingError),
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

  void _checkLoginState() async {
    await Future.delayed(Duration(microseconds: 50));
    if (isLogin) {
      _homeKey.currentState.hideSnackBar();
    } else {
      _homeKey.currentState
          .showSnackBar(
            text: ApLocalizations.of(context).notLogin,
            actionText: ApLocalizations.of(context).login,
            onSnackBarTapped: openLoginPage,
          )
          ?.closed
          ?.then(
        (SnackBarClosedReason reason) {
          _checkLoginState();
        },
      );
    }
  }

  _login() async {
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    SelcrsHelper.instance.login(
      username: username,
      password: password,
      callback: GeneralCallback(
        onError: (GeneralResponse e) {
          if (e.statusCode == 400)
            _homeKey.currentState.showBasicHint(text: ap.loginFail);
          else if (e.statusCode == 401) {
            ApUtils.showToast(
                context, AppLocalizations.of(context).pleaseConfirmForm);
            Utils.openConfirmForm(context, username);
          } else
            _homeKey.currentState.showBasicHint(text: ap.unknownError);
        },
        onFailure: (DioError e) {
          _homeKey.currentState.showBasicHint(
            text: e.i18nMessage,
          );
        },
        onSuccess: (GeneralResponse data) {
          _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
          setState(() {
            isLogin = true;
          });
          _getUserInfo();
        },
      ),
    );
  }

  _checkUpdate() async {
    if (kIsWeb) return;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await Future.delayed(Duration(milliseconds: 50));
    var currentVersion =
        Preferences.getString(Constants.PREF_CURRENT_VERSION, '');
    if (currentVersion != packageInfo.buildNumber) {
      DialogUtils.showUpdateContent(
        context,
        "v${packageInfo.version}\n"
        "${app.updateNoteContent}",
      );
      Preferences.setString(
        Constants.PREF_CURRENT_VERSION,
        packageInfo.buildNumber,
      );
    }
    if (!Constants.isInDebugMode) {
      VersionInfo versionInfo =
          await FirebaseRemoteConfigUtils.getVersionInfo();
      if (versionInfo != null)
        DialogUtils.showNewVersionContent(
          context: context,
          iOSAppId: '146752219',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          appName: app.appName,
          versionInfo: versionInfo,
        );
    }
  }

  openLoginPage() async {
    var result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(),
      ),
    );
    if (result ?? false) {
      if (state != HomeState.finish) {
        _getAllAnnouncement();
      }
      isLogin = true;
      _getUserInfo();
      _homeKey.currentState.hideSnackBar();
    } else {
      _checkLoginState();
    }
  }

  _openPage(Widget page, {needLogin = false, bool useCupertinoRoute = true}) {
    if (isMobile) Navigator.of(context).pop();
    if (needLogin && !isLogin)
      ApUtils.showToast(
        context,
        ApLocalizations.of(context).notLoginHint,
      );
    else {
      if (isMobile) {
        if (useCupertinoRoute)
          ApUtils.pushCupertinoStyle(context, page);
        else
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => page),
          );
      } else
        setState(() => content = page);
    }
  }
}
