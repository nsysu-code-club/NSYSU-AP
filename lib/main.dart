import 'dart:async';
import 'dart:io';

import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
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
  await Firebase.initializeApp();
  if (FirebaseUtils.isSupportCrashlytics) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }
  runApp(MyApp());
}
