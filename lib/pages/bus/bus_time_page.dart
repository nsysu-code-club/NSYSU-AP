import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/bus_helper.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

enum _State { loading, finish, error }

class BusTimePage extends StatefulWidget {
  final Locale locale;
  final BusInfo busInfo;

  const BusTimePage({
    super.key,
    required this.busInfo,
    required this.locale,
  });

  @override
  _BusTimePageState createState() => _BusTimePageState();
}

class _BusTimePageState extends State<BusTimePage>
    with SingleTickerProviderStateMixin {
  _State state = _State.loading;

  List<BusTime> startList = <BusTime>[];
  List<BusTime> endList = <BusTime>[];

  TabController? _tabController;

  Timer? timer;

  @override
  void initState() {
    _tabController = TabController(
      vsync: this,
      length: 2,
    );
    _getData();
    timer = Timer.periodic(
      const Duration(seconds: 10),
      (Timer timer) {
        _getData();
      },
    );
    AnalyticsUtil.instance.setCurrentScreen(
      'BusTimePage',
      'bus_time_page.dart',
    );
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BusInfo busInfo = widget.busInfo;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.busInfo.name),
        backgroundColor: ApTheme.of(context).blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              text: busInfo.departure,
            ),
            Tab(
              text: busInfo.destination,
            ),
          ],
        ),
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
        return startList.isEmpty && startList.isEmpty
            ? InkWell(
                onTap: () => _getData(),
                child: HintContent(
                  icon: ApIcon.info,
                  content: ApLocalizations.of(context).busEmpty,
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  ListView.separated(
                    itemCount: startList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1.0),
                    itemBuilder: (_, int index) => BusTimeItem(
                      busTime: startList[index],
                      locale: widget.locale,
                    ),
                  ),
                  ListView.separated(
                    itemCount: endList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1.0),
                    itemBuilder: (_, int index) => BusTimeItem(
                      busTime: endList[index],
                      locale: widget.locale,
                    ),
                  ),
                ],
              );
    }
  }

  Future<void> _getData() async {
    try {
      final List<BusTime> data = await BusHelper.instance.getBusTime(
        locale: widget.locale,
        busInfo: widget.busInfo,
      );
      startList.clear();
      endList.clear();
      for (final BusTime element in data) {
        if (element.isGoBack == 'Y') {
          endList.add(element);
        } else {
          startList.add(element);
        }
      }
      if (mounted) setState(() => state = _State.finish);
    } catch (_) {
      if (mounted) setState(() => state = _State.error);
    }
  }
}

class BusTimeItem extends StatelessWidget {
  final BusTime busTime;
  final Locale locale;

  const BusTimeItem({
    super.key,
    required this.busTime,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = locale.languageCode.contains('en');
    final String postfix = int.tryParse(busTime.arrivedTime ?? '') == null
        ? ''
        : ' ${AppLocalizations.of(context).minute}';
    String arrivedTimeText = '';
    double? fontSize;
    Color color = ApTheme.of(context).greyText;
    if (busTime.arrivedTime != null) {
      arrivedTimeText = busTime.arrivedTime!;
      switch (busTime.arrivedTime) {
        case '進站中':
          if (isEnglish) {
            arrivedTimeText = 'Arriving';
          }
          color = Colors.red;
        case '將到站':
          if (isEnglish) {
            arrivedTimeText = 'Coming\nSoon';
            fontSize = 12.0;
          }
          color = Colors.green;
        default:
          break;
      }
    } else {
      if (isEnglish) {
        arrivedTimeText = 'Departed';
        fontSize = 12.0;
      } else {
        arrivedTimeText = '已離站';
      }
    }
    return ListTile(
      leading: Container(
        height: 40.0,
        width: 72.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(32.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          '$arrivedTimeText$postfix',
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(busTime.name),
    );
  }
}
