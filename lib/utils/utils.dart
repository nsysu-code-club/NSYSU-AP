import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/pages/comfirm_form_page.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static Future<void> openConfirmForm(
    BuildContext context, {
    required bool mounted,
    required String username,
  }) async {
    String confirmFormUrl = '';
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      confirmFormUrl = remoteConfig.getString(Constants.confirmFormUrl);
      PreferenceUtil.instance.getString(
        Constants.confirmFormUrl,
        confirmFormUrl,
      );
    } catch (e) {
      confirmFormUrl = PreferenceUtil.instance.getString(
        Constants.confirmFormUrl,
        'https://regweb.nsysu.edu.tw/webreg/confirm_wuhan_pneumonia.asp?STUID=%s&STAT_COD=1&STATUS_COD=1&LOGINURL=https://selcrs.nsysu.edu.tw/',
      );
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (!context.mounted) return;
      Navigator.push(
        context,
        CupertinoPageRoute<dynamic>(
          builder: (_) => ConfirmFormPage(
            confirmFormUrl: confirmFormUrl,
            username: username,
          ),
        ),
      );
    } else {
      await launchUrl(
        Uri.parse(
          sprintf(confirmFormUrl, <String>[username]),
        ),
      );
    }
  }

  static bool checkIsInSchool({
    required double latitude,
    required double longitude,
  }) {
    //TODO more accuracy position check
    const double latBottom = 22.622056;
    const double latTop = 22.636574;
    const double longLeft = 120.258485;
    const double lonRight = 120.271779;
    return latitude >= latBottom &&
        latitude <= latTop &&
        longitude >= longLeft &&
        longitude <= lonRight;
  }

  /// Semester code (e.g. `1151`) for [date]. Used as the last-resort default
  /// when Firebase Remote Config is unavailable (desktop) and nothing has
  /// been cached yet.
  ///
  /// Boundaries follow 各級學校學生學年學期假期辦法 §2–3: the academic year
  /// starts on August 1; semester 1 runs Aug 1 – Jan 31 and semester 2 runs
  /// Feb 1 – Jul 31. Only the regular semesters (`1`, `2`) are returned;
  /// summer sessions (`0` 碩專暑, `3` 暑修) stay selectable in the picker but
  /// are never guessed as the default.
  static String semesterCodeFor(DateTime date) {
    const int rocYearOffset = 1911;
    const int academicYearStartMonth = DateTime.august;
    final bool isFirstSemester =
        date.month >= academicYearStartMonth || date.month == DateTime.january;
    final int academicYearStart = date.month >= academicYearStartMonth
        ? date.year
        : date.year - 1;
    return '${academicYearStart - rocYearOffset}${isFirstSemester ? 1 : 2}';
  }

  /// [semesterCodeFor] at [instant] in Taiwan time (UTC+8, no DST), so the
  /// Aug 1 / Feb 1 boundaries do not move with the device's time zone, e.g.
  /// for students who are abroad.
  static String semesterCodeAt(DateTime instant) {
    const Duration taiwanOffset = Duration(hours: 8);
    return semesterCodeFor(instant.toUtc().add(taiwanOffset));
  }

  static String get currentSemesterCode => semesterCodeAt(DateTime.now());

  /// [code] if it is a four-digit semester code such as `1151`, otherwise
  /// [currentSemesterCode]. Remote Config returns an empty string when the
  /// parameter is missing, and that value may also have been cached.
  static String semesterCodeOrCurrent(String code) =>
      RegExp(r'^\d{4}$').hasMatch(code) ? code : currentSemesterCode;

  /// Removes the cached official timetables for every semester, e.g. on
  /// logout, so the next account on this device cannot see them. Uses the
  /// same key rule as preference_migrations.dart: custom courses
  /// (`custom_course_data_*`) are user-created and are kept.
  static Future<void> clearCourseCache(PreferenceUtil preferences) async {
    final List<String> keys = preferences
        .getKeys()
        .where(
          (String key) =>
              key == Constants.prefCourseData ||
              key.startsWith('${ApConstants.packageName}.course_data_'),
        )
        .toList();
    for (final String key in keys) {
      await preferences.remove(key);
    }
  }
}
