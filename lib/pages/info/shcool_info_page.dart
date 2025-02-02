import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';

class SchoolInfoPage extends StatefulWidget {
  static const String routerName = '/ShcoolInfo';

  @override
  SchoolInfoPageState createState() => SchoolInfoPageState();
}

class SchoolInfoPageState extends State<SchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final List<PhoneModel> phoneModelList = <PhoneModel>[
    PhoneModel('總機', '(07)5252-000#2350'),
    PhoneModel('校安專線', ''),
    PhoneModel('生輔組', '0911-705-999'),
    PhoneModel('值班室1', '(07)525-6666#6666'),
    PhoneModel('值班室2', '(07)525-6666#6667'),
  ];

  NotificationState notificationState = NotificationState.loading;

  List<Notifications> notificationList = <Notifications>[];

  int page = 1;

  PhoneState phoneState = PhoneState.finish;

  PdfState pdfState = PdfState.loading;

  late ApLocalizations ap;

  late TabController controller;

  int _currentIndex = 0;

  Uint8List? data;

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('SchoolInfoPage', 'school_info_page.dart');
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
      ),
      body: TabBarView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          PhoneListView(
            state: phoneState,
            phoneModelList: phoneModelList,
          ),
          PdfView(
            state: pdfState,
            data: data,
            onRefresh: () {
              setState(() => pdfState = PdfState.loading);
              _getSchedules();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
            controller.animateTo(_currentIndex);
          });
        },
        fixedColor: ApTheme.of(context).yellow,
        items: <BottomNavigationBarItem>[
//          BottomNavigationBarItem(
//            icon: Icon(ApIcon.fiberNew),
//            title: Text(ap.notifications),
//          ),
          BottomNavigationBarItem(
            icon: Icon(ApIcon.phone),
            label: ap.phones,
          ),
          BottomNavigationBarItem(
            icon: Icon(ApIcon.dateRange),
            label: ap.events,
          ),
        ],
      ),
    );
  }

  Future<void> _getSchedules() async {
    String pdfUrl =
        'https://raw.githubusercontent.com/abc873693/NSYSU-AP/master/school_schedule.pdf';
    if (FirebaseRemoteConfigUtils.isSupported) {
      try {
        final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetch();
        await remoteConfig.activate();
        pdfUrl = remoteConfig.getString(Constants.schedulePdfUrl);
        downloadFdf(pdfUrl);
      } catch (exception) {
        downloadFdf(pdfUrl);
      }
    } else {
      downloadFdf(pdfUrl);
    }
  }

  Future<void> downloadFdf(String url) async {
    try {
      final Response<Uint8List> response = await Dio().get<Uint8List>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      setState(() {
        pdfState = PdfState.finish;
        data = response.data;
      });
    } catch (e) {
      setState(() {
        pdfState = PdfState.error;
      });
      rethrow;
    }
  }
}
