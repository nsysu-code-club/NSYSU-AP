import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/helper.dart';
import 'package:nsysu_ap/widgets/hint_content.dart';
import 'package:sprintf/sprintf.dart';

enum _State { loading, finish, error, empty }

class TuitionAndFeesPageRoute extends MaterialPageRoute {
  TuitionAndFeesPageRoute()
      : super(builder: (BuildContext context) => TuitionAndFeesPage());

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: TuitionAndFeesPage());
  }
}

class TuitionAndFeesPage extends StatefulWidget {
  @override
  _TuitionAndFeesPageState createState() => _TuitionAndFeesPageState();
}

class _TuitionAndFeesPageState extends State<TuitionAndFeesPage> {
  _State state = _State.loading;

  AppLocalizations app;

  List<TuitionAndFees> items;

  @override
  void initState() {
//TODO decide class name
    // FA.setCurrentScreen("LoginPage", "login_page.dart");
    _getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.tuitionAndFees),
        backgroundColor: Resource.Colors.blue,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (state) {
      case _State.loading:
        return Container(
            child: CircularProgressIndicator(), alignment: Alignment.center);
      case _State.error:
      case _State.empty:
        return FlatButton(
          onPressed: _getData,
          child: HintContent(
            icon: Icons.assignment,
            content: state == _State.error ? app.clickToRetry : app.busEmpty,
          ),
        );
      default:
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              state = _State.loading;
            });
            await _getData();
            FA.logAction('refresh', 'swipe');
            return null;
          },
          child: ListView.builder(
            itemBuilder: (context, index) {
              return _notificationItem(items[index]);
            },
            itemCount: items.length,
          ),
        );
    }
  }

  Widget _notificationItem(TuitionAndFees item) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            item.title,
            style: TextStyle(fontSize: 18.0),
          ),
          trailing: Text(
            '${item.paymentStatus}',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.green,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              sprintf(
                app.tuitionAndFeesItemTitleFormat,
                [
                  item.amount,
                  item.dateOfPayment,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Null> _getData() async {
    List<TuitionAndFees> data = await Helper.instance.getTfData();
    setState(() {
      if (data == null) {
        setState(() {
          state = _State.empty;
        });
      } else {
        setState(() {
          state = _State.finish;
          items = data;
        });
      }
    });
  }
}