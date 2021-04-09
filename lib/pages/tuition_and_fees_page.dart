import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/pdf_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/api/tuition_helper.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common/widgets/progress_dialog.dart';
import 'package:sprintf/sprintf.dart';

enum _State { loading, finish, error, empty }

class TuitionAndFeesPage extends StatefulWidget {
  const TuitionAndFeesPage({Key key}) : super(key: key);

  @override
  _TuitionAndFeesPageState createState() => _TuitionAndFeesPageState();
}

class _TuitionAndFeesPageState extends State<TuitionAndFeesPage> {
  ApLocalizations ap;
  AppLocalizations app;

  _State state = _State.loading;

  List<TuitionAndFees> items;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("TuitionAndFeesPage", "tuition_and_fees_page.dart");
    if (TuitionHelper.instance.isLogin)
      _getData();
    else
      _login();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.tuitionAndFees),
        backgroundColor: ApTheme.of(context).blue,
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
        return InkWell(
          onTap: _getData,
          child: HintContent(
            icon: Icons.assignment,
            content: state == _State.error
                ? ApLocalizations.of(context).clickToRetry
                : app.tuitionAndFeesEmpty,
          ),
        );
      default:
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              state = _State.loading;
            });
            await _getData();
            FirebaseAnalyticsUtils.instance.logAction('refresh', 'swipe');
            return null;
          },
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              if (index == 0)
                return Text(
                  app.tuitionAndFeesPageHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ApTheme.of(context).grey),
                );
              else
                return _notificationItem(items[index - 1]);
            },
            itemCount: items.length + 1,
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
              color: item.isPayment ? Colors.green : Colors.red,
            ),
          ),
          onTap: () async {
            showDialog(
              context: context,
              builder: (BuildContext context) => WillPopScope(
                  child: ProgressDialog(ap.loading),
                  onWillPop: () async {
                    return false;
                  }),
              barrierDismissible: false,
            );
            TuitionHelper.instance.downloadFdf(
              serialNumber: item.serialNumber,
              callback: GeneralCallback(
                onError: (GeneralResponse e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ApUtils.showToast(
                    context,
                    ApLocalizations.of(context).somethingError,
                  );
                },
                onFailure: (DioError e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ApUtils.showToast(
                    context,
                    e.i18nMessage,
                  );
                },
                onSuccess: (data) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ApUtils.pushCupertinoStyle(
                    context,
                    PdfScaffold(
                      state: PdfState.finish,
                      data: data,
                    ),
                  );
                },
              ),
            );
          },
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

  Function get _onFailure => (DioError e) => setState(() {
        state = _State.error;
        switch (e.type) {
          case DioErrorType.connectTimeout:
          case DioErrorType.sendTimeout:
          case DioErrorType.receiveTimeout:
          case DioErrorType.response:
          case DioErrorType.cancel:
            break;
          case DioErrorType.other:
            throw e;
            break;
        }
      });

  Function get _onError => (_) => setState(() => state = _State.error);

  _login() {
    TuitionHelper.instance.login(
      username: SelcrsHelper.instance.username,
      password: SelcrsHelper.instance.password,
      callback: GeneralCallback(
        onFailure: _onFailure,
        onError: _onError,
        onSuccess: (GeneralResponse data) {
          _getData();
        },
      ),
    );
  }

  Future<Null> _getData() async {
    TuitionHelper.instance.getData(
      callback: GeneralCallback(
        onFailure: _onFailure,
        onError: _onError,
        onSuccess: (List<TuitionAndFees> data) {
          items = data;
          if (mounted && items != null)
            setState(() {
              if (items.length == 0)
                state = _State.empty;
              else
                state = _State.finish;
            });
        },
      ),
    );
  }
}
