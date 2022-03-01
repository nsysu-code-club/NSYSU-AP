import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/login/search_student_id_page.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/utils.dart';

class LoginPage extends StatefulWidget {
  static const String routerName = "/login";

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  ApLocalizations ap;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  var isRememberPassword = true;
  var isAutoLogin = false;

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("LoginPage", "login_page.dart");
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return LoginScaffold(
      logoMode: LogoMode.text,
      logoSource: 'N',
      forms: [
        ApTextField(
          key: const Key('username'),
          controller: _username,
          textInputAction: TextInputAction.next,
          focusNode: usernameFocusNode,
          onSubmitted: (text) {
            usernameFocusNode.unfocus();
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
          labelText: ap.studentId,
          autofillHints: [AutofillHints.username],
        ),
        ApTextField(
          key: const Key('password'),
          obscureText: true,
          textInputAction: TextInputAction.send,
          controller: _password,
          focusNode: passwordFocusNode,
          onSubmitted: (text) {
            passwordFocusNode.unfocus();
            _login();
          },
          labelText: ap.password,
          autofillHints: [AutofillHints.password],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextCheckBox(
              text: ap.autoLogin,
              value: isAutoLogin,
              onChanged: _onAutoLoginChanged,
            ),
            TextCheckBox(
              text: ap.rememberPassword,
              value: isRememberPassword,
              onChanged: _onRememberPasswordChanged,
            ),
          ],
        ),
        SizedBox(height: 8.0),
        ApButton(
          text: ap.login,
          onPressed: () {
            SelcrsHelper.instance.error = 0;
            _login();
            FirebaseAnalyticsUtils.instance.logEvent('login_click');
          },
        ),
        ApFlatButton(
          onPressed: () async {
            var username = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchStudentIdPage(),
              ),
            );
            if (username != null && username is String) {
              setState(() {
                _username.text = username;
              });
              ApUtils.showToast(
                context,
                AppLocalizations.of(context).firstLoginHint,
              );
            }
          },
          text: ap.searchUsername,
        ),
      ],
    );
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
      ApUtils.showToast(context, ap.doNotEmpty);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
          child: ProgressDialog(ap.logining),
          onWillPop: () async {
            return false;
          },
        ),
        barrierDismissible: false,
      );
      if (_username.text.indexOf(' ') != -1)
        FirebaseAnalyticsUtils.instance.logEvent('username_has_empty');
      _username.text = _username.text.replaceAll(' ', '');
      Preferences.setString(Constants.PREF_USERNAME, _username.text);
      SelcrsHelper.instance.login(
        username: _username.text.toUpperCase(),
        password: _password.text,
        callback: GeneralCallback(
          onError: (GeneralResponse e) {
            Navigator.pop(context);
            if (e.statusCode == 400)
              ApUtils.showToast(context, ap.loginFail);
            else if (e.statusCode == 401) {
              ApUtils.showToast(
                  context, AppLocalizations.of(context).pleaseConfirmForm);
              Utils.openConfirmForm(context, _username.text);
            } else
              ApUtils.showToast(context, ap.unknownError);
          },
          onFailure: (DioError e) {
            Navigator.pop(context);
            ApUtils.showToast(context, e.i18nMessage);
          },
          onSuccess: (GeneralResponse data) async {
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
            TextInput.finishAutofillContext();
          },
        ),
      );
    }
  }
}
