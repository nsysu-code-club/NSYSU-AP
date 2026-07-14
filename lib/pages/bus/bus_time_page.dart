import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class BusTimePage extends StatefulWidget {
  final Locale locale;
  final BusInfo busInfo;

  const BusTimePage({super.key, required this.busInfo, required this.locale});

  @override
  _BusTimePageState createState() => _BusTimePageState();
}

class _BusTimePageState extends State<BusTimePage>
    with SingleTickerProviderStateMixin {
  DataState<(List<BusTime>, List<BusTime>)> state =
      const DataLoading<(List<BusTime>, List<BusTime>)>();

  List<BusTime> get startList => state.dataOrNull?.$1 ?? <BusTime>[];
  List<BusTime> get endList => state.dataOrNull?.$2 ?? <BusTime>[];

  TabController? _tabController;

  Timer? timer;
  bool _isFetching = false;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 2);
    _getData();
    timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _getData();
    });
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
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(text: busInfo.departure),
            Tab(text: busInfo.destination),
          ],
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (String? hint) => InkWell(
        onTap: () {
          _getData();
        },
        child: HintContent(icon: ApIcon.error, content: ap.clickToRetry),
      ),
      empty: (String? hint) => InkWell(
        onTap: () => _getData(),
        child: HintContent(icon: ApIcon.info, content: ap.busEmpty),
      ),
      loaded: ((List<BusTime>, List<BusTime>) data, String? hint) => TabBarView(
        controller: _tabController,
        children: <Widget>[
          ListView.separated(
            itemCount: data.$1.length,
            separatorBuilder: (_, _) => const Divider(height: 1.0),
            itemBuilder: (_, int index) => BusTimeItem(busTime: data.$1[index]),
          ),
          ListView.separated(
            itemCount: data.$2.length,
            separatorBuilder: (_, _) => const Divider(height: 1.0),
            itemBuilder: (_, int index) => BusTimeItem(busTime: data.$2[index]),
          ),
        ],
      ),
    );
  }

  Future<void> _getData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final ApiResult<List<BusTime>?> result = await BusHelper.instance
          .getBusTime(
            languageCode: widget.locale.languageCode.contains('zh')
                ? 'zh'
                : 'en',
            busInfo: widget.busInfo,
          );
      if (!mounted) return;
      switch (result) {
        case ApiSuccess<List<BusTime>?>(:final List<BusTime>? data):
          final List<BusTime> starts = <BusTime>[];
          final List<BusTime> ends = <BusTime>[];
          for (final BusTime element in data ?? <BusTime>[]) {
            if (element.direction == BusDirection.back) {
              ends.add(element);
            } else {
              starts.add(element);
            }
          }
          setState(() {
            if (starts.isEmpty && ends.isEmpty) {
              state = const DataEmpty<(List<BusTime>, List<BusTime>)>();
            } else {
              state = DataLoaded<(List<BusTime>, List<BusTime>)>((
                starts,
                ends,
              ));
            }
          });
        case ApiFailure<List<BusTime>?>():
          setState(
            () => state = const DataError<(List<BusTime>, List<BusTime>)>(),
          );
        case ApiError<List<BusTime>?>():
          setState(
            () => state = const DataError<(List<BusTime>, List<BusTime>)>(),
          );
      }
    } finally {
      _isFetching = false;
    }
  }
}

class BusTimeItem extends StatelessWidget {
  final BusTime busTime;

  const BusTimeItem({super.key, required this.busTime});

  @override
  Widget build(BuildContext context) {
    String arrivedTimeText;
    double? fontSize;
    Color color = Theme.of(context).colorScheme.onSurfaceVariant;
    switch (busTime.arrivalStatus) {
      case BusArrivalStatus.arriving:
        arrivedTimeText = app.busArriving;
        color = Colors.red;
      case BusArrivalStatus.comingSoon:
        arrivedTimeText = app.busComingSoon;
        color = Colors.green;
      case BusArrivalStatus.minutes:
        arrivedTimeText = '${busTime.etaMinutes ?? 0} ${app.minute}';
      case BusArrivalStatus.scheduled:
        arrivedTimeText = app.busScheduledTime(
          time: busTime.scheduledTime ?? '',
        );
        color = Theme.of(context).colorScheme.primary;
        fontSize = 12.0;
      case BusArrivalStatus.departed:
        arrivedTimeText = app.busDeparted;
        fontSize = 12.0;
      case BusArrivalStatus.notOperating:
        arrivedTimeText = app.busNotOperating;
        color = Theme.of(context).colorScheme.outline;
        fontSize = 12.0;
    }
    return ListTile(
      leading: Container(
        height: 40.0,
        width: 72.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: const BorderRadius.all(Radius.circular(32.0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          arrivedTimeText,
          style: TextStyle(fontSize: fontSize, color: color),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(busTime.name),
    );
  }
}
