///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class AppLocalizationsEn extends AppLocalizations with BaseTranslations<AppLocale, AppLocalizations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	AppLocalizationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, AppLocalizations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, AppLocalizations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final AppLocalizationsEn _root = this; // ignore: unused_field

	@override 
	AppLocalizationsEn $copyWith({TranslationMetadata<AppLocale, AppLocalizations>? meta}) => AppLocalizationsEn(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'NSYSU AP';
	@override String get updateNoteContent => '* Fix part of device home widget error.';
	@override String get aboutOpenSourceContent => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.';
	@override String get graduationCheckChecklist => 'Graduation check checklist';
	@override String get missingRequiredCourses => 'Missing Required Courses';
	@override String get generalEducationCourse => 'General Education Courses';
	@override String get otherEducationsCourse => 'Other Education Courses';
	@override String get check => 'Check';
	@override String get shouldCredits => 'Should Credits';
	@override String get actualCredits => 'Actual Credits';
	@override String get totalCredits => 'Total Credits';
	@override String get practiceSituation => 'Practice Situation';
	@override String get courseClickHint => 'Click subject show more.';
	@override String get graduationCheckChecklistHint => 'The selected credits for this semester are considered as passing prequalification.\nThe information is for reference only. Please refer to the school service system.';
	@override String get graduationCheckChecklistEmpty => 'No graduation check information yet';
	@override String get graduationCheckChecklistSummary => 'Summary';
	@override String get firstLoginHint => 'For first-time login, please fill in the last six number of your ID as your password';
	@override String get tuitionAndFees => 'Tuition Payment Status';
	@override String tuitionAndFeesItemTitleFormat({required Object amount, required Object date}) => 'Amount：${amount}\nDate of Payment：${date}';
	@override String get admissionGuide => 'Admission Guide';
	@override String get tuitionAndFeesPageHint => 'Click to view the receipt or fees bill';
	@override String get tuitionAndFeesPageDialogTitle => 'Pick method of export.';
	@override String get courseYear => 'Year';
	@override String get continuingSummerEducationProgram => 'Continuing Summer Education Program';
	@override String get fallSemester => 'Fall Semester';
	@override String get springSemester => 'Spring Semester';
	@override String get summerSemester => 'Summer Semester';
	@override String get tuitionAndFeesEmpty => 'Oops！No tuition and fees data～😋';
	@override String get hasPreScoreHint => 'Yellow Text not final score, proved by instructor.';
	@override String get pleaseConfirmForm => 'Please fill out confirm form before login.\nIf you still can\'t log in after filling in, please click on the upper right corner to fill in through other browsers (ex. Chrome)';
	@override String get openBrowserToFill => 'Open browser to fill';
	@override String get minute => 'Min';
	@override String get towCarHelper => 'Tow Car Helper';
	@override String get subscriptionArea => 'Subscription Area';
	@override String get towCarNews => 'News';
	@override String get towCarSubscriptionArea => 'Subscription';
	@override String get towCarAlertReport => 'Report';
	@override String get credibility => 'Credibility';
	@override String get viewCounts => 'views';
	@override String get publishTime => 'Publish Time';
	@override String get alertContent => 'Content';
	@override String get notificationArea => 'Report Area';
	@override String get uploadImage => 'Upload Image';
	@override String get allArea => 'All Area';
	@override String get processing => 'Processing...';
	@override String get pleaseProvideImage => 'Please Provide Image';
	@override String get towCarUploadPolicy => '拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕';
	@override String get agreeAndUpload => 'Agree and Upload';
	@override String get notLocationPermissionHint => 'Not Location Permission';
	@override String get locationNotNearSchool => 'Your location not in school, can\'t publish.';
	@override String get unknownTime => 'Unknown Time';
	@override String get success => 'Success';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppLocalizationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'NSYSU AP',
			'updateNoteContent' => '* Fix part of device home widget error.',
			'aboutOpenSourceContent' => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
			'graduationCheckChecklist' => 'Graduation check checklist',
			'missingRequiredCourses' => 'Missing Required Courses',
			'generalEducationCourse' => 'General Education Courses',
			'otherEducationsCourse' => 'Other Education Courses',
			'check' => 'Check',
			'shouldCredits' => 'Should Credits',
			'actualCredits' => 'Actual Credits',
			'totalCredits' => 'Total Credits',
			'practiceSituation' => 'Practice Situation',
			'courseClickHint' => 'Click subject show more.',
			'graduationCheckChecklistHint' => 'The selected credits for this semester are considered as passing prequalification.\nThe information is for reference only. Please refer to the school service system.',
			'graduationCheckChecklistEmpty' => 'No graduation check information yet',
			'graduationCheckChecklistSummary' => 'Summary',
			'firstLoginHint' => 'For first-time login, please fill in the last six number of your ID as your password',
			'tuitionAndFees' => 'Tuition Payment Status',
			'tuitionAndFeesItemTitleFormat' => ({required Object amount, required Object date}) => 'Amount：${amount}\nDate of Payment：${date}',
			'admissionGuide' => 'Admission Guide',
			'tuitionAndFeesPageHint' => 'Click to view the receipt or fees bill',
			'tuitionAndFeesPageDialogTitle' => 'Pick method of export.',
			'courseYear' => 'Year',
			'continuingSummerEducationProgram' => 'Continuing Summer Education Program',
			'fallSemester' => 'Fall Semester',
			'springSemester' => 'Spring Semester',
			'summerSemester' => 'Summer Semester',
			'tuitionAndFeesEmpty' => 'Oops！No tuition and fees data～😋',
			'hasPreScoreHint' => 'Yellow Text not final score, proved by instructor.',
			'pleaseConfirmForm' => 'Please fill out confirm form before login.\nIf you still can\'t log in after filling in, please click on the upper right corner to fill in through other browsers (ex. Chrome)',
			'openBrowserToFill' => 'Open browser to fill',
			'minute' => 'Min',
			'towCarHelper' => 'Tow Car Helper',
			'subscriptionArea' => 'Subscription Area',
			'towCarNews' => 'News',
			'towCarSubscriptionArea' => 'Subscription',
			'towCarAlertReport' => 'Report',
			'credibility' => 'Credibility',
			'viewCounts' => 'views',
			'publishTime' => 'Publish Time',
			'alertContent' => 'Content',
			'notificationArea' => 'Report Area',
			'uploadImage' => 'Upload Image',
			'allArea' => 'All Area',
			'processing' => 'Processing...',
			'pleaseProvideImage' => 'Please Provide Image',
			'towCarUploadPolicy' => '拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕',
			'agreeAndUpload' => 'Agree and Upload',
			'notLocationPermissionHint' => 'Not Location Permission',
			'locationNotNearSchool' => 'Your location not in school, can\'t publish.',
			'unknownTime' => 'Unknown Time',
			'success' => 'Success',
			_ => null,
		};
	}
}
