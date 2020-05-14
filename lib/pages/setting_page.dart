import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/option_dialog.dart';
import 'package:ap_common/widgets/setting_page_widgets.dart';
import 'package:ap_common_firebase/constants/fiirebase_constants.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:package_info/package_info.dart';

class SettingPage extends StatefulWidget {
  static const String routerName = "/setting";

  @override
  SettingPageState createState() => new SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ApLocalizations ap;

  bool busNotify = false;
  bool courseNotify = false;
  bool displayPicture = true;
  bool isOffline = false;

  String appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("SettingPage", "setting_page.dart");
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            SettingTitle(text: ap.environmentSettings),
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
                          locale = Locale(
                            code,
                            code == ApSupportLanguageConstants.ZH ? 'TW' : null,
                          );
                          break;
                      }
                      Preferences.setString(Constants.PREF_LANGUAGE_CODE, code);
                      setState(() {
                        AppLocalizationsDelegate().load(locale);
                        ApLocalizationsDelegate().load(locale);
                      });
                      FirebaseAnalyticsUtils.instance.logAction(
                        'change_language',
                        code,
                      );
                      FirebaseAnalyticsUtils.instance.setUserProperty(
                        FirebaseConstants.LANGUAGE,
                        AppLocalizations.locale.languageCode,
                      );
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
                      FirebaseAnalyticsUtils.instance.logAction(
                        'change_theme',
                        ThemeMode.values[index].toString(),
                      );
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
                ApUtils.launchFbFansPage(context, Constants.FANS_PAGE_ID);
                FirebaseAnalyticsUtils.instance.logAction('feedback', 'click');
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
