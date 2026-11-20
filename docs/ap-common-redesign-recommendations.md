# `ap_common` 套件配合 Liquid Glass 新設計之修改紀錄與演進建議

因應 `NSYSU-AP` 移除傳統「漢堡選單（`ApDrawer`）+ `HomePageScaffold`」並全面升級為 **Apple HIG / Liquid Glass 4 分頁浮動膠囊導覽架構**，本文件彙整：
1. 已於本機 `/Users/kaijin/TWCKaijin/_playground/ap_common`（`new-widget-design` 分支）直接實作的非破壞性配合修改；
2. 針對 `ap_common` 套件內部元件、Scaffold、Theme 與導覽架構的後續結構性改正建議。

---

## 一、已於 `ap_common`（`new-widget-design` 分支）完成的配合修改

以下修改皆已直接套用至 `/Users/kaijin/TWCKaijin/_playground/ap_common` 的 `new-widget-design` 分支，並維持 100% 向後相容：

### 1. `ApTheme` 支援表面色／透明導覽列模式（`surfaceAppBar`）
- **檔案**：`packages/ap_common_flutter_ui/lib/src/resources/ap_theme.dart`
- **問題原因**：
  原本 `ApTheme._buildTheme` 在 Light Mode 下強制將 `AppBarTheme.backgroundColor` 設為 `colorScheme.primary`（實心主色藍），且將 `TabBarThemeData.labelColor` 與 `indicatorColor` 寫死為 `colorScheme.onPrimary`（白色）。當採用 Apple HIG 的淺色表面背景（`#F2F2F7`）或透明 AppBar 時，Light Mode 下的 `TabBar` 文字與指示器會呈現「白底白字」而無法辨識。
- **已作修改**：
  於 `ApTheme.light()` 與 `ApTheme.dark()` 新增 `bool surfaceAppBar = false` 參數（預設 `false` 不影響舊版 App）。當 `surfaceAppBar: true` 時，Light Mode 的 `AppBarTheme` 自動採用 `colorScheme.surface` 背景與 `colorScheme.onSurface` 文字／圖示，且 `TabBarThemeData` 自動改用 `colorScheme.primary` 作為選中文字與指示條顏色。

### 2. `HomePageScaffold` 寬螢幕無抽屜（`drawer == null`）空指標防護
- **檔案**：`packages/ap_common_flutter_ui/lib/src/scaffold/home_page_scaffold.dart`
- **問題原因**：
  第 173 行原本寫死 `if (isTablet) widget.drawer!`，當任何 App 移除漢堡選單（不傳入 `drawer`）並在平板或桌面寬螢幕（`shortestSide >= 680`）執行時，會直接觸發 `Null check operator used on a null value` 崩潰。
- **已作修改**：
  改為 `if (isTablet && widget.drawer != null) widget.drawer!`，確保無抽屜架構在寬螢幕下的安全性。

### 3. `TodayScheduleCard` 與 `QuickInfoRow` 尊重主題 `CardTheme` 並強化無障礙回饋
- **檔案**：`packages/ap_common_flutter_ui/lib/src/widgets/home_dashboard_widgets.dart`
- **問題原因**：
  1. `TodayScheduleCard` 與 `QuickInfoRow` 原本硬編碼 `colorScheme.surfaceContainerLowest`，忽略了外部 `ThemeData.cardTheme.color`（例如 Apple Dark Mode 的 `#1C1C1E` 純粹深灰卡片色）。
  2. `TodayScheduleCard` 僅使用 `GestureDetector`，缺乏按壓水波紋／視覺回饋與 `Semantics(button: true)` 無障礙標記。
- **已作修改**：
  - 優先讀取 `Theme.of(context).cardTheme.color ?? colorScheme.surfaceContainerLowest`。
  - 為 `TodayScheduleCard` 加入 `Semantics(button: onTap != null)`、`Material` 與 `InkWell`（20pt 圓角），符合 Apple HIG 互動回饋與無障礙要求。

### 4. `SettingCard` 尊重主題 `CardTheme.color`
- **檔案**：`packages/ap_common_flutter_ui/lib/src/widgets/setting_page_widgets.dart`
- **問題原因**：
  `SettingCard` 同樣硬編碼 `colorScheme.surfaceContainerLowest`，導致 `SettingPage` 在 Dark Mode 下與新設計的卡片底色不一致。
- **已作修改**：
  改為 `Theme.of(context).cardTheme.color ?? colorScheme.surfaceContainerLowest`，使設定頁卡片自動融入 Apple HIG 深淺色主題。

### 5. `UserInfoScaffold` 的 `SliverAppBar` 前景色與圖示對比保護
- **檔案**：`packages/ap_common_flutter_ui/lib/src/scaffold/user_info_scaffold.dart`
- **問題原因**：
  `UserInfoScaffold` 的 `SliverAppBar` 在 Light Mode 下使用 `colorScheme.primary` 深色漸層背景與白色標題，但未明確指定 `foregroundColor` 與 `iconTheme`。當外部 App 將全域 `AppBarTheme.iconTheme` 改為深色（`onSurface`）以配合 Apple 淺色標題列時，`UserInfoScaffold` 左上角返回鍵與右上角重新整理／編輯圖示在 Light Mode 下會變成深色，與深色漸層背景缺乏對比。
- **已作修改**：
  在 `UserInfoScaffold` 的 `SliverAppBar` 明確指定 `foregroundColor` 與 `iconTheme` 為 `isDark ? colorScheme.onSurface : colorScheme.onPrimary`。

---

## 二、後續 `ap_common` 套件進階架構改正建議

為了讓整個 `ap_common` 生態系（包含 NKUST-AP、NSYSU-AP 等校務通系列）都能原生共享此次 Apple Liquid Glass 與底部浮動膠囊設計，建議在 `ap_common_flutter_ui` 推動以下演進：

### 建議 1：將 `LiquidGlassSurface`、`LiquidGlassTabBar` 與 `AppleGroupedSection` 上收至 `ap_common_flutter_ui`
- **現況**：`ap_common_flutter_ui` 目前僅提供傳統 `HomePageScaffold` + `ApDrawer`（漢堡選單 + Material `NavigationBar`），迫使想採用現代底部浮動膠囊導覽的 App 自行實作根殼層。
- **具體建議**：
  - 將 `NSYSU-AP` 新增的 `LiquidGlassTheme`、`LiquidGlassSurface`、`LiquidGlassTabBar`（含 `trailingAction` 4+1 右側獨立圓形按鈕擴充槽）、`ApplePageHeader`（大標題 + 右上角圓形個人頭像）、`AppleGroupedSection` 及 `AccountSheet` 抽離至 `ap_common_flutter_ui`。
  - 新增 `ApFloatingShellScaffold`，允許各校 App 只需傳入 4~5 個分頁定義與 `trailingAction` 即可完成無漢堡選單的現代化導覽。

### 建議 2：淘汰 `HomePageScaffold.showSnackBar` 的 1 天超長時效循環未登入提示
- **現況**：`HomePageScaffoldState.showSnackBar` 預設 `duration: const Duration(days: 1)`，各校 App 過去常在 `_checkLoginState()` 中搭配 `.closed.then(...)` 無限循環彈出底部 `SnackBar`。在浮動底欄架構下，常駐 `SnackBar` 會直接遮擋或頂起底部導覽列，且違反 Apple HIG「以內嵌狀態取代干擾式橫幅」的原則。
- **具體建議**：
  - 在 `ap_common_flutter_ui` 提供標準化的 `InlineLoginPromptCard` 元件（置於首頁課表區塊位置）。
  - 將 `showSnackBar` 預設時長改回標準 4 秒，並將循環 `SnackBar` 模式標記為 `@Deprecated`。

### 建議 3：內頁 Scaffold（`CourseScaffold`、`ScoreScaffold`、`AnnouncementHomePage`）新增嵌入式與底部浮動留白支援
- **現況**：
  - `CourseScaffold` 與 `ScoreScaffold` 內部皆固定包了一層帶 `AppBar` 與 `FloatingActionButton` 的 `Scaffold`。
  - 若未來某校 App 希望將「課表」或「成績」直接作為底部浮動膠囊的根分頁（而非由「課業 Hub」推入），其內建的 `FloatingActionButton` 與底部捲動清單會與浮動膠囊導覽列重疊。
- **具體建議**：
  - 為 `CourseScaffold` 與 `ScoreScaffold` 新增 `bool embedded = false` 與 `double bottomSafePadding = 0.0` 參數。
  - 當 `embedded: true` 時，不顯示左上角返回鍵，並自動將清單底部 padding 與 FAB 位置向上偏移 `bottomSafePadding`（例如 `LiquidGlassTabBar.bottomClearance`）。

### 建議 4：`ApTheme` 原生提供 `iOSThemeColors` 與 `AppleLiquidTheme` 模式切換
- **現況**：`ApTheme` 雖然已定義 `iOSThemeColors` 常數（第 81 行），但 `getSeedColor()` 與 `ChangeThemeColorItem` 仍綁定舊版 Material `themeColors`。
- **具體建議**：
  - 在 `ApTheme` 新增 `ApDesignStyle { material3, appleLiquidGlass }` 設定。
  - 當設為 `appleLiquidGlass` 時，`ApTheme.light` / `ApTheme.dark` 自動啟用 `surfaceAppBar: true`、套用 `#000000` / `#F2F2F7` 畫布底色與 `#1C1C1E` / `#FFFFFF` 卡片色，並注入 `LiquidGlassTheme` `ThemeExtension`。

### 建議 5：`NSYSU-AP` 串接本機或遠端 `ap_common` `new-widget-design` 分支的方式
目前 `NSYSU-AP` 的 `pubspec.yaml` 引用的是發布版 `ap_common: ^1.0.1-dev.13`。若要在開發期直接套用本機 `ap_common`（`new-widget-design` 分支）的修改，可於 `NSYSU-AP/pubspec.yaml` 的 `dependency_overrides` 加入：

```yaml
dependency_overrides:
  ap_common:
    path: ../ap_common/packages/ap_common
  ap_common_core:
    path: ../ap_common/packages/ap_common_core
  ap_common_flutter_core:
    path: ../ap_common/packages/ap_common_flutter_core
  ap_common_flutter_ui:
    path: ../ap_common/packages/ap_common_flutter_ui
  ap_common_flutter_platform:
    path: ../ap_common/packages/ap_common_flutter_platform
  ap_common_announcement_ui:
    path: ../ap_common/packages/ap_common_announcement_ui
  ap_common_firebase:
    path: ../ap_common/packages/ap_common_firebase
  ap_common_plugin:
    path: ../ap_common/packages/ap_common_plugin
```
待 `ap_common` 的 `new-widget-design` 分支合併並發布新版本後，再移除 path overrides 並升級版號即可。
