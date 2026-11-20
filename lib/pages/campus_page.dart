import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/new_feature_label.dart';

class CampusPage extends StatelessWidget {
  final VoidCallback onOpenGraduationCheck;
  final VoidCallback onOpenTuitionAndCert;
  final VoidCallback onOpenCourseSelector;
  final bool showNewTuitionFeature;
  final List<Widget> additionalEntries;
  final bool isLogin;
  final int? pendingAnnouncementCount;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onAvatarTap;
  final VoidCallback onOpenSchoolMap;
  final VoidCallback onOpenSchoolInfo;
  final VoidCallback onOpenAnnouncementReview;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAbout;

  const CampusPage({
    super.key,
    required this.onOpenGraduationCheck,
    required this.onOpenTuitionAndCert,
    required this.onOpenCourseSelector,
    required this.showNewTuitionFeature,
    this.additionalEntries = const <Widget>[],
    required this.isLogin,
    this.pendingAnnouncementCount,
    required this.userInfo,
    required this.displayPicture,
    required this.onAvatarTap,
    required this.onOpenSchoolMap,
    required this.onOpenSchoolInfo,
    required this.onOpenAnnouncementReview,
    required this.onOpenSettings,
    required this.onOpenAbout,
  });

  @override
  Widget build(BuildContext context) {
    return ApMoreContent(
      title: app.tabCampus,
      isLogin: isLogin,
      userInfo: userInfo,
      displayPicture: displayPicture,
      onAvatarTap: onAvatarTap,
      additionalEntries: additionalEntries,
      sections: <Widget>[
        AppleGroupedSection(
          title: app.studyToolsSection,
          children: <Widget>[
            AppleGroupedTile(
              icon: ApIcon.school,
              title: app.graduationCheckChecklist,
              subtitle: app.graduationCheckSubtitle,
              onTap: onOpenGraduationCheck,
            ),
            AppleGroupedTile(
              icon: ApIcon.monetizationOn,
              title: app.tuitionAndCert,
              titleAccessory: showNewTuitionFeature
                  ? const NewFeatureLabel()
                  : null,
              subtitle: app.tuitionAndCertSubtitle,
              onTap: onOpenTuitionAndCert,
            ),
            AppleGroupedTile(
              icon: ApIcon.exitToApp,
              title: app.courseSelector,
              subtitle: app.courseSelectorSubtitle,
              isExternal: true,
              onTap: onOpenCourseSelector,
            ),
          ],
        ),
        AppleGroupedSection(
          title: app.campusServicesSection,
          children: <Widget>[
            AppleGroupedTile(
              icon: ApIcon.map,
              title: ap.schoolMap,
              subtitle: app.schoolMapSubtitle,
              onTap: onOpenSchoolMap,
            ),
            AppleGroupedTile(
              icon: ApIcon.info,
              title: ap.schoolInfo,
              subtitle: app.schoolInfoSubtitle,
              onTap: onOpenSchoolInfo,
            ),
            AppleGroupedTile(
              icon: ApIcon.edit,
              title: ap.announcementReviewSystem,
              titleAccessory: !isLogin || pendingAnnouncementCount == null
                  ? null
                  : PendingAnnouncementBadge(count: pendingAnnouncementCount!),
              subtitle: app.announcementReviewSubtitle,
              onTap: onOpenAnnouncementReview,
            ),
          ],
        ),
        AppleGroupedSection(
          title: app.appSection,
          children: <Widget>[
            AppleGroupedTile(
              icon: ApIcon.settings,
              title: ap.settings,
              onTap: onOpenSettings,
            ),
            AppleGroupedTile(
              icon: ApIcon.face,
              title: ap.about,
              onTap: onOpenAbout,
            ),
          ],
        ),
      ],
    );
  }
}
