import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/widgets/locale_initialization_gate.dart';

void main() {
  testWidgets(
    'does not create request-owning pages until initialization ends',
    (WidgetTester tester) async {
      final Completer<void> localeReady = Completer<void>();
      final Completer<void> analyticsReady = Completer<void>();
      int pageBuilds = 0;
      final Future<void> initialization = () async {
        await localeReady.future;
        await analyticsReady.future;
      }();

      await tester.pumpWidget(
        LocaleInitializationGate(
          initialization: initialization,
          onRetry: () {},
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          builder: (_) {
            pageBuilds++;
            return const MaterialApp(home: Text('Home'));
          },
        ),
      );
      expect(pageBuilds, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      localeReady.complete();
      await tester.pump();
      expect(pageBuilds, 0);

      analyticsReady.complete();
      await tester.pumpAndSettle();
      expect(pageBuilds, 1);
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('failed initialization can retry without building pages early', (
    WidgetTester tester,
  ) async {
    final Completer<void> firstAttempt = Completer<void>();
    final Completer<void> retry = Completer<void>();
    Future<void> initialization = firstAttempt.future;
    int attempts = 1;
    int pageBuilds = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return LocaleInitializationGate(
            initialization: initialization,
            onRetry: () => setState(() {
              attempts++;
              initialization = retry.future;
            }),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            builder: (_) {
              pageBuilds++;
              return const MaterialApp(home: Text('Home'));
            },
          );
        },
      ),
    );
    firstAttempt.completeError(StateError('Locale failed'));
    await tester.pumpAndSettle();
    expect(pageBuilds, 0);
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(attempts, 2);
    expect(pageBuilds, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retry.complete();
    await tester.pumpAndSettle();
    expect(pageBuilds, 1);
  });
}
