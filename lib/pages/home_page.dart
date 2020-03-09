import 'dart:io';

import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/news/news_content_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:ap_common/models/new_response.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:nsysu_ap/pages/score_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:ap_common/widgets/yes_no_dialog.dart';

import 'admission_guide_page.dart';
import 'course_page.dart';
import 'graduation_report_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();
  AppLocalizations app;

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
    _checkLoginState();
    //TODO add check auto login
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return HomePageScaffold(
      key: _homeKey,
      isLogin: isLogin,
      state: state,
      title: app.appName,
      actions: <Widget>[
        IconButton(
          icon: Icon(ApIcon.info),
          onPressed: _showInformationDialog,
        )
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
          var userInfo = await Helper.instance.getUserInfo();
          FA.setUserProperty('department', userInfo.department);
          FA.logUserInfo(userInfo.department);
          FA.setUserId(userInfo.studentId);
          return UserInfo(
            id: userInfo.studentId,
            name: userInfo.studentNameCht,
          );
        },
        widgets: <Widget>[
          ExpansionTile(
            initiallyExpanded: isStudyExpanded,
            onExpansionChanged: (bool) {
              setState(() => isStudyExpanded = bool);
            },
            leading: Icon(
              Icons.collections_bookmark,
              color: isStudyExpanded
                  ? ApTheme.of(context).blueAccent
                  : ApTheme.of(context).grey,
            ),
            title: Text(app.courseInfo, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: Icons.class_,
                title: app.course,
                page: CoursePage(),
              ),
              DrawerSubItem(
                icon: Icons.assignment,
                title: app.score,
                page: ScorePage(),
              ),
            ],
          ),
          DrawerItem(
            icon: Icons.school,
            title: app.graduationCheckChecklist,
            page: GraduationReportPage(
              username: ShareDataWidget.of(context).data.username,
              password: ShareDataWidget.of(context).data.password,
            ),
          ),
          DrawerItem(
            icon: Icons.monetization_on,
            title: app.tuitionAndFees,
            page: TuitionAndFeesPage(
              username: ShareDataWidget.of(context).data.username,
              password: ShareDataWidget.of(context).data.password,
            ),
          ),
          DrawerItem(
            icon: Icons.accessibility_new,
            title: app.admissionGuide,
            page: AdmissionGuidePage(),
          ),
          DrawerItem(
            icon: Icons.face,
            title: app.about,
            page: AboutUsPage(
              assetImage: 'assets/images/nsysu.webp',
              githubName: 'NKUST-ITC',
              email: 'abc873693@gmail.com',
              appLicense: app.aboutOpenSourceContent,
              fbFanPageId: '735951703168873',
              fbFanPageUrl: 'https://www.facebook.com/NKUST.ITC/',
              githubUrl: 'https://github.com/NKUST-ITC',
            ),
          ),
          DrawerItem(
            icon: Icons.settings,
            title: app.settings,
            page: SettingPage(),
          ),
          if (isLogin)
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: ApTheme.of(context).grey,
              ),
              onTap: () {
                Navigator.of(context).pop();
                isLogin = false;
                _checkLoginState();
                //TODO clear session
              },
              title: Text(
                app.logout,
                style: _defaultStyle,
              ),
            ),
        ],
        onTapHeader: () {},
      ),
      newsList: newsList,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: [
        BottomNavigationBarItem(
          icon: Icon(Icons.accessibility_new),
          title: Text(app.admissionGuide),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.class_),
          title: Text(app.course),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
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
          Utils.pushCupertinoStyle(context, CoursePage());
          break;
        case 2:
          Utils.pushCupertinoStyle(context, ScorePage());
          break;
      }
    });
  }

  _getAllNews() async {
    try {
      RemoteConfig remoteConfig = await RemoteConfig.instance;
      await remoteConfig.fetch(expiration: const Duration(seconds: 10));
      await remoteConfig.activateFetched();
      String rawString = remoteConfig.getString(Constants.NEWS_DATA);
      newsList = NewsResponse.fromRawJson(rawString).data;
    } catch (exception) {
      newsList = await Helper.instance.getNews();
    }
    newsList.sort((a, b) {
      return b.weight.compareTo(a.weight);
    });
    setState(() {
      state = HomeState.finish;
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
    await Future.delayed(Duration(microseconds: 30));
    if (isLogin) {
      _homeKey.currentState.hideSnackBar();
    } else {
      _homeKey.currentState
          .showSnackBar(
            text: ApLocalizations.of(context).notLogin,
            actionText: ApLocalizations.of(context).login,
            onSnackBarTapped: () async {
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
            },
          )
          .closed
          .then(
        (SnackBarClosedReason reason) {
          _checkLoginState();
        },
      );
    }
  }
}
