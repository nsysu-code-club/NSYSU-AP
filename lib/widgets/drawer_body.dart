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

class DrawerBody extends StatefulWidget {
  final UserInfo userInfo;

  const DrawerBody({Key key, this.userInfo}) : super(key: key);

  @override
  DrawerBodyState createState() => DrawerBodyState();
}

class DrawerBodyState extends State<DrawerBody> {
  AppLocalizations app;

  bool isStudyExpanded = false;
  bool displayPicture = true;

  TextStyle get _defaultStyle =>
      TextStyle(color: Resource.Colors.grey, fontSize: 16.0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
              title: Text(app.courseInfo, style: _defaultStyle),
              children: <Widget>[
                _subItem(
                  icon: Icons.class_,
                  title: app.course,
                  page: CoursePage(),
                ),
                _subItem(
                  icon: Icons.assignment,
                  title: app.score,
                  page: ScorePage(),
                ),
              ],
            ),
            _item(
              icon: Icons.school,
              title: app.graduationCheckChecklist,
              page: GraduationReportPage(
                username: ShareDataWidget.of(context).data.username,
                password: ShareDataWidget.of(context).data.password,
              ),
            ),
            _item(
              icon: Icons.monetization_on,
              title: app.tuitionAndFees,
              page: TuitionAndFeesPage(
                username: ShareDataWidget.of(context).data.username,
                password: ShareDataWidget.of(context).data.password,
              ),
            ),
            _item(
                icon: Icons.accessibility_new,
                title: app.admissionGuide,
                page: AdmissionGuidePage()),
            _item(
              icon: Icons.face,
              title: app.about,
              page: AboutUsPage(),
            ),
            _item(
              icon: Icons.settings,
              title: app.settings,
              page: SettingPage(),
            ),
            ListTile(
              leading: Icon(
                Icons.power_settings_new,
                color: Resource.Colors.grey,
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
        ),
      ),
    );
  }

  _item({
    @required IconData icon,
    @required String title,
    @required Widget page,
  }) =>
      ListTile(
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle),
        onTap: () {
          Navigator.pop(context);
          Utils.pushCupertinoStyle(context, page);
        },
      );

  _subItem({
    @required IconData icon,
    @required String title,
    @required Widget page,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 72.0),
        leading: Icon(icon, color: Resource.Colors.grey),
        title: Text(title, style: _defaultStyle),
        onTap: () async {
          Navigator.of(context).pop();
          Utils.pushCupertinoStyle(context, page);
        },
      );
}
