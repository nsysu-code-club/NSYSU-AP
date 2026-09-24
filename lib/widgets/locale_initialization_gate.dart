import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';

/// Keeps pages (and their startup requests) behind locale initialization.
class LocaleInitializationGate extends StatelessWidget {
  const LocaleInitializationGate({
    super.key,
    required this.initialization,
    required this.onRetry,
    required this.builder,
    required this.theme,
    required this.darkTheme,
    required this.themeMode,
  });

  final Future<void> initialization;
  final VoidCallback onRetry;
  final WidgetBuilder builder;
  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return builder(context);
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          home: Scaffold(
            body: Center(
              child: snapshot.connectionState == ConnectionState.done
                  ? TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(ap.clickToRetry),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
