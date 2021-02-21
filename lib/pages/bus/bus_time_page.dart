import 'dart:async';

import 'package:ap_common/api/announcement_helper.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/bus_helper.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/models/bus_time.dart';

enum _State { loading, finish, error }

class BusTimePage extends StatefulWidget {
  final Locale locale;
  final BusInfo busInfo;

  const BusTimePage({Key key, this.busInfo, this.locale}) : super(key: key);

  @override
  _BusTimePageState createState() => _BusTimePageState();
}

class _BusTimePageState extends State<BusTimePage>
    with SingleTickerProviderStateMixin {
  _State state = _State.loading;

  List<BusTime> startList = [];
  List<BusTime> endList = [];

  TabController _tabController;

  Timer timer;

  @override
  void initState() {
    _tabController = TabController(
      vsync: this,
      length: 2,
    );
    _getData();
    timer = Timer.periodic(
      Duration(seconds: 10),
      (timer) {
        _getData();
      },
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
    final busInfo = widget.busInfo;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.busInfo.name),
        backgroundColor: ApTheme.of(context).blue,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: busInfo.departure ?? '',
            ),
            Tab(
              text: busInfo.destination ?? '',
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
        return Center(
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
        return TabBarView(
          controller: _tabController,
          children: <Widget>[
            ListView.separated(
              itemCount: startList.length,
              separatorBuilder: (_, __) => Divider(height: 1.0),
              itemBuilder: (_, index) => BusTimeItem(
                busTime: startList[index],
              ),
            ),
            ListView.separated(
              itemCount: endList.length,
              separatorBuilder: (_, __) => Divider(height: 1.0),
              itemBuilder: (_, index) => BusTimeItem(
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
      callback: GeneralCallback(
        onFailure: (_) {
          setState(() => state = _State.error);
        },
        onError: (_) {
          setState(() => state = _State.error);
        },
        onSuccess: (data) {
          startList.clear();
          endList.clear();
          data.forEach((element) {
            if (element.isGoBack == 'Y')
              endList.add(element);
            else
              startList.add(element);
          });
          setState(() => state = _State.finish);
        },
      ),
    );
  }
}

class BusTimeItem extends StatelessWidget {
  final BusTime busTime;

  const BusTimeItem({
    Key key,
    this.busTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.0,
            color: busTime.arrivedTime == '進站中'
                ? Colors.red
                : ApTheme.of(context).greyText,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(16.0),
          ),
        ),
        padding: EdgeInsets.all(8.0),
        child: Text(
          busTime.arrivedTime,
          style: TextStyle(
            color: busTime.arrivedTime == '進站中'
                ? Colors.red
                : ApTheme.of(context).greyText,
          ),
        ),
      ),
      title: Text(busTime.name ?? ''),
    );
  }
}
