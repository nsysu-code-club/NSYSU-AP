# Endpoint Catalog

每個 NSYSU 真實 endpoint、用什麼 method、回什麼編碼、成功的辨識方式。
學校沒有官方 API 文件，這份是我們從 prod 觀察 + 試錯整理出來的——更動 helper / parser 之前先看這份。

---

## 慣例

- **Sentinel** 欄位寫的是「helper 怎麼判斷成功」。對 `selcrs` / `tfstu` 系列的登入流程，學校 server 不回 200/JSON，而是用 `302 + Location` 跳轉表示登入成功；helper 接到 `DioException` 但 `statusCode == 302` 才算對。
- **Encoding** 欄是 response body 的字元集——選課/成績系統的 HTML 是 BIG-5（`parse(text, encoding: 'BIG-5')`），其它新系統大多 UTF-8。
- **Timeout text** 欄是 session 失效時 server 回的中文字串；helper 偵測到後會自動 reLogin（最多 5 次）。

---

## 1. 選課系統 — `selcrs.nsysu.edu.tw`

### 1.1 登入（兩段式：成績系統 → 選課系統）

| Path | Method | Body | Sentinel | 備註 |
|---|---|---|---|---|
| `/scoreqry/sco_query_prs_sso2.asp` | POST | `SID`, `PASSWD`(base64md5), `ACTION=0`, `INTYPE=1` | `302 → sco_query.asp?action=101` | 成績系統第一道 SSO；錯密碼回 200 含「資料錯誤請重新輸入」 |
| `/menu4/Studcheck_sso2.asp` | POST | `stuid`, `SPassword`(base64md5) | `302 → main_frame.asp` | 選課系統第二道；錯密碼回 200 含「學號碼密碼不符」；需要填表回「請先填寫」(401) |

實作：`SelcrsHelper.login()`。失敗會 `changeSelcrsUrl()`（學校有 4 台 mirror），重試上限 5 次。

### 1.2 個人資訊

| Path | Method | Helper | Encoding | Sentinel | Timeout text |
|---|---|---|---|---|---|
| `/menu4/tools/changedat.asp` | GET | `getUserInfo` / `parseUserInfo` | UTF-8 | 200 + 至少 10 個 `<td>` | 「請重新登錄」 |
| `/menu4/tools/changedat.asp` | POST `T1=<email>` | `changeMail` | UTF-8 | 同上 | 同上 |

### 1.3 課表

| Path | Method | Body | Encoding | Helper |
|---|---|---|---|---|
| `/menu4/query/stu_slt_up.asp` | POST | — | UTF-8 | `getCourseSemesterData` |
| `/menu4/query/stu_slt_data.asp` | POST | `stuact=B`, `YRSM=<年學期>`, `Stuid=<學號>`, `B1=%BDT%A9w%B0e%A5X` | UTF-8 | `getCourseData` |

`YRSM` 拼接：學年（ROC，3 碼）+ 學期值（`1`=上、`2`=下），例如 `1132` = 113 學年下學期。
課程標題的 `<a>` 內文以 `<br>` 分隔中／英；`languageProvider()` 決定取哪一段。

### 1.4 成績

| Path | Method | Query / Body | Encoding | Helper |
|---|---|---|---|---|
| `/scoreqry/sco_query.asp?ACTION=702&KIND=2&LANGS={cht\|eng}` | POST | — | **BIG-5** | `getScoreSemesterData` |
| `/scoreqry/sco_query.asp?ACTION=804&KIND=2&LANGS={cht\|eng}` | POST | `SYEAR=<年>`, `SEM=<1\|2>` | **BIG-5** | `getScoreData` |
| `/scoreqry/sco_query.asp?ACTION=814&KIND=1&LANGS={cht\|eng}` | POST | `CRSNO=<課號>` | **BIG-5** | `getPreScoreData`（選擇性 — 期中時撈授課老師預給分） |

`LANGS` 跟 selcrs 的中英版本綁定，由 `SelcrsHelper.language` 決定（`languageProvider()` 回 `'en'` 時填 `eng`，否則 `cht`）。

### 1.5 學號查詢（找帳號用）

| Path | Method | Body | Encoding |
|---|---|---|---|
| `/newstu/stu_new.asp?action=16` | POST | `CNAME`(big5 + uri-encoded), `T_CID`(身分證末四碼), `B1=%BDT%A9w%B0e%A5X` | BIG-5 |

實作：`SelcrsHelper.getUsername`。送中文姓名前要先 `uriEncodeBig5(name)`。

---

## 2. 畢業審查 — `selcrs.nsysu.edu.tw/gadchk/`（同 host，獨立 session）

| Path | Method | Body | Sentinel |
|---|---|---|---|
| `/gadchk/gad_chk_login_prs_sso2.asp` | POST | `SID`, `PASSWD`(base64md5), `PGKIND=GAD_CHK`, `ACTION=0` | `302 → gad_chk.asp?action=1` |
| `/gadchk/gad_chk_stu_list.asp?stno=<學號>&KIND=5&frm=1` | GET | — | 200 |

注意：`GraduationHelper` 跟 `SelcrsHelper` **不共用 cookie jar**，需要獨立登入。錯密碼回 200 含「資料錯誤請重新輸入」(401)。

---

## 3. 學雜費 — `tfstu.nsysu.edu.tw`

| Path | Method | Body | Encoding | Sentinel |
|---|---|---|---|---|
| `/tfstu/tfstu_login_chk.asp` | POST | `ID=<學號>`, `passwd=<明文>` | — | `302 → tfstudata.asp?act=11` |
| `/tfstu/tfstudata.asp?act=11` | GET | — | **BIG-5** | 200 + `tbody[1]`；空清單時 body 含「沒有合乎查詢條件的資料」 |
| `/tfstu/<serialNumber>` | GET | — | bytes (PDF) | 200 |

⚠️ 這個系統的密碼**不做 hashing**——直接把明碼 POST 上去。架構決定，不是我們的選擇。
列表 row 的 `td[2]` 是混合編碼（中文 BIG-5 + 英文 ASCII 交錯），我們依 codeUnit < 200 拆雙語版本。
PDF 序號從 `<a onclick="javascript:window.location.href='...'">` 解出。

---

## 4. 校車 — `ibus.nsysu.edu.tw` + GitHub Pages CDN

| Path | Method | Body | Encoding | Helper |
|---|---|---|---|---|
| `https://nsysu-code-club.github.io/nsysu-bus/bus_info_data_{zh\|en}.json` | GET | — | UTF-8 | `getBusInfoList` |
| `https://ibus.nsysu.edu.tw/API/RoutePathStop.aspx?<timestamp>` | POST (FormData) | `RID`, `C={zh\|en}`, `CID` | UTF-8 | `getBusTime` |

校車不需要登入。`getBusInfoList` 抓的不是學校 server，是社團維護的 [nsysu-bus](https://github.com/nsysu-code-club/nsysu-bus) GitHub Pages CDN（學校 ibus 沒有公開的「全部路線」endpoint，只能查單條路線到站時間）。

URL query 後綴 `?<millisecondsSinceEpoch>` 是用來破 CDN cache，不是 auth。

---

## 5. 其它（已知但目前未實作）

這些 endpoint 在 root README 的爬蟲清單裡有列、但尚未抽 helper：

- 歷年學生缺曠課資料（選課系統）
- 通識教育講座次數查詢（選課系統）— 對應 #21
- 修改登錄密碼（選課系統）— 對應 #22
- 學生預警查詢（成績系統）— 對應 #23
- 各類所得郵局劃帳暨歸戶查詢系統 — 對應 #24
- 課程課綱（選課系統）— 對應 #35
- 收發室（信件查詢）— 對應 #45
- 總務處維修系統
- 歷年成績單
- 借書系統 — 對應 #36

加新 endpoint 時的流程：把真實 HTML 存進 `test/fixtures/`、寫 parser pure function、寫 fixture-based unit test、最後在 helper 裡 wire 起來——詳見 `docs/adding-an-endpoint.md`（**TODO**：實作第一個新 endpoint 時順便寫）。

---

## 觀察新 endpoint 的工具

跑 live test 時 set `NSYSU_HTTP_LOG=1`：

```bash
NSYSU_USER=... NSYSU_PASS=... NSYSU_HTTP_LOG=1 \
  dart test -P live -r expanded
```

每個 dio request 的 method + URL（含 redirect chain）都會印出來，看完就知道 helper 實際打了哪些。對 reverse-engineer 新 endpoint 也方便。
