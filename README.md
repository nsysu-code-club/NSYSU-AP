[![Build Test](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/workflow.yml/badge.svg)](https://github.com/nsysu-code-club/NSYSU-AP/actions/workflows/workflow.yml)
# 中山校務通

 提供中山大學學生查詢基本校務系統功能，由 Google 開源跨平台框架 [Flutter](https://flutter.dev/) 開發

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
 - Flutter 穩定版本 v3.24
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
