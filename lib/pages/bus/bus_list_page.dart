// ignore_for_file: prefer_single_quotes

import 'package:ap_common/ap_common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/bus_helper.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/pages/bus/bus_time_page.dart';

enum _State { loading, finish, error }

class BusListPage extends StatefulWidget {
  final Locale locale;

  const BusListPage({
    super.key,
    required this.locale,
  });

  @override
  _BusListPageState createState() => _BusListPageState();
}

class _BusListPageState extends State<BusListPage> {
  _State state = _State.loading;

  List<BusInfo> busList = <BusInfo>[];

  @override
  void initState() {
    _getData();
    AnalyticsUtil.instance.setCurrentScreen(
      'BusListPage',
      "bus_list_page.dart",
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ApLocalizations ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.bus),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (state) {
      case _State.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case _State.error:
        return InkWell(
          onTap: () {
            _getData();
          },
          child: HintContent(
            icon: ApIcon.error,
            content: ApLocalizations.current.clickToRetry,
          ),
        );
      default:
        return ListView.builder(
          itemCount: busList.length,
          itemBuilder: (_, int index) {
            final BusInfo bus = busList[index];
            return ListTile(
              title: Text(bus.name),
              trailing: Text(
                bus.carId?.split(',').first ?? bus.carId ?? bus.stopName,
                style: TextStyle(
                  color: bus.carId == null ? Colors.red : Colors.green,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute<dynamic>(
                    builder: (_) => BusTimePage(
                      busInfo: bus,
                      locale: widget.locale,
                    ),
                  ),
                );
              },
            );
          },
        );
    }
  }

  Future<void> _getData() async {
    BusHelper.instance.getBusInfoList(
      locale: widget.locale,
      callback: GeneralCallback<List<BusInfo>?>(
        onFailure: (_) {
          setState(() => state = _State.error);
        },
        onError: (_) {
          setState(() => state = _State.error);
        },
        onSuccess: (List<BusInfo>? data) {
          busList = data ?? <BusInfo>[];
          setState(() => state = _State.finish);
        },
      ),
    );
  }
}
