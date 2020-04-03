import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/scaffold/user_info_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';

class UserInfoPage extends StatefulWidget {
  final UserInfo userInfo;

  const UserInfoPage({Key key, this.userInfo}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserInfo userInfo;

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
        return this.userInfo;
      },
    );
  }
}
