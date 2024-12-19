import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';

class UserInfoPage extends StatefulWidget {
  final UserInfo userInfo;

  const UserInfoPage({
    super.key,
    required this.userInfo,
  });

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late UserInfo userInfo;

  late TextEditingController newEmail;

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('UserInfoPage', 'user_info_page.dart');
    userInfo = widget.userInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return UserInfoScaffold(
      userInfo: userInfo,
      onRefresh: () async {
        final UserInfo data = await SelcrsHelper.instance.getUserInfo();
        setState(() {
          userInfo = data;
        });
        AnalyticsUtil.instance.logUserInfo(userInfo);
        return data;
      },
      actions: <Widget>[
        IconButton(
          onPressed: () {
            newEmail = TextEditingController(text: userInfo.email);
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: Text(ApLocalizations.of(context).changeEmail),
                  content: TextField(
                    controller: newEmail,
                  ),
                  actions: <Widget>[
                    InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => PopScope(
                            canPop: false,
                            child: ProgressDialog(
                              ApLocalizations.of(context).loading,
                            ),
                          ),
                          barrierDismissible: false,
                        );
                        try {
                          final UserInfo userInfo =
                              await SelcrsHelper.instance.changeMail(
                            mail: newEmail.text,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          UiUtil.instance.showToast(
                            context,
                            ApLocalizations.of(context).updateSuccess,
                          );
                          setState(() {
                            this.userInfo = userInfo;
                          });
                        } catch (e) {
                          switch (e) {
                            case DioException():
                              if (e.i18nMessage case final String message?) {
                                UiUtil.instance.showToast(context, message);
                              }
                            case GeneralResponse():
                              UiUtil.instance.showToast(context, e.message);
                            default:
                              UiUtil.instance.showToast(
                                context,
                                ApLocalizations.of(context).somethingError,
                              );
                          }
                        }
                      },
                      child: Text(ApLocalizations.of(context).confirm),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.edit),
        ),
      ],
    );
  }
}
