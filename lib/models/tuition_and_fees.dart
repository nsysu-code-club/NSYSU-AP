import 'package:intl/intl.dart';

class TuitionAndFees {
  final String titleZH;
  final String titleEN;
  final String amount;
  final String paymentStatusZH;
  final String paymentStatusEN;
  final String dateOfPayment;
  final String serialNumber;

  TuitionAndFees({
    required this.titleZH,
    required this.titleEN,
    required this.amount,
    required this.paymentStatusZH,
    required this.paymentStatusEN,
    required this.dateOfPayment,
    required this.serialNumber,
  });

  String get title {
    if (Intl.defaultLocale!.contains('zh')) {
      return titleZH;
    } else {
      return titleEN;
    }
  }

  String get paymentStatus {
    if (Intl.defaultLocale!.contains('zh')) {
      return paymentStatusZH;
    } else {
      return paymentStatusEN;
    }
  }

  bool get isPayment =>
      paymentStatus.contains('繳費成功') || paymentStatus.contains('completed');
}
