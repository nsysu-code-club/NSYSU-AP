import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/car_park_area.dart';
import '../../models/tow_car_alert_data.dart';
import '../../utils/app_localizations.dart';

class TowCarContentPage extends StatefulWidget {
  final List<CarParkArea> carParkAreas;
  final TowCarAlert towCarAlert;

  const TowCarContentPage({
    Key key,
    @required this.carParkAreas,
    @required this.towCarAlert,
  }) : super(key: key);

  @override
  _TowCarContentPageState createState() => _TowCarContentPageState();
}

class _TowCarContentPageState extends State<TowCarContentPage> {
  final dateFormat = DateFormat('yyyy/MM/dd\na hh:mm');

  AppLocalizations app;

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
    app = AppLocalizations.of(context);
    int index = widget.carParkAreas.indexWhere(
      (element) => element.fcmTopic == widget.towCarAlert.topic,
    );
    String location = widget.carParkAreas[index].name;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.towCarAlertReport),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.towCarAlert.hashCode,
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
                      location,
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
                            "${widget.towCarAlert.viewCounts ?? 0}",
                            style: _subContentStyle,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            app.viewCounts,
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
                            widget.towCarAlert.time == null
                                ? app.unknownTime
                                : dateFormat.format(widget.towCarAlert.time),
                            style: _subContentStyle,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            app.publishTime,
                            style: _subTitleStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Text(
                  app.alertContent,
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
