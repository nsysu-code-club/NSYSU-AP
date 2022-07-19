import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/analytics_utils.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/setting_page_widgets.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';

class SettingPage extends StatefulWidget {
  static const String routerName = '/setting';

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late ApLocalizations ap;

  bool displayPicture = true;

  String appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen('SettingPage', 'setting_page.dart');
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(ap.settings),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SettingTitle(text: ap.otherSettings),
            const CheckCourseNotifyItem(),
            const ClearAllNotifyItem(),
            const Divider(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.environmentSettings),
            ChangeLanguageItem(
              onChange: (Locale locale) {
                ShareDataWidget.of(context)!.data.loadLocale(locale);
              },
            ),
            ChangeThemeModeItem(
              onChange: (ThemeMode themeMode) {
                ShareDataWidget.of(context)!.data.loadTheme(themeMode);
              },
            ),
            ChangeIconStyleItem(
              onChange: (String code) {
                ShareDataWidget.of(context)!.data.update();
              },
            ),
            const Divider(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.otherInfo),
            SettingItem(
              text: ap.feedback,
              subText: ap.feedbackViaFacebook,
              onTap: () {
                ApUtils.launchFbFansPage(context, Constants.FANS_PAGE_ID);
                AnalyticsUtils.instance?.logEvent('feedback_click');
              },
            ),
            SettingItem(
              text: ap.appVersion,
              subText: 'v$appVersion',
              onTap: () {
                AnalyticsUtils.instance?.logEvent('app_version_click');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getPreference() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      displayPicture =
          Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true);
    });
  }
}
