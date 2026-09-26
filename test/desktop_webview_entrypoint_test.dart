import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/app.dart';
import 'package:nsysu_ap/main.dart' as app;

void main() {
  const MethodChannel channel = MethodChannel('webview_message/client_channel');

  testWidgets(
    'WebView engine starts its title bar without app initialization',
    (WidgetTester tester) async {
      // No preferences, Firebase, or other application plugins are registered.
      await app.main(<String>['web_view_title_bar', '42', '24']);
      await tester.pumpAndSettle();

      expect(find.byType(TitleBarWebViewState), findsOneWidget);
      expect(find.byType(MyApp), findsNothing);
      expect(tester.takeException(), isNull);

      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        MethodCall call,
      ) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        channel.setMethodCallHandler(null);
      });

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'onRefreshPressed');
      expect(calls.single.arguments, <String, int>{'webViewId': 42});
    },
  );
}
