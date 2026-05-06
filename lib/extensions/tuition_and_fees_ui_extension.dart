import 'package:nsysu_crawler/nsysu_crawler.dart';

import 'package:nsysu_ap/utils/app_localizations.dart';

extension TuitionAndFeesUiExtension on TuitionAndFees {
  String get title =>
      LocaleSettings.currentLocale == AppLocale.zhHantTw ? titleZH : titleEN;

  String get paymentStatus => LocaleSettings.currentLocale == AppLocale.zhHantTw
      ? paymentStatusZH
      : paymentStatusEN;

  bool get isPayment =>
      paymentStatus.contains('繳費成功') || paymentStatus.contains('completed');
}
