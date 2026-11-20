# Apple 設計規範 AI 操作指南

更新日期：2026 年 11 月 15 日。

本指南用來設定 AI coding agent，讓它在規劃、實作與檢查 Apple 平台介面時，查閱 Apple Human Interface Guidelines（HIG）、使用對應 Skills，並遵循專案自己的設計決策。主要涵蓋 Codex、Claude Code 與 Cursor；安裝預設只作用於目前專案。

建議組合是：`apple-hig` 負責設計決策；SwiftUI 專案另加 `swiftui-expert-skill`；`AGENTS.md` 負責提醒 AI 何時使用；`DESIGN.md` 保存產品自己的設計規格。

# 一 先決定適用範圍與資料來源

設定前，請 AI 從專案確認目標平台、框架與最低支援 OS。若專案尚未建立，就將未知欄位列為待確認，先完成可確定的設定。

| 專案類型 | 建議配置 |
| --- | --- |
| iOS 或 iPadOS，使用 SwiftUI | 安裝 apple-hig 與 swiftui-expert-skill |
| macOS，使用 SwiftUI | 安裝兩套，但依 macOS 的輸入、視窗及導覽慣例判斷 |
| UIKit 或 AppKit 專案 | 安裝 apple-hig；依實際框架查官方 API 文件 |
| Web、React Native、Flutter | 可參考 apple-hig 的設計原則；保留原技術棧，分別確認宿主平台的實作方式 |
| 只有一般聊天介面 | 使用本文與官方文件作為參考；無檔案或終端工具時，不能完成本機 Skill 安裝 |

## 官方參考入口

- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)

- [HIG 官方 Markdown 索引](https://developer.apple.com/design/human-interface-guidelines.md)

- [Apple Design Resources](https://developer.apple.com/design/resources/)

- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

- [Layout](https://developer.apple.com/design/human-interface-guidelines/layout)

HIG Markdown 首頁是索引；AI 仍須開啟本次任務相關的章節。請區分 Apple 官方要求、官方建議、Skill 作者的整理，以及專案自己的選擇。使用者的產品需求與既有專案限制需要一併考量；偏離指引時，記下理由與影響。Skills 不改變工具原有權限。

# 二 選擇要安裝的 Skills

| Skill | 來源 | 用途 |
| --- | --- | --- |
| `apple-hig` | [daft2/apple-hig-skill](https://github.com/daft2/apple-hig-skill) | 元件選擇、導覽、字體、配色、版面、無障礙與設計檢查 |
| `swiftui-expert-skill` | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) | SwiftUI 狀態、View 組織、導覽、版面、效能及 API 使用 |

兩套都是第三方資源。HIG Skill 的 README 註明以 2026 年 8 月的 HIG 整理，重要細節應再核對 Apple 現行文件。SwiftUI Skill 僅在專案使用 SwiftUI 時加裝。

不要只下載 `SKILL.md`。HIG Skill 的同一資料夾還包含 `PLATFORMS.md`、`FOUNDATIONS.md`、`PATTERNS.md`、`COMPONENTS.md`、`INPUTS.md`、`TECHNOLOGIES.md` 和 `CHECKLIST.md`。SwiftUI Skill 也有配套的 `references/` 等檔案，應保留整個技能資料夾。

來源：[HIG README](https://github.com/daft2/apple-hig-skill/blob/main/README.md)、[HIG SKILL.md](https://github.com/daft2/apple-hig-skill/blob/main/skills/apple-hig/SKILL.md)、[SwiftUI 安裝說明](https://github.com/AvdLee/SwiftUI-Agent-Skill/blob/main/INSTALLATION.md)。

# 三 下載與安裝

## 3.1 在實際開發環境開啟專案

先進入 App 專案根目錄，再執行安裝。若 agent 在 WSL、SSH 主機或容器執行，就在該環境與對應專案目錄操作。

先讀取既有的 `AGENTS.md`、`CLAUDE.md`、Cursor 規則與已安裝技能，保留其內容。若已有同名 Skill，確認來源與版本後再決定是否更新，避免同時安裝同一套 Skill 與 plugin 版本。

本指南使用 [Vercel Skills CLI](https://github.com/vercel-labs/skills)。目前 README 要求 Node.js 22.20 或更新版本。先確認：

```bash
node --version
npm --version
git --version
```

若不具備這些工具，可使用下方的手動下載方式。安裝或升級 Node.js 請依現有開發環境的管理方式處理。

## 3.2 選擇自己的 agent

| 你使用的工具 | `--agent` 值 | 本指南使用的專案 Skill 目錄 |
| --- | --- | --- |
| Codex | `codex` | `.agents/skills/` |
| Claude Code | `claude-code` | `.claude/skills/` |
| Cursor | `cursor` | `.agents/skills/` |

這是目前 Vercel CLI 的安裝目標。Cursor 官方也支援 `.cursor/skills/`。安裝時選擇你實際使用的工具即可；多工具專案應檢查既有來源，避免重複發現同名技能。

來源：[Vercel supported agents](https://github.com/vercel-labs/skills/blob/main/docs/agents.md)、[Codex Skills](https://learn.chatgpt.com/docs/build-skills)、[Claude Code Skills](https://code.claude.com/docs/en/skills)、[Cursor Skills](https://cursor.com/docs/skills)。

## 3.3 安裝 HIG Skill

以下三行只選適合你的一行：

```bash
npx skills@latest add daft2/apple-hig-skill --skill apple-hig --agent codex --copy
```

```bash
npx skills@latest add daft2/apple-hig-skill --skill apple-hig --agent claude-code --copy
```

```bash
npx skills@latest add daft2/apple-hig-skill --skill apple-hig --agent cursor --copy
```

不加 `-g`，所以使用專案安裝。`--copy` 會使用實體複本；本指南選它以方便檢查檔案與跨環境搬移。CLI 的預設符號連結方式也可使用。

安裝前若想先看 repository 中可用技能：

```bash
npx skills@latest add daft2/apple-hig-skill --list
```

## 3.4 SwiftUI 專案再安裝實作 Skill

以 Codex 為例；其他工具將 `codex` 改成 `claude-code` 或 `cursor`：

```bash
npx skills@latest add AvdLee/SwiftUI-Agent-Skill --skill swiftui-expert-skill --agent codex --copy
```

這些指令只下載與設定 agent 的技能資料，不會把 Web 或其他框架專案轉換為 SwiftUI。

命令與旗標依據：[Vercel CLI reference](https://github.com/vercel-labs/skills/blob/main/docs/commands.md)。

## 3.5 不使用 Skills CLI 時的手動方式

在專案外的暫存位置，從 repository 下載 ZIP，或用 Git 取得來源：

```bash
git clone --depth 1 https://github.com/daft2/apple-hig-skill.git
git clone --depth 1 https://github.com/AvdLee/SwiftUI-Agent-Skill.git
```

第二個 repository 只在需要 SwiftUI Skill 時下載。接著複製整個技能資料夾：

| 來源資料夾 | Codex 或 Cursor 目標 | Claude Code 目標 |
| --- | --- | --- |
| `apple-hig-skill/skills/apple-hig/` | `<專案>/.agents/skills/apple-hig/` | `<專案>/.claude/skills/apple-hig/` |
| `SwiftUI-Agent-Skill/skills/swiftui-expert-skill/` | `<專案>/.agents/skills/swiftui-expert-skill/` | `<專案>/.claude/skills/swiftui-expert-skill/` |

複製後檢查 `SKILL.md` 是否直接位於目標技能資料夾內，不要多出一層 repository 名稱。保留上游授權檔與來源資訊。手動下載不代表具有 CLI 的安裝追蹤記錄，更新時應使用原本的下載方式或明確遷移至 CLI 管理。

# 四 設定持續生效的專案規則

Skill 提供知識與工作流程；專案規則告訴 AI 何時讀取它。建議在專案根目錄使用 `AGENTS.md` 保存共用規則，並用 `DESIGN.md` 保存設計決策。

## 4.1 可合併到 AGENTS.md 的範本

以下為本專案工作規則範本，不是 Apple 官方原文。若檔案已存在，只合併相關段落。

```markdown
## Apple 介面設計與檢查

適用於 Apple 平台 UI 的規劃、實作、修改與審查。
維持使用者的產品需求、既有技術棧、最低支援 OS 與已確認的專案限制。

### 使用資料

- 涉及上述 UI 任務時，先讀取本專案 apple-hig 的 SKILL.md，
  再依任務讀取目標平台、元件、模式與無障礙相關章節。
- SwiftUI 專案同時使用 swiftui-expert-skill，
  只讀取此次實作需要的 references。
- 已存在 DESIGN.md 時，先讀取與本次變更相關的設計決策；
  新決策應合併回該文件。
- 重要設計細節與版本敏感的 API，以 Apple 現行 HIG
  與開發文件查證。區分官方要求、官方建議、社群整理與專案選擇。
- 找不到 Skill、無法開啟來源或無法執行驗證時，回報具體缺口，
  並完成仍可進行的工作；不要宣稱已讀取或已通過。

### 設計與實作

- 從使用者任務、資訊層級與導覽開始，說明元件選擇的理由。
- 優先採用目標平台提供的合適元件與互動方式。
- 依平台處理安全區域、鍵盤、視窗尺寸及不同輸入方式。
- 使用一致的語意化色彩、文字層級與元件規則。
- 在支援的平台處理 Dynamic Type；其他平台採合適的文字縮放方式。
- 檢查 VoiceOver 標籤、閱讀順序、焦點、對比，
  以及適用的減少動態效果與透明度設定。
- 依任務補齊載入中、空白、錯誤、停用與成功等狀態。
- 使用 Liquid Glass 或新 API 前，核對官方使用情境、
  最低系統版本與必要的退回方案。
- 具體尺寸依平台與元件查證，不將單一數字套用所有 Apple 平台。

### 完成條件

- 依變更範圍執行可用的建置、預覽、操作檢查與必要測試。
- 將程式碼檢查、建置成功、畫面檢查與實際輔助功能操作分別回報。
- 說明已修正問題、採用規範、保留的取捨與仍未驗證項目。
```

Codex 官方說明 `AGENTS.md` 會作為專案指令讀取；Cursor 也支援此文件作為規則入口。規則應保持精簡，以任務條件載入相關資料，不必每次小修改都讀完所有 HIG。

來源：[Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[Cursor Rules](https://cursor.com/docs/rules)。

## 4.2 Claude Code 的設定

在專案根目錄的 `CLAUDE.md` 合併加入：

```markdown
@AGENTS.md
```

現行 Claude Code 在特定條件下也會直接讀 `AGENTS.md`；這個 import 可以兼容已有 `CLAUDE.md` 的專案及較舊環境，官方說明不會因此重複讀取同一份文件。

來源：[Claude Code memory](https://code.claude.com/docs/en/memory)。

## 4.3 Cursor 的設定

本指南直接使用根目錄 `AGENTS.md`，不要求再複製一份相同規則到 `.cursor/rules/`。若專案已使用 Cursor Project Rules，保留既有結構並合併路由即可。

需要 Project Rule 時，其副檔名是 `.mdc`。以下是替代入口範例：

```markdown
---
description: Apple UI design and review guidance
alwaysApply: true
---

For Apple UI design, implementation, or review tasks, read and apply
the Apple UI section in the repository root AGENTS.md.
```

這段只讓入口規則持續可見；Skill 的詳細內容仍應按任務讀取。根目錄 AGENTS.md 路線與此替代路線擇一維護即可。

# 五 驗證設定是否真的生效

## 5.1 檢查安裝記錄與檔案

CLI 安裝可執行：

```bash
npx skills@latest list
```

必要時只看自己的 agent：

```bash
npx skills@latest list --agent codex
```

確認出現 `apple-hig`；SwiftUI 專案另有 `swiftui-expert-skill`。接著確認對應技能資料夾與配套參考檔存在。CLI 清單只能證明安裝狀態，還需要讓 agent 實際讀取。

## 5.2 明確呼叫技能

| 工具 | 手動使用方式 |
| --- | --- |
| Codex CLI 或 IDE extension | 輸入 `$apple-hig`，或先用 `/skills` 選擇 |
| Claude Code | 輸入 `/apple-hig` |
| Cursor | 在 Agent chat 輸入 `/`，搜尋並選擇 `apple-hig` |

SwiftUI Skill 同理使用 `swiftui-expert-skill` 的名稱。手動呼叫一次只代表該次任務使用；後續是否使用仍要看專案規則、任務內容與技能選擇。

Codex 通常會偵測技能變更；若未出現，重新啟動。Claude Code 會監看既有技能目錄；如果會話開始後才首次建立頂層技能目錄，可用 `/reload-skills`。Cursor 若看不到新技能，可重新開啟工作區。更改專案指令後，開一個新會話驗證最清楚。

來源：[Codex Skills](https://learn.chatgpt.com/docs/build-skills)、[Claude Code Skills](https://code.claude.com/docs/en/skills)、[Cursor Skills](https://cursor.com/docs/skills)。

## 5.3 可直接使用的驗證指令

```text
請驗證本專案的 Apple 設計 Skills 設定。

1. 找出 apple-hig，實際讀取它的 SKILL.md，回報完整路徑。
2. 讀取 PLATFORMS.md 中本專案目標平台的章節，
   以及 FOUNDATIONS.md、CHECKLIST.md 與此次介面相關的部分。
3. 若專案使用 SwiftUI，讀取 swiftui-expert-skill 的 SKILL.md
   與至少一份此次任務相關的 reference。
4. 回報已載入的專案規則文件與目前技術棧。
5. 列出五項這個專案應採用的具體規則，附來源檔案或官方連結。
6. 指出仍需查證的規範與無法執行的驗證。
本次先檢查設定，不修改應用程式功能。
```

如果 AI 只回覆「已啟用 Apple 風格」，請要求它提供實際讀檔結果。單靠口頭確認不足以判斷技能是否被使用。

# 六 建立自己的 DESIGN.md

`DESIGN.md` 是專案設計決策文件，本指南不要求綁定特定工具的 schema。它通常不會只因檔名存在就被所有 agent 自動讀取，所以前面的專案規則需要明確指向它。

建議包含：

| 區塊 | 應記錄內容 |
| --- | --- |
| 專案背景 | 主要使用者、核心任務、目標平台、最低 OS、框架 |
| 資訊架構 | 頁面、導覽、返回方式、主要與次要操作 |
| 視覺規則 | 語意色彩、文字層級、間距、形狀與亮暗模式 |
| 元件規則 | 按鈕、列表、表單、搜尋、彈出介面與選取方式 |
| 狀態 | 載入中、沒有資料、錯誤、成功、停用、離線等適用情境 |
| 自適應 | 大小螢幕、視窗縮放、橫向、鍵盤與焦點 |
| 無障礙 | 文字縮放、VoiceOver、對比、動態效果與操作目標 |
| 來源與例外 | 官方章節 URL、查閱日期、專案取捨與待確認項目 |

建立文件時，先沿用既有品牌與元件。只有涉及本次任務的新增或改動才更新設計決策，避免每次開發都重新生成一套風格。

## Apple 規範的幾個具體查核方向

- 字體：在支援的平台使用 Dynamic Type，檢查大字級下的換行、裁切與元件擠壓。macOS 的文字處理須依 macOS 指引判斷。

- 材質：Apple 將 Liquid Glass 定位於控制與導覽的功能層；內容層應依 Materials 章節選擇合適處理。

- 無障礙：以實際介面檢查資訊是否能被理解、感知和操作，並使用可用的輔助功能檢查工具。

來源：[Typography](https://developer.apple.com/design/human-interface-guidelines/typography)、[Materials](https://developer.apple.com/design/human-interface-guidelines/materials)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)。

# 七 後續日常使用指令

以下文字貼在 agent 的聊天框。Codex 可在前面加上 `$apple-hig`；Claude Code 用 `/apple-hig`；Cursor 先從 `/` 選取技能。需要 SwiftUI 實作時，再指定 `swiftui-expert-skill`。

## 7.1 新增畫面

```text
請依本專案 AGENTS.md、DESIGN.md 與 apple-hig，
設計並實作以下畫面：[填入畫面與使用者任務]。

沿用現有框架與最低支援 OS。
先說明資訊層級、導覽與元件選擇，再完成實作；
若是 SwiftUI，使用 swiftui-expert-skill。
處理此畫面適用的載入中、空白、錯誤與停用狀態。
依變更範圍檢查文字縮放、安全區域、鍵盤及無障礙。
最後回報採用的 HIG 依據、完成的驗證與未驗證事項。
```

## 7.2 修改既有畫面

```text
請用 apple-hig 檢查並改善 [指定畫面或檔案]。

保留既有功能與已確認的產品需求。
先列出影響操作、資訊理解或無障礙的問題，再處理視覺細節。
針對每個問題說明依據、影響與具體修改方式，
並完成本次範圍內的修正。
如果改動了共用設計決策，更新 DESIGN.md。
回報實際驗證結果與保留的取捨。
```

## 7.3 只做設計審查

```text
請依 apple-hig 與本專案 DESIGN.md 審查目前介面。

本次不修改程式。
請用表格列出：問題、影響、官方依據或專案規則、
建議修正、優先順序，以及需要實際裝置才能確認的項目。
優先處理操作與無障礙，再處理一致性與視覺細節。
不要將 Skill 作者的偏好當成 Apple 官方強制要求。
```

## 7.4 交付前驗證

```text
請針對本次變更完成 Apple 介面交付檢查。

依實際支援範圍，檢查亮暗模式、文字放大、不同視窗尺寸、
鍵盤遮擋、導覽返回、焦點順序、VoiceOver 標籤及錯誤狀態。
能執行的建置、預覽和操作檢查請實際執行。
把已通過、發現問題、不適用、未驗證分開回報，
附上檢查方法與必要的畫面或檔案證據。
```

# 八 更新與維護

用 CLI 安裝的技能可先檢查更新：

```bash
npx skills@latest check
```

再只更新這個專案需要的技能：

```bash
npx skills@latest update apple-hig --project
```

SwiftUI 專案另執行：

```bash
npx skills@latest update swiftui-expert-skill --project
```

更新前查看本機差異，更新後重新進行一次讀檔驗證。自己的規則放在 `AGENTS.md` 或 `DESIGN.md`，便於與上游技能分別維護。若 CLI 產生 `skills-lock.json`，保留它與技能來源記錄，方便團隊理解使用的版本。

`skills check` 發現可更新或本機有變更時可能回傳非零狀態；先看輸出內容，再判斷是否真的發生下載錯誤。

來源：[Vercel CLI reference](https://github.com/vercel-labs/skills/blob/main/docs/commands.md)。

# 九 常見問題

| 情況 | 檢查方式 |
| --- | --- |
| 安裝完成但找不到 Skill | 確認 agent 正在使用的專案根目錄、目標資料夾與 SKILL.md 位置，再檢查技能選單 |
| 只讀 SKILL.md，規則仍很空泛 | 要求讀取本次任務相關的配套章節，並回報實際來源 |
| Claude 沒有遵循共用規則 | 檢查 CLAUDE.md 的 @AGENTS.md import，以及目前載入的指令文件 |
| 新會話忘記設計規格 | 確認專案規則指向 DESIGN.md，且文件位於 agent 可讀的專案中 |
| Windows 安裝後 WSL 找不到 | 在實際執行 agent 的環境與專案中確認目錄；全域安裝位置不會自動相同 |
| AI 宣稱符合 HIG，只有程式碼檢查 | 要求分開回報程式碼、建置、畫面與實際操作的驗證狀態 |
| 第三方規則與官方文件不同 | 查現行官方章節，記錄差異與採用理由 |
| 新 API 超出最低 OS | 使用適合支援版本的 API，或加入經確認的 availability 檢查與退回方案 |
| 無法開啟官方頁 | 試用官方 Markdown 或已保存的章節；標示查核日期與未查證項目 |
| 同名技能出現多次 | 檢查 project、user、plugin 的來源，合併方案前先保留既有內容 |

# 十 可以直接交給另一個 AI 的設定指令

將以下文字連同本指南交給具有專案檔案與終端權限的 AI。這次任務是完成技能與專案規則設定；應用畫面的開發再用第七節的指令開始。

```text
請依附上的 Apple 設計規範 AI 操作指南，
為目前專案建立可持續使用的 Apple HIG 設計工作流程。

一、先辨識環境
確認專案根目錄、目標平台、框架、最低支援 OS 與目前使用的 agent。
先讀既有的 AGENTS.md、CLAUDE.md、相關工具規則與設計文件。
依專案可確定的資訊繼續工作；不確定且不影響設定的欄位標為待確認。

二、下載與設定 Skills
在目前專案安裝 daft2/apple-hig-skill 的 apple-hig。
只有專案使用 SwiftUI 時，才加裝
AvdLee/SwiftUI-Agent-Skill 的 swiftui-expert-skill。
使用指南中對應 agent 的 project-level 安裝命令，
保留完整技能資料夾與配套檔案。
先確認既有安裝，避免重複技能與 plugin 版本。
若 CLI 不可用，可依指南手動複製整個技能資料夾。
維持現有技術棧與工具權限。

三、建立持續指令
將指南第四節的 Apple 介面工作規則合併到 AGENTS.md，
保留所有既有且仍適用的指令。
Claude Code 專案在 CLAUDE.md 加入 @AGENTS.md。
Codex 與 Cursor 使用共用 AGENTS.md；
已有工具專屬規則時，合併必要入口並避免重複內容。

四、建立專案設計規格
依目前產品與程式碼建立或更新 DESIGN.md。
記錄目標平台、導覽、語意色彩、文字、元件、畫面狀態、
自適應、無障礙、官方參考連結、查閱日期與待確認項目。
以使用者需求與既有專案限制為前提，
區分官方要求、官方建議、社群整理及專案選擇。

五、實際驗證
執行可用的安裝清單檢查。
實際讀取 apple-hig 的 SKILL.md 與相關配套章節，
回報讀取的完整路徑與五項適用本專案的規則。
SwiftUI 專案另確認 swiftui-expert-skill 及相關 reference。
確認持續指令確實能在目前 agent 使用；
若需要重新載入或新會話，說明具體操作。

六、完成回報
列出已安裝技能、實際路徑、來源、修改或新增的設定文件、
驗證結果，以及下一次可直接使用的呼叫範例。
這次先完成設定，不任意改動產品畫面或更換框架。
缺少執行能力時，完成可做的部分並列出剩餘操作；
不要宣稱未執行的安裝、讀檔或驗證已成功。
```

# 十一 主要來源

1. [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

2. [HIG 官方 Markdown](https://developer.apple.com/design/human-interface-guidelines.md)

3. [Apple Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

4. [Apple Typography](https://developer.apple.com/design/human-interface-guidelines/typography)

5. [Apple Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

6. [Apple HIG Skill README](https://github.com/daft2/apple-hig-skill/blob/main/README.md)

7. [Apple HIG SKILL.md](https://github.com/daft2/apple-hig-skill/blob/main/skills/apple-hig/SKILL.md)

8. [SwiftUI Agent Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill)

9. [SwiftUI 安裝文件](https://github.com/AvdLee/SwiftUI-Agent-Skill/blob/main/INSTALLATION.md)

10. [Vercel Skills CLI](https://github.com/vercel-labs/skills)

11. [Vercel CLI commands](https://github.com/vercel-labs/skills/blob/main/docs/commands.md)

12. [Vercel 支援的 agents 與目錄](https://github.com/vercel-labs/skills/blob/main/docs/agents.md)

13. [Codex Skills](https://learn.chatgpt.com/docs/build-skills)

14. [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

15. [Claude Code Skills](https://code.claude.com/docs/en/skills)

16. [Claude Code memory](https://code.claude.com/docs/en/memory)

17. [Cursor Skills](https://cursor.com/docs/skills)

18. [Cursor Rules](https://cursor.com/docs/rules)
