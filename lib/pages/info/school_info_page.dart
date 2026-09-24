import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/pages/info/calendar_info_page.dart';

class SchoolInfoPage extends StatefulWidget {
  static const String routerName = '/SchoolInfo';

  @override
  SchoolInfoPageState createState() => SchoolInfoPageState();
}

class SchoolInfoPageState extends State<SchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final List<PhoneModel> phoneModelList = <PhoneModel>[
    const PhoneModel('總機', '(07)5252-000#2350'),
    const PhoneModel('校安專線', ''),
    const PhoneModel('生輔組', '0911-705-999'),
    const PhoneModel('值班室1', '(07)525-6666#6666'),
    const PhoneModel('值班室2', '(07)525-6666#6667'),
  ];

  NotificationState notificationState = NotificationState.loading;

  List<Notifications> notificationList = <Notifications>[];

  int page = 1;

  PhoneState phoneState = PhoneState.finish;

  late TabController controller;

  int _currentIndex = 0;

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('SchoolInfoPage', 'school_info_page.dart');
    controller = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const CalendarPage(),
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
        fixedColor: Theme.of(context).colorScheme.primary,
        items: <BottomNavigationBarItem>[
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
}
