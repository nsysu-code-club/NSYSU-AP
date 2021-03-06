import 'dart:async';

import 'package:ap_common/config/ap_constants.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

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

  timeago.setLocaleMessages('zh-TW', timeago.ZhMessages());
  timeago.setLocaleMessages('en-US', timeago.EnMessages());
  final currentVersion =
      Preferences.getString(Constants.PREF_CURRENT_VERSION, '0');
  if (int.parse(currentVersion) < 700) _migrate700();
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

void _migrate700() {
  CourseData.migrateFrom0_10();
  Preferences.setBool(
    ApConstants.SHOW_COURSE_SEARCH_BUTTON,
    Preferences.getBool(
      Constants.PREF_IS_SHOW_COURSE_SEARCH_BUTTON,
      true,
    ),
  );
}
