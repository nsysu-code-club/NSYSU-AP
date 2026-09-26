[![CI](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/ci.yml/badge.svg)](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/ci.yml) [![Store CD](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/cd.yml/badge.svg)](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/cd.yml) [![Crawler Monitor](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/crawler-monitor.yml/badge.svg)](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/crawler-monitor.yml)
# 中山校務通

 提供中山學生更方便的校務系統查詢入口，由 Google 開源跨平台框架 [Flutter](https://flutter.dev) 開發

<a href='https://play.google.com/store/apps/details?id=com.nsysu.ap&hl=zh_TW'><img alt='Get it on the App Store' src='screenshots/google_play.png' height='48px'/></a>
<a href='https://apps.apple.com/tw/app/id1467522198'><img alt='Get it on the App Store' src='screenshots/app_store.png' height='48px'/></a>

## [專案介紹(簡報)](https://docs.google.com/presentation/d/1qMMqqsM91MYmqOkNNU6Cz6vaYj1VUSnF-JNg_hNMtL0/edit)
## 支援系統
- [x] Android
- [x] iOS
- [x] MacOS
- [X] Windows
- [ ] Linux

## 開發環境
 - Flutter 穩定版本 v3.44.8

### 暫時使用本機 ap_common（僅限 chore/devops-and-deps-update 分支）

**只有在 `chore/devops-and-deps-update` 分支進行開發時，才需要依照本節設定暫時的本機方案。其他分支可直接使用 `pubspec.yaml` 安裝依賴。本異常將最晚在2.2.X修正**

此開發分支的 `pubspec.yaml` 透過 `dependency_overrides` 使用本機的 `ap_common_flutter_core`，以修正 Dio 5.11.1 新增 `DioExceptionType.transformTimeout` 所造成的編譯錯誤。請將包含此修正的 `ap_common` checkout 放在本專案的同層目錄：

```text
工作目錄/
├── NSYSU-AP/
└── ap_common/
    └── packages/ap_common_flutter_core/
```

共用套件必須包含以下修正：`lib/src/l10n/ap_localizations.dart` 的 `i18nMessage` 將 `DioExceptionType.transformTimeout` 歸類為 `ap.timeoutMessage`，且套件的 `pubspec.yaml` 將 Dio 最低版本提高至 `^5.11.1`。僅取得尚未包含修正的 checkout 仍會編譯失敗；共用套件的變更需在 `ap_common` repository 另行提交並分享。

在 `NSYSU-AP` 根目錄執行：

```bash
fvm flutter pub get
```

此設定已直接寫入 `pubspec.yaml`，不需要另建 `pubspec_overrides.yaml`。此分支的 CI 若只 checkout 本專案，會因缺少相鄰的 `ap_common` 目錄而無法解析依賴；使用此暫時方案的建置環境也必須準備相同目錄及修正版本。

待共用套件發布修正版後，請更新 `dependencies.ap_common_flutter_core`、移除該套件的 path override，再執行 `fvm flutter pub get` 並提交更新的 `pubspec.lock`。

### iOS / macOS 工具鏈

iOS 與 macOS 的 CocoaPods 由根目錄的 `Gemfile`／`Gemfile.lock` 固定為 **1.17.0**。在專案根目錄透過 Bundler 啟動 Flutter，讓 Flutter 呼叫的 `pod` 使用固定版本：

```bash
export PATH="/opt/homebrew/opt/ruby/bin:$PATH" # Apple Silicon / Homebrew Ruby
export BUNDLE_GEMFILE="$PWD/Gemfile"
bundle config set --local path vendor/bundle
bundle install
bundle exec pod --version # 1.17.0
bundle exec fvm flutter run -d macos
```

iOS 同樣使用 `bundle exec fvm flutter build ios`。直接執行 `fvm flutter` 仍會使用環境中的 CocoaPods；`Podfile.lock` 的 `COCOAPODS` 欄位不會替你切換工具版本。執行既有的 Fastlane 流程時，請另外指定平台的 `BUNDLE_GEMFILE`（例如 `"$PWD/ios/Gemfile"`）。

第一次設定本機開發環境時，建議安裝專案提供的 pre-commit hook：

```bash
fvm dart run tool/install_git_hooks.dart
```

沒有使用 FVM 的環境可改用 `dart run tool/install_git_hooks.dart`。安裝後，每次 `git commit` 前會執行 `dart analyze .`；只有暫存區包含 `lib/l10n` 變更時，才會先執行已安裝的 Slang 快照與 l10n 產生檔暫存檢查。詳細流程請參考 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

## 功能列表

- 首頁最新消息
    - 前端 [ap_common](https://github.com/abc873693/ap_common)
    - 後端 [announcements_service](https://github.com/takidog/announcements_service)
- 課程學習
    - [x] 學期成績查詢(選課系統)
    - [x] 學期課表查詢(成績查詢系統)
    - [x] 請假系統(學生請假系統)
- 校車系統
    - [x] 校園公車列表
    - [x] 公車時刻查詢
- 總務處
    - [x] 學雜費繳費單列印暨繳費狀況查詢
- 畢業生審查系統
    - [ ] 歷年成績單
    - [x] 應屆畢業生成績檢核表
- 教務處註冊系統
    - [x] 在學證明 PDF 提取與匯出
- 各類所得劃帳暨歸戶查詢
    - [ ] 各類所得郵局劃帳暨歸戶查詢系統
- 設定
    - [x] 上課提醒
    - [x] 主題切換
    - [x] 切換語言
        - [x] 中文
        - [x] 英文
    - [x] 開啟粉絲專頁

## 使用套件

- [ap_common](https://pub.dev/packages/ap_common)：提供校務通系列共用的介面與程式碼工程
- [ap_common_firebase](https://pub.dev/packages/ap_common_firebase)：串接 Firebase 中校務通會使用到的功能
- [ap_common_plugin](https://pub.dev/packages/ap_common_plugin)：校務通系列的原生套件，目前支援 Android 的 課堂桌面小工具

## 文件索引

第一次接觸專案的人從這裡開始：

| 文件 | 內容 |
|---|---|
| [`packages/nsysu_crawler/README.md`](packages/nsysu_crawler/README.md) | 純 Dart 爬蟲 package 的公開 API、bootstrap 範例、測試方式 |
| [`packages/nsysu_crawler/docs/endpoint-catalog.md`](packages/nsysu_crawler/docs/endpoint-catalog.md) | 所有 NSYSU endpoint 的 method / encoding / 成功 sentinel / 已知坑 |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | 如何參與 NSYSU_AP 的開發（如要貢獻，請詳閱） |

## 測試

### Flutter app 測試

```bash
flutter test test/
```

目前 app 端的 widget test 還少（見 #97），歡迎補。

### 爬蟲測試（純 Dart，不需 flutter）

爬蟲已抽成獨立 package `packages/nsysu_crawler/`，分三層測試：

```bash
cd packages/nsysu_crawler

# 1. Hermetic — 單元測試 + JSON 序列化 + 工具函式，預設、不打網路
dart test

# 2. live-anonymous — 連到真站做連線檢查 + 校車（不需帳密）
dart test -P live-anonymous -r expanded

# 3. live — 含 selcrs / 畢業審查 / 學雜費，需要學生帳密
NSYSU_USER=B12345678 NSYSU_PASS=xxx dart test -P live -r expanded
```

完整命令、PII redact、`NSYSU_HTTP_LOG=1` 等選項見 [package README 的 Tests 段](packages/nsysu_crawler/README.md#tests)。

### CI 自動化

| Workflow | 觸發 | 功能 |
|---|---|---|
| [`CI`](.github/workflows/ci.yml) | PR / push to master | Android / iOS / Windows 建置驗證 |
| [`Crawler Tests`](.github/workflows/test.yml) | PR / push to master | 跑 nsysu_crawler 的 hermetic dart test，亞秒級 |
| [`Crawler Monitor`](.github/workflows/crawler-monitor.yml) | 每天 08:00 TPE + 手動觸發 | 打真站跑 live tests，失敗發 Discord 通知並分類「網站異常」🔴 / 「結構異常」🟡 |

設 secrets：repo Settings → Secrets and variables → Actions
- `NSYSU_USERNAME` / `NSYSU_PASSWORD`：跑 cron 的測試帳號（**用 alt account，不要日常帳號**）
- `DISCORD_WEBHOOK_URL`：失敗通知用

### 本地 pre-commit

第一次設定本機 Git hooks：

```bash
fvm dart run tool/install_git_hooks.dart
```

沒有使用 FVM 的環境可改用：

```bash
dart run tool/install_git_hooks.dart
```

安裝器會在 Git 的 hooks 目錄建立 `pre-commit`、`nsysu-pre-commit.dart` 與 SDK 路徑檔 `nsysu-dart-path`，執行安裝時保存的 [`tool/pre_commit.dart`](tool/pre_commit.dart) 副本，並固定使用安裝時的 Dart 執行檔。切換分支不會替換已安裝的 hook 程式；請只從信任的 checkout 執行安裝器，安裝時也會把已解析的 Slang 及其傳遞依賴編譯成 `nsysu-slang.dill`，commit 時直接執行快照，不再從目前分支解析 `dart run slang`。工具流程、Slang 版本或 SDK 更新後需重新安裝；缺少快照時會阻擋提交，不會回退執行分支套件。翻譯來源與設定仍讀取工作目錄，analyzer 仍分析目前專案。既有的其他 hooks 會保留；舊版專案管理的 wrapper 會升級，若有不同的 `pre-commit` 或設定了 `core.hooksPath`，安裝器會提示手動整合並停止，不會覆寫自訂 hook 或修改 Git 設定。

之後每次 `git commit` 前會依序執行：

1. 若暫存區包含 `lib/l10n` 變更，使用安裝時的 Dart 執行 `nsysu-slang.dill`。
2. 產生後確認 `lib/l10n` 沒有未暫存或未追蹤的變更。
3. 使用相同 Dart 執行 `analyze .`，分析整個工作目錄。

執行 hook 時不再重新選擇 FVM 或 PATH 中的 Dart。
沒有暫存 `lib/l10n` 變更時，Slang 與 l10n 暫存檢查會跳過，未暫存或未追蹤的 l10n 檔案不會觸發這兩步。暫存的新增、修改、刪除及移入／移出 `lib/l10n` 都會觸發檢查。

有暫存 l10n 變更時，Slang 仍讀取工作目錄中的所有翻譯來源；這不是暫存區快照檢查。若 `lib/l10n` 有未暫存或未追蹤的變更，請先整理並暫存本次要提交的 l10n 檔案，再重新提交。pre-commit 不會自動暫存檔案。結束時會輸出 summary，列出每個 step 的 success / failed / skipped 狀態；任一步失敗都會阻擋 commit，靜態分析的 error 與 warning 都會阻擋提交。

pre-commit 不執行爬蟲單元測試或校務網站測試；相關測試由 CI、排程監控或開發者按需執行。

pre-commit 的主要流程寫在 [`tool/pre_commit.dart`](tool/pre_commit.dart)，
安裝流程寫在 [`tool/install_git_hooks.dart`](tool/install_git_hooks.dart)；已安裝的 hook 不再執行工作目錄中的 `bin/git_hooks.dart`。

## 爬蟲

邏輯以需要登入做系統區隔，若有功能有問題可向 [中山大學軟體工程組執掌查詢](https://lis.nsysu.edu.tw/p/405-1001-180580,c1173.php) 聯絡

  - [x] [選課系統](https://selcrs.nsysu.edu.tw/)
      - [x] 歷年學期選課清單
      - [ ] 歷年學生缺曠課資料
      - [ ] 通識教育講座次數查詢
      - [x] 學生基本資料
          - [x] 修改Email信箱
      - [ ] 修改登錄密碼
  - [x] [成績查詢系統](https://selcrs.nsysu.edu.tw/scoreqry/)
      - [x] 授課教師開放成績查詢
      - [ ] 學生預警查詢
      - [x] 學期成績查詢
      - [ ] 歷年成績查詢
  - [x] [畢業審查系統](https://sis.nsysu.edu.tw/SLAMS/SLAMS_student_view.php)
  - [x] [教務處註冊系統](https://regweb.nsysu.edu.tw/webreg/)
      - [x] 在學證明 PDF 提取
  - [ ] 總務處維修系統
  - [x] [學生請假系統](https://sso.nsysu.edu.tw/index.php/home/applisturl/0H00/0051)
  - [ ] 新網路大學 To-Do 提示
  - [x] [學雜費繳費單列印暨繳費狀況查詢系統](https://tfstu.nsysu.edu.tw/)
  - [x] [校車系統](https://selcrs.nsysu.edu.tw/scoreqry/)

## 維護團隊

校務通源於高科校務通，後續衍伸出中山校務通，又因套件獨立而產生AP Common，讓校務通開發更加統一與高效。  
目前由 [中山大學程式研習社xGoogle開發者社群](https://www.instagram.com/gdg.nsysu/) 做主要維護，App 商店託管由 [OCF 財團法人開放文化基金會](https://ocf.tw)管理。  
開發人員：房志剛（Rainvisitor），胡智強（JohnHuCC），張柏瑄（Ryan Chang），蔡明軒（Yukimura），高聖傑（JasonZzz），陳展皝（David），吳楷鈞 （TWCKaijin）

OCF 由多個台灣開源社群共同發起，在開放源碼、開放資料、開放政府等領域，提供社群支援、組織合作、海外交流、顧問諮詢等服務。期待以法人組織的力量激起開放協作的火花。
