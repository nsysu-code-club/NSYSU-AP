import 'package:ap_common/resources/ap_theme.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/tow_car_alert_data.dart';

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
      title: '管院拖車快來救',
      message: '管院拖車拉，發新年紅包了，快來救...',
    ),
    TowCarAlert(
      time: DateTime.now().subtract(
        Duration(hours: 2),
      ),
      topic: '武二',
      title: '武二發紅包快來',
      message: '管院拖車拉，發新年紅包了，快來救...',
    ),
    TowCarAlert(
      time: DateTime.now().subtract(
        Duration(days: 1),
      ),
      topic: 'L停',
      title: 'L停大量猴子',
      message: 'L停大量猴子，拿食物請注意',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: towCarAlerts?.length ?? 0,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (_, index) {
        final alert = towCarAlerts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: FlutterLogo(size: 68.0),
              ),
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
        );
      },
    );
  }
}
