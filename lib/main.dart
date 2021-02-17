import 'dart:async';
import 'dart:io';

import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';

import 'app.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init(
    key: Constants.key,
    iv: Constants.iv,
  );
  final currentVersion =
      Preferences.getString(Constants.PREF_CURRENT_VERSION, '0');
  if (int.parse(currentVersion) < 700) CourseData.migrateFrom0_10();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (FirebaseUtils.isSupportCore) await Firebase.initializeApp();
  if (!kDebugMode && FirebaseUtils.isSupportCrashlytics) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    runZonedGuarded(() {
      runApp(MyApp());
    }, (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    });
  } else
    runApp(MyApp());
}
