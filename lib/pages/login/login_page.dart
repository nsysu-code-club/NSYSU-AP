import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/login/search_student_id_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:nsysu_ap/widgets/share_data_widget.dart';

class LoginPage extends StatefulWidget {
  static const String routerName = "/login";

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  AppLocalizations app;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  var isRememberPassword = true;
  var isAutoLogin = false;

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("LoginPage", "login_page.dart");
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  _editTextStyle() => TextStyle(
      color: Colors.white, fontSize: 18.0, decorationColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return OrientationBuilder(
      builder: (_, orientation) {
        return Scaffold(
          backgroundColor: ApTheme.of(context).blue,
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
      },
    );
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
                textAlign: TextAlign.center,
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
                    checkColor: ApTheme.of(context).blue,
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
                    checkColor: ApTheme.of(context).blue,
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
            style: TextStyle(color: ApTheme.of(context).blue, fontSize: 18.0),
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
              ApUtils.showToast(context, app.firstLoginHint);
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

  _onRememberPasswordChanged(bool value) async {
    setState(() {
      isRememberPassword = value;
      if (!isRememberPassword) isAutoLogin = false;
      Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
      Preferences.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
    });
  }

  _onAutoLoginChanged(bool value) async {
    setState(() {
      isAutoLogin = value;
      isRememberPassword = isAutoLogin;
      Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
      Preferences.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
    });
  }

  _getPreference() async {
    isRememberPassword =
        Preferences.getBool(Constants.PREF_REMEMBER_PASSWORD, true);
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = '';
    if (isRememberPassword) {
      password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    }
    setState(() {
      _username.text = username;
      _password.text = password;
    });
  }

  _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      ApUtils.showToast(context, app.doNotEmpty);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
          child: ProgressDialog(app.logining),
          onWillPop: () async {
            return false;
          },
        ),
        barrierDismissible: false,
      );
      Preferences.setString(Constants.PREF_USERNAME, _username.text);
      var response = await Helper.instance.selcrsLogin(
        username: _username.text,
        password: _password.text,
        callback: GeneralCallback(
          onError: (GeneralResponse e) {
            if (e.statusCode == 400)
              ApUtils.showToast(context, app.loginFail);
            else
              _changeHost();
          },
          onFailure: (DioError e) {
            _changeHost();
          },
        ),
      );
      if (response != null) {
        Navigator.pop(context);
        Preferences.setString(Constants.PREF_USERNAME, _username.text);
        if (isRememberPassword) {
          await Preferences.setStringSecurity(
            Constants.PREF_PASSWORD,
            _password.text,
          );
        }
        Preferences.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
        Navigator.of(context).pop(true);
      }
    }
  }

  void _changeHost() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    Helper.changeSelcrsUrl();
    Helper.error++;
    if (Helper.error < 5) {
      _login();
      setState(() {});
    } else {
      ApUtils.showToast(context, ApLocalizations.of(context).timeoutMessage);
    }
  }
}
