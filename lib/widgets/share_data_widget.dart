import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/app.dart';

class ShareDataWidget extends InheritedWidget {
  const ShareDataWidget({required this.data, required super.child});

  final MyAppState data;

  static ShareDataWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(ShareDataWidget oldWidget) {
    return true;
  }
}
