// ignore_for_file: unnecessary_string_interpolations

import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/exception/tuition_login_exception.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/api/tuition_helper.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:sprintf/sprintf.dart';

enum _State { loading, finish, error, empty }

class TuitionAndFeesPage extends StatefulWidget {
  const TuitionAndFeesPage({super.key});

  @override
  _TuitionAndFeesPageState createState() => _TuitionAndFeesPageState();
}

class _TuitionAndFeesPageState extends State<TuitionAndFeesPage> {
  late ApLocalizations ap;
  late AppLocalizations app;

  _State state = _State.loading;

  List<TuitionAndFees> items = <TuitionAndFees>[];

  @override
  void initState() {
    AnalyticsUtil.instance
        .setCurrentScreen('TuitionAndFeesPage', 'tuition_and_fees_page.dart');
    if (TuitionHelper.instance.isLogin) {
      _getData();
    } else {
      _login();
    }
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
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
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
            AnalyticsUtil.instance.logEvent('t_and_f_refresh');
            return;
          },
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Text(
                  app.tuitionAndFeesPageHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ApTheme.of(context).grey),
                );
              } else {
                return _notificationItem(items[index - 1]);
              }
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
            style: const TextStyle(fontSize: 18.0),
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
              builder: (BuildContext context) => PopScope(
                canPop: false,
                child: ProgressDialog(ap.loading),
              ),
              barrierDismissible: false,
            );
            try {
              final Uint8List? data = await TuitionHelper.instance.downloadFdf(
                serialNumber: item.serialNumber,
              );
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              ApUtils.pushCupertinoStyle(
                context,
                PdfView(
                  state: PdfState.finish,
                  data: data,
                ),
              );
            } on Exception catch (e) {
              switch (e) {
                case DioException():
                  Navigator.of(context, rootNavigator: true).pop();
                  if (e.i18nMessage case final String message?) {
                    UiUtil.instance.showToast(
                      context,
                      message,
                    );
                  }
                case GeneralResponse():
                  Navigator.of(context, rootNavigator: true).pop();
                  UiUtil.instance.showToast(
                    context,
                    ApLocalizations.of(context).somethingError,
                  );
              }
            }
          },
          subtitle: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              sprintf(
                app.tuitionAndFeesItemTitleFormat,
                <String>[
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

  Future<void> _login() async {
    try {
      final GeneralResponse _ = await TuitionHelper.instance.login(
        username: SelcrsHelper.instance.username,
        password: SelcrsHelper.instance.password,
      );
      _getData();
    } on TuitionLoginException catch (_) {
      setState(() {
        state = _State.error;
      });
    } catch (e, s) {
      setState(() {
        switch (e) {
          case DioException():
            state = _State.error;
            if (e.type == DioExceptionType.unknown) {
              CrashlyticsUtil.instance.recordError(e, s);
            }
          case GeneralResponse():
            state = _State.error;
        }
      });
    }
  }

  Future<void> _getData() async {
    try {
      final List<TuitionAndFees> data = await TuitionHelper.instance.getData();
      items = data;
      if (mounted) {
        setState(() {
          if (items.isEmpty) {
            state = _State.empty;
          } else {
            state = _State.finish;
          }
        });
      }
    } catch (e, s) {
      setState(() {
        switch (e) {
          case DioException():
            state = _State.error;
            if (e.type == DioExceptionType.unknown) {
              CrashlyticsUtil.instance.recordError(e, s);
            }
          case GeneralResponse():
            state = _State.error;
        }
      });
    }
  }
}
