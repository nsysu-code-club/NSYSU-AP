import 'dart:async';

import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/tow_car_helper.dart';
import 'package:nsysu_ap/models/tow_car_alert_data.dart';
import 'package:nsysu_ap/pages/tow/tow_car_content_page.dart';

import '../../models/car_park_area.dart';
import '../../utils/app_localizations.dart';
import 'tow_car_home_page.dart';

enum _State { loading, error, empty, finish }

class TowCarNewsPage extends StatefulWidget {
  @override
  _TowCarNewsPageState createState() => _TowCarNewsPageState();
}

class _TowCarNewsPageState extends State<TowCarNewsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  AppLocalizations app;

  List<TowCarAlert> towCarAlerts = [];

  _State state = _State.finish;

  String hint;

  int areaIndex = 0;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance?.setCurrentScreen(
      "TowCarNewsPage",
      "tow_car_news_page.dart",
    );
    Future.microtask(_getData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    final carParkAreas = TowCarConfig.of(context).carParkAreas;
    final subscriptions = TowCarConfig.of(context).subscriptions;
    List<TowCarAlert> selectTowCarAlerts = [];
    this.towCarAlerts.forEach((element) {
      if (areaIndex == 0 && subscriptions?.indexOf(element.topic) != -1) {
        selectTowCarAlerts.add(element);
      } else if (areaIndex != 0 &&
          carParkAreas[areaIndex - 1].fcmTopic == element.topic) {
        selectTowCarAlerts.add(element);
      }
    });
    super.build(context);
    switch (state) {
      case _State.loading:
        return Center(
          child: CircularProgressIndicator(),
        );
        break;
      case _State.error:
      case _State.empty:
        return InkWell(
          onTap: () {
            Future.microtask(_getData);
          },
          child: HintContent(
            icon: ApIcon.error,
            content: hint,
          ),
        );
        break;
      case _State.finish:
      default:
        return Column(
          children: [
            SizedBox(
              height: 108.0,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => SizedBox(width: 4.0),
                shrinkWrap: true,
                itemCount: (carParkAreas?.length ?? 0) + 1,
                itemBuilder: (_, index) {
                  final carParkArea = index == 0
                      ? CarParkArea(
                          name: app.subscriptionArea,
                          imageUrl: 'https://i.imgur.com/pS8opJN.png',
                        )
                      : carParkAreas[index - 1];
                  return GestureDetector(
                    onTap: () {
                      setState(() => areaIndex = index);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: CachedNetworkImage(
                            width: 150.0,
                            imageUrl: carParkArea.imageUrl,
                            errorWidget: (context, url, error) =>
                                Icon(ApIcon.error),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          carParkArea.name,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _getData,
                child: ListView.separated(
                  itemCount: selectTowCarAlerts?.length ?? 0,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (_, index) {
                    final alert = selectTowCarAlerts[index];
                    return InkWell(
                      onTap: () {
                        ApUtils.pushCupertinoStyle(
                          context,
                          TowCarContentPage(
                            towCarAlert: alert,
                            carParkAreas: carParkAreas,
                          ),
                        );
                        FirebaseAnalyticsUtils.instance
                            ?.logEvent('show_tow_car_alert_content');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Hero(
                                tag: alert.hashCode,
                                child: CachedNetworkImage(
                                  width: 68.0,
                                  imageUrl: alert.imageUrl,
                                  errorWidget: (context, url, error) =>
                                      Icon(ApIcon.error),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8.0),
                                  Text(
                                    alert.title ?? '',
                                    style: TextStyle(
                                      color: ApTheme.of(context).blueText,
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    alert.message.length > 18
                                        ? "${alert.message.substring(0, 18)}..."
                                        : alert.message,
                                    style: TextStyle(
                                      color: ApTheme.of(context).greyText,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  alert.time == null
                                      ? app.unknownTime
                                      : alert.ago,
                                  style: TextStyle(
                                    color: ApTheme.of(context).blueText,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 8.0),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _getData() async {
    await TowCarHelper.instance.getAllTowCarAlert(
      callback: GeneralCallback(
        onSuccess: (List<TowCarAlert> data) {
          setState(() {
            towCarAlerts = data;
            state = _State.finish;
          });
        },
        onFailure: (DioError e) {
          setState(() {
            state = _State.finish;
            hint = e.i18nMessage;
          });
        },
        onError: (GeneralResponse response) {
          setState(() {
            state = _State.error;
            hint = response.message;
          });
        },
      ),
    );
  }
}
