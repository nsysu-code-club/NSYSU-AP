import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';

enum NewFeatureLocation { studyTab, tuitionAndFees, enrollmentCertificate }

enum NewFeature {
  enrollmentCertificate(
    'pref_opened_enrollment_certificate',
    <NewFeatureLocation>{
      NewFeatureLocation.studyTab,
      NewFeatureLocation.tuitionAndFees,
      NewFeatureLocation.enrollmentCertificate,
    },
  );

  const NewFeature(this.preferenceKey, this.locations);

  final String preferenceKey;
  final Set<NewFeatureLocation> locations;
}

/// A parent stays marked while any new feature on its path is unopened.
class NewFeatureDiscovery extends ChangeNotifier {
  NewFeatureDiscovery(PreferenceUtil preferences)
    : _preferences = preferences,
      _unopened = NewFeature.values
          .where(
            (NewFeature feature) =>
                !preferences.getBool(feature.preferenceKey, false),
          )
          .toSet();

  final PreferenceUtil _preferences;
  final Set<NewFeature> _unopened;

  bool showsLabelAt(NewFeatureLocation location) => _unopened.any(
    (NewFeature feature) => feature.locations.contains(location),
  );

  Future<void> markOpened(NewFeature feature) async {
    if (!_unopened.remove(feature)) return;
    notifyListeners();
    try {
      await _preferences.setBool(feature.preferenceKey, true);
    } on Exception catch (error) {
      debugPrint(
        'Could not save opened feature ${feature.name}: ${error.runtimeType}',
      );
    }
  }
}
