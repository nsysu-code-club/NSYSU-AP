import 'dart:async';
import 'dart:io';

import 'package:ap_common/config/ap_constants.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firebase/utils/firebase_crashlytics_utils.dart';
import 'package:ap_common_firebase/utils/firebase_performance_utils.dart';
import 'package:ap_common_firebase/utils/firebase_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:nsysu_ap/app.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/config/sdk_constants.dart';
import 'package:nsysu_ap/firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Preferences.init(
        key: Constants.key,
        iv: Constants.iv,
      );

      timeago.setLocaleMessages('zh-TW', timeago.ZhMessages());
      timeago.setLocaleMessages('en-US', timeago.EnMessages());
      final String currentVersion =
          Preferences.getString(Constants.PREF_CURRENT_VERSION, '0');
      if (int.parse(currentVersion) < 700) _migrate700();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      if (FirebaseUtils.isSupportCore ||
          Platform.isWindows ||
          Platform.isLinux) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (kDebugMode) {
        if (FirebaseCrashlyticsUtils.isSupported) {
          await FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(false);
        }
        if (FirebasePerformancesUtils.isSupported) {
          await FirebasePerformance.instance
              .setPerformanceCollectionEnabled(false);
        }
      }
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        GoogleSignInDart.register(
          clientId: SdkConstants.googleSignInDesktopClientId,
        );
      }
      if (!kDebugMode && FirebaseCrashlyticsUtils.isSupported) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      }
      runApp(MyApp());
    },
    (Object e, StackTrace s) {
      if (!kDebugMode && FirebaseCrashlyticsUtils.isSupported) {
        FirebaseCrashlytics.instance.recordError(e, s);
      } else {
        throw e;
      }
    },
  );
}

void _migrate700() {
  CourseData.migrateFrom0_10();
  Preferences.setBool(
    ApConstants.showCourseSearchButton,
    Preferences.getBool(
      Constants.PREF_IS_SHOW_COURSE_SEARCH_BUTTON,
      true,
    ),
  );
}
