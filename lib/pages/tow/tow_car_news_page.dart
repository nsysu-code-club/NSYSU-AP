import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/tow_car_alert_data.dart';
import 'package:nsysu_ap/pages/tow/tow_car_content_page.dart';

class TowCarNewsPage extends StatefulWidget {
  @override
  _TowCarNewsPageState createState() => _TowCarNewsPageState();
}

class _TowCarNewsPageState extends State<TowCarNewsPage> {
  List<TowCarAlert> towCarAlerts = [
    TowCarAlert(
      time: DateTime.now().subtract(
        Duration(hours: 1),
      ),
      topic: '管院',
      viewCounts: 30,
      title: '管院拖車快來救',
      message: '管院拖車拉，發新年紅包了，快來救...',
      imageUrl: 'https://i.imgur.com/iHKvJUIb.jpg',
    ),
    TowCarAlert(
      time: DateTime.now().subtract(
        Duration(hours: 2),
      ),
      topic: '武二',
      viewCounts: 23,
      title: '武二發紅包快來',
      message: '管院拖車拉，發新年紅包了，快來救...',
      imageUrl: 'https://i.imgur.com/Iethorib.jpg',
    ),
    TowCarAlert(
      time: DateTime.now().subtract(
        Duration(days: 1),
      ),
      topic: 'L停',
      viewCounts: 22,
      title: 'L停大量猴子',
      message: 'L停大量猴子，拿食物請注意',
      imageUrl: 'https://i.imgur.com/2SCaPvbb.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: towCarAlerts?.length ?? 0,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (_, index) {
        final alert = towCarAlerts[index];
        return InkWell(
          onTap: () {
            ApUtils.pushCupertinoStyle(
              context,
              TowCarContentPage(towCarAlert: alert),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Hero(
                    tag: alert.imageUrl,
                    child: CachedNetworkImage(
                      width: 68.0,
                      imageUrl: alert.imageUrl,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(ApIcon.error),
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
                        alert.title,
                        style: TextStyle(
                          color: ApTheme.of(context).blueText,
                          fontSize: 17.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        alert.message,
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
                      alert.ago,
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
    );
  }
}
