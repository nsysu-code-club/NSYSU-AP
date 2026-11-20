import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nested detail routes hide navbar and preserve back button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: ApAppShell(
          destinations: <ApDestination>[
            ApDestination(
              id: 'home',
              label: 'Home',
              icon: Icons.home,
              builder: (BuildContext context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ApPageScaffold(
                        title: const Text('Details'),
                        body: const Text('Detail body'),
                      ),
                    ),
                  ),
                  child: const Text('Open details'),
                ),
              ),
            ),
            ApDestination(
              id: 'campus',
              label: 'Campus',
              icon: Icons.school,
              builder: (_) => const Scaffold(),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(ApIcon.chevronLeft), findsOneWidget);
    await tester.tap(find.byIcon(ApIcon.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });
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

  testWidgets('shows a small feature dot without adding label text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlassTabBar(
            items: const <LiquidGlassTabItem>[
              LiquidGlassTabItem(icon: Icons.home, label: 'Home'),
              LiquidGlassTabItem(
                icon: Icons.school,
                label: 'Campus',
                showBadge: true,
                semanticsLabel: 'Campus, New',
              ),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(Badge), findsNWidgets(2));
    expect(find.text('New'), findsNothing);
    expect(find.bySemanticsLabel('Campus, New'), findsOneWidget);
  });

  testWidgets('handles high contrast, reduced motion, and 2.0x text scaling '
      'without overflow', (WidgetTester tester) async {
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
  });
}
