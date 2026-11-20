///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef AppLocalizationsZhHantTw = AppLocalizations; // ignore: unused_element
class AppLocalizations with BaseTranslations<AppLocale, AppLocalizations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final app = AppLocalizations.of(context);
	static AppLocalizations of(BuildContext context) => InheritedLocaleData.of<AppLocale, AppLocalizations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	AppLocalizations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, AppLocalizations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHantTw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hant-TW>.
	@override final TranslationMetadata<AppLocale, AppLocalizations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final AppLocalizations _root = this; // ignore: unused_field

	AppLocalizations $copyWith({TranslationMetadata<AppLocale, AppLocalizations>? meta}) => AppLocalizations(meta: meta ?? this.$meta);

	// Translations

	/// zh-Hant-TW: '中山校務通'
	String get appName => '中山校務通';

	/// zh-Hant-TW: '* 修正部分裝置桌面小工具無法顯示'
	String get updateNoteContent => '* 修正部分裝置桌面小工具無法顯示';

	/// zh-Hant-TW: 'https://github.com/nsysu-code-club/NSYSU-AP This project is licensed under the terms of the MIT license: The MIT License (MIT) Copyright © 2024 NSYSU Code Club This project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
	String get aboutOpenSourceContent => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.';

	/// zh-Hant-TW: '應屆畢業生成績檢核表'
	String get graduationCheckChecklist => '應屆畢業生成績檢核表';

	/// zh-Hant-TW: '學系必修課程缺修'
	String get missingRequiredCourses => '學系必修課程缺修';

	/// zh-Hant-TW: '通識課程'
	String get generalEducationCourse => '通識課程';

	/// zh-Hant-TW: '其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查'
	String get otherEducationsCourse => '其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查';

	/// zh-Hant-TW: '檢核'
	String get check => '檢核';

	/// zh-Hant-TW: '應修學分'
	String get shouldCredits => '應修學分';

	/// zh-Hant-TW: '實得學分'
	String get actualCredits => '實得學分';

	/// zh-Hant-TW: '累計學分'
	String get totalCredits => '累計學分';

	/// zh-Hant-TW: '修習情形'
	String get practiceSituation => '修習情形';

	/// zh-Hant-TW: '點擊科目名稱可看詳細資訊'
	String get courseClickHint => '點擊科目名稱可看詳細資訊';

	/// zh-Hant-TW: '本學期已選學分視同及格預審 資料僅供參考詳細請參考校務系統'
	String get graduationCheckChecklistHint => '本學期已選學分視同及格預審\n資料僅供參考詳細請參考校務系統';

	/// zh-Hant-TW: '尚未有任畢業檢核資料'
	String get graduationCheckChecklistEmpty => '尚未有任畢業檢核資料';

	/// zh-Hant-TW: '總結'
	String get graduationCheckChecklistSummary => '總結';

	/// zh-Hant-TW: '首次登入密碼預設為身分證末六碼'
	String get firstLoginHint => '首次登入密碼預設為身分證末六碼';

	/// zh-Hant-TW: '學雜費繳費狀況查詢'
	String get tuitionAndFees => '學雜費繳費狀況查詢';

	/// zh-Hant-TW: '學雜費與在學證明'
	String get tuitionAndCert => '學雜費與在學證明';

	/// zh-Hant-TW: '金額：${amount} 繳費日期：${date}'
	String tuitionAndFeesItemTitleFormat({required Object amount, required Object date}) => '金額：${amount}\n繳費日期：${date}';

	/// zh-Hant-TW: '入學指南'
	String get admissionGuide => '入學指南';

	/// zh-Hant-TW: '點擊可查看收據或繳費單'
	String get tuitionAndFeesPageHint => '點擊可查看收據或繳費單';

	/// zh-Hant-TW: '請選擇匯出方式'
	String get tuitionAndFeesPageDialogTitle => '請選擇匯出方式';

	/// zh-Hant-TW: '學年度'
	String get courseYear => '學年度';

	/// zh-Hant-TW: '選課小助手'
	String get courseSelector => '選課小助手';

	/// zh-Hant-TW: '碩專暑'
	String get continuingSummerEducationProgram => '碩專暑';

	/// zh-Hant-TW: '上學期'
	String get fallSemester => '上學期';

	/// zh-Hant-TW: '下學期'
	String get springSemester => '下學期';

	/// zh-Hant-TW: '暑假'
	String get summerSemester => '暑假';

	/// zh-Hant-TW: '碩專暑'
	String get continuingSummerEducationProgramShort => '碩專暑';

	/// zh-Hant-TW: '上'
	String get fallSemesterShort => '上';

	/// zh-Hant-TW: '下'
	String get springSemesterShort => '下';

	/// zh-Hant-TW: '暑'
	String get summerSemesterShort => '暑';

	/// zh-Hant-TW: 'Oops！查無任何學雜費資料哦～😋'
	String get tuitionAndFeesEmpty => 'Oops！查無任何學雜費資料哦～😋';

	/// zh-Hant-TW: '尚未載入課表，點擊查看'
	String get courseNotLoaded => '尚未載入課表，點擊查看';

	/// zh-Hant-TW: '部分科目為授課老師開放成績查詢 並非最終成績'
	String get hasPreScoreHint => '部分科目為授課老師開放成績查詢 並非最終成績';

	/// zh-Hant-TW: '請先填寫確認表單再進行登入 若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)'
	String get pleaseConfirmForm => '請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)';

	/// zh-Hant-TW: '開啟瀏覽器填寫'
	String get openBrowserToFill => '開啟瀏覽器填寫';

	/// zh-Hant-TW: '分'
	String get minute => '分';

	/// zh-Hant-TW: '進站中'
	String get busArriving => '進站中';

	/// zh-Hant-TW: '將到站'
	String get busComingSoon => '將到站';

	/// zh-Hant-TW: '表定 ${time}'
	String busScheduledTime({required Object time}) => '表定\n${time}';

	/// zh-Hant-TW: '已離站'
	String get busDeparted => '已離站';

	/// zh-Hant-TW: '未行駛'
	String get busNotOperating => '未行駛';

	/// zh-Hant-TW: '目前無車輛'
	String get busNoLiveBus => '目前無車輛';

	/// zh-Hant-TW: '拖車小幫手'
	String get towCarHelper => '拖車小幫手';

	/// zh-Hant-TW: '訂閱區域'
	String get subscriptionArea => '訂閱區域';

	/// zh-Hant-TW: '最新消息'
	String get towCarNews => '最新消息';

	/// zh-Hant-TW: '訂閱區域'
	String get towCarSubscriptionArea => '訂閱區域';

	/// zh-Hant-TW: '狀況回報'
	String get towCarAlertReport => '狀況回報';

	/// zh-Hant-TW: '可信度'
	String get credibility => '可信度';

	/// zh-Hant-TW: '多少人看過'
	String get viewCounts => '多少人看過';

	/// zh-Hant-TW: '發布時間'
	String get publishTime => '發布時間';

	/// zh-Hant-TW: '警報內容'
	String get alertContent => '警報內容';

	/// zh-Hant-TW: '回報區域'
	String get notificationArea => '回報區域';

	/// zh-Hant-TW: '上傳圖片'
	String get uploadImage => '上傳圖片';

	/// zh-Hant-TW: '全部區域'
	String get allArea => '全部區域';

	/// zh-Hant-TW: '處理中...'
	String get processing => '處理中...';

	/// zh-Hant-TW: '請提供照片'
	String get pleaseProvideImage => '請提供照片';

	/// zh-Hant-TW: '拖車小幫手系統 可透過此功能回報校園狀況 如果同意使用此系統 將透過中山大學校務系統的帳號密碼作為驗證機制 建立基本資料(不包含密碼)在我們的伺服器 一切將遵守雙平台商店隱私政策運作 回報時會以不具名提供資訊在此系統 影音則是公開上傳至 Imgur 任何資訊都會經過審查並非直接發佈 若同意以上資訊請點擊下方按鈕'
	String get towCarUploadPolicy => '拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕';

	/// zh-Hant-TW: '同意並開始上傳'
	String get agreeAndUpload => '同意並開始上傳';

	/// zh-Hant-TW: '尚未取得定位權限'
	String get notLocationPermissionHint => '尚未取得定位權限';

	/// zh-Hant-TW: '您的位置尚未在學校附近，無法發布'
	String get locationNotNearSchool => '您的位置尚未在學校附近，無法發布';

	/// zh-Hant-TW: '未知時間'
	String get unknownTime => '未知時間';

	/// zh-Hant-TW: '成功'
	String get success => '成功';

	/// zh-Hant-TW: '確認'
	String get optionComfirm => '確認';

	/// zh-Hant-TW: '取消'
	String get optionCancel => '取消';

	/// zh-Hant-TW: '將使用瀏覽器開啟外部網站，是否繼續？'
	String get openingBrowserContent => '將使用瀏覽器開啟外部網站，是否繼續？';

	/// zh-Hant-TW: '開啟外部網站'
	String get openingBrowserTitle => '開啟外部網站';

	/// zh-Hant-TW: '不安全的連結，請確認網址是否正確'
	String get visitingUnSafeLink => '不安全的連結，請確認網址是否正確';

	late final AppLocalizationsEnrollCertificateZhHantTw enrollCertificate = AppLocalizationsEnrollCertificateZhHantTw.internal(_root);

	/// zh-Hant-TW: '課業'
	String get tabStudy => '課業';

	/// zh-Hant-TW: '校園'
	String get tabCampus => '校園';

	/// zh-Hant-TW: '新功能'
	String get newFeature => '新功能';

	/// zh-Hant-TW: '最新公告'
	String get latestAnnouncements => '最新公告';

	/// zh-Hant-TW: '投稿'
	String get postAnnouncement => '投稿';

	/// zh-Hant-TW: '登入校務系統'
	String get loginCardTitle => '登入校務系統';

	/// zh-Hant-TW: '登入後即可查看今日課表、學期成績、畢業檢核與在學證明'
	String get loginCardSubtitle => '登入後即可查看今日課表、學期成績、畢業檢核與在學證明';

	/// zh-Hant-TW: '核心學務'
	String get studyCoreSection => '核心學務';

	/// zh-Hant-TW: '學務工具與證明'
	String get studyToolsSection => '學務工具與證明';

	/// zh-Hant-TW: '查看本學期課表與上課地點'
	String get courseSubtitle => '查看本學期課表與上課地點';

	/// zh-Hant-TW: '查詢各學期成績與學分明細'
	String get scoreSubtitle => '查詢各學期成績與學分明細';

	/// zh-Hant-TW: '檢視必修、通識與累計畢業學分'
	String get graduationCheckSubtitle => '檢視必修、通識與累計畢業學分';

	/// zh-Hant-TW: '下載學雜費收據與提取在學證明'
	String get tuitionAndCertSubtitle => '下載學雜費收據與提取在學證明';

	/// zh-Hant-TW: '開啟外部選課輔助工具網站'
	String get courseSelectorSubtitle => '開啟外部選課輔助工具網站';

	/// zh-Hant-TW: '校園服務'
	String get campusServicesSection => '校園服務';

	/// zh-Hant-TW: '應用程式'
	String get appSection => '應用程式';

	/// zh-Hant-TW: '瀏覽西子灣校區建築與位置導覽'
	String get schoolMapSubtitle => '瀏覽西子灣校區建築與位置導覽';

	/// zh-Hant-TW: '查詢校園常用電話與年度行事曆'
	String get schoolInfoSubtitle => '查詢校園常用電話與年度行事曆';

	/// zh-Hant-TW: '投稿校園活動宣傳或管理審核'
	String get announcementReviewSubtitle => '投稿校園活動宣傳或管理審核';

	/// zh-Hant-TW: '首頁輪播投稿系統'
	String get announcementSubmissionSystem => '首頁輪播投稿系統';

	/// zh-Hant-TW: '限非營利校園活動。請以活動名稱為標題，附上活動連結。封面會公開上傳至 ImgBB，建議使用 100 KB 以內的壓縮 JPEG，內文以 100 字為宜。'
	String get carouselGuidelines => '限非營利校園活動。請以活動名稱為標題，附上活動連結。封面會公開上傳至 ImgBB，建議使用 100 KB 以內的壓縮 JPEG，內文以 100 字為宜。';

	/// zh-Hant-TW: '輪播封面'
	String get carouselCover => '輪播封面';

	/// zh-Hant-TW: '選擇封面圖片'
	String get carouselPick => '選擇封面圖片';

	/// zh-Hant-TW: '更換圖片'
	String get carouselReplace => '更換圖片';

	/// zh-Hant-TW: '圖片將公開上傳至 ImgBB，建議使用 100 KB 以內的 JPEG。'
	String get carouselImageHint => '圖片將公開上傳至 ImgBB，建議使用 100 KB 以內的 JPEG。';

	/// zh-Hant-TW: '請先上傳封面圖片'
	String get carouselImageRequired => '請先上傳封面圖片';

	/// zh-Hant-TW: '圖片上傳失敗，請重新選擇圖片。'
	String get carouselUploadFailed => '圖片上傳失敗，請重新選擇圖片。';

	/// zh-Hant-TW: '活動資訊'
	String get carouselDetails => '活動資訊';

	/// zh-Hant-TW: '活動連結（選填）'
	String get carouselLink => '活動連結（選填）';

	/// zh-Hant-TW: '請輸入完整的 https 或 http 網址'
	String get carouselLinkError => '請輸入完整的 https 或 http 網址';

	/// zh-Hant-TW: '設定到期時間'
	String get carouselSetExpiry => '設定到期時間';

	/// zh-Hant-TW: '無到期時間'
	String get carouselNoExpiry => '無到期時間';

	/// zh-Hant-TW: '請選擇未來的到期時間'
	String get carouselExpired => '請選擇未來的到期時間';

	/// zh-Hant-TW: '活動說明'
	String get carouselBody => '活動說明';

	/// zh-Hant-TW: '輸入活動說明…'
	String get carouselBodyHint => '輸入活動說明…';

	/// zh-Hant-TW: '檢查'
	String get carouselCheck => '檢查';

	/// zh-Hant-TW: '投稿未送出，請再試一次。'
	String get carouselSubmitFailed => '投稿未送出，請再試一次。';

	/// zh-Hant-TW: '檢查投稿'
	String get carouselPreview => '檢查投稿';

	/// zh-Hant-TW: '粗體'
	String get carouselBold => '粗體';

	/// zh-Hant-TW: '斜體'
	String get carouselItalic => '斜體';

	/// zh-Hant-TW: '字型大小'
	String get carouselSize => '字型大小';

	/// zh-Hant-TW: '小字'
	String get carouselSmall => '小字';

	/// zh-Hant-TW: '標準'
	String get carouselNormal => '標準';

	/// zh-Hant-TW: '大字'
	String get carouselLarge => '大字';

	/// zh-Hant-TW: '項目符號'
	String get carouselBullet => '項目符號';

	/// zh-Hant-TW: '編號清單'
	String get carouselOrdered => '編號清單';

	/// zh-Hant-TW: '增加縮排'
	String get carouselIndent => '增加縮排';

	/// zh-Hant-TW: '減少縮排'
	String get carouselOutdent => '減少縮排';

	/// zh-Hant-TW: '開啟活動連結'
	String get carouselOpenLink => '開啟活動連結';

	/// zh-Hant-TW: '放大封面圖片'
	String get carouselZoom => '放大封面圖片';

	/// zh-Hant-TW: '${count} 則未審查公告'
	String pendingAnnouncementCount({required Object count}) => '${count} 則未審查公告';

	/// zh-Hant-TW: '使用具審查權限的公告帳號登入後，會連結目前的校務帳號，下次可自動登入審查系統。'
	String get announcementReviewLinkHint => '使用具審查權限的公告帳號登入後，會連結目前的校務帳號，下次可自動登入審查系統。';

	/// zh-Hant-TW: '使用 Google 登入'
	String get announcementGoogleSignIn => '使用 Google 登入';

	/// zh-Hant-TW: '使用 Apple 登入'
	String get announcementAppleSignIn => '使用 Apple 登入';

	/// zh-Hant-TW: '新增公告'
	String get addPublishedAnnouncement => '新增公告';

	/// zh-Hant-TW: '投稿審查'
	String get announcementReviewQueue => '投稿審查';

	/// zh-Hant-TW: '已發布公告'
	String get publishedAnnouncements => '已發布公告';

	/// zh-Hant-TW: '核准'
	String get approveAnnouncement => '核准';

	/// zh-Hant-TW: '退回'
	String get rejectAnnouncement => '退回';

	/// zh-Hant-TW: '已複製投稿者帳號'
	String get announcementApplicantCopied => '已複製投稿者帳號';

	/// zh-Hant-TW: '截止日期 ${date}'
	String announcementDeadline({required Object date}) => '截止日期 ${date}';

	/// zh-Hant-TW: '「${title}」的更多操作'
	String announcementItemActions({required Object title}) => '「${title}」的更多操作';

	/// zh-Hant-TW: '刪除投稿'
	String get deleteReviewApplication => '刪除投稿';

	/// zh-Hant-TW: '確定要刪除「${title}」嗎？'
	String confirmAnnouncementDeletion({required Object title}) => '確定要刪除「${title}」嗎？';

	/// zh-Hant-TW: '帳號與設定'
	String get accountSheetTitle => '帳號與設定';

	/// zh-Hant-TW: '查看與編輯個人資料'
	String get viewProfileHint => '查看與編輯個人資料';

	/// zh-Hant-TW: '校園公車路線'
	String get busRoutesSection => '校園公車路線';

	/// zh-Hant-TW: '營運中 · ${busId}'
	String busOperatingStatus({required Object busId}) => '營運中 · ${busId}';
}

// Path: enrollCertificate
class AppLocalizationsEnrollCertificateZhHantTw {
	AppLocalizationsEnrollCertificateZhHantTw.internal(this._root);

	final AppLocalizations _root; // ignore: unused_field

	// Translations

	/// zh-Hant-TW: '在學證明'
	String get title => '在學證明';

	/// zh-Hant-TW: '產生在學證明'
	String get action => '產生在學證明';

	/// zh-Hant-TW: '重新提取'
	String get regenerate => '重新提取';

	/// zh-Hant-TW: '重新執行'
	String get retry => '重新執行';

	/// zh-Hant-TW: '下載／匯出'
	String get download => '下載／匯出';

	/// zh-Hant-TW: '在學證明'
	String get fileName => '在學證明';

	/// zh-Hant-TW: '正在讀取已儲存的在學證明...'
	String get loadingCached => '正在讀取已儲存的在學證明...';

	/// zh-Hant-TW: '正在向校方系統提取在學證明...'
	String get retrieving => '正在向校方系統提取在學證明...';

	/// zh-Hant-TW: '找不到目前帳號，請先登入 App 後再取得在學證明。'
	String get missingAccount => '找不到目前帳號，請先登入 App 後再取得在學證明。';

	/// zh-Hant-TW: '找不到目前登入帳密，請先重新登入 App 後再重新提取。'
	String get missingCredentials => '找不到目前登入帳密，請先重新登入 App 後再重新提取。';

	/// zh-Hant-TW: '已取得文件，但無法更新本機快取。'
	String get saveFailed => '已取得文件，但無法更新本機快取。';

	/// zh-Hant-TW: '尚未取得在學證明，請重新執行。'
	String get notObtained => '尚未取得在學證明，請重新執行。';

	/// zh-Hant-TW: '校方系統回應逾時，請稍後重新提取。'
	String get requestTimedOut => '校方系統回應逾時，請稍後重新提取。';

	/// zh-Hant-TW: '無法從校方系統取得在學證明，請確認網路後重試。'
	String get requestFailed => '無法從校方系統取得在學證明，請確認網路後重試。';

	/// zh-Hant-TW: '校方系統未回傳有效的在學證明 PDF，請確認帳密或稍後重試。'
	String get invalidResponse => '校方系統未回傳有效的在學證明 PDF，請確認帳密或稍後重試。';

	/// zh-Hant-TW: '無法下載／匯出在學證明，請稍後再試。'
	String get downloadFailed => '無法下載／匯出在學證明，請稍後再試。';

	/// zh-Hant-TW: '無法開啟瀏覽器，請再試一次。'
	String get openBrowserFailed => '無法開啟瀏覽器，請再試一次。';

	/// zh-Hant-TW: '網路註冊'
	String get registrationTitle => '網路註冊';

	/// zh-Hant-TW: '校方未提供在學證明。請在註冊系統確認並補填必要資料，完成後再重新提取。'
	String get registrationRequired => '校方未提供在學證明。請在註冊系統確認並補填必要資料，完成後再重新提取。';

	/// zh-Hant-TW: '無法安全地清除先前的註冊系統工作階段。為保護帳號資料，請關閉此頁後再試一次，或改用外部瀏覽器。'
	String get registrationSessionUnavailable => '無法安全地清除先前的註冊系統工作階段。為保護帳號資料，請關閉此頁後再試一次，或改用外部瀏覽器。';

	/// zh-Hant-TW: '完成填寫，重新提取'
	String get registrationComplete => '完成填寫，重新提取';
}

/// The flat map containing all translations for locale <zh-Hant-TW>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppLocalizations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => '中山校務通',
			'updateNoteContent' => '* 修正部分裝置桌面小工具無法顯示',
			'aboutOpenSourceContent' => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
			'graduationCheckChecklist' => '應屆畢業生成績檢核表',
			'missingRequiredCourses' => '學系必修課程缺修',
			'generalEducationCourse' => '通識課程',
			'otherEducationsCourse' => '其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查',
			'check' => '檢核',
			'shouldCredits' => '應修學分',
			'actualCredits' => '實得學分',
			'totalCredits' => '累計學分',
			'practiceSituation' => '修習情形',
			'courseClickHint' => '點擊科目名稱可看詳細資訊',
			'graduationCheckChecklistHint' => '本學期已選學分視同及格預審\n資料僅供參考詳細請參考校務系統',
			'graduationCheckChecklistEmpty' => '尚未有任畢業檢核資料',
			'graduationCheckChecklistSummary' => '總結',
			'firstLoginHint' => '首次登入密碼預設為身分證末六碼',
			'tuitionAndFees' => '學雜費繳費狀況查詢',
			'tuitionAndCert' => '學雜費與在學證明',
			'tuitionAndFeesItemTitleFormat' => ({required Object amount, required Object date}) => '金額：${amount}\n繳費日期：${date}',
			'admissionGuide' => '入學指南',
			'tuitionAndFeesPageHint' => '點擊可查看收據或繳費單',
			'tuitionAndFeesPageDialogTitle' => '請選擇匯出方式',
			'courseYear' => '學年度',
			'courseSelector' => '選課小助手',
			'continuingSummerEducationProgram' => '碩專暑',
			'fallSemester' => '上學期',
			'springSemester' => '下學期',
			'summerSemester' => '暑假',
			'continuingSummerEducationProgramShort' => '碩專暑',
			'fallSemesterShort' => '上',
			'springSemesterShort' => '下',
			'summerSemesterShort' => '暑',
			'tuitionAndFeesEmpty' => 'Oops！查無任何學雜費資料哦～😋',
			'courseNotLoaded' => '尚未載入課表，點擊查看',
			'hasPreScoreHint' => '部分科目為授課老師開放成績查詢 並非最終成績',
			'pleaseConfirmForm' => '請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)',
			'openBrowserToFill' => '開啟瀏覽器填寫',
			'minute' => '分',
			'busArriving' => '進站中',
			'busComingSoon' => '將到站',
			'busScheduledTime' => ({required Object time}) => '表定\n${time}',
			'busDeparted' => '已離站',
			'busNotOperating' => '未行駛',
			'busNoLiveBus' => '目前無車輛',
			'towCarHelper' => '拖車小幫手',
			'subscriptionArea' => '訂閱區域',
			'towCarNews' => '最新消息',
			'towCarSubscriptionArea' => '訂閱區域',
			'towCarAlertReport' => '狀況回報',
			'credibility' => '可信度',
			'viewCounts' => '多少人看過',
			'publishTime' => '發布時間',
			'alertContent' => '警報內容',
			'notificationArea' => '回報區域',
			'uploadImage' => '上傳圖片',
			'allArea' => '全部區域',
			'processing' => '處理中...',
			'pleaseProvideImage' => '請提供照片',
			'towCarUploadPolicy' => '拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕',
			'agreeAndUpload' => '同意並開始上傳',
			'notLocationPermissionHint' => '尚未取得定位權限',
			'locationNotNearSchool' => '您的位置尚未在學校附近，無法發布',
			'unknownTime' => '未知時間',
			'success' => '成功',
			'optionComfirm' => '確認',
			'optionCancel' => '取消',
			'openingBrowserContent' => '將使用瀏覽器開啟外部網站，是否繼續？',
			'openingBrowserTitle' => '開啟外部網站',
			'visitingUnSafeLink' => '不安全的連結，請確認網址是否正確',
			'enrollCertificate.title' => '在學證明',
			'enrollCertificate.action' => '產生在學證明',
			'enrollCertificate.regenerate' => '重新提取',
			'enrollCertificate.retry' => '重新執行',
			'enrollCertificate.download' => '下載／匯出',
			'enrollCertificate.fileName' => '在學證明',
			'enrollCertificate.loadingCached' => '正在讀取已儲存的在學證明...',
			'enrollCertificate.retrieving' => '正在向校方系統提取在學證明...',
			'enrollCertificate.missingAccount' => '找不到目前帳號，請先登入 App 後再取得在學證明。',
			'enrollCertificate.missingCredentials' => '找不到目前登入帳密，請先重新登入 App 後再重新提取。',
			'enrollCertificate.saveFailed' => '已取得文件，但無法更新本機快取。',
			'enrollCertificate.notObtained' => '尚未取得在學證明，請重新執行。',
			'enrollCertificate.requestTimedOut' => '校方系統回應逾時，請稍後重新提取。',
			'enrollCertificate.requestFailed' => '無法從校方系統取得在學證明，請確認網路後重試。',
			'enrollCertificate.invalidResponse' => '校方系統未回傳有效的在學證明 PDF，請確認帳密或稍後重試。',
			'enrollCertificate.downloadFailed' => '無法下載／匯出在學證明，請稍後再試。',
			'enrollCertificate.openBrowserFailed' => '無法開啟瀏覽器，請再試一次。',
			'enrollCertificate.registrationTitle' => '網路註冊',
			'enrollCertificate.registrationRequired' => '校方未提供在學證明。請在註冊系統確認並補填必要資料，完成後再重新提取。',
			'enrollCertificate.registrationSessionUnavailable' => '無法安全地清除先前的註冊系統工作階段。為保護帳號資料，請關閉此頁後再試一次，或改用外部瀏覽器。',
			'enrollCertificate.registrationComplete' => '完成填寫，重新提取',
			'tabStudy' => '課業',
			'tabCampus' => '校園',
			'newFeature' => '新功能',
			'latestAnnouncements' => '最新公告',
			'postAnnouncement' => '投稿',
			'loginCardTitle' => '登入校務系統',
			'loginCardSubtitle' => '登入後即可查看今日課表、學期成績、畢業檢核與在學證明',
			'studyCoreSection' => '核心學務',
			'studyToolsSection' => '學務工具與證明',
			'courseSubtitle' => '查看本學期課表與上課地點',
			'scoreSubtitle' => '查詢各學期成績與學分明細',
			'graduationCheckSubtitle' => '檢視必修、通識與累計畢業學分',
			'tuitionAndCertSubtitle' => '下載學雜費收據與提取在學證明',
			'courseSelectorSubtitle' => '開啟外部選課輔助工具網站',
			'campusServicesSection' => '校園服務',
			'appSection' => '應用程式',
			'schoolMapSubtitle' => '瀏覽西子灣校區建築與位置導覽',
			'schoolInfoSubtitle' => '查詢校園常用電話與年度行事曆',
			'announcementReviewSubtitle' => '投稿校園活動宣傳或管理審核',
			'announcementSubmissionSystem' => '首頁輪播投稿系統',
			'carouselGuidelines' => '限非營利校園活動。請以活動名稱為標題，附上活動連結。封面會公開上傳至 ImgBB，建議使用 100 KB 以內的壓縮 JPEG，內文以 100 字為宜。',
			'carouselCover' => '輪播封面',
			'carouselPick' => '選擇封面圖片',
			'carouselReplace' => '更換圖片',
			'carouselImageHint' => '圖片將公開上傳至 ImgBB，建議使用 100 KB 以內的 JPEG。',
			'carouselImageRequired' => '請先上傳封面圖片',
			'carouselUploadFailed' => '圖片上傳失敗，請重新選擇圖片。',
			'carouselDetails' => '活動資訊',
			'carouselLink' => '活動連結（選填）',
			'carouselLinkError' => '請輸入完整的 https 或 http 網址',
			'carouselSetExpiry' => '設定到期時間',
			'carouselNoExpiry' => '無到期時間',
			'carouselExpired' => '請選擇未來的到期時間',
			'carouselBody' => '活動說明',
			'carouselBodyHint' => '輸入活動說明…',
			'carouselCheck' => '檢查',
			'carouselSubmitFailed' => '投稿未送出，請再試一次。',
			'carouselPreview' => '檢查投稿',
			'carouselBold' => '粗體',
			'carouselItalic' => '斜體',
			'carouselSize' => '字型大小',
			'carouselSmall' => '小字',
			'carouselNormal' => '標準',
			'carouselLarge' => '大字',
			'carouselBullet' => '項目符號',
			'carouselOrdered' => '編號清單',
			'carouselIndent' => '增加縮排',
			'carouselOutdent' => '減少縮排',
			'carouselOpenLink' => '開啟活動連結',
			'carouselZoom' => '放大封面圖片',
			'pendingAnnouncementCount' => ({required Object count}) => '${count} 則未審查公告',
			'announcementReviewLinkHint' => '使用具審查權限的公告帳號登入後，會連結目前的校務帳號，下次可自動登入審查系統。',
			'announcementGoogleSignIn' => '使用 Google 登入',
			'announcementAppleSignIn' => '使用 Apple 登入',
			'addPublishedAnnouncement' => '新增公告',
			'announcementReviewQueue' => '投稿審查',
			'publishedAnnouncements' => '已發布公告',
			'approveAnnouncement' => '核准',
			'rejectAnnouncement' => '退回',
			'announcementApplicantCopied' => '已複製投稿者帳號',
			'announcementDeadline' => ({required Object date}) => '截止日期 ${date}',
			'announcementItemActions' => ({required Object title}) => '「${title}」的更多操作',
			'deleteReviewApplication' => '刪除投稿',
			'confirmAnnouncementDeletion' => ({required Object title}) => '確定要刪除「${title}」嗎？',
			'accountSheetTitle' => '帳號與設定',
			'viewProfileHint' => '查看與編輯個人資料',
			'busRoutesSection' => '校園公車路線',
			'busOperatingStatus' => ({required Object busId}) => '營運中 · ${busId}',
			_ => null,
		};
	}
}
