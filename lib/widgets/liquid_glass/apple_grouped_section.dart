import 'package:flutter/material.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';

class AppleSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? titleColor;

  const AppleSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color resolvedColor = titleColor ?? theme.colorScheme.onSurface;

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: resolvedColor,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AppleGroupedSection extends StatelessWidget {
  final String? title;
  final Widget? headerTrailing;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const AppleGroupedSection({
    super.key,
    this.title,
    this.headerTrailing,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          AppleSectionHeader(title: title!, trailing: headerTrailing),
        Padding(
          padding: margin,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glass.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glass.subtleBorderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < children.length; i++) ...<Widget>[
                    children[i],
                    if (i < children.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.6,
                        indent: 64,
                        color: glass.subtleBorderColor,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppleGroupedTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final Widget? titleAccessory;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isExternal;
  final Color? titleColor;

  const AppleGroupedTile({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.titleAccessory,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.isExternal = false,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = iconColor ?? theme.colorScheme.primary;
    final Color badgeBg =
        iconBackgroundColor ?? primary.withValues(alpha: 0.14);
    final Color onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: titleColor ?? onSurface,
                            ),
                          ),
                          if (titleAccessory != null) titleAccessory!,
                        ],
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      isExternal
                          ? Icons.open_in_new_rounded
                          : Icons.chevron_right_rounded,
                      size: isExternal ? 18 : 22,
                      color: onSurface.withValues(alpha: 0.38),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
