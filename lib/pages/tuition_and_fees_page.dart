// ignore_for_file: unnecessary_string_interpolations

import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/api/tuition_helper.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class TuitionAndFeesPage extends StatefulWidget {
  const TuitionAndFeesPage({super.key});

  @override
  _TuitionAndFeesPageState createState() => _TuitionAndFeesPageState();
}

class _TuitionAndFeesPageState extends State<TuitionAndFeesPage> {
  DataState<List<TuitionAndFees>> state =
      const DataLoading<List<TuitionAndFees>>();

  List<TuitionAndFees> get items => state.dataOrNull ?? <TuitionAndFees>[];

  @override
  void initState() {
    AnalyticsUtil.instance.setCurrentScreen(
      'TuitionAndFeesPage',
      'tuition_and_fees_page.dart',
    );
    if (TuitionHelper.instance.isLogin) {
      _getData();
    } else {
      _login();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(app.tuitionAndFees)),
      body: _body(),
    );
  }

  Widget _body() {
    return state.when(
      loading: () => Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (String? hint) => InkWell(
        onTap: _getData,
        child: HintContent(
          icon: Icons.assignment,
          content: ap.clickToRetry,
        ),
      ),
      empty: (String? hint) => InkWell(
        onTap: _getData,
        child: HintContent(
          icon: Icons.assignment,
          content: app.tuitionAndFeesEmpty,
        ),
      ),
      loaded: (List<TuitionAndFees> data, String? hint) => RefreshIndicator(
        onRefresh: () async {
          setState(() {
            state = const DataLoading<List<TuitionAndFees>>();
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              );
            } else {
              return _notificationItem(data[index - 1]);
            }
          },
          itemCount: data.length + 1,
        ),
      ),
    );
  }

  Widget _notificationItem(TuitionAndFees item) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(item.title, style: const TextStyle(fontSize: 18.0)),
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
              builder: (BuildContext context) =>
                  PopScope(canPop: false, child: ProgressDialog(ap.loading)),
              barrierDismissible: false,
            );
            final ApiResult<Uint8List?> result =
                await TuitionHelper.instance.downloadFdf(
              serialNumber: item.serialNumber,
            );
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop();
            switch (result) {
              case ApiSuccess<Uint8List?>(:final Uint8List? data):
                ApUtils.pushCupertinoStyle(
                  context,
                  PdfView(state: PdfState.finish, data: data),
                );
              case ApiFailure<Uint8List?>(:final DioException exception):
                if (exception.i18nMessage != null) {
                  UiUtil.instance.showToast(context, exception.i18nMessage!);
                }
              case ApiError<Uint8List?>():
                UiUtil.instance.showToast(
                  context,
                  ap.somethingError,
                );
            }
          },
          subtitle: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              app.tuitionAndFeesItemTitleFormat(
                amount: item.amount,
                date: item.dateOfPayment,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final ApiResult<GeneralResponse> result =
        await TuitionHelper.instance.login(
      username: SelcrsHelper.instance.username,
      password: SelcrsHelper.instance.password,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<GeneralResponse>():
        _getData();
      case ApiFailure<GeneralResponse>():
        setState(() => state = const DataError<List<TuitionAndFees>>());
      case ApiError<GeneralResponse>():
        setState(() => state = const DataError<List<TuitionAndFees>>());
    }
  }

  Future<void> _getData() async {
    final ApiResult<List<TuitionAndFees>> result =
        await TuitionHelper.instance.getData();
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<TuitionAndFees>>(:final List<TuitionAndFees> data):
        setState(() {
          if (data.isEmpty) {
            state = const DataEmpty<List<TuitionAndFees>>();
          } else {
            state = DataLoaded<List<TuitionAndFees>>(data);
          }
        });
      case ApiFailure<List<TuitionAndFees>>():
        setState(() => state = const DataError<List<TuitionAndFees>>());
      case ApiError<List<TuitionAndFees>>():
        setState(() => state = const DataError<List<TuitionAndFees>>());
    }
  }
}
