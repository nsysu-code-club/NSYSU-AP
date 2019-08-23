import 'dart:async';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/search_student_id_page.dart';
import 'package:nsysu_ap/res/colors.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/helper.dart';
import 'package:nsysu_ap/utils/utils.dart';
import 'package:nsysu_ap/widgets/default_dialog.dart';
import 'package:nsysu_ap/widgets/progress_dialog.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';
import 'package:nsysu_ap/widgets/yes_no_dialog.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  static const String routerName = "/login";

  @override
  LoginPageState createState() => new LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  AppLocalizations app;
  SharedPreferences prefs;

  final TextEditingController _username = new TextEditingController();
  final TextEditingController _password = new TextEditingController();
  var isRememberPassword = true;
  var isAutoLogin = false;

  FocusNode usernameFocusNode;
  FocusNode passwordFocusNode;

  final encrypter = Encrypter(AES(Constants.key, mode: AESMode.cbc));

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("LoginPage", "login_page.dart");
    usernameFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    if (Platform.isAndroid || Platform.isIOS) {
      _getPreference();
      _checkUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  _editTextStyle() => new TextStyle(
      color: Colors.white, fontSize: 18.0, decorationColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return OrientationBuilder(builder: (_, orientation) {
      return Scaffold(
        backgroundColor: Resource.Colors.blue,
        resizeToAvoidBottomPadding: orientation == Orientation.portrait,
        body: Container(
          alignment: Alignment(0, 0),
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: orientation == Orientation.portrait
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: _renderContent(orientation),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _renderContent(orientation),
                ),
        ),
      );
    });
  }

  _renderContent(Orientation orientation) {
    List<Widget> list = orientation == Orientation.portrait
        ? <Widget>[
            Center(
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ]
        : <Widget>[
            Expanded(
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ];
    List<Widget> listB = <Widget>[
      TextField(
        maxLines: 1,
        controller: _username,
        textInputAction: TextInputAction.next,
        focusNode: usernameFocusNode,
        onSubmitted: (text) {
          usernameFocusNode.unfocus();
          FocusScope.of(context).requestFocus(passwordFocusNode);
        },
        decoration: InputDecoration(
          labelText: app.username,
        ),
        style: _editTextStyle(),
      ),
      TextField(
        obscureText: true,
        maxLines: 1,
        textInputAction: TextInputAction.send,
        controller: _password,
        focusNode: passwordFocusNode,
        onSubmitted: (text) {
          passwordFocusNode.unfocus();
          _login();
        },
        decoration: InputDecoration(
          labelText: app.password,
        ),
        style: _editTextStyle(),
      ),
      SizedBox(height: 8.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: Checkbox(
                    activeColor: Colors.white,
                    checkColor: Color(0xff2574ff),
                    value: isAutoLogin,
                    onChanged: _onAutoLoginChanged,
                  ),
                ),
                Text(app.autoLogin, style: TextStyle(color: Colors.white))
              ],
            ),
            onTap: () => _onAutoLoginChanged(!isAutoLogin),
          ),
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: Checkbox(
                    activeColor: Colors.white,
                    checkColor: Color(0xff2574ff),
                    value: isRememberPassword,
                    onChanged: _onRememberPasswordChanged,
                  ),
                ),
                Text(app.remember, style: TextStyle(color: Colors.white))
              ],
            ),
            onTap: () => _onRememberPasswordChanged(!isRememberPassword),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      Container(
        width: double.infinity,
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30.0),
            ),
          ),
          padding: EdgeInsets.all(14.0),
          onPressed: () {
            FA.logAction('login', 'click');
            Helper.error = 0;
            _login();
          },
          color: Colors.white,
          child: Text(
            app.login,
            style: TextStyle(color: Resource.Colors.blue, fontSize: 18.0),
          ),
        ),
      ),
      Center(
        child: FlatButton(
          onPressed: () async {
            var username = await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => SearchStudentIdPage(),
              ),
            );
            if (username != null && username is String) {
              setState(() {
                _username.text = username;
              });
              Utils.showToast(context, app.firstLoginHint);
            }
          },
          child: Text(
            app.searchUsername,
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
        ),
      ),
    ];
    if (orientation == Orientation.portrait) {
      list.addAll(listB);
    } else {
      list.add(Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: listB)));
    }
    return list;
  }

  _checkUpdate() async {
    prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await Future.delayed(Duration(milliseconds: 50));
    var currentVersion = prefs.getString(Constants.PREF_CURRENT_VERSION) ?? "";
    if (currentVersion != packageInfo.buildNumber) {
      showDialog(
        context: context,
        builder: (BuildContext context) => DefaultDialog(
          title: app.updateNoteTitle,
          contentWidget: Text(
            "v${packageInfo.version}\n"
            "${app.updateNoteContent}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Resource.Colors.grey),
          ),
          actionText: app.iKnow,
          actionFunction: () =>
              Navigator.of(context, rootNavigator: true).pop('dialog'),
        ),
      );
      prefs.setString(Constants.PREF_CURRENT_VERSION, packageInfo.buildNumber);
    }
    if (!Constants.isInDebugMode) {
      final RemoteConfig remoteConfig = await RemoteConfig.instance;
      try {
        await remoteConfig.fetch(expiration: const Duration(seconds: 10));
        await remoteConfig.activateFetched();
      } on FetchThrottledException catch (exception) {} catch (exception) {}
      String url = "";
      int versionDiff = 0, newVersion;
      if (Platform.isAndroid) {
        url = "market://details?id=${packageInfo.packageName}";
        newVersion = remoteConfig.getInt(Constants.ANDROID_APP_VERSION);
      } else if (Platform.isIOS) {
        url =
            "itms-apps://itunes.apple.com/tw/app/apple-store/id1467522198?mt=8";
        newVersion = remoteConfig.getInt(Constants.IOS_APP_VERSION);
      } else {
        url = "https://www.facebook.com/NKUST.ITC/";
        newVersion = remoteConfig.getInt(Constants.APP_VERSION);
      }
      versionDiff = newVersion - int.parse(packageInfo.buildNumber);
      String versionContent =
          "\nv${newVersion ~/ 10000}.${newVersion % 1000 ~/ 100}.${newVersion % 100}\n";
      switch (AppLocalizations.locale.languageCode) {
        case 'zh':
          versionContent +=
              remoteConfig.getString(Constants.NEW_VERSION_CONTENT_ZH);
          break;
        default:
          versionContent +=
              remoteConfig.getString(Constants.NEW_VERSION_CONTENT_EN);
          break;
      }
      if (versionDiff < 5 && versionDiff > 0) {
        showDialog(
          context: context,
          builder: (BuildContext context) => YesNoDialog(
            title: app.updateTitle,
            contentWidget: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: TextStyle(
                      color: Resource.Colors.grey, height: 1.3, fontSize: 16.0),
                  children: [
                    TextSpan(
                      text:
                          '${Utils.getPlatformUpdateContent(app)}\n${versionContent.replaceAll('\\n', '\n')}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
            ),
            leftActionText: app.skip,
            rightActionText: app.update,
            leftActionFunction: null,
            rightActionFunction: () {
              Utils.launchUrl(url);
            },
          ),
        );
      } else if (versionDiff >= 5) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => WillPopScope(
            child: DefaultDialog(
                title: app.updateTitle,
                actionText: app.update,
                contentWidget: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                      style: TextStyle(
                          color: Resource.Colors.grey,
                          height: 1.3,
                          fontSize: 16.0),
                      children: [
                        TextSpan(
                            text:
                                '${Utils.getPlatformUpdateContent(app)}\n${versionContent.replaceAll('\\n', '\n')}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                ),
                actionFunction: () {
                  Utils.launchUrl(url);
                }),
            onWillPop: () async {
              return false;
            },
          ),
        );
      }
    }
  }

  _onRememberPasswordChanged(bool value) async {
    setState(() {
      isRememberPassword = value;
      if (!isRememberPassword) isAutoLogin = false;
      if (Platform.isAndroid || Platform.isIOS) {
        prefs.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
        prefs.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
      }
    });
  }

  _onAutoLoginChanged(bool value) async {
    setState(() {
      isAutoLogin = value;
      isRememberPassword = isAutoLogin;
      if (Platform.isAndroid || Platform.isIOS) {
        prefs.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
        prefs.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
      }
    });
  }

  _getPreference() async {
    prefs = await SharedPreferences.getInstance();
    isRememberPassword =
        prefs.getBool(Constants.PREF_REMEMBER_PASSWORD) ?? true;
    isAutoLogin = prefs.getBool(Constants.PREF_AUTO_LOGIN) ?? false;
    var username = prefs.getString(Constants.PREF_USERNAME) ?? "";
    var password = "";
    if (isRememberPassword) {
      var encryptPassword = prefs.getString(Constants.PREF_PASSWORD) ?? "";
      if (encryptPassword != "") {
        try {
          password = encrypter.decrypt64(encryptPassword, iv: Constants.iv);
        } catch (e) {
          password = encryptPassword;
          await prefs.setString(
              Constants.PREF_PASSWORD,
              encrypter
                  .encrypt(
                    encryptPassword,
                    iv: Constants.iv,
                  )
                  .base64);
          throw e;
        }
      }
    }
    setState(() {
      _username.text = username;
      _password.text = password;
    });
    await Future.delayed(Duration(microseconds: 50));
    if (isAutoLogin) {
      _login();
    }
  }

  _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      Utils.showToast(context, app.doNotEmpty);
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => WillPopScope(
              child: ProgressDialog(app.logining),
              onWillPop: () async {
                return false;
              }),
          barrierDismissible: false);

      if (Platform.isAndroid || Platform.isIOS)
        prefs.setString(Constants.PREF_USERNAME, _username.text);
      Helper.instance
          .selcrsLogin(_username.text, _password.text)
          .then((response) async {
        ShareDataWidget.of(context).data.username = _username.text;
        ShareDataWidget.of(context).data.password = _password.text;
        if (Navigator.canPop(context)) Navigator.pop(context, 'dialog');
        if (response == 403) {
          Utils.showToast(context, app.loginFail);
        } else if (Platform.isAndroid || Platform.isIOS) {
          prefs.setString(Constants.PREF_USERNAME, _username.text);
          if (isRememberPassword) {
            await prefs.setString(Constants.PREF_PASSWORD,
                encrypter.encrypt(_password.text, iv: Constants.iv).base64);
          }
          prefs.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
          _navigateToFilterObject(context);
        }
      }).catchError((e) {
        if (Navigator.canPop(context)) Navigator.pop(context, 'dialog');
        Helper.changeSelcrsUrl();
        Helper.error++;
        if (Helper.error < 5) {
          _login();
          setState(() {});
        } else {
          Utils.showToast(context, app.timeoutMessage);
        }
      });
    }
  }

  _navigateToFilterObject(BuildContext context) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomePage()));
    print(result);
    clearSetting();
  }

  void clearSetting() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setBool(Constants.PREF_AUTO_LOGIN, false);
    setState(() {
      isAutoLogin = false;
      //pictureUrl = "";
    });
  }
}
