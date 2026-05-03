[![Build Test](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/workflow.yml/badge.svg)](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/workflow.yml)
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
 - Flutter 穩定版本 v3.29
## 功能列表

- 首頁最新消息
    - 前端 [ap_common](https://github.com/abc873693/ap_common/blob/master/lib/scaffold/home_page_scaffold.dart)
    - 後端 [announcements_service](https://github.com/takidog/announcements_service)
- 課程學習
    - [x] 學期成績查詢(選課系統)
    - [x] 學期課表查詢(成績查詢系統)
- 校車系統
    - [x] 校園公車列表
    - [x] 公車時刻查詢
- 總務處
    - [x] 學雜費繳費單列印暨繳費狀況查詢
- 畢業生審查系統
    - [ ] 歷年成績單
    - [x] 應屆畢業生成績檢核表
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
| [`Build Test`](.github/workflows/workflow.yml) | PR / push to master | Android / iOS / Windows 建置驗證 |
| [`Crawler Tests`](.github/workflows/test.yml) | PR / push to master | 跑 nsysu_crawler 的 hermetic dart test，亞秒級 |
| [`Crawler Monitor`](.github/workflows/crawler-monitor.yml) | 每天 08:00 TPE + 手動觸發 | 打真站跑 live tests，失敗發 Discord 通知並分類「網站異常」🔴 / 「結構異常」🟡 |

設 secrets：repo Settings → Secrets and variables → Actions
- `NSYSU_USERNAME` / `NSYSU_PASSWORD`：跑 cron 的測試帳號（**用 alt account，不要日常帳號**）
- `DISCORD_WEBHOOK_URL`：失敗通知用

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
  - [x] [畢業審查系統](https://selcrs.nsysu.edu.tw/gadchk/)
  - [ ] 總務處維修系統
  - [x] [學雜費繳費單列印暨繳費狀況查詢系統](https://tfstu.nsysu.edu.tw/)
  - [x] [校車系統](https://selcrs.nsysu.edu.tw/scoreqry/)

## 維護團隊

校務通源於高科校務通，後續衍伸出中山校務通，又因套件獨立而產生AP Common，讓校務通開發更加統一與高效。  
目前由中山大學程式研習社做維護， App 商店託管由 [OCF 財團法人開放文化基金會](https://ocf.tw)管理。  
開發人員：房志剛（Rainvisitor），胡智強（JohnHuCC），張柏瑄（Ryan Chang），蔡明軒（Yukimura），高聖傑（JasonZzz）

OCF 由多個台灣開源社群共同發起，在開放源碼、開放資料、開放政府等領域，提供社群支援、組織合作、海外交流、顧問諮詢等服務。期待以法人組織的力量激起開放協作的火花。