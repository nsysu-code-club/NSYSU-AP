import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_article.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class AnnouncementReviewCard extends StatelessWidget {
  const AnnouncementReviewCard({
    super.key,
    required this.announcement,
    required this.showReviewStatus,
    required this.onOpen,
    this.showApplicant = false,
    this.isBlocked = false,
    this.menu,
    this.actions = const <Widget>[],
  });

  final Announcement announcement;
  final bool showReviewStatus;
  final bool showApplicant;
  final bool isBlocked;
  final VoidCallback onOpen;
  final Widget? menu;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final String excerpt = carouselExcerpt(announcement.description);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool? status = announcement.reviewStatus;
    final String? applicant = showApplicant ? announcement.applicant : null;
    final bool hasApplicant = applicant != null && applicant.isNotEmpty;
    final DateTime? deadline = DateTime.tryParse(
      announcement.expireTime?.trim() ?? '',
    )?.toLocal();
    final List<String> tags = announcement.tags ?? const <String>[];
    final BorderRadius radius = BorderRadius.circular(20);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                announcement.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (excerpt.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  excerpt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (showReviewStatus ||
                                  tags.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: <Widget>[
                                    if (showReviewStatus)
                                      _Label(
                                        text: switch (status) {
                                          null => ap.waitingForReview,
                                          true => ap.reviewApproval,
                                          false => ap.reviewReject,
                                        },
                                        background: switch (status) {
                                          null => colors.tertiaryContainer,
                                          true => colors.primaryContainer,
                                          false => colors.errorContainer,
                                        },
                                        foreground: switch (status) {
                                          null => colors.onTertiaryContainer,
                                          true => colors.onPrimaryContainer,
                                          false => colors.onErrorContainer,
                                        },
                                      ),
                                    for (final String tag in tags)
                                      _Label(
                                        text: tag,
                                        background:
                                            colors.surfaceContainerHighest,
                                        foreground: colors.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (announcement.imgUrl.isNotEmpty &&
                            MediaQuery.sizeOf(context).width >= 360 &&
                            MediaQuery.textScalerOf(context).scale(1) <=
                                1.4) ...<Widget>[
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox.square(
                              dimension: 64,
                              child: ApNetworkImage(url: announcement.imgUrl),
                            ),
                          ),
                        ],
                        if (menu == null) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (menu != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4, end: 4),
                  child: menu,
                ),
            ],
          ),
          if (deadline != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, hasApplicant ? 0 : 12),
              child: Text(
                app.announcementDeadline(
                  date: MaterialLocalizations.of(
                    context,
                  ).formatShortDate(deadline),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          if (hasApplicant)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: applicant));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(app.announcementApplicantCopied)),
                    );
                  },
                  style: isBlocked
                      ? TextButton.styleFrom(foregroundColor: colors.error)
                      : null,
                  icon: Icon(
                    isBlocked ? Icons.person_off_outlined : Icons.copy,
                  ),
                  label: Text(
                    applicant,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          if (actions.isNotEmpty) ...<Widget>[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 4,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
