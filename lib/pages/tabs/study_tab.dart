import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_grouped_section.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_page_header.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_tab_bar.dart';
import 'package:nsysu_ap/widgets/liquid_glass/new_feature_label.dart';

class StudyTab extends StatelessWidget {
  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onAvatarTap;
  final VoidCallback onOpenCourse;
  final VoidCallback onOpenScore;
  final VoidCallback onOpenGraduationCheck;
  final bool showNewTuitionFeature;
  final VoidCallback onOpenTuitionAndCert;
  final VoidCallback onOpenCourseSelector;

  const StudyTab({
    super.key,
    required this.isLogin,
    required this.userInfo,
    required this.displayPicture,
    required this.onAvatarTap,
    required this.onOpenCourse,
    required this.onOpenScore,
    required this.onOpenGraduationCheck,
    required this.showNewTuitionFeature,
    required this.onOpenTuitionAndCert,
    required this.onOpenCourseSelector,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: AppleContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ApplePageHeader(
                    title: app.tabStudy,
                    isLogin: isLogin,
                    userInfo: userInfo,
                    displayPicture: displayPicture,
                    onAvatarTap: onAvatarTap,
                  ),
                  AppleSectionHeader(
                    title: app.studyCoreSection,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final bool useSingleColumn =
                                constraints.maxWidth < 310 ||
                                MediaQuery.textScalerOf(context).scale(1.0) >
                                    1.45;
                            final Widget courseCard = _StudyFeatureCard(
                              icon: ApIcon.classIcon,
                              title: ap.course,
                              subtitle: app.courseSubtitle,
                              onTap: onOpenCourse,
                            );
                            final Widget scoreCard = _StudyFeatureCard(
                              icon: ApIcon.assignment,
                              title: ap.score,
                              subtitle: app.scoreSubtitle,
                              onTap: onOpenScore,
                            );
                            if (useSingleColumn) {
                              return Column(
                                children: <Widget>[
                                  courseCard,
                                  const SizedBox(height: 12),
                                  scoreCard,
                                ],
                              );
                            }
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(child: courseCard),
                                  const SizedBox(width: 14),
                                  Expanded(child: scoreCard),
                                ],
                              ),
                            );
                          },
                    ),
                  ),
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
                  const SizedBox(height: LiquidGlassTabBar.bottomClearance),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StudyFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass.cardBackgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: glass.subtleBorderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 26, color: primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
