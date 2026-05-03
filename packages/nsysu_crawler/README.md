# nsysu_crawler

Pure-Dart crawler / API client for NSYSU 校務系統. Lifted out of the
`nsysu_ap` Flutter app so it can be reused server-side, in a CLI, or in a
second native client without dragging Flutter SDK dependencies along.

Runs on `dart test` (no `flutter` required).

## Public surface

```dart
import 'package:nsysu_crawler/nsysu_crawler.dart';

// Helpers (each is a singleton via `.instance`)
SelcrsHelper       // login + user info + course + score
GraduationHelper   // login + graduation report
TuitionHelper      // login + tuition list + PDF download
BusHelper          // bus info + arrival times (no creds)

// Abstractions (NoOp by default; host app injects real impls at bootstrap)
CrashReporter      // SelcrsHelper.instance.crashReporter
AnalyticsLogger    // SelcrsHelper.instance.analyticsLogger

// Locale / debug
SelcrsHelper.instance.languageProvider = () => 'zh'; // or 'en'
const bool kCrawlerDebugMode = ...;
```

## Bootstrap from the host Flutter app

`lib/utils/crawler_bootstrap.dart` in `nsysu_ap` is the canonical example:

```dart
void bootstrapCrawler() {
  SelcrsHelper.instance
    ..crashReporter = const _FirebaseCrashReporter()
    ..analyticsLogger = const _FirebaseAnalyticsLogger()
    ..languageProvider = () =>
        LocaleSettings.currentLocale == AppLocale.zhHantTw ? 'zh' : 'en';
}
```

Call `bootstrapCrawler()` from `main()` after Firebase init, before `runApp`.

## Tests

```bash
# Hermetic unit tests (default — fast, no network)
dart test

# Bus endpoints (no creds required)
dart test -P live-anonymous -r expanded

# Selcrs / Graduation / Tuition (requires creds)
NSYSU_USER=B12345678 NSYSU_PASS=xxx dart test -P live -r expanded
```

`-P live` and `-P live-anonymous` use the `expanded` reporter so each request
hit (`→ METHOD URL` / `← STATUS path`) is printed inline. See
`test/live/_dio_logging.dart` for the interceptor.

### Local creds via direnv

Copy `.envrc.example` → `.envrc`, fill in your creds, run `direnv allow`.
`.envrc` is gitignored at the repo root.

> **Never** commit credentials. If you accidentally paste them in a chat,
> commit, or PR, change your selcrs password immediately.
