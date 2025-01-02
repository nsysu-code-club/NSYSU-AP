import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:nsysu_ap/models/tuition_and_fees.dart';

class TuitionParser {
  List<TuitionAndFees> tuitionAndFeeList(String text) {
    if (text.contains('沒有合乎查詢條件的資料')) {
      return <TuitionAndFees>[];
    }
    final Document document = parse(text, encoding: 'BIG-5');
    final List<Element> tbody = document.getElementsByTagName('tbody');
    final List<TuitionAndFees> list = <TuitionAndFees>[];
    final List<Element> trElements = tbody[1].getElementsByTagName('tr');
    for (int i = 1; i < trElements.length; i++) {
      final List<Element> tdDoc = trElements[i].getElementsByTagName('td');
      final List<Element> aTag = tdDoc[4].getElementsByTagName('a');
      String? serialNumber;
      if (aTag.isNotEmpty) {
        serialNumber = aTag[0]
            .attributes['onclick']!
            .split("javascript:window.location.href='")
            .last;
        serialNumber = serialNumber.substring(0, serialNumber.length - 1);
      }
      String paymentStatus = '';
      String paymentStatusEn = '';
      for (final int charCode in tdDoc[2].text.codeUnits) {
        if (charCode < 200) {
          if (charCode == 32) {
            paymentStatusEn += '\n';
          } else {
            paymentStatusEn += String.fromCharCode(charCode);
          }
        } else {
          paymentStatus += String.fromCharCode(charCode);
        }
      }
      final String titleEN = tdDoc[0].getElementsByTagName('span')[0].text;
      list.add(
        TuitionAndFees(
          titleZH: tdDoc[0].text.replaceAll(titleEN, ''),
          titleEN: titleEN,
          amount: tdDoc[1].text,
          paymentStatusZH: paymentStatus,
          paymentStatusEN: paymentStatusEn,
          dateOfPayment: tdDoc[3].text,
          serialNumber: serialNumber ?? '',
        ),
      );
    }
    return list.reversed.toList();
  }
}
