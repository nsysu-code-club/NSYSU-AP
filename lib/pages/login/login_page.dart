import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/login/search_student_id_page.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/utils.dart';

class LoginPage extends StatefulWidget {
  static const String routerName = '/login';

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  late ApLocalizations ap;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool isRememberPassword = true;
  bool isAutoLogin = false;

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen('LoginPage', 'login_page.dart');
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
      logoSource: 'N',
      forms: <Widget>[
        ApTextField(
          key: const Key('username'),
          controller: _username,
          focusNode: usernameFocusNode,
          onSubmitted: (String text) {
            usernameFocusNode.unfocus();
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
          labelText: ap.studentId,
          autofillHints: const <String>[AutofillHints.username],
        ),
        ApTextField(
          key: const Key('password'),
          obscureText: true,
          textInputAction: TextInputAction.send,
          controller: _password,
          focusNode: passwordFocusNode,
          onSubmitted: (String text) {
            passwordFocusNode.unfocus();
            _login();
          },
          labelText: ap.password,
          autofillHints: const <String>[AutofillHints.password],
        ),
        const SizedBox(height: 8.0),
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
        const SizedBox(height: 8.0),
        ApButton(
          text: ap.login,
          onPressed: () {
            SelcrsHelper.instance.error = 0;
            _login();
            AnalyticsUtil.instance.logEvent('login_click');
          },
        ),
        ApFlatButton(
          onPressed: () async {
            final dynamic username = await Navigator.push(
              context,
              MaterialPageRoute<dynamic>(
                builder: (_) => SearchStudentIdPage(),
              ),
            );
            if (username != null && username is String) {
              setState(() {
                _username.text = username;
              });
              if (!context.mounted) return;
              UiUtil.instance.showToast(
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

  Future<void> _onRememberPasswordChanged(bool? value) async {
    if (value != null) {
      setState(() {
        isRememberPassword = value;
        if (!isRememberPassword) isAutoLogin = false;
        PreferenceUtil.instance.setBool(Constants.prefAutoLogin, isAutoLogin);
        PreferenceUtil.instance.setBool(
          Constants.prefRememberPassword,
          isRememberPassword,
        );
      });
    }
  }

  Future<void> _onAutoLoginChanged(bool? value) async {
    if (value != null) {
      setState(() {
        isAutoLogin = value;
        isRememberPassword = isAutoLogin;
        PreferenceUtil.instance.setBool(Constants.prefAutoLogin, isAutoLogin);
        PreferenceUtil.instance.setBool(
          Constants.prefRememberPassword,
          isRememberPassword,
        );
      });
    }
  }

  Future<void> _getPreference() async {
    isRememberPassword =
        PreferenceUtil.instance.getBool(Constants.prefRememberPassword, true);
    final String username =
        PreferenceUtil.instance.getString(Constants.prefUsername, '');
    String password = '';
    if (isRememberPassword) {
      password =
          PreferenceUtil.instance.getStringSecurity(Constants.prefPassword, '');
    }
    setState(() {
      _username.text = username;
      _password.text = password;
    });
  }

  Future<void> _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      UiUtil.instance.showToast(context, ap.doNotEmpty);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => PopScope(
          canPop: false,
          child: ProgressDialog(ap.logining),
        ),
        barrierDismissible: false,
      );
      if (_username.text.contains(' ')) {
        AnalyticsUtil.instance.logEvent('username_has_empty');
      }
      final String username = _username.text.replaceAll(' ', '').toUpperCase();
      PreferenceUtil.instance.setString(
        Constants.prefUsername,
        username.toUpperCase(),
      );
      try {
        final GeneralResponse _ = await SelcrsHelper.instance.login(
          username: username,
          password: _password.text,
        );
        if (!mounted) return;
        Navigator.pop(context);
        PreferenceUtil.instance.setString(Constants.prefUsername, username);
        if (isRememberPassword) {
          await PreferenceUtil.instance.setStringSecurity(
            Constants.prefPassword,
            _password.text,
          );
        }
        PreferenceUtil.instance.setBool(Constants.prefIsOfflineLogin, false);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        TextInput.finishAutofillContext();
      } catch (e) {
        switch (e) {
          case DioException():
            if (e.i18nMessage != null) {
              Navigator.pop(context);
              UiUtil.instance.showToast(context, e.i18nMessage!);
            }
          case GeneralResponse():
            Navigator.pop(context);
            if (e.statusCode == 400) {
              UiUtil.instance.showToast(context, ap.loginFail);
            } else if (e.statusCode == 401) {
              UiUtil.instance.showToast(
                context,
                AppLocalizations.of(context).pleaseConfirmForm,
              );
              Utils.openConfirmForm(
                context,
                mounted: mounted,
                username: username,
              );
            } else {
              UiUtil.instance.showToast(context, ap.unknownError);
            }
          default:
            UiUtil.instance.showToast(context, ap.unknownError);
        }
      }
    }
  }
}
