import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPageRoute extends MaterialPageRoute {
  SettingPageRoute()
      : super(builder: (BuildContext context) => new SettingPage());

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return new FadeTransition(opacity: animation, child: new SettingPage());
  }
}

class SettingPage extends StatefulWidget {
  static const String routerName = "/setting";

  @override
  SettingPageState createState() => new SettingPageState();
}

class SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  SharedPreferences prefs;

  var busNotify = false, courseNotify = false, displayPicture = true;

  AppLocalizations app;

  String appVersion = "1.0.0";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("SettingPage", "setting_page.dart");
    _getPreference();
    //Utils.showAppReviewDialog(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(app.settings),
        backgroundColor: Resource.Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _titleItem(app.notificationItem),
              _itemSwitch(app.courseNotify, courseNotify, () async {
                Utils.showToast(context, app.functionNotOpen);
//            FA.logAction('notify_course', 'create');
//            setState(() {
//              courseNotify = !courseNotify;
//            });
//            if (courseNotify)
//              _setupCourseNotify(context);
//            else {
//              await Utils.cancelCourseNotify();
//            }
//            FA.logAction('notify_course', 'create', message: '$courseNotify');
//            prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
              }),
              Container(
                color: Colors.grey,
                height: 0.5,
              ),
              _titleItem(app.otherSettings),
              _itemSingle(app.language, () {
                Utils.showChoseLanguageDialog(context, () {
                  setState(() {});
                });
              }),
              Divider(
                color: Colors.grey,
                height: 0.5,
              ),
              _titleItem(app.otherInfo),
              _item(app.feedback, app.feedbackViaFacebook, () {
                if (Platform.isAndroid)
                  Utils.launchUrl('fb://messaging/${Constants.FANS_PAGE_ID}')
                      .catchError((onError) =>
                          Utils.launchUrl(Constants.FANS_PAGE_URL));
                else if (Platform.isIOS)
                  Utils.launchUrl(
                          'fb-messenger://user-thread/${Constants.FANS_PAGE_ID}')
                      .catchError((onError) =>
                          Utils.launchUrl(Constants.FANS_PAGE_URL));
                else {
                  Utils.launchUrl(Constants.FANS_PAGE_URL).catchError(
                      (onError) => Utils.showToast(context, app.platformError));
                }
                FA.logAction('feedback', 'click');
              }),
              _item(app.donateTitle, app.donateContent, () {
                Utils.launchUrl("https://p.ecpay.com.tw/3D54D").catchError(
                    (onError) => Utils.showToast(context, app.platformError));
                FA.logAction('donate', 'click');
              }),
              _item(app.appVersion, "v$appVersion", () {
                //FA.logAction('donate', 'click');
              }),
            ]),
      ),
    );
  }

  _titleItem(String text) => Container(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Text(
          text,
          style: TextStyle(color: Resource.Colors.blue, fontSize: 14.0),
          textAlign: TextAlign.start,
        ),
      );

  _itemSwitch(String text, bool value, Function function) => FlatButton(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              text,
              style: TextStyle(fontSize: 16.0),
            ),
            Switch(
              value: value,
              activeColor: Resource.Colors.blue,
              activeTrackColor: Resource.Colors.blue,
              onChanged: (b) {
                function();
              },
            ),
          ],
        ),
        onPressed: function,
      );

  _getPreference() async {
    prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      isOffline = prefs.getBool(Constants.PREF_IS_OFFLINE_LOGIN) ?? false;
      appVersion = packageInfo.version;
      courseNotify = prefs.getBool(Constants.PREF_COURSE_NOTIFY) ?? false;
      displayPicture = prefs.getBool(Constants.PREF_DISPLAY_PICTURE) ?? true;
      busNotify = prefs.getBool(Constants.PREF_BUS_NOTIFY) ?? false;
    });
  }

  _item(String text, String subText, Function function) => FlatButton(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                text,
                style: TextStyle(fontSize: 16.0),
              ),
              Text(
                subText,
                style: TextStyle(fontSize: 14.0, color: Resource.Colors.grey),
              ),
            ],
          ),
        ),
        onPressed: function,
      );

  _itemSingle(String text, Function function) => FlatButton(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                text,
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
        onPressed: function,
      );

//  void _setupCourseNotify(BuildContext context) async {
//    showDialog(
//        context: context,
//        builder: (BuildContext context) => ProgressDialog(app.loading),
//        barrierDismissible: false);
//    if (isOffline) {
//      if (Navigator.canPop(context)) Navigator.pop(context, 'dialog');
//      SemesterData semesterData = await CacheUtils.loadSemesterData();
//      if (semesterData != null) {
//        CourseData courseData =
//            await CacheUtils.loadCourseData(semesterData.defaultSemester.value);
//        if (courseData != null)
//          _setCourseData(courseData);
//        else {
//          setState(() {
//            courseNotify = false;
//            prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
//          });
//          Utils.showToast(context, app.noOfflineData);
//        }
//      } else {
//        setState(() {
//          courseNotify = false;
//          prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
//        });
//        Utils.showToast(context, app.noOfflineData);
//      }
//      return;
//    }
//    Helper.instance.getSemester().then((SemesterData semesterData) {
//      var textList = semesterData.defaultSemester.value.split(",");
//      if (textList.length == 2) {
//        Helper.instance
//            .getCourseTables(textList[0], textList[1])
//            .then((CourseData courseData) {
//          if (Navigator.canPop(context)) Navigator.pop(context, 'dialog');
//          _setCourseData(courseData);
//        }).catchError((e) {
//          setState(() {
//            courseNotify = false;
//            prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
//          });
//          if (e is DioError) {
//            switch (e.type) {
//              case DioErrorType.RESPONSE:
//                Utils.handleResponseError(
//                    context, 'getCourseTables', mounted, e);
//                break;
//              case DioErrorType.CANCEL:
//                break;
//              default:
//                Utils.handleDioError(context, e);
//                break;
//            }
//          } else {
//            throw e;
//          }
//        });
//      }
//    }).catchError((e) {
//      setState(() {
//        courseNotify = false;
//      });
//      prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
//      if (e is DioError) {
//        switch (e.type) {
//          case DioErrorType.RESPONSE:
//            Utils.handleResponseError(context, 'getSemester', mounted, e);
//            break;
//          case DioErrorType.CANCEL:
//            break;
//          default:
//            Utils.handleDioError(context, e);
//            break;
//        }
//      } else {
//        throw e;
//      }
//    });
//  }
//
//  _setCourseData(CourseData courseData) async {
//    switch (courseData.status) {
//      case 200:
//        await Utils.setCourseNotify(context, courseData.courseTables);
//        Utils.showToast(context, app.courseNotifyHint);
//        break;
//      case 204:
//        Utils.showToast(context, app.courseNotifyEmpty);
//        break;
//      default:
//        Utils.showToast(context, app.courseNotifyError);
//        break;
//    }
//    if (courseData.status != 200) {
//      setState(() {
//        courseNotify = false;
//        prefs.setBool(Constants.PREF_COURSE_NOTIFY, courseNotify);
//      });
//    }
//  }
}
