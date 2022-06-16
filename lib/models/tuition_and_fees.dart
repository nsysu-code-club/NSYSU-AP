import 'package:ap_common/utils/ap_localizations.dart';

class TuitionAndFees {
  final String titleZH;
  final String titleEN;
  final String amount;
  final String paymentStatusZH;
  final String paymentStatusEN;
  final String dateOfPayment;
  final String serialNumber;

  TuitionAndFees({
    this.titleZH,
    this.titleEN,
    this.amount,
    this.paymentStatusZH,
    this.paymentStatusEN,
    this.dateOfPayment,
    this.serialNumber,
  });

  String get title {
    switch (Intl.defaultLocale) {
      case 'zh':
        return titleZH;
      default:
        return titleEN;
    }
  }

  String get paymentStatus {
    switch (Intl.defaultLocale) {
      case 'zh':
        return paymentStatusZH;
      default:
        return paymentStatusEN;
    }
  }

  bool get isPayment =>
      paymentStatus.contains('繳費成功') || paymentStatus.contains('completed');
}
