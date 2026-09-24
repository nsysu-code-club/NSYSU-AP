import 'package:ap_common/ap_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/preference_migrations.dart';

void main() {
  test('silent build-marker failure is surfaced and can be retried', () async {
    final _MigrationPreferences preferences = _MigrationPreferences();
    await expectLater(
      migratePreferences(preferences, currentBuild: 701),
      throwsStateError,
    );
    expect(preferences.build, '699');
    preferences.ignoreWrite = false;
    await migratePreferences(preferences, currentBuild: 701);
    expect(preferences.build, '701');
    final int removals = preferences.removals;
    await migratePreferences(preferences, currentBuild: 701);
    expect(preferences.removals, removals);
    expect(preferences.writes, 2);
  });
}

class _MigrationPreferences implements PreferenceUtil {
  String build = '699';
  bool ignoreWrite = true;
  int writes = 0;
  int removals = 0;

  @override
  String getString(String key, String defaultValue) {
    expect(key, Constants.prefCurrentBuild);
    return build;
  }

  @override
  Set<String> getKeys() => <String>{
    Constants.prefCourseData,
    ApConstants.showCourseSearchButton,
  };

  @override
  Future<bool> remove(String key) async {
    expect(key, Constants.prefCourseData);
    removals++;
    return true;
  }

  @override
  Future<void> setString(String key, String data) async {
    expect(key, Constants.prefCurrentBuild);
    writes++;
    if (!ignoreWrite) build = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
