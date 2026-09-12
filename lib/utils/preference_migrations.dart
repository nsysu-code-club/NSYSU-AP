import 'package:ap_common/ap_common.dart';
import 'package:nsysu_ap/config/constants.dart';

/// Runs migrations introduced after the last successfully initialized build.
Future<void> migratePreferences(
  PreferenceUtil preferences, {
  required int currentBuild,
}) async {
  const int legacyCourseMigrationBuild = 700;
  final int previousBuild =
      int.tryParse(preferences.getString(Constants.prefCurrentBuild, '')) ?? 0;

  if (previousBuild >= currentBuild) {
    return;
  }

  if (previousBuild < legacyCourseMigrationBuild) {
    // The package's migrateFrom0_10 uses contains('course_data'), which also
    // deletes custom_course_data. Only invalidate official course caches.
    final Set<String> keys = preferences.getKeys();
    for (final String key in keys) {
      if (key == Constants.prefCourseData ||
          key.startsWith('${ApConstants.packageName}.course_data_')) {
        if (await preferences.remove(key) != true) {
          throw StateError('Could not remove legacy course cache');
        }
      }
    }
    // Keep the user's current setting if the old migration already ran.
    if (!keys.contains(ApConstants.showCourseSearchButton)) {
      await preferences.setBool(
        ApConstants.showCourseSearchButton,
        preferences.getBool(Constants.prefIsShowCourseSearchButton, true),
      );
    }
  }

  // Written last so an interrupted migration can retry on the next launch.
  await preferences.setString(
    Constants.prefCurrentBuild,
    currentBuild.toString(),
  );
}
