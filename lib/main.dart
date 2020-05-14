import 'dart:async';
import 'dart:io';

import 'package:ap_common/utils/preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isInDebugMode = Constants.isInDebugMode;
  HttpClient.enableTimelineLogging = isInDebugMode;
  await Preferences.init(
    key: Constants.key,
    iv: Constants.iv,
  );
  if (isInDebugMode || kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
    runApp(MyApp());
  } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    Crashlytics.instance.enableInDevMode = isInDebugMode;
    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = Crashlytics.instance.recordFlutterError;
    runZonedGuarded(() async {
      runApp(MyApp());
    }, Crashlytics.instance.recordError);
  }
}
