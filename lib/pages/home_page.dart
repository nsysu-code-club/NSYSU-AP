import 'dart:io';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/news/news_content_page.dart';
import 'package:ap_common/pages/open_source_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:ap_common/widgets/default_dialog.dart';
import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:ap_common/models/new_response.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:nsysu_ap/pages/study/score_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/pages/user_info_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:ap_common/widgets/yes_no_dialog.dart';
import 'package:package_info/package_info.dart';

import 'admission_guide_page.dart';
import 'study/course_page.dart';
import 'graduation_report_page.dart';
import 'login/login_page.dart';

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();

  AppLocalizations app;
  ApLocalizations ap;

  HomeState state = HomeState.loading;

  bool isLogin = false;

  UserInfo userInfo = UserInfo();

  List<News> newsList = [];

  bool isStudyExpanded = false;

  TextStyle get _defaultStyle => TextStyle(
        color: ApTheme.of(context).grey,
        fontSize: 16.0,
      );

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("HomePage", "home_page.dart");
    _getAllNews();
    if (Preferences.getBool(Constants.PREF_AUTO_LOGIN, false))
      _login();
    else
      _checkLoginState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _checkUpdate();
    }
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
      actions: <Widget>[
        IconButton(
          icon: Icon(ApIcon.info),
          onPressed: _showInformationDialog,
        ),
      ],
      onImageTapped: (News news) {
        ApUtils.pushCupertinoStyle(
          context,
          NewsContentPage(news: news),
        );
        String message = news.description.length > 12
            ? news.description
            : news.description.substring(0, 12);
        FA.logAction('news_image', 'click', message: message);
      },
      drawer: ApDrawer(
        builder: () async {
          if (isLogin) {
            this.userInfo = await Helper.instance.getUserInfo(
              callback: GeneralCallback(
                onFailure: (DioError e) => ApUtils.handleDioError(context, e),
                onError: (GeneralResponse e) =>
                    ApUtils.showToast(context, ap.somethingError),
              ),
            );
            if (userInfo != null) {
              FA.setUserProperty('department', userInfo.department);
              FA.logUserInfo(userInfo.department);
              FA.setUserId(userInfo.id);
            }
          }
          return this.userInfo;
        },
        widgets: <Widget>[
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
            title: Text(app.courseInfo, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: ApIcon.classIcon,
                title: app.course,
                page: CoursePage(),
                needLogin: !isLogin,
              ),
              DrawerSubItem(
                icon: ApIcon.assignment,
                title: app.score,
                page: ScorePage(),
                needLogin: !isLogin,
              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.school,
            title: app.graduationCheckChecklist,
            page: GraduationReportPage(
              username: ShareDataWidget.of(context).data.username,
              password: ShareDataWidget.of(context).data.password,
            ),
            needLogin: !isLogin,
          ),
          DrawerItem(
            icon: ApIcon.monetizationOn,
            title: app.tuitionAndFees,
            page: TuitionAndFeesPage(
              username: ShareDataWidget.of(context).data.username,
              password: ShareDataWidget.of(context).data.password,
            ),
            needLogin: !isLogin,
          ),
          DrawerItem(
            icon: ApIcon.accessibilityNew,
            title: app.admissionGuide,
            page: AdmissionGuidePage(),
          ),
          DrawerItem(
            icon: ApIcon.face,
            title: app.about,
            page: AboutUsPage(
              assetImage: 'assets/images/nsysu.webp',
              githubName: 'NKUST-ITC',
              email: 'abc873693@gmail.com',
              appLicense: app.aboutOpenSourceContent,
              fbFanPageId: '735951703168873',
              fbFanPageUrl: 'https://www.facebook.com/NKUST.ITC/',
              githubUrl: 'https://github.com/NKUST-ITC',
              logEvent: (name, value) => FA.logAction(name, value),
              setCurrentScreen: () =>
                  FA.setCurrentScreen("AboutUsPage", "about_us_page.dart"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(ApIcon.codeIcon),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => OpenSourcePage(
                          setCurrentScreen: () => FA.setCurrentScreen(
                              "OpenSourcePage", "open_source_page.dart"),
                        ),
                      ),
                    );
                    FA.logAction('open_source', 'click');
                  },
                )
              ],
            ),
          ),
          DrawerItem(
            icon: ApIcon.settings,
            title: app.settings,
            page: SettingPage(),
          ),
          if (isLogin)
            ListTile(
              leading: Icon(
                ApIcon.powerSettingsNew,
                color: ApTheme.of(context).grey,
              ),
              onTap: () {
                Navigator.of(context).pop();
                isLogin = false;
                Preferences.setBool(Constants.PREF_AUTO_LOGIN, false);
                Helper.instance.clearSession();
                _checkLoginState();
              },
              title: Text(
                app.logout,
                style: _defaultStyle,
              ),
            ),
        ],
        onTapHeader: () {
          if (isLogin) {
            if (userInfo != null) {
              Navigator.of(context).pop();
              ApUtils.pushCupertinoStyle(
                context,
                UserInfoPage(
                  userInfo: userInfo,
                ),
              );
            }
          } else {
            Navigator.of(context).pop();
            _showLoginPage();
          }
        },
      ),
      newsList: newsList,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: [
        BottomNavigationBarItem(
          icon: Icon(ApIcon.accessibilityNew),
          title: Text(app.admissionGuide),
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.classIcon),
          title: Text(app.course),
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.assignment),
          title: Text(app.score),
        ),
      ],
    );
  }

  void onTabTapped(int index) async {
    setState(() {
      switch (index) {
        case 0:
          Utils.pushCupertinoStyle(context, AdmissionGuidePage());
          break;
        case 1:
          if (isLogin)
            Utils.pushCupertinoStyle(context, CoursePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
        case 2:
          if (isLogin)
            Utils.pushCupertinoStyle(context, ScorePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
      }
    });
  }

  _getAllNews() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      RemoteConfig remoteConfig = await RemoteConfig.instance;
      await remoteConfig.fetch(expiration: const Duration(seconds: 10));
      await remoteConfig.activateFetched();
      String rawString = remoteConfig.getString(Constants.NEWS_DATA);
      newsList = NewsResponse.fromRawJson(rawString).data;
    } else {
      newsList = await Helper.instance.getNews(
        callback: GeneralCallback(
          onError: (GeneralResponse e) {
            setState(() {
              state = HomeState.error;
            });
          },
          onFailure: (DioError e) {
            setState(() {
              state = HomeState.error;
            });
            ApUtils.handleDioError(context, e);
          },
        ),
      );
    }
    setState(() {
      if (newsList == null || newsList.length == 0)
        state = HomeState.empty;
      else {
        newsList.sort((a, b) {
          return b.weight.compareTo(a.weight);
        });
        state = HomeState.finish;
      }
    });
  }

  void _showInformationDialog() {
    FA.logAction('news_rule', 'click');
    showDialog(
      context: context,
      builder: (BuildContext context) => YesNoDialog(
        title: app.newsRuleTitle,
        contentWidget: RichText(
          text: TextSpan(
            style: TextStyle(color: ApTheme.of(context).grey, fontSize: 16.0),
            children: [
              TextSpan(
                  text: '${app.newsRuleDescription1}',
                  style: TextStyle(fontWeight: FontWeight.normal)),
              TextSpan(
                  text: '${app.newsRuleDescription2}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: '${app.newsRuleDescription3}',
                  style: TextStyle(fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        leftActionText: app.cancel,
        rightActionText: app.contactFansPage,
        leftActionFunction: () {},
        rightActionFunction: () {
          if (Platform.isAndroid)
            Utils.launchUrl('fb://messaging/${Constants.FANS_PAGE_ID}')
                .catchError(
                    (onError) => Utils.launchUrl(Constants.FANS_PAGE_URL));
          else if (Platform.isIOS)
            Utils.launchUrl(
                    'fb-messenger://user-thread/${Constants.FANS_PAGE_ID}')
                .catchError(
                    (onError) => Utils.launchUrl(Constants.FANS_PAGE_URL));
          else {
            Utils.launchUrl(Constants.FANS_PAGE_URL).catchError(
                (onError) => ApUtils.showToast(context, app.platformError));
          }
          FA.logAction('contact_fans_page', 'click');
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
            onSnackBarTapped: _showLoginPage,
          )
          .closed
          .then(
        (SnackBarClosedReason reason) {
          _checkLoginState();
        },
      );
    }
  }

  _login() async {
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    Helper.instance.selcrsLogin(
      username: username,
      password: password,
      callback: GeneralCallback(
        onError: (GeneralResponse e) {
          if (e.statusCode == 400)
            _homeKey.currentState.showBasicHint(text: ap.loginFail);
          else
            _changeHost();
        },
        onFailure: (DioError e) {
          _changeHost();
        },
        onSuccess: (GeneralResponse data) {
          _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
          setState(() {
            ShareDataWidget.of(context).data.username = username;
            ShareDataWidget.of(context).data.password = password;
            isLogin = true;
          });
        },
      ),
    );
  }

  void _changeHost() {
    Helper.changeSelcrsUrl();
    Helper.error++;
    if (Helper.error < 5) {
      _login();
    } else {
      _homeKey.currentState.showBasicHint(text: ap.timeoutMessage);
    }
  }

  _checkUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await Future.delayed(Duration(milliseconds: 50));
    var currentVersion =
        Preferences.getString(Constants.PREF_CURRENT_VERSION, '');
    if (currentVersion != packageInfo.buildNumber) {
      showDialog(
        context: context,
        builder: (BuildContext context) => DefaultDialog(
          title: app.updateNoteTitle,
          contentWidget: Text(
            "v${packageInfo.version}\n"
            "${app.updateNoteContent}",
            textAlign: TextAlign.center,
            style: TextStyle(color: ApTheme.of(context).grey),
          ),
          actionText: app.iKnow,
          actionFunction: () =>
              Navigator.of(context, rootNavigator: true).pop(),
        ),
      );
      Preferences.setString(
        Constants.PREF_CURRENT_VERSION,
        packageInfo.buildNumber,
      );
    }
    if (Constants.isInDebugMode) {
      final RemoteConfig remoteConfig = await RemoteConfig.instance;
      try {
        await remoteConfig.fetch(expiration: const Duration(seconds: 10));
        await remoteConfig.activateFetched();
      } on FetchThrottledException catch (exception) {} catch (exception) {} finally {
        String versionContent = '';
        switch (AppLocalizations.locale.languageCode) {
          case ApSupportLanguageConstants.ZH:
            versionContent =
                remoteConfig.getString(Constants.NEW_VERSION_CONTENT_ZH);
            break;
          case ApSupportLanguageConstants.EN:
          default:
            versionContent =
                remoteConfig.getString(Constants.NEW_VERSION_CONTENT_EN);
            break;
        }
        ApUtils.showNewVersionDialog(
          context: context,
          newVersionCode: remoteConfig.getInt(Constants.APP_VERSION),
          iOSAppId: '146752219',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          newVersionContent: versionContent,
          appName: AppLocalizations.of(context).appName,
        );
      }
    }
  }

  _showLoginPage() async {
    var result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => LoginPage(),
      ),
    );
    if (result ?? false) {
      if (state != HomeState.finish) {
        _getAllNews();
      }
      isLogin = true;
      _homeKey.currentState.hideSnackBar();
    } else {
      _checkLoginState();
    }
  }
}
