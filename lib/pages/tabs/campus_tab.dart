import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_grouped_section.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_page_header.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_tab_bar.dart';

class CampusTab extends StatelessWidget {
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

  const CampusTab({
    super.key,
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
                    title: app.tabCampus,
                    isLogin: isLogin,
                    userInfo: userInfo,
                    displayPicture: displayPicture,
                    onAvatarTap: onAvatarTap,
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
                        icon: Icons.post_add_rounded,
                        title: ap.announcementReviewSystem,
                        titleAccessory:
                            !isLogin || pendingAnnouncementCount == null
                            ? null
                            : _PendingAnnouncementBadge(
                                count: pendingAnnouncementCount!,
                              ),
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

class _PendingAnnouncementBadge extends StatelessWidget {
  const _PendingAnnouncementBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool highContrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highContrast ? colors.onSurface : colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          app.pendingAnnouncementCount(count: count),
          style: TextStyle(
            color: highContrast ? colors.surface : colors.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
