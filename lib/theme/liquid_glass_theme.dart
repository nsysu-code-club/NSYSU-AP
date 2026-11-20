import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class LiquidGlassTheme extends ThemeExtension<LiquidGlassTheme> {
  final double blurSigma;
  final Color regularTint;
  final Color clearTint;
  final Color highContrastTint;
  final Color borderTopLeftColor;
  final Color borderBottomRightColor;
  final Color activePillColor;
  final Color activePillBorderColor;
  final Color shadowColor;
  final Color cardBackgroundColor;
  final Color secondaryCardColor;
  final Color canvasBackgroundColor;
  final Color subtleBorderColor;

  const LiquidGlassTheme({
    required this.blurSigma,
    required this.regularTint,
    required this.clearTint,
    required this.highContrastTint,
    required this.borderTopLeftColor,
    required this.borderBottomRightColor,
    required this.activePillColor,
    required this.activePillBorderColor,
    required this.shadowColor,
    required this.cardBackgroundColor,
    required this.secondaryCardColor,
    required this.canvasBackgroundColor,
    required this.subtleBorderColor,
  });

  static const LiquidGlassTheme light = LiquidGlassTheme(
    blurSigma: 24.0,
    regularTint: Color(0xB8F4F4F8),
    clearTint: Color(0x8CF4F4F8),
    highContrastTint: Color(0xF2FFFFFF),
    borderTopLeftColor: Color(0xD9FFFFFF),
    borderBottomRightColor: Color(0x26000000),
    activePillColor: Color(0xD9FFFFFF),
    activePillBorderColor: Color(0x99FFFFFF),
    shadowColor: Color(0x1F000000),
    cardBackgroundColor: Color(0xFFFFFFFF),
    secondaryCardColor: Color(0xFFE9E9EF),
    canvasBackgroundColor: Color(0xFFF2F2F7),
    subtleBorderColor: Color(0x14000000),
  );

  static const LiquidGlassTheme dark = LiquidGlassTheme(
    blurSigma: 26.0,
    regularTint: Color(0x9E26262A),
    clearTint: Color(0x731C1C20),
    highContrastTint: Color(0xF01C1C1E),
    borderTopLeftColor: Color(0x4DFFFFFF),
    borderBottomRightColor: Color(0x1AFFFFFF),
    activePillColor: Color(0x3DFFFFFF),
    activePillBorderColor: Color(0x42FFFFFF),
    shadowColor: Color(0x66000000),
    cardBackgroundColor: Color(0xFF1C1C1E),
    secondaryCardColor: Color(0xFF2C2C2E),
    canvasBackgroundColor: Color(0xFF000000),
    subtleBorderColor: Color(0x1FFFFFFF),
  );

  static LiquidGlassTheme of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LiquidGlassTheme? ext = theme.extension<LiquidGlassTheme>();
    if (ext != null) return ext;
    return theme.brightness == Brightness.dark ? dark : light;
  }

  @override
  LiquidGlassTheme copyWith({
    double? blurSigma,
    Color? regularTint,
    Color? clearTint,
    Color? highContrastTint,
    Color? borderTopLeftColor,
    Color? borderBottomRightColor,
    Color? activePillColor,
    Color? activePillBorderColor,
    Color? shadowColor,
    Color? cardBackgroundColor,
    Color? secondaryCardColor,
    Color? canvasBackgroundColor,
    Color? subtleBorderColor,
  }) {
    return LiquidGlassTheme(
      blurSigma: blurSigma ?? this.blurSigma,
      regularTint: regularTint ?? this.regularTint,
      clearTint: clearTint ?? this.clearTint,
      highContrastTint: highContrastTint ?? this.highContrastTint,
      borderTopLeftColor: borderTopLeftColor ?? this.borderTopLeftColor,
      borderBottomRightColor:
          borderBottomRightColor ?? this.borderBottomRightColor,
      activePillColor: activePillColor ?? this.activePillColor,
      activePillBorderColor:
          activePillBorderColor ?? this.activePillBorderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      secondaryCardColor: secondaryCardColor ?? this.secondaryCardColor,
      canvasBackgroundColor:
          canvasBackgroundColor ?? this.canvasBackgroundColor,
      subtleBorderColor: subtleBorderColor ?? this.subtleBorderColor,
    );
  }

  @override
  LiquidGlassTheme lerp(
    covariant ThemeExtension<LiquidGlassTheme>? other,
    double t,
  ) {
    if (other is! LiquidGlassTheme) return this;
    return LiquidGlassTheme(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      regularTint: Color.lerp(regularTint, other.regularTint, t) ?? regularTint,
      clearTint: Color.lerp(clearTint, other.clearTint, t) ?? clearTint,
      highContrastTint:
          Color.lerp(highContrastTint, other.highContrastTint, t) ??
          highContrastTint,
      borderTopLeftColor:
          Color.lerp(borderTopLeftColor, other.borderTopLeftColor, t) ??
          borderTopLeftColor,
      borderBottomRightColor:
          Color.lerp(borderBottomRightColor, other.borderBottomRightColor, t) ??
          borderBottomRightColor,
      activePillColor:
          Color.lerp(activePillColor, other.activePillColor, t) ??
          activePillColor,
      activePillBorderColor:
          Color.lerp(activePillBorderColor, other.activePillBorderColor, t) ??
          activePillBorderColor,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t) ?? shadowColor,
      cardBackgroundColor:
          Color.lerp(cardBackgroundColor, other.cardBackgroundColor, t) ??
          cardBackgroundColor,
      secondaryCardColor:
          Color.lerp(secondaryCardColor, other.secondaryCardColor, t) ??
          secondaryCardColor,
      canvasBackgroundColor:
          Color.lerp(canvasBackgroundColor, other.canvasBackgroundColor, t) ??
          canvasBackgroundColor,
      subtleBorderColor:
          Color.lerp(subtleBorderColor, other.subtleBorderColor, t) ??
          subtleBorderColor,
    );
  }
}

class AppleLiquidTheme {
  /// Harmonizes [base] from `ApTheme` with Apple HIG & Liquid Glass tokens
  /// while preserving the user's selected primary seed color.
  static ThemeData harmonize(ThemeData base) {
    final bool isDark = base.brightness == Brightness.dark;
    final LiquidGlassTheme glass = isDark
        ? LiquidGlassTheme.dark
        : LiquidGlassTheme.light;
    final ColorScheme scheme = base.colorScheme.copyWith(
      surface: glass.cardBackgroundColor,
      surfaceContainerHighest: glass.secondaryCardColor,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: glass.canvasBackgroundColor,
      canvasColor: glass.canvasBackgroundColor,
      cardColor: glass.cardBackgroundColor,
      cardTheme: base.cardTheme.copyWith(
        color: glass.cardBackgroundColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: glass.subtleBorderColor),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: glass.canvasBackgroundColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: glass.cardBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      extensions: base.extensions.values.followedBy(
        <ThemeExtension<dynamic>>[glass],
      ),
    );
  }
}
