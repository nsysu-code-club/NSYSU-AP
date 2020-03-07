import 'dart:io';

import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/option_dialog.dart';
import 'package:ap_common/widgets/setting_page_widgets.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:package_info/package_info.dart';

class SettingPage extends StatefulWidget {
  static const String routerName = "/setting";

  @override
  SettingPageState createState() => new SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  AppLocalizations app;
  ApLocalizations ap;

  bool busNotify = false;
  bool courseNotify = false;
  bool displayPicture = true;
  bool isOffline = false;

  String appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("SettingPage", "setting_page.dart");
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    final languageTextList = [
      ApLocalizations.of(context).systemLanguage,
      ApLocalizations.of(context).traditionalChinese,
      ApLocalizations.of(context).english,
    ];
    final themeTextList = [
      ApLocalizations.of(context).systemTheme,
      ApLocalizations.of(context).light,
      ApLocalizations.of(context).dark,
    ];
    final code = Preferences.getString(
        Constants.PREF_LANGUAGE_CODE, ApSupportLanguageConstants.SYSTEM);
    final languageIndex = ApSupportLanguageExtension.fromCode(code);
    final themeModeIndex = ApTheme.of(context).themeMode.index;
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
            SettingTitle(text: ap.notificationItem),
            SettingSwitch(
              text: ap.courseNotify,
              subText: ap.courseNotifyHint,
              value: courseNotify,
              onChanged: (state) async {
                Utils.showToast(
                  context,
                  ap.functionNotOpen,
                );
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
              },
            ),
            Container(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.otherSettings),
            SettingItem(
              text: ap.language,
              subText: languageTextList[languageIndex],
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => SimpleOptionDialog(
                    title: ap.language,
                    items: languageTextList,
                    index: languageIndex,
                    onSelected: (int index) {
                      Locale locale;
                      String code = ApSupportLanguage.values[index].code;
                      switch (index) {
                        case 0:
                          locale = Localizations.localeOf(context);
                          break;
                        default:
                          locale = Locale(code);
                          break;
                      }
                      Preferences.setString(Constants.PREF_LANGUAGE_CODE, code);
                      setState(() {
                        AppLocalizationsDelegate().load(locale);
                        ApLocalizationsDelegate().load(locale);
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
            SettingItem(
              text: ap.theme,
              subText: themeTextList[themeModeIndex],
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => SimpleOptionDialog(
                    title: ap.theme,
                    items: themeTextList,
                    index: themeModeIndex,
                    onSelected: (int index) {
                      Preferences.getInt(
                        Constants.PREF_THEME_MODE_INDEX,
                        index,
                      );
                      ShareDataWidget.of(context)
                          .data
                          .update(ThemeMode.values[index]);
                      Preferences.setInt(
                          Constants.PREF_THEME_MODE_INDEX, index);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
            Divider(
              color: Colors.grey,
              height: 0.5,
            ),
            SettingTitle(text: ap.otherInfo),
            SettingItem(
              text: ap.feedback,
              subText: ap.feedbackViaFacebook,
              onTap: () {
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
                      (onError) => Utils.showToast(context, ap.platformError));
                }
                FA.logAction('feedback', 'click');
              },
            ),
            SettingItem(
              text: ap.donateTitle,
              subText: ap.donateContent,
              onTap: () {
                Utils.launchUrl("https://p.ecpay.com.tw/3D54D").catchError(
                    (onError) => Utils.showToast(context, ap.platformError));
                FA.logAction('donate', 'click');
              },
            ),
            SettingItem(
              text: ap.appVersion,
              subText: 'v$appVersion',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  _getPreference() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      isOffline = Preferences.getBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
      appVersion = packageInfo.version;
      courseNotify = Preferences.getBool(Constants.PREF_COURSE_NOTIFY, false);
      displayPicture =
          Preferences.getBool(Constants.PREF_DISPLAY_PICTURE, true);
      busNotify = Preferences.getBool(Constants.PREF_BUS_NOTIFY, false);
    });
  }
}
