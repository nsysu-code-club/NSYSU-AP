import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nsysu_ap/app.dart';

class ShareDataWidget extends InheritedWidget {
  final MyAppState data;

  const ShareDataWidget(this.data, {required super.child});

  static ShareDataWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(ShareDataWidget oldWidget) {
    return true;
  }
}
