# nsysu_crawler

Pure-Dart crawler / API client for NSYSU 校務系統. Lifted out of the
`nsysu_ap` Flutter app so it can be reused server-side, in a CLI, or in a
second native client without dragging Flutter SDK dependencies along.

`dart test` 執行（不需 `flutter`）。

## 文件索引

- [Endpoint catalog](docs/endpoint-catalog.md) — 每個學校 endpoint 的 method / encoding / sentinel
- 上層說明（測試、CI、貢獻流程）見 [專案根 README](../../README.md)

## Public API

```dart
import 'package:nsysu_crawler/nsysu_crawler.dart';
```

### 4 個 helper（皆為 singleton，透過 `.instance` 取用）

| Helper | 主要方法 | 是否需登入 |
|---|---|---|
| `SelcrsHelper` | `login`, `getUserInfo`, `getCourseSemesterData`, `getCourseData`, `getScoreSemesterData`, `getScoreData`, `changeMail`, `getUsername` | ✅ |
| `GraduationHelper` | `login`, `getGraduationReport` | ✅（獨立 session）|
| `TuitionHelper` | `login`, `getData`, `downloadFdf` | ✅（明文密碼，學校系統限制）|
| `BusHelper` | `getBusInfoList(languageCode:)`, `getBusTime(languageCode:, busInfo:)` | ❌ |

### 2 個抽象介面（NoOp 預設，host app 注入真實實作）

```dart
abstract interface class CrashReporter {
  void recordError(Object error, StackTrace stack, {String? reason});
  void setCustomKey(String key, Object value);
}

abstract interface class AnalyticsLogger {
  void logTimeEvent(String name, double seconds);
}
```

掛上實作：
```dart
SelcrsHelper.instance
  ..crashReporter = MyFirebaseCrashReporter()
  ..analyticsLogger = MyFirebaseAnalyticsLogger();
```

### Locale / debug

```dart
// 預設 'zh'，host 在 bootstrap 時改成讀 slang locale
SelcrsHelper.instance.languageProvider = () => 'zh'; // or 'en'

// !bool.fromEnvironment('dart.vm.product')
const bool kCrawlerDebugMode = ...;
```

## Bootstrap from the host Flutter app

`lib/utils/crawler_bootstrap.dart` in `nsysu_ap` 是參考實作：

```dart
void bootstrapCrawler() {
  SelcrsHelper.instance
    ..crashReporter = const _FirebaseCrashReporter()
    ..analyticsLogger = const _FirebaseAnalyticsLogger()
    ..languageProvider = () =>
        LocaleSettings.currentLocale == AppLocale.zhHantTw ? 'zh' : 'en';
}
```

在 `main()` 內 Firebase init 之後、`runApp` 之前呼叫一次。

## Tests

三層測試金字塔：

| 層 | 命令 | 跑哪些 | 何時跑 |
|---|---|---|---|
| Hermetic | `dart test` | abstractions、codec、model JSON、`redact()`、`currentAcademicSemester()` | 每次 `dart test` |
| Live (anonymous) | `dart test -P live-anonymous -r expanded` | 3 個 health check probe + bus（不需 creds）| 本機 debug bus、CI 排程 |
| Live (authenticated) | `NSYSU_USER=… NSYSU_PASS=… dart test -P live -r expanded` | selcrs + graduation + tuition 全套 | 本機需要打真站 / CI 排程 |

跑出來範例：
```
[live] login as B•••••••6 (score + course endpoints)
[live]   ← isLogin=true result=ApiSuccess<GeneralResponse>
[live] GET /menu4/tools/changedat.asp (user info)
[live]   ← id=B•••••••6 name=梁• dept=資•••••系 class=資•••
```

PII（學號 / 姓名 / 系所 / 班級 / 課名）用 `redact()` mask 中間字。

要看每個 dio request 的 URL（跟 redirect chain）：
```bash
NSYSU_HTTP_LOG=1 dart test -P live -r expanded
```
詳見 `test/live/_helpers.dart`。

### Local creds via direnv

複製 `.envrc.example` → `.envrc`、填入 creds、`direnv allow`。`.envrc` 已被根 `.gitignore` 排除。

> **絕對不要 commit creds**。如果不小心貼進 chat / commit / PR，**馬上去 selcrs 改密碼**。

### CI

- 每個 PR：`.github/workflows/test.yml`（hermetic dart test only，亞秒級）
- 每天 08:00 TPE：`.github/workflows/crawler-monitor.yml`（live + live-anonymous，失敗時發 Discord）

## Architecture（簡述）

```
nsysu_crawler/
├── lib/
│   ├── nsysu_crawler.dart                # 公開 barrel
│   └── src/
│       ├── abstractions/                 # CrashReporter / AnalyticsLogger 介面
│       ├── helpers/                      # 4 個 helper（dio + cookie + 解析串接）
│       ├── models/                       # Bus / Score / Tuition / Graduation 等
│       ├── parsers/                      # pure HTML parser（fixture-testable）
│       └── utils/
│           ├── big5/                     # BIG-5 codec
│           └── codec_utils.dart          # base64md5 / uriEncodeBig5
└── test/
    ├── abstractions_test.dart
    ├── codec_utils_test.dart
    ├── models_test.dart
    ├── live/                             # 帶 @Tags(['live'/'live-anonymous'])
    │   ├── _helpers.dart                 # redact / currentAcademicSemester / dio logger
    │   ├── _helpers_test.dart
    │   ├── bus_live_test.dart
    │   ├── graduation_live_test.dart
    │   ├── health_check_live_test.dart   # connectivity probes
    │   ├── selcrs_live_test.dart
    │   └── tuition_live_test.dart
    ├── fixtures/                         # 真實 HTML / JSON 樣本，給 parser tests 用
    └── parsers/                          # fixture-based parser tests
```

不依賴 Flutter SDK；`pubspec.yaml` 只列 `ap_common_core` + `dio` 系列 + `html` + `crypto` + `sprintf`。
