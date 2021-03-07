import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/tow_car_alert_data.dart';

class TowCarContentPage extends StatefulWidget {
  final TowCarAlert towCarAlert;

  const TowCarContentPage({
    Key key,
    @required this.towCarAlert,
  }) : super(key: key);

  @override
  _TowCarContentPageState createState() => _TowCarContentPageState();
}

class _TowCarContentPageState extends State<TowCarContentPage> {
  TextStyle get _subTitleStyle => TextStyle(
        color: ApTheme.of(context).greyText,
        fontSize: 16.0,
        fontWeight: FontWeight.w300,
      );

  TextStyle get _subContentStyle => TextStyle(
        color: ApTheme.of(context).blueText,
        fontSize: 20.0,
        fontWeight: FontWeight.w900,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('拖車警報'),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.towCarAlert.imageUrl,
            child: CachedNetworkImage(
              height: 250.0,
              fit: BoxFit.cover,
              imageUrl: widget.towCarAlert.imageUrl,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Icon(ApIcon.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.towCarAlert.title,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.0,
                      color: ApTheme.of(context).greyText,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      widget.towCarAlert.topic,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w400,
                        color: ApTheme.of(context).greyText,
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${widget.towCarAlert.viewCounts}",
                            style: _subContentStyle,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            "多少人看過",
                            style: _subTitleStyle,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 68.0,
                      child: VerticalDivider(),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${widget.towCarAlert.time}",
                            style: _subContentStyle,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            "發布時間",
                            style: _subTitleStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Text(
                  "警報內容",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  widget.towCarAlert.message,
                  style: TextStyle(
                    color: ApTheme.of(context).greyText,
                    fontSize: 18.0,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
