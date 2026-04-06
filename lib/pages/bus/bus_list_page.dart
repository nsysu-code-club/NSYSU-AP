// ignore_for_file: prefer_single_quotes

import 'package:ap_common/ap_common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/bus_helper.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/pages/bus/bus_time_page.dart';

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
  DataState<List<BusInfo>> state = const DataLoading<List<BusInfo>>();

  List<BusInfo> get busList => state.dataOrNull ?? <BusInfo>[];

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
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.bus),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (String? hint) => InkWell(
        onTap: () {
          _getData();
        },
        child: HintContent(
          icon: ApIcon.error,
          content: ap.clickToRetry,
        ),
      ),
      empty: (String? hint) => HintContent(
        icon: ApIcon.info,
        content: ap.busEmpty,
      ),
      loaded: (List<BusInfo> data, String? hint) => ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, int index) {
          final BusInfo bus = data[index];
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
      ),
    );
  }

  Future<void> _getData() async {
    final ApiResult<List<BusInfo>?> result =
        await BusHelper.instance.getBusInfoList(locale: widget.locale);
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<BusInfo>?>(:final List<BusInfo>? data):
        final List<BusInfo> list = data ?? <BusInfo>[];
        setState(() {
          if (list.isEmpty) {
            state = const DataEmpty<List<BusInfo>>();
          } else {
            state = DataLoaded<List<BusInfo>>(list);
          }
        });
      case ApiFailure<List<BusInfo>?>():
        setState(() => state = const DataError<List<BusInfo>>());
      case ApiError<List<BusInfo>?>():
        setState(() => state = const DataError<List<BusInfo>>());
    }
  }
}
