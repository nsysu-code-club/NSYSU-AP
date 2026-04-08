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

	/// zh-Hant-TW: '碩專署'
	String get continuingSummerEducationProgram => '碩專署';

	/// zh-Hant-TW: '上學期'
	String get fallSemester => '上學期';

	/// zh-Hant-TW: '下學期'
	String get springSemester => '下學期';

	/// zh-Hant-TW: '暑假'
	String get summerSemester => '暑假';

	/// zh-Hant-TW: 'Oops！查無任何學雜費資料哦～😋'
	String get tuitionAndFeesEmpty => 'Oops！查無任何學雜費資料哦～😋';

	/// zh-Hant-TW: '黃字為授課老師開放成績查詢 並非最終成績'
	String get hasPreScoreHint => '黃字為授課老師開放成績查詢 並非最終成績';

	/// zh-Hant-TW: '請先填寫確認表單再進行登入 若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)'
	String get pleaseConfirmForm => '請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)';

	/// zh-Hant-TW: '開啟瀏覽器填寫'
	String get openBrowserToFill => '開啟瀏覽器填寫';

	/// zh-Hant-TW: '分'
	String get minute => '分';

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
			'tuitionAndFeesItemTitleFormat' => ({required Object amount, required Object date}) => '金額：${amount}\n繳費日期：${date}',
			'admissionGuide' => '入學指南',
			'tuitionAndFeesPageHint' => '點擊可查看收據或繳費單',
			'tuitionAndFeesPageDialogTitle' => '請選擇匯出方式',
			'courseYear' => '學年度',
			'continuingSummerEducationProgram' => '碩專署',
			'fallSemester' => '上學期',
			'springSemester' => '下學期',
			'summerSemester' => '暑假',
			'tuitionAndFeesEmpty' => 'Oops！查無任何學雜費資料哦～😋',
			'hasPreScoreHint' => '黃字為授課老師開放成績查詢 並非最終成績',
			'pleaseConfirmForm' => '請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)',
			'openBrowserToFill' => '開啟瀏覽器填寫',
			'minute' => '分',
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
			_ => null,
		};
	}
}
