import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/car_park_area.dart';

import '../../config/constants.dart';
import '../../models/car_park_area.dart';
import '../../utils/app_localizations.dart';
import 'tow_car_home_page.dart';

class TowCarSubscriptionPage extends StatefulWidget {
  @override
  _TowCarSubscriptionPageState createState() => _TowCarSubscriptionPageState();
}

class _TowCarSubscriptionPageState extends State<TowCarSubscriptionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  AppLocalizations app;

  bool enableAll = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    app = AppLocalizations.of(context);
    final carParkAreas = TowCarConfig.of(context).carParkAreas;
    final subscriptions = TowCarConfig.of(context).subscriptions;
    return ListView(
      children: [
        SwitchListTile.adaptive(
          title: Text(app.allArea),
          value: enableAll,
          onChanged: (value) async {
            showDialog(
              context: context,
              builder: (BuildContext context) => WillPopScope(
                child: ProgressDialog(app.processing),
                onWillPop: () async {
                  return false;
                },
              ),
              barrierDismissible: false,
            );
            for (var element in carParkAreas) {
              element.enable = value;
              if (element.enable) {
                await FirebaseMessaging.instance
                    .subscribeToTopic(element.fcmTopic);
                subscriptions.add(element.fcmTopic);
              } else {
                await FirebaseMessaging.instance
                    .unsubscribeFromTopic(element.fcmTopic);
              }
            }
            if (!value) subscriptions.clear();
            Preferences.setStringList(
              Constants.CAR_PARK_AREA_SUBSCRIPTION,
              subscriptions,
            );
            Navigator.pop(context);
            setState(() => enableAll = value);
          },
        ),
        for (CarParkArea carParkArea in carParkAreas ?? [])
          SwitchListTile.adaptive(
            title: Text(carParkArea.name),
            value: carParkArea.enable,
            onChanged: (value) async {
              showDialog(
                context: context,
                builder: (BuildContext context) => WillPopScope(
                  child: ProgressDialog('Waiting...'),
                  onWillPop: () async {
                    return false;
                  },
                ),
                barrierDismissible: false,
              );
              final topic = carParkArea.fcmTopic;
              if (value) {
                await FirebaseMessaging.instance.subscribeToTopic(topic);
                subscriptions.add(topic);
              } else {
                await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
                subscriptions.remove(topic);
              }
              Preferences.setStringList(
                Constants.CAR_PARK_AREA_SUBSCRIPTION,
                subscriptions,
              );
              enableAll = subscriptions.length == carParkAreas.length;
              Navigator.pop(context);
              setState(() => carParkArea.enable = value);
            },
          ),
      ],
    );
  }
}
