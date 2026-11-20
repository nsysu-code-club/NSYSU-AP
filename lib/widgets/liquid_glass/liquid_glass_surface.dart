import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';

enum LiquidGlassVariant {
  regular,
  clear,
}

class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final LiquidGlassVariant variant;
  final bool showShadow;
  final Color? tintOverride;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.padding,
    this.variant = LiquidGlassVariant.regular,
    this.showShadow = true,
    this.tintOverride,
  });

  @override
  Widget build(BuildContext context) {
    final LiquidGlassTheme glass = LiquidGlassTheme.of(context);
    final bool highContrast =
        MediaQuery.maybeHighContrastOf(context) ?? false;
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Color surfaceTint =
        tintOverride ??
        (highContrast
            ? glass.highContrastTint
            : (variant == LiquidGlassVariant.clear
                  ? glass.clearTint
                  : glass.regularTint));

    final double blurSigma = highContrast
        ? 0.0
        : (disableAnimations ? glass.blurSigma * 0.75 : glass.blurSigma);

    Widget content = CustomPaint(
      foregroundPainter: _SpecularBorderPainter(
        borderRadius: borderRadius,
        topLeftColor: glass.borderTopLeftColor,
        bottomRightColor: glass.borderBottomRightColor,
        strokeWidth: highContrast ? 1.6 : 1.1,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceTint,
          borderRadius: borderRadius,
          gradient: highContrast
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                  stops: const <double>[0.0, 0.45, 1.0],
                ),
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (blurSigma > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: glass.shadowColor,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }
}

class _SpecularBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color topLeftColor;
  final Color bottomRightColor;
  final double strokeWidth;

  const _SpecularBorderPainter({
    required this.borderRadius,
    required this.topLeftColor,
    required this.bottomRightColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius
        .resolve(TextDirection.ltr)
        .toRRect(rect)
        .deflate(strokeWidth / 2);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          topLeftColor,
          bottomRightColor,
          topLeftColor.withValues(alpha: 0.35),
        ],
        stops: const <double>[0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.topLeftColor != topLeftColor ||
        oldDelegate.bottomRightColor != bottomRightColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
