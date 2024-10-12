import 'dart:async';
import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ByteData data = await PlatformAssetBundle().load(
    'assets/ca/twca_nsysu.cer',
  );
  SecurityContext.defaultContext.setTrustedCertificatesBytes(
    data.buffer.asUint8List(),
  );

  /// Register all ap_common injection util
  registerOneForAll();

  await (PreferenceUtil.instance as ApPreferenceUtil).init(
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
      PreferenceUtil.instance.getString(Constants.prefCurrentVersion, '0');
  if (int.parse(currentVersion) < 700) _migrate700();
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );
  if (FirebaseUtils.isSupportCore || Platform.isWindows || Platform.isLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (kDebugMode) {
    if (FirebaseCrashlyticsUtils.isSupported) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
    if (FirebasePerformancesUtils.isSupported) {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(false);
    }
  }
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    GoogleSignInDart.register(
      clientId: SdkConstants.googleSignInDesktopClientId,
    );
  }

  if (!kDebugMode && FirebaseCrashlyticsUtils.isSupported) {
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };
  }
  runApp(MyApp());
}

void _migrate700() {
  CourseData.migrateFrom0_10();
  PreferenceUtil.instance.setBool(
    ApConstants.showCourseSearchButton,
    PreferenceUtil.instance.getBool(
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
