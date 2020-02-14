import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'package:nsysu_ap/config/constants.dart';

import 'app.dart';

void main() async {
  bool isInDebugMode = Constants.isInDebugMode;
  if (Platform.isIOS || Platform.isAndroid) {
    if (!Constants.isInDebugMode) {
      FlutterError.onError = (FlutterErrorDetails details) {
        if (isInDebugMode) {
          // In development mode simply print to console.
          FlutterError.dumpErrorToConsole(details);
        } else {
          // In production mode report to the application zone to report to
          // Crashlytics.
          Zone.current.handleUncaughtError(details.exception, details.stack);
        }
      };

      await FlutterCrashlytics().initialize();

      runZoned<Future<Null>>(() async {
        runApp(
          MyApp(),
        );
      }, onError: (error, stackTrace) async {
        // Whenever an error occurs, call the `reportCrash` function. This will send
        // Dart errors to our dev console or Crashlytics depending on the environment.
        await FlutterCrashlytics()
            .reportCrash(error, stackTrace, forceCrash: false);
      });
    } else {
      runApp(
        MyApp(),
      );
    }
  } else {
    // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    runApp(MyApp());
    //TODO add other platform Crashlytics
  }
}
