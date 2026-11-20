import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_article.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_grouped_section.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_page_header.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_tab_bar.dart';

class HomeTab extends StatelessWidget {
  static const Key loginCardKey = ValueKey<String>('home_login_prompt_card');

  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final HomeState announcementState;
  final List<Announcement> announcements;
  final CourseData? courseData;
  final VoidCallback onAvatarTap;
  final VoidCallback onLoginTap;
  final VoidCallback onOpenCourse;
  final VoidCallback onOpenAnnouncementSubmission;
  final ValueChanged<Announcement> onAnnouncementTap;
  final Future<void> Function() onRefreshAnnouncements;

  const HomeTab({
    super.key,
    required this.isLogin,
    required this.userInfo,
    required this.displayPicture,
    required this.announcementState,
    required this.announcements,
    required this.courseData,
    required this.onAvatarTap,
    required this.onLoginTap,
    required this.onOpenCourse,
    required this.onOpenAnnouncementSubmission,
    required this.onAnnouncementTap,
    required this.onRefreshAnnouncements,
  });

  @override
  Widget build(BuildContext context) {
    final String? userName = userInfo?.name;
    final String? subtitle =
        (isLogin && userName != null && userName.isNotEmpty)
        ? userName
        : null;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefreshAnnouncements,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: AppleContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ApplePageHeader(
                      title: app.appName,
                      subtitle: subtitle,
                      isLogin: isLogin,
                      userInfo: userInfo,
                      displayPicture: displayPicture,
                      onAvatarTap: onAvatarTap,
                    ),
                    _buildScheduleOrLoginSection(context),
                    _buildAnnouncementsSection(context),
                    const SizedBox(height: LiquidGlassTabBar.bottomClearance),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOrLoginSection(BuildContext context) {
    if (!isLogin) {
      return _buildInlineLoginCard(context);
    }
    if (courseData?.courses.isNotEmpty ?? false) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TodayScheduleCard(
          courseData: courseData!,
          onTap: onOpenCourse,
        ),
      );
    }
    return _buildEmptyScheduleCard(context);
  }

  Widget _buildInlineLoginCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        key: loginCardKey,
        decoration: BoxDecoration(
          color: glass.cardBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: glass.subtleBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.school_rounded, color: primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      app.loginCardTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                app.loginCardSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: onSurface.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: onLoginTap,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    ap.login,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScheduleCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final Color onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glass.subtleBorderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOpenCourse,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.today_rounded,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      courseData == null ? app.courseNotLoaded : ap.courseEmpty,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onSurface.withValues(alpha: 0.42),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppleSectionHeader(
          title: app.latestAnnouncements,
          titleColor: theme.colorScheme.primary,
          trailing: TextButton.icon(
            onPressed: onOpenAnnouncementSubmission,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              app.postAnnouncement,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        _buildAnnouncementsBody(context),
      ],
    );
  }

  Widget _buildAnnouncementsBody(BuildContext context) {
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final ThemeData theme = Theme.of(context);

    switch (announcementState) {
      case HomeState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      case HomeState.error:
      case HomeState.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glass.cardBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: glass.subtleBorderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onRefreshAnnouncements,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        announcementState == HomeState.empty
                            ? Icons.campaign_outlined
                            : ApIcon.error,
                        size: 40,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcementState == HomeState.empty
                            ? ap.noData
                            : ap.clickToRetry,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case HomeState.finish:
      case HomeState.offline:
        if (announcements.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: announcements.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (BuildContext context, int index) {
              final Announcement item = announcements[index];
              return _AnnouncementHeroCard(
                announcement: item,
                onTap: () => onAnnouncementTap(item),
              );
            },
          ),
        );
    }
  }
}

class _AnnouncementHeroCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _AnnouncementHeroCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String excerpt = carouselExcerpt(announcement.description);
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth = (screenWidth - 56).clamp(240.0, 340.0);

    return SizedBox(
      width: cardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: glass.subtleBorderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (announcement.imgUrl.isNotEmpty)
                    Image.network(
                      announcement.imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallbackBackdrop(theme),
                    )
                  else
                    _buildFallbackBackdrop(theme),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const <double>[0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          announcement.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        if (excerpt.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.82),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBackdrop(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primary.withValues(alpha: 0.75),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
