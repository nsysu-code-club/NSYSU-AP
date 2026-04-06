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
        final ApiResult<UserInfo> result =
            await SelcrsHelper.instance.getUserInfo();
        if (result case ApiSuccess<UserInfo>(:final UserInfo data)) {
          setState(() {
            userInfo = data;
          });
          AnalyticsUtil.instance.logUserInfo(userInfo);
          return data;
        }
        return userInfo;
      },
      actions: <Widget>[
        IconButton(
          onPressed: () {
            newEmail = TextEditingController(text: userInfo.email);
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: Text(ap.changeEmail),
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
                              ap.loading,
                            ),
                          ),
                          barrierDismissible: false,
                        );
                        final ApiResult<UserInfo> result =
                            await SelcrsHelper.instance.changeMail(
                          mail: newEmail.text,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        switch (result) {
                          case ApiSuccess<UserInfo>(:final UserInfo data):
                            UiUtil.instance.showToast(
                              context,
                              ap.updateSuccess,
                            );
                            setState(() {
                              userInfo = data;
                            });
                          case ApiFailure<UserInfo>(
                              :final DioException exception):
                            if (exception.i18nMessage != null) {
                              UiUtil.instance.showToast(
                                  context, exception.i18nMessage!);
                            }
                          case ApiError<UserInfo>(
                              :final GeneralResponse response):
                            UiUtil.instance.showToast(
                                context, response.message);
                        }
                      },
                      child: Text(ap.confirm),
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
