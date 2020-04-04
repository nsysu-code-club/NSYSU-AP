import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/scaffold/user_info_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/utils.dart';

class UserInfoPage extends StatefulWidget {
  final UserInfo userInfo;

  const UserInfoPage({Key key, this.userInfo}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserInfo userInfo;

  TextEditingController newEmail;

  @override
  void initState() {
    FA.setCurrentScreen("UserInfoPage", "user_info_page.dart");
    userInfo = widget.userInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return UserInfoScaffold(
      userInfo: userInfo,
      onRefresh: () async {
        this.userInfo = await Helper.instance.getUserInfo();
        FA.setUserProperty('department', userInfo.department);
        FA.logUserInfo(userInfo.department);
        FA.setUserId(userInfo.id);
        setState(() {});
        return null;
      },
      actions: <Widget>[
        IconButton(
          onPressed: () {
            newEmail = TextEditingController(text: userInfo.email);
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: Text('更改電子信箱'),
                  content: TextField(
                    controller: newEmail,
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () async {
                        var userInfo = await Helper.instance.changeMail(
                          mail: newEmail.text,
                          callback: GeneralCallback.simple(context),
                        );
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
          icon: Icon(Icons.edit),
        )
      ],
    );
  }
}
