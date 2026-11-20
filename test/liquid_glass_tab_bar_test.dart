import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';
import 'package:nsysu_ap/widgets/liquid_glass/liquid_glass_tab_bar.dart';

void main() {
  const List<LiquidGlassTabItem> sampleItems = <LiquidGlassTabItem>[
    LiquidGlassTabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: '首頁',
    ),
    LiquidGlassTabItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: '課業',
    ),
    LiquidGlassTabItem(
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      label: '校車',
    ),
    LiquidGlassTabItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: '校園',
    ),
  ];

  testWidgets(
    'renders 4 tabs, hides trailing circle by default, and switches selection',
    (WidgetTester tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleLiquidTheme.harmonize(
            ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF007AFF),
              ),
            ),
          ),
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: LiquidGlassTabBar(
                    items: sampleItems,
                    currentIndex: currentIndex,
                    onTap: (int index) => setState(() => currentIndex = index),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('首頁'), findsOneWidget);
      expect(find.text('課業'), findsOneWidget);
      expect(find.text('校車'), findsOneWidget);
      expect(find.text('校園'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('trailing_action')),
        findsNothing,
      );

      await tester.tap(find.text('課業'));
      await tester.pumpAndSettle();
      expect(currentIndex, 1);

      await tester.tap(find.text('校園'));
      await tester.pumpAndSettle();
      expect(currentIndex, 3);
    },
  );

  testWidgets(
    'renders detached circular trailingAction when provided '
    'and invokes callback',
    (WidgetTester tester) async {
      bool trailingTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppleLiquidTheme.harmonize(ThemeData.dark()),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LiquidGlassTabBar(
                items: sampleItems,
                currentIndex: 0,
                onTap: (_) {},
                trailingAction: LiquidGlassTabAction(
                  icon: Icons.search_rounded,
                  tooltip: '搜尋',
                  onTap: () => trailingTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      final Finder trailingFinder = find.byKey(
        const ValueKey<String>('trailing_action'),
      );
      expect(trailingFinder, findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      await tester.tap(trailingFinder);
      await tester.pumpAndSettle();
      expect(trailingTapped, isTrue);
    },
  );

  testWidgets(
    'handles high contrast, reduced motion, and 2.0x text scaling '
    'without overflow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            highContrast: true,
            disableAnimations: true,
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppleLiquidTheme.harmonize(ThemeData.dark()),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: LiquidGlassTabBar(
                  items: sampleItems,
                  currentIndex: 1,
                  onTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
