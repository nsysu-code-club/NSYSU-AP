import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/user_info.dart';
import 'package:nsysu_ap/pages/about/about_us_page.dart';
import 'package:nsysu_ap/pages/admission_guide_page.dart';
import 'package:nsysu_ap/pages/course_page.dart';
import 'package:nsysu_ap/pages/graduation_report_page.dart';
import 'package:nsysu_ap/pages/score_page.dart';
import 'package:nsysu_ap/pages/setting_page.dart';
import 'package:nsysu_ap/pages/tuition_and_fees_page.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

var pictureUrl = "";

class DrawerBody extends StatefulWidget {
  final UserInfo userInfo;

  const DrawerBody({Key key, this.userInfo}) : super(key: key);

  @override
  DrawerBodyState createState() => DrawerBodyState();
}

class DrawerBodyState extends State<DrawerBody> {
  SharedPreferences prefs;
  bool displayPicture = true;

  AppLocalizations app;

  bool isStudyExpanded = false;
  bool isBusExpanded = false;
  bool isLeaveExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _defaultStyle() => TextStyle(color: Resource.Colors.grey, fontSize: 16.0);

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () {
//                if (widget.userInfo == null) return;
//                if ((widget.userInfo.status == null
//                    ? 200
//                    : widget.userInfo.status) ==
//                    200)
//                //Navigator.of(context)
//                //     .push(UserInfoPageRoute(widget.userInfo));
//                else
//                  Utils.showToast(context, widget.userInfo.message);
              },
              child: Stack(
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    margin: EdgeInsets.all(0),
                    currentAccountPicture: Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 72.0,
                      ),
                    ),
                    accountName: Text(
                      widget.userInfo == null
                          ? ""
                          : "${widget.userInfo.studentNameCht}",
                      style: TextStyle(color: Colors.white),
                    ),
                    accountEmail: Text(
                      widget.userInfo == null
                          ? ""
                          : "${widget.userInfo.studentId}",
                      style: TextStyle(color: Colors.white),
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xff0071FF),
                      image: DecorationImage(
                          image:
                              AssetImage("assets/images/drawer-backbroud.webp"),
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.bottomCenter),
                    ),
                  ),
//                  Positioned(
//                    bottom: 20.0,
//                    right: 20.0,
//                    child: Container(
//                      child: Image.asset(
//                        "assets/images/drawer-icon.webp",
//                        width: 90.0,
//                      ),
//                    ),
//                  ),
                ],
              ),
            ),
            ExpansionTile(
              onExpansionChanged: (bool) {
                setState(() {
                  isStudyExpanded = bool;
                });
              },
              leading: Icon(
                Icons.collections_bookmark,
                color: isStudyExpanded
                    ? Resource.Colors.blue
                    : Resource.Colors.grey,
              ),
              title: Text(app.courseInfo, style: _defaultStyle()),
              children: <Widget>[
                _subItem(Icons.class_, app.course, CoursePage()),
                _subItem(Icons.assignment, app.score, ScorePage()),
              ],
            ),
            _item(
              Icons.school,
              app.graduationCheckChecklist,
              GraduationReportPage(
                username: ShareDataWidget.of(context).data.username,
                password: ShareDataWidget.of(context).data.password,
              ),
            ),
            _item(
              Icons.monetization_on,
              app.tuitionAndFees,
              TuitionAndFeesPage(
                username: ShareDataWidget.of(context).data.username,
                password: ShareDataWidget.of(context).data.password,
              ),
            ),
            _item(Icons.accessibility_new, app.admissionGuide,
                AdmissionGuidePage()),
            _item(Icons.face, app.about, AboutUsPage()),
            _item(Icons.settings, app.settings, SettingPage()),
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: Resource.Colors.grey,
              ),
              onTap: () {
                Navigator.popUntil(
                    context, ModalRoute.withName(Navigator.defaultRouteName));
              },
              title: Text(app.logout, style: _defaultStyle()),
            ),
          ],
        ),
      ),
    );
  }

  _item(IconData icon, String title, Widget page) => ListTile(
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle()),
        onTap: () {
          Navigator.pop(context);
          Utils.pushCupertinoStyle(context, page);
        },
      );

  _subItem(IconData icon, String title, Widget page) => ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 72.0),
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle()),
        onTap: () async {
          Navigator.of(context).pop();
          Utils.pushCupertinoStyle(context, page);
        },
      );
}
