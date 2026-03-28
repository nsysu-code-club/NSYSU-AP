import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    AnalyticsUtil.instance.setCurrentScreen('SettingPage', 'setting_page.dart');
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SettingTitle(
              text: ap.notificationItem,
              icon: Icons.notifications_outlined,
            ),
            SettingCard(
              children: <Widget>[
                const CheckCourseNotifyItem(),
                const ClearAllNotifyItem(),
              ],
            ),
            SettingTitle(
              text: ap.otherSettings,
              icon: Icons.tune_outlined,
            ),
            SettingCard(
              children: <Widget>[
                SettingSwitch(
                  text: ap.headPhotoSetting,
                  subText: ap.headPhotoSettingSubTitle,
                  icon: Icons.person_outline,
                  value: displayPicture,
                  onChanged: (bool b) {
                    setState(() {
                      displayPicture = !displayPicture;
                    });
                    PreferenceUtil.instance.setBool(
                      Constants.prefDisplayPicture,
                      displayPicture,
                    );
                  },
                ),
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
                ChangeThemeColorItem(
                  onChanged: (Color color) {
                    final int index = ApTheme.themeColors.indexWhere(
                      (ThemeColor tc) =>
                          tc.color.toARGB32() == color.toARGB32(),
                    );
                    final int newIndex = (index != -1)
                        ? index
                        : ApTheme.customColorIndex;
                    final Color? newCustomColor = (index != -1) ? null : color;
                    ShareDataWidget.of(context)!.data.loadThemeColor(
                          newIndex,
                          newCustomColor,
                        );
                    ApTheme.of(context).saveSettings(
                      index: newIndex,
                      customColor: newCustomColor,
                    );
                  },
                ),
              ],
            ),
            SettingTitle(
              text: ap.otherInfo,
              icon: Icons.info_outline,
            ),
            SettingCard(
              children: <Widget>[
                SettingItem(
                  text: ap.feedback,
                  subText: ap.feedbackViaFacebook,
                  icon: Icons.feedback_outlined,
                  isExternalLink: true,
                  onTap: () {
                    ApUtils.launchFbFansPage(context, Constants.fansPageId);
                    AnalyticsUtil.instance.logEvent('feedback_click');
                  },
                ),
                SettingInfoItem(
                  text: ap.appVersion,
                  icon: Icons.info_outline,
                  value: 'v$appVersion',
                ),
              ],
            ),
            const SizedBox(height: 32),
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
          PreferenceUtil.instance.getBool(Constants.prefDisplayPicture, true);
    });
  }
}
