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
import 'package:flutter/services.dart';
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

      final ByteData data = await PlatformAssetBundle().load(
        'assets/ca/twca_nsysu.cer',
      );
      SecurityContext.defaultContext.setTrustedCertificatesBytes(
        data.buffer.asUint8List(),
      );

      await Preferences.init(
        key: Constants.key,
        iv: Constants.iv,
      );

      timeago.setLocaleMessages('zh-TW', timeago.ZhMessages());
      timeago.setLocaleMessages('en-US', timeago.EnMessages());
      if (!kIsWeb && Platform.isAndroid) {
        //TODO: 改使用原生方式限制特定網域
        HttpOverrides.global = MyHttpOverrides();
      }
      final String currentVersion =
          Preferences.getString(Constants.prefCurrentVersion, '0');
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
      Constants.prefIsShowCourseSearchButton,
      true,
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
