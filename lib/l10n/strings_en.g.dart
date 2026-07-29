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
	@override String get courseSelector => 'Course Selector Helper';
	@override String get continuingSummerEducationProgram => 'Continuing Summer Education Program';
	@override String get fallSemester => 'Fall Semester';
	@override String get springSemester => 'Spring Semester';
	@override String get summerSemester => 'Summer Semester';
	@override String get continuingSummerEducationProgramShort => 'Continuing Summer';
	@override String get fallSemesterShort => 'Fall';
	@override String get springSemesterShort => 'Spring';
	@override String get summerSemesterShort => 'Summer';
	@override String get tuitionAndFeesEmpty => 'Oops！No tuition and fees data～😋';
	@override String get hasPreScoreHint => 'Some subjects have scores available for preview, but are not final.';
	@override String get pleaseConfirmForm => 'Please fill out confirm form before login.\nIf you still can\'t log in after filling in, please click on the upper right corner to fill in through other browsers (ex. Chrome)';
	@override String get openBrowserToFill => 'Open browser to fill';
	@override String get minute => 'Min';
	@override String get busArriving => 'Arriving';
	@override String get busComingSoon => 'Coming\nSoon';
	@override String busScheduledTime({required Object time}) => 'Scheduled\n${time}';
	@override String get busDeparted => 'Departed';
	@override String get busNotOperating => 'Not\nOperating';
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
	@override String get optionComfirm => 'Confirm';
	@override String get optionCancel => 'Cancel';
	@override String get openingBrowserContent => 'This will open an external website in your browser. Continue?';
	@override String get openingBrowserTitle => 'Open External Website';
	@override String get visitingUnSafeLink => 'Unsafe link. Please confirm the URL is correct.';
	@override late final _AppLocalizationsEnrollCertificateEn enrollCertificate = _AppLocalizationsEnrollCertificateEn._(_root);
}

// Path: enrollCertificate
class _AppLocalizationsEnrollCertificateEn extends AppLocalizationsEnrollCertificateZhHantTw {
	_AppLocalizationsEnrollCertificateEn._(AppLocalizationsEn root) : this._root = root, super.internal(root);

	final AppLocalizationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Certificate of Enrollment';
	@override String get regenerate => 'Regenerate';
	@override String get retry => 'Try Again';
	@override String get fileName => 'Certificate of Enrollment';
	@override String get loadingCached => 'Loading the saved certificate...';
	@override String get openingFlow => 'Starting the automatic certificate process...';
	@override String get missingAccount => 'No signed-in account was found. Sign in to the app before obtaining a certificate.';
	@override String get missingCredentials => 'No saved credentials were found. Sign in to the app before regenerating the certificate.';
	@override String get saveFailed => 'Failed to save the certificate. Please try again.';
	@override String get notObtained => 'The certificate has not been obtained. Please try again.';
	@override String attemptProgress({required Object current, required Object total}) => 'Attempting ${current}/${total}';
	@override String mayTakeUpToSeconds({required Object seconds}) => 'This may take up to ${seconds} seconds';
	@override String get hideStatus => 'Hide status';
	@override String get manualOperation => 'Continue manually in the current page';
	@override String get manualEntryNotFound => 'Certificate entry not found';
	@override String get manualEntryInstruction => 'Select Certificate of Enrollment on the current page';
	@override String get unknownPage => 'The university system tried to open an unknown page';
	@override String get unknownNavigation => 'An unknown page navigation was blocked';
	@override String get credentialError => 'Incorrect username or password';
	@override String get loginRejected => 'The registration system rejected the login';
	@override String get sessionRejected => 'The university system rejected the current session';
	@override String get registrationPageInvalid => 'Unable to verify the registration page';
	@override String attemptsReached({required Object count}) => 'Automatic login reached ${count} attempts';
	@override String get loginFormMissing => 'Login form not found';
	@override String captchaUnrecognized({required Object count}) => 'Unable to recognize ${count} consecutive CAPTCHAs';
	@override String attemptsExhausted({required Object count}) => 'Automatic login failed after ${count} attempts';
	@override String get loginPageReloadFailed => 'Failed to reload the login page';
	@override String get registrationNoResponse => 'The registration page did not respond';
	@override String get pdfUnreadable => 'Unable to read the certificate PDF';
	@override String get pdfDownloadFailed => 'Failed to download the certificate PDF';
	@override String get pdfInvalid => 'The university system did not return a valid PDF';
	@override String get pdfProcessingFailed => 'Failed to process the certificate PDF';
	@override String get pdfTimeout => 'Timed out waiting for the PDF';
	@override String get retryInstruction => 'Select Regenerate to try again';
	@override String get retryLater => 'Please select Regenerate and try again later';
	@override String get checkCredentials => 'Go back and verify your sign-in details';
	@override String get navigationStopped => 'Automatic navigation stopped. Please regenerate the certificate';
	@override String get pageIncomplete => 'The page is incomplete. Please regenerate the certificate';
	@override String get checkNetwork => 'Check your connection and select Regenerate';
	@override String get documentIncomplete => 'The file is incomplete. Please regenerate the certificate';
	@override String pdfTimeoutDetail({required Object seconds}) => 'The university system did not return a document within ${seconds} seconds';
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
			'courseSelector' => 'Course Selector Helper',
			'continuingSummerEducationProgram' => 'Continuing Summer Education Program',
			'fallSemester' => 'Fall Semester',
			'springSemester' => 'Spring Semester',
			'summerSemester' => 'Summer Semester',
			'continuingSummerEducationProgramShort' => 'Continuing Summer',
			'fallSemesterShort' => 'Fall',
			'springSemesterShort' => 'Spring',
			'summerSemesterShort' => 'Summer',
			'tuitionAndFeesEmpty' => 'Oops！No tuition and fees data～😋',
			'hasPreScoreHint' => 'Some subjects have scores available for preview, but are not final.',
			'pleaseConfirmForm' => 'Please fill out confirm form before login.\nIf you still can\'t log in after filling in, please click on the upper right corner to fill in through other browsers (ex. Chrome)',
			'openBrowserToFill' => 'Open browser to fill',
			'minute' => 'Min',
			'busArriving' => 'Arriving',
			'busComingSoon' => 'Coming\nSoon',
			'busScheduledTime' => ({required Object time}) => 'Scheduled\n${time}',
			'busDeparted' => 'Departed',
			'busNotOperating' => 'Not\nOperating',
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
			'optionComfirm' => 'Confirm',
			'optionCancel' => 'Cancel',
			'openingBrowserContent' => 'This will open an external website in your browser. Continue?',
			'openingBrowserTitle' => 'Open External Website',
			'visitingUnSafeLink' => 'Unsafe link. Please confirm the URL is correct.',
			'enrollCertificate.title' => 'Certificate of Enrollment',
			'enrollCertificate.regenerate' => 'Regenerate',
			'enrollCertificate.retry' => 'Try Again',
			'enrollCertificate.fileName' => 'Certificate of Enrollment',
			'enrollCertificate.loadingCached' => 'Loading the saved certificate...',
			'enrollCertificate.openingFlow' => 'Starting the automatic certificate process...',
			'enrollCertificate.missingAccount' => 'No signed-in account was found. Sign in to the app before obtaining a certificate.',
			'enrollCertificate.missingCredentials' => 'No saved credentials were found. Sign in to the app before regenerating the certificate.',
			'enrollCertificate.saveFailed' => 'Failed to save the certificate. Please try again.',
			'enrollCertificate.notObtained' => 'The certificate has not been obtained. Please try again.',
			'enrollCertificate.attemptProgress' => ({required Object current, required Object total}) => 'Attempting ${current}/${total}',
			'enrollCertificate.mayTakeUpToSeconds' => ({required Object seconds}) => 'This may take up to ${seconds} seconds',
			'enrollCertificate.hideStatus' => 'Hide status',
			'enrollCertificate.manualOperation' => 'Continue manually in the current page',
			'enrollCertificate.manualEntryNotFound' => 'Certificate entry not found',
			'enrollCertificate.manualEntryInstruction' => 'Select Certificate of Enrollment on the current page',
			'enrollCertificate.unknownPage' => 'The university system tried to open an unknown page',
			'enrollCertificate.unknownNavigation' => 'An unknown page navigation was blocked',
			'enrollCertificate.credentialError' => 'Incorrect username or password',
			'enrollCertificate.loginRejected' => 'The registration system rejected the login',
			'enrollCertificate.sessionRejected' => 'The university system rejected the current session',
			'enrollCertificate.registrationPageInvalid' => 'Unable to verify the registration page',
			'enrollCertificate.attemptsReached' => ({required Object count}) => 'Automatic login reached ${count} attempts',
			'enrollCertificate.loginFormMissing' => 'Login form not found',
			'enrollCertificate.captchaUnrecognized' => ({required Object count}) => 'Unable to recognize ${count} consecutive CAPTCHAs',
			'enrollCertificate.attemptsExhausted' => ({required Object count}) => 'Automatic login failed after ${count} attempts',
			'enrollCertificate.loginPageReloadFailed' => 'Failed to reload the login page',
			'enrollCertificate.registrationNoResponse' => 'The registration page did not respond',
			'enrollCertificate.pdfUnreadable' => 'Unable to read the certificate PDF',
			'enrollCertificate.pdfDownloadFailed' => 'Failed to download the certificate PDF',
			'enrollCertificate.pdfInvalid' => 'The university system did not return a valid PDF',
			'enrollCertificate.pdfProcessingFailed' => 'Failed to process the certificate PDF',
			'enrollCertificate.pdfTimeout' => 'Timed out waiting for the PDF',
			'enrollCertificate.retryInstruction' => 'Select Regenerate to try again',
			'enrollCertificate.retryLater' => 'Please select Regenerate and try again later',
			'enrollCertificate.checkCredentials' => 'Go back and verify your sign-in details',
			'enrollCertificate.navigationStopped' => 'Automatic navigation stopped. Please regenerate the certificate',
			'enrollCertificate.pageIncomplete' => 'The page is incomplete. Please regenerate the certificate',
			'enrollCertificate.checkNetwork' => 'Check your connection and select Regenerate',
			'enrollCertificate.documentIncomplete' => 'The file is incomplete. Please regenerate the certificate',
			'enrollCertificate.pdfTimeoutDetail' => ({required Object seconds}) => 'The university system did not return a document within ${seconds} seconds',
			_ => null,
		};
	}
}
