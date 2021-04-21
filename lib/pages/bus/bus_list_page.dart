import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_remote_config_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/api/bus_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/bus_info.dart';
import 'package:nsysu_ap/pages/bus/bus_time_page.dart';

enum _State { loading, finish, error }

class BusListPage extends StatefulWidget {
  final Locale locale;

  const BusListPage({Key key, this.locale}) : super(key: key);

  @override
  _BusListPageState createState() => _BusListPageState();
}

class _BusListPageState extends State<BusListPage> {
  _State state = _State.loading;

  List<BusInfo> busList;

  @override
  void initState() {
    _getData();
    FirebaseAnalyticsUtils.instance?.setCurrentScreen(
      "BusListPage",
      "bus_list_page.dart",
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ap = ApLocalizations.of(context);
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
        return ListView.builder(
          itemCount: busList.length,
          itemBuilder: (_, index) {
            final bus = busList[index];
            return ListTile(
              title: Text(bus.name),
              trailing: Text(
                bus.carId?.split(',')?.first ?? bus.carId ?? bus.stopName,
                style: TextStyle(
                  color: bus.carId == null ? Colors.red : Colors.green,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
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

  Future<void> _getDataByConfig() async {
    await Future.delayed(Duration(milliseconds: 100));
    final RemoteConfig remoteConfig = RemoteConfig.instance;
    try {
      await remoteConfig.fetch();
      await remoteConfig.activate();
    } catch (e) {}
    busList = BusInfo.fromRawList(
      remoteConfig.getString(Constants.BUS_INFO_DATA),
    );
    setState(() {});
  }

  Future<void> _getData() async {
    BusHelper.instance.getBusInfoList(
      locale: widget.locale,
      callback: GeneralCallback(
        onFailure: (_) {
          setState(() => state = _State.error);
        },
        onError: (_) {
          setState(() => state = _State.error);
        },
        onSuccess: (data) {
          busList = data;
          setState(() => state = _State.finish);
        },
      ),
    );
  }
}
