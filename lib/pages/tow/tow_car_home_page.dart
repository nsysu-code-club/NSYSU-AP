import 'dart:async';

import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/pages/tow/alert_report_page.dart';
import 'package:nsysu_ap/pages/tow/tow_car_subscription_page.dart';
import 'package:nsysu_ap/pages/tow/tow_car_news_page.dart';

import '../../config/constants.dart';
import '../../models/car_park_area.dart';
import '../../resources/image_assets.dart';
import '../../utils/app_localizations.dart';

class TowCarConfig extends InheritedWidget {
  final List<CarParkArea> carParkAreas;
  final List<String> subscriptions;

  TowCarConfig({
    this.carParkAreas,
    this.subscriptions,
    Widget child,
  }) : super(child: child);

  static TowCarConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(TowCarConfig oldWidget) {
    return true;
  }
}

class TowCarHomePage extends StatefulWidget {
  @override
  _TowCarHomePageState createState() => _TowCarHomePageState();
}

class _TowCarHomePageState extends State<TowCarHomePage>
    with SingleTickerProviderStateMixin {
  AppLocalizations app;
  ApLocalizations ap;

  TabController controller;

  int _currentIndex = 0;

  List<CarParkArea> carParkAreas;

  List<String> subscriptions;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("TowCarHomePage", "tow_car_page.dart");
    controller = TabController(length: 3, vsync: this);
    Future.microtask(_getData);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    return TowCarConfig(
      carParkAreas: carParkAreas,
      subscriptions: subscriptions,
      child: Scaffold(
        appBar: AppBar(
          title: Text(app.towCarHelper),
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
              label: app.towCarNews,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tag_faces_outlined),
              label: app.subscriptionArea,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notification_important_outlined),
              label: app.towCarAlertReport,
            ),
          ],
        ),
      ),
    );
  }

  Future<FutureOr> _getData() async {
    subscriptions =
        Preferences.getStringList(Constants.CAR_PARK_AREA_SUBSCRIPTION, []);
    final json = await FileAssets.carParkAreaData;
    carParkAreas = CarParkAreaData.fromJson(json).data;
    carParkAreas.forEach((element) {
      if (subscriptions.indexOf(element.fcmTopic) != -1) element.enable = true;
    });
    setState(() {});
  }
}
