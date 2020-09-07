import 'dart:typed_data';

import 'package:ap_common/models/notification_data.dart';
import 'package:ap_common/models/phone_model.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/notification_scaffold.dart';
import 'package:ap_common/scaffold/pdf_scaffold.dart';
import 'package:ap_common/scaffold/phone_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';

class SchoolInfoPage extends StatefulWidget {
  static const String routerName = "/ShcoolInfo";

  @override
  SchoolInfoPageState createState() => SchoolInfoPageState();
}

class SchoolInfoPageState extends State<SchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final phoneModelList = [
    PhoneModel("總機", "(07)5252-000#2350"),
    PhoneModel("校安專線", ''),
    PhoneModel("生輔組", "0911-705-999"),
    PhoneModel("值班室1", "(07)525-6666#6666"),
    PhoneModel("值班室2", "(07)525-6666#6667"),
  ];

  NotificationState notificationState = NotificationState.loading;

  List<Notifications> notificationList = [];

  int page = 1;

  PhoneState phoneState = PhoneState.finish;

  PdfState pdfState = PdfState.loading;

  Uint8List byteList;

  ApLocalizations ap;

  TabController controller;

  int _currentIndex = 0;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("SchoolInfoPage", "school_info_page.dart");
    controller = TabController(length: 2, vsync: this);
    _getSchedules();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.schoolInfo),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: TabBarView(
        children: [
          PhoneScaffold(
            state: phoneState,
            phoneModelList: phoneModelList,
            logEvent: (key, value) =>
                FirebaseAnalyticsUtils.instance.logAction(key, value),
          ),
          PdfScaffold(
            state: pdfState,
            byteList: byteList,
            onRefresh: () {
              setState(() => pdfState = PdfState.loading);
              _getSchedules();
            },
          ),
        ],
        controller: controller,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            controller.animateTo(_currentIndex);
          });
        },
        fixedColor: ApTheme.of(context).yellow,
        items: [
//          BottomNavigationBarItem(
//            icon: Icon(ApIcon.fiberNew),
//            title: Text(ap.notifications),
//          ),
          BottomNavigationBarItem(
            icon: Icon(ApIcon.phone),
            title: Text(ap.phones),
          ),
          BottomNavigationBarItem(
            icon: Icon(ApIcon.dateRange),
            title: Text(ap.events),
          ),
        ],
      ),
    );
  }

  _getSchedules() async {
    String pdfUrl =
        'https://raw.githubusercontent.com/abc873693/NSYSU-AP/master/school_schedule.pdf';
    if (FirebaseUtils.isSupportRemoteConfig) {
      try {
        final RemoteConfig remoteConfig = await RemoteConfig.instance;
        await remoteConfig.fetch(expiration: const Duration(hours: 1));
        await remoteConfig.activateFetched();
        pdfUrl = remoteConfig.getString(Constants.SCHEDULE_PDF_URL);
        downloadFdf(pdfUrl);
      } catch (exception) {
        downloadFdf(pdfUrl);
      }
    } else {
      downloadFdf(pdfUrl);
    }
  }

  void downloadFdf(String url) async {
    try {
      var response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      setState(() {
        pdfState = PdfState.finish;
        byteList = response.data;
      });
    } catch (e) {
      setState(() {
        pdfState = PdfState.error;
      });
      throw e;
    }
  }
}
