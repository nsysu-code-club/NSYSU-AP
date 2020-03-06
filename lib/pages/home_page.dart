import 'dart:convert';
import 'dart:io';

import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/widgets/drawer_body.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/news.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:nsysu_ap/pages/score_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:ap_common/widgets/yes_no_dialog.dart';

import 'admission_guide_page.dart';
import 'course_page.dart';
import 'graduation_report_page.dart';
import 'news_content_page.dart';

enum _State { loading, finish, error, empty, offline }

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  _State state = _State.loading;
  AppLocalizations app;

  int _currentTabIndex = 0;
  int _currentNewsIndex = 0;
  UserInfo userInfo = UserInfo();

  List<News> newsList = [];

  CarouselSlider cardSlider;

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _newImage(News news) {
    return Container(
      margin: EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(NewsContentPageRoute(news));
          String message = news.content.length > 12
              ? news.content
              : news.content.substring(0, 12);
          FA.logAction('news_image', 'click', message: message);
        },
        child: Hero(
          tag: news.hashCode,
          child: CachedNetworkImage(
            imageUrl: news.image,
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _homebody(Orientation orientation) {
    var rate =
        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    switch (state) {
      case _State.loading:
        return Center(
          child: CircularProgressIndicator(),
        );
      case _State.finish:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: Constants.TAG_NEWS_TITLE,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  newsList[_currentNewsIndex].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20.0,
                      color: ApTheme.of(context).grey,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Hero(
              tag: Constants.TAG_NEWS_ICON,
              child: Icon(Icons.arrow_drop_down),
            ),
            cardSlider = CarouselSlider(
              items: [
                for (var news in newsList) _newImage(news),
              ],
              viewportFraction:
                  orientation == Orientation.portrait ? 0.65 : 0.5,
              aspectRatio: orientation == Orientation.portrait
                  ? 7 / 6
                  : (rate > 1.5 ? 21 / 4 : 21 / 9),
              autoPlay: false,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              onPageChanged: (int current) {
                setState(() {
                  _currentNewsIndex = current;
                });
                FA.logAction('news_image', 'swipe');
              },
            ),
            SizedBox(height: orientation == Orientation.portrait ? 16.0 : 4.0),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: TextStyle(
                      color: ApTheme.of(context).grey, fontSize: 24.0),
                  children: [
                    TextSpan(
                        text:
                            "${newsList.length >= 10 && _currentNewsIndex < 9 ? "0" : ""}"
                            "${_currentNewsIndex + 1}",
                        style: TextStyle(color: ApTheme.of(context).red)),
                    TextSpan(text: ' / ${newsList.length}'),
                  ]),
            ),
          ],
        );
      case _State.offline:
        return HintContent(
          icon: Icons.offline_bolt,
          content: app.offlineMode,
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text(app.appName),
            backgroundColor: ApTheme.of(context).blue,
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.info),
                onPressed: _showInformationDialog,
              )
            ],
          ),
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
                  page: AdmissionGuidePage()),
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
              ListTile(
                leading: Icon(
                  Icons.power_settings_new,
                  color: ApTheme.of(context).grey,
                ),
                onTap: () {
                  Navigator.popUntil(
                      context, ModalRoute.withName(Navigator.defaultRouteName));
                },
                title: Text(
                  app.logout,
                  style: _defaultStyle,
                ),
              ),
            ],
            onTapHeader: () {},
          ),
          body: OrientationBuilder(builder: (_, orientation) {
            return Container(
              padding: EdgeInsets.symmetric(
                  vertical: orientation == Orientation.portrait ? 32.0 : 4.0),
              child: Center(
                child: _homebody(orientation),
              ),
            );
          }),
          bottomNavigationBar: BottomNavigationBar(
            fixedColor: ApTheme.of(context).bottomNavigationSelect,
            unselectedItemColor: ApTheme.of(context).bottomNavigationSelect,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12.0,
            unselectedFontSize: 12.0,
            selectedIconTheme: IconThemeData(size: 24.0),
            onTap: onTabTapped,
            items: [
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
          ),
        ),
        onWillPop: () async {
          if (Platform.isAndroid) _showLogoutDialog();
          return false;
        });
  }

  void onTabTapped(int index) async {
    setState(() {
      _currentTabIndex = index;
      switch (_currentTabIndex) {
        case 0:
          Utils.pushCupertinoStyle(
            context,
            AdmissionGuidePage(),
          );
          break;
        case 1:
          Utils.pushCupertinoStyle(
            context,
            CoursePage(),
          );
          break;
        case 2:
          Utils.pushCupertinoStyle(
            context,
            ScorePage(),
          );
          break;
      }
    });
  }

  _getAllNews() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    try {
      await remoteConfig.fetch(expiration: const Duration(seconds: 10));
      await remoteConfig.activateFetched();
    } on FetchThrottledException catch (exception) {
      setState(() {
        state = _State.error;
      });
    } catch (exception) {
      setState(() {
        state = _State.error;
      });
    }
    String newsString = remoteConfig.getString(Constants.NEWS_DATA);
    newsList = News.toList(jsonDecode(newsString));
    newsList.sort((a, b) {
      return b.weight.compareTo(a.weight);
    });
    setState(() {
      state = _State.finish;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => YesNoDialog(
        title: app.logout,
        contentWidget: Text(app.logoutCheck,
            textAlign: TextAlign.center,
            style: TextStyle(color: ApTheme.of(context).grey)),
        leftActionText: app.cancel,
        rightActionText: app.ok,
        rightActionFunction: () {
          Navigator.popUntil(
              context, ModalRoute.withName(Navigator.defaultRouteName));
        },
      ),
    );
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
              ]),
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
                (onError) => Utils.showToast(context, app.platformError));
          }
          FA.logAction('contact_fans_page', 'click');
        },
      ),
    );
  }
}
