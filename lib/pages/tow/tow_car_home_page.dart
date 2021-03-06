import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/pages/tow/alert_report_page.dart';
import 'package:nsysu_ap/pages/tow/tow_car_subscription_page.dart';
import 'package:nsysu_ap/pages/tow/tow_car_news_page.dart';

class TowCarHomePage extends StatefulWidget {
  @override
  _TowCarHomePageState createState() => _TowCarHomePageState();
}

class _TowCarHomePageState extends State<TowCarHomePage>
    with SingleTickerProviderStateMixin {
  ApLocalizations ap;

  TabController controller;

  int _currentIndex = 0;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("TowCarHomePage", "tow_car_page.dart");
    controller = TabController(length: 3, vsync: this);
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
        title: Text(''),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: TabBarView(
        children: [
          TowCarNewsPage(),
          TowCarSubscriptionPage(),
          TowCarAlertReportPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: ap.announcements,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tag_faces_outlined),
            label: '訂閱區域',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notification_important_outlined),
            label: '警報推播',
          ),
        ],
      ),
    );
  }
}
