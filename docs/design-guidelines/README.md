# 設計規範與專案 Skills

下載日期：2026-11-18。安裝範圍：本專案 `.agents/skills/`。

## Space 原始指南

已將 [Apple 設計規範 AI 操作指南](https://chatgpt.com/space/page_01d734d5d5d4819194698da961c726ff) 的標題及全部內容區塊，依原順序匯出為 [apple-space-guide.md](apple-space-guide.md)。原頁更新日期為 2026-11-15；匯出資訊見 [apple-space-guide.source.json](apple-space-guide.source.json)。這是你的操作指南快照，不是 Apple HIG 全站鏡像。

## 已安裝

以下為第三方社群 skill，不是官方發布的 skill。完整來源 commit、檔案 SHA-256 見 [sources.lock.json](sources.lock.json)。

| 平台／系統 | Skill | 上游來源 | 官方規範 |
| --- | --- | --- | --- |
| Apple | `apple-hig` | [daft2/apple-hig-skill](https://github.com/daft2/apple-hig-skill/tree/d7fb4531db34115c2dd7c2089abd3641362a8a98/skills/apple-hig) | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/) |

Apple 包含七份主題／檢查參考文件。技能資料夾完整下載，未執行其中的示範程式。

## 使用方式

本專案可使用此專案 skill；根目錄 [AGENTS.md](../../AGENTS.md) 也提供直接讀檔入口。

```text
$apple-hig 請審查畫面的 Liquid Glass 導覽、排版與無障礙。
```

Flutter 共用畫面遵循 Apple HIG 與 Liquid Glass 視覺規範，同時保留既有 `ApTheme` 主題色設定與深淺色切換。上游的 Swift／UIKit 範例需轉換成適合既有 Flutter 版本的做法。

## 授權與維護

- Apple：保留上游 `UPSTREAM-LICENSE`。
- 安裝使用 Codex skill-installer，固定 Git commit；`sources.lock.json` 是本專案來源記錄，不是 Vercel Skills CLI 的 lockfile。更新時先比較上游版本，再重新下載完整技能資料夾並更新校驗值，不直接覆寫本機修改。
- 這些快照未經逐條官方合規認證。上游的強制語氣、色碼、尺寸與品牌主張仍需以現行官方章節核對。
