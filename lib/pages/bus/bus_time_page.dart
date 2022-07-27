import 'dart:async';

import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
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
    Key? key,
    required this.busInfo,
    required this.locale,
  }) : super(key: key);

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
    FirebaseAnalyticsUtils.instance.setCurrentScreen(
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
                    ),
                  ),
                  ListView.separated(
                    itemCount: endList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1.0),
                    itemBuilder: (_, int index) => BusTimeItem(
                      busTime: endList[index],
                    ),
                  )
                ],
              );
    }
  }

  void _getData() {
    BusHelper.instance.getBusTime(
      locale: widget.locale,
      busInfo: widget.busInfo,
      callback: GeneralCallback<List<BusTime>?>(
        onFailure: (_) {
          if (mounted) setState(() => state = _State.error);
        },
        onError: (_) {
          if (mounted) setState(() => state = _State.error);
        },
        onSuccess: (List<BusTime>? data) {
          startList.clear();
          endList.clear();
          for (final BusTime element in data!) {
            if (element.isGoBack == 'Y') {
              endList.add(element);
            } else {
              startList.add(element);
            }
          }
          if (mounted) setState(() => state = _State.finish);
        },
      ),
    );
  }
}

class BusTimeItem extends StatelessWidget {
  final BusTime busTime;

  const BusTimeItem({
    Key? key,
    required this.busTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String postfix = int.tryParse(busTime.arrivedTime) == null
        ? ''
        : ' ${AppLocalizations.of(context).minute}';
    final bool isComing =
        busTime.arrivedTime == '進站中' || busTime.arrivedTime == '將到站';
    return ListTile(
      leading: Container(
        constraints: const BoxConstraints(
          minWidth: 65.0,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isComing ? Colors.red : ApTheme.of(context).greyText,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(16.0),
          ),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '${busTime.arrivedTime}$postfix',
          style: TextStyle(
            color: isComing ? Colors.red : ApTheme.of(context).greyText,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(busTime.name),
    );
  }
}
