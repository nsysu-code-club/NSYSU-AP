import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_surface.dart';
import 'package:nsysu_ap/widgets/liquid_glass/new_feature_label.dart';

@immutable
class LiquidGlassTabItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? semanticsLabel;
  final bool showNewFeature;

  const LiquidGlassTabItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.semanticsLabel,
    this.showNewFeature = false,
  });
}

@immutable
class LiquidGlassTabAction {
  final Key? key;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const LiquidGlassTabAction({
    this.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}

class LiquidGlassTabBar extends StatelessWidget {
  static const double barHeight = 64.0;
  static const double bottomClearance = 108.0;

  final List<LiquidGlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional detached circular action button on the trailing side of the
  /// capsule tab bar (matching the Apple Store 4+1 layout).
  /// Defaults to `null` (hidden) and can be enabled by passing an action.
  final LiquidGlassTabAction? trailingAction;

  const LiquidGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.trailingAction,
  }) : assert(items.length >= 2);

  @override
  Widget build(BuildContext context) {
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double bottomMargin = math.max(bottomInset, 12.0);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        // Scroll edge effect: soft gradient separating scrolling content
        // from the floating Liquid Glass capsule bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: barHeight + bottomMargin + 28,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    glass.canvasBackgroundColor.withValues(alpha: 0.0),
                    glass.canvasBackgroundColor.withValues(alpha: 0.68),
                    glass.canvasBackgroundColor.withValues(alpha: 0.92),
                  ],
                  stops: const <double>[0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomMargin),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(child: _buildCapsuleBar(context, glass)),
                if (trailingAction != null) ...<Widget>[
                  const SizedBox(width: 12),
                  _TrailingActionCircle(action: trailingAction!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapsuleBar(BuildContext context, LiquidGlassTheme glass) {
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final int count = items.length;
    final int safeIndex = currentIndex.clamp(0, count - 1);
    final double alignX = count <= 1
        ? 0.0
        : -1.0 + (2.0 * safeIndex / (count - 1));

    return SizedBox(
      height: barHeight,
      child: LiquidGlassSurface(
        borderRadius: BorderRadius.circular(barHeight / 2),
        padding: const EdgeInsets.all(5),
        child: Stack(
          children: <Widget>[
            // Sliding inner Liquid Glass selection lens
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: glass.activePillColor,
                    borderRadius: BorderRadius.circular((barHeight - 10) / 2),
                    border: Border.all(
                      color: glass.activePillBorderColor,
                      width: 0.9,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (int i = 0; i < count; i++)
                  Expanded(
                    child: _TabBarDestinationButton(
                      item: items[i],
                      isSelected: i == safeIndex,
                      onTap: () {
                        if (i != safeIndex) {
                          HapticFeedback.selectionClick();
                        }
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDestinationButton extends StatefulWidget {
  final LiquidGlassTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabBarDestinationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabBarDestinationButton> createState() =>
      _TabBarDestinationButtonState();
}

class _TabBarDestinationButtonState extends State<_TabBarDestinationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.68);
    final Color foreground = widget.isSelected ? activeColor : inactiveColor;
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final double currentScale = MediaQuery.textScalerOf(context).scale(1.0);
    final TextScaler clampedScaler = TextScaler.linear(
      math.min(currentScale, 1.15),
    );
    final bool showNewFeature = widget.item.showNewFeature;
    final String label = widget.item.semanticsLabel ?? widget.item.label;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: showNewFeature ? '$label, ${app.newFeature}' : label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onHighlightChanged: (bool pressed) =>
              setState(() => _isPressed = pressed),
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: AnimatedScale(
              scale: _isPressed ? 0.93 : 1.0,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 110),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: clampedScaler),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        widget.isSelected
                            ? (widget.item.activeIcon ?? widget.item.icon)
                            : widget.item.icon,
                        size: showNewFeature ? 18 : 23,
                        color: foreground,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: foreground,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (showNewFeature) const NewFeatureLabel(compact: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailingActionCircle extends StatefulWidget {
  final LiquidGlassTabAction action;

  const _TrailingActionCircle({required this.action});

  @override
  State<_TrailingActionCircle> createState() => _TrailingActionCircleState();
}

class _TrailingActionCircleState extends State<_TrailingActionCircle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.82);
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      label: widget.action.tooltip,
      child: Tooltip(
        message: widget.action.tooltip,
        child: GestureDetector(
          key: widget.action.key ?? const ValueKey<String>('trailing_action'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.action.onTap();
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 110),
            child: SizedBox(
              width: LiquidGlassTabBar.barHeight,
              height: LiquidGlassTabBar.barHeight,
              child: LiquidGlassSurface(
                borderRadius: BorderRadius.circular(
                  LiquidGlassTabBar.barHeight / 2,
                ),
                child: Center(
                  child: Icon(widget.action.icon, size: 26, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
