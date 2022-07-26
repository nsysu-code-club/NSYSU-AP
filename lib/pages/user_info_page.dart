import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/scaffold/user_info_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';

class UserInfoPage extends StatefulWidget {
  final UserInfo userInfo;

  const UserInfoPage({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  late UserInfo userInfo;

  late TextEditingController newEmail;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen('UserInfoPage', 'user_info_page.dart');
    userInfo = widget.userInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return UserInfoScaffold(
      userInfo: userInfo,
      onRefresh: () async {
        return (await SelcrsHelper.instance.getUserInfo(
              callback: GeneralCallback<UserInfo>(
                onSuccess: (UserInfo data) {
                  setState(() {
                    userInfo = data;
                  });
                  FirebaseAnalyticsUtils.instance.logUserInfo(userInfo);
                  return data;
                },
                onFailure: (DioError e) {},
                onError: (GeneralResponse e) {},
              ),
            )) ??
            userInfo;
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
                          builder: (BuildContext context) => WillPopScope(
                            child: ProgressDialog(
                              ApLocalizations.of(context).loading,
                            ),
                            onWillPop: () async {
                              return false;
                            },
                          ),
                          barrierDismissible: false,
                        );
                        final UserInfo? userInfo =
                            await SelcrsHelper.instance.changeMail(
                          mail: newEmail.text,
                          callback: GeneralCallback<UserInfo>.simple(
                            context,
                            (UserInfo userInfo) => userInfo,
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        if (userInfo != null) {
                          ApUtils.showToast(context,
                              ApLocalizations.of(context).updateSuccess);
                          setState(() {
                            this.userInfo = userInfo;
                          });
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
        )
      ],
    );
  }
}
