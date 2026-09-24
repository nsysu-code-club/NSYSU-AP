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
class AppLocalizationsJa extends AppLocalizations with BaseTranslations<AppLocale, AppLocalizations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	AppLocalizationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, AppLocalizations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, AppLocalizations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final AppLocalizationsJa _root = this; // ignore: unused_field

	@override 
	AppLocalizationsJa $copyWith({TranslationMetadata<AppLocale, AppLocalizations>? meta}) => AppLocalizationsJa(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'NSYSU AP';
	@override String get updateNoteContent => '* 一部の端末でホーム画面のウィジェットが表示されない問題を修正しました';
	@override String get aboutOpenSourceContent => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.';
	@override String get graduationCheckChecklist => '卒業予定者の成績・卒業要件チェックリスト';
	@override String get missingRequiredCourses => '学科の必修科目の未履修';
	@override String get generalEducationCourse => '一般教養科目';
	@override String get otherEducationsCourse => 'その他：所属学科の専門選択科目、およびダブルメジャー・副専攻の履修要件を必ず確認してください';
	@override String get check => '確認';
	@override String get shouldCredits => '必要単位数';
	@override String get actualCredits => '修得単位数';
	@override String get totalCredits => '累計単位数';
	@override String get practiceSituation => '履修状況';
	@override String get courseClickHint => '科目名をタップすると詳細を確認できます';
	@override String get graduationCheckChecklistHint => '事前審査では、今学期の履修登録科目を合格したものとして単位を計算します。\nこの情報は参考用です。詳細は大学の教務システムで確認してください';
	@override String get graduationCheckChecklistEmpty => '卒業要件の確認情報はまだありません';
	@override String get graduationCheckChecklistSummary => '概要';
	@override String get firstLoginHint => '初回ログイン時のパスワードは、身分証番号の下6桁です';
	@override String get tuitionAndFees => '学費・諸費用の納付状況';
	@override String get tuitionAndCert => '学費・諸費用と在学証明書';
	@override String tuitionAndFeesItemTitleFormat({required Object amount, required Object date}) => '金額：${amount}\n納付日：${date}';
	@override String get admissionGuide => '入学案内';
	@override String get tuitionAndFeesPageHint => 'タップすると領収書または納付書を確認できます';
	@override String get tuitionAndFeesPageDialogTitle => 'エクスポート方法を選択してください';
	@override String get courseYear => '学年度';
	@override String get courseSelector => '履修登録サポート';
	@override String get continuingSummerEducationProgram => '社会人向け修士課程（夏期）';
	@override String get fallSemester => '前期';
	@override String get springSemester => '後期';
	@override String get summerSemester => '夏休み';
	@override String get continuingSummerEducationProgramShort => '社会人修士・夏期';
	@override String get fallSemesterShort => '前期';
	@override String get springSemesterShort => '後期';
	@override String get summerSemesterShort => '夏';
	@override String get tuitionAndFeesEmpty => '学費・諸費用の情報が見つかりませんでした😋';
	@override String get hasPreScoreHint => '一部の科目では担当教員が成績の事前確認を許可していますが、最終成績ではありません';
	@override String get pleaseConfirmForm => 'ログインする前に確認フォームに入力してください。\n入力後もログインできない場合は、右上のボタンから別のブラウザー（Chromeなど）でフォームを開いて入力してください';
	@override String get openBrowserToFill => 'ブラウザーで開いて入力';
	@override String get minute => '分';
	@override String get busArriving => '到着中';
	@override String get busComingSoon => 'まもなく到着';
	@override String busScheduledTime({required Object time}) => '予定時刻\n${time}';
	@override String get busDeparted => '出発済み';
	@override String get busNotOperating => '運行なし';
	@override String get towCarHelper => 'レッカー移動サポート';
	@override String get subscriptionArea => '通知を受け取るエリア';
	@override String get towCarNews => '最新情報';
	@override String get towCarSubscriptionArea => '通知を受け取るエリア';
	@override String get towCarAlertReport => '状況を報告';
	@override String get credibility => '信頼度';
	@override String get viewCounts => '閲覧数';
	@override String get publishTime => '公開日時';
	@override String get alertContent => '警告内容';
	@override String get notificationArea => '報告対象エリア';
	@override String get uploadImage => '画像をアップロード';
	@override String get allArea => 'すべてのエリア';
	@override String get processing => '処理中...';
	@override String get pleaseProvideImage => '写真を添付してください';
	@override String get towCarUploadPolicy => 'レッカー移動サポートシステム\n\nこの機能を使って学内の状況を報告できます。\n本システムの利用に同意すると、\n国立中山大学の教務システムのアカウントとパスワードで本人確認を行い、\n基本情報（パスワードを除く）を当方のサーバーに登録します。\n運用は両プラットフォームのアプリストアのプライバシーポリシーに従います。\n\n報告した情報は、本システム上で匿名で提供されます。\n画像や動画は Imgur に公開アップロードされます。\nすべての情報は審査を経て公開され、直ちに公開されることはありません。\n以上に同意する場合は、下のボタンをタップしてください';
	@override String get agreeAndUpload => '同意してアップロード';
	@override String get notLocationPermissionHint => '位置情報へのアクセスが許可されていません';
	@override String get locationNotNearSchool => '大学の近くにいないため、投稿できません';
	@override String get unknownTime => '時刻不明';
	@override String get success => '成功';
	@override String get optionComfirm => '確認';
	@override String get optionCancel => 'キャンセル';
	@override String get openingBrowserContent => 'ブラウザーで外部サイトを開きます。続行しますか？';
	@override String get openingBrowserTitle => '外部サイトを開く';
	@override String get visitingUnSafeLink => '安全でないリンクです。URLが正しいか確認してください';
	@override late final _AppLocalizationsEnrollCertificateJa enrollCertificate = _AppLocalizationsEnrollCertificateJa._(_root);
}

// Path: enrollCertificate
class _AppLocalizationsEnrollCertificateJa extends AppLocalizationsEnrollCertificateZhHantTw {
	_AppLocalizationsEnrollCertificateJa._(AppLocalizationsJa root) : this._root = root, super.internal(root);

	final AppLocalizationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '在学証明書';
	@override String get regenerate => '再取得';
	@override String get retry => '再試行';
	@override String get download => 'ダウンロード／エクスポート';
	@override String get fileName => '在学証明書';
	@override String get loadingCached => '保存済みの在学証明書を読み込んでいます...';
	@override String get retrieving => '大学のシステムから在学証明書を取得しています...';
	@override String get missingAccount => 'アカウントが見つかりません。在学証明書を取得する前に、アプリにログインしてください。';
	@override String get missingCredentials => '保存済みのログイン情報が見つかりません。再取得する前に、アプリにログインし直してください。';
	@override String get saveFailed => '書類は取得できましたが、端末のキャッシュを更新できませんでした。';
	@override String get notObtained => '在学証明書をまだ取得できていません。もう一度お試しください。';
	@override String get requestTimedOut => '大学のシステムからの応答がタイムアウトしました。しばらくしてから再取得してください。';
	@override String get requestFailed => '大学のシステムから在学証明書を取得できませんでした。ネットワーク接続を確認して、もう一度お試しください。';
	@override String get invalidResponse => '大学のシステムから有効な在学証明書のPDFが返されませんでした。ログイン情報を確認するか、しばらくしてからもう一度お試しください。';
	@override String get downloadFailed => '在学証明書をダウンロード／エクスポートできませんでした。しばらくしてからもう一度お試しください。';
	@override String get openBrowserFailed => 'ブラウザーを開けませんでした。もう一度お試しください。';
	@override String get registrationTitle => 'オンライン学籍登録';
	@override String get registrationRequired => '大学から在学証明書が発行されませんでした。学籍登録システムで必要事項を確認・入力してから再取得してください。';
	@override String get registrationSessionUnavailable => '以前の学籍登録セッションを安全に削除できませんでした。アカウントを保護するため、このページを閉じて再試行するか、外部ブラウザーを使用してください。';
	@override String get registrationComplete => '入力を完了して再取得';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on AppLocalizationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'NSYSU AP',
			'updateNoteContent' => '* 一部の端末でホーム画面のウィジェットが表示されない問題を修正しました',
			'aboutOpenSourceContent' => 'https://github.com/nsysu-code-club/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2024 NSYSU Code Club\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
			'graduationCheckChecklist' => '卒業予定者の成績・卒業要件チェックリスト',
			'missingRequiredCourses' => '学科の必修科目の未履修',
			'generalEducationCourse' => '一般教養科目',
			'otherEducationsCourse' => 'その他：所属学科の専門選択科目、およびダブルメジャー・副専攻の履修要件を必ず確認してください',
			'check' => '確認',
			'shouldCredits' => '必要単位数',
			'actualCredits' => '修得単位数',
			'totalCredits' => '累計単位数',
			'practiceSituation' => '履修状況',
			'courseClickHint' => '科目名をタップすると詳細を確認できます',
			'graduationCheckChecklistHint' => '事前審査では、今学期の履修登録科目を合格したものとして単位を計算します。\nこの情報は参考用です。詳細は大学の教務システムで確認してください',
			'graduationCheckChecklistEmpty' => '卒業要件の確認情報はまだありません',
			'graduationCheckChecklistSummary' => '概要',
			'firstLoginHint' => '初回ログイン時のパスワードは、身分証番号の下6桁です',
			'tuitionAndFees' => '学費・諸費用の納付状況',
			'tuitionAndCert' => '学費・諸費用と在学証明書',
			'tuitionAndFeesItemTitleFormat' => ({required Object amount, required Object date}) => '金額：${amount}\n納付日：${date}',
			'admissionGuide' => '入学案内',
			'tuitionAndFeesPageHint' => 'タップすると領収書または納付書を確認できます',
			'tuitionAndFeesPageDialogTitle' => 'エクスポート方法を選択してください',
			'courseYear' => '学年度',
			'courseSelector' => '履修登録サポート',
			'continuingSummerEducationProgram' => '社会人向け修士課程（夏期）',
			'fallSemester' => '前期',
			'springSemester' => '後期',
			'summerSemester' => '夏休み',
			'continuingSummerEducationProgramShort' => '社会人修士・夏期',
			'fallSemesterShort' => '前期',
			'springSemesterShort' => '後期',
			'summerSemesterShort' => '夏',
			'tuitionAndFeesEmpty' => '学費・諸費用の情報が見つかりませんでした😋',
			'hasPreScoreHint' => '一部の科目では担当教員が成績の事前確認を許可していますが、最終成績ではありません',
			'pleaseConfirmForm' => 'ログインする前に確認フォームに入力してください。\n入力後もログインできない場合は、右上のボタンから別のブラウザー（Chromeなど）でフォームを開いて入力してください',
			'openBrowserToFill' => 'ブラウザーで開いて入力',
			'minute' => '分',
			'busArriving' => '到着中',
			'busComingSoon' => 'まもなく到着',
			'busScheduledTime' => ({required Object time}) => '予定時刻\n${time}',
			'busDeparted' => '出発済み',
			'busNotOperating' => '運行なし',
			'towCarHelper' => 'レッカー移動サポート',
			'subscriptionArea' => '通知を受け取るエリア',
			'towCarNews' => '最新情報',
			'towCarSubscriptionArea' => '通知を受け取るエリア',
			'towCarAlertReport' => '状況を報告',
			'credibility' => '信頼度',
			'viewCounts' => '閲覧数',
			'publishTime' => '公開日時',
			'alertContent' => '警告内容',
			'notificationArea' => '報告対象エリア',
			'uploadImage' => '画像をアップロード',
			'allArea' => 'すべてのエリア',
			'processing' => '処理中...',
			'pleaseProvideImage' => '写真を添付してください',
			'towCarUploadPolicy' => 'レッカー移動サポートシステム\n\nこの機能を使って学内の状況を報告できます。\n本システムの利用に同意すると、\n国立中山大学の教務システムのアカウントとパスワードで本人確認を行い、\n基本情報（パスワードを除く）を当方のサーバーに登録します。\n運用は両プラットフォームのアプリストアのプライバシーポリシーに従います。\n\n報告した情報は、本システム上で匿名で提供されます。\n画像や動画は Imgur に公開アップロードされます。\nすべての情報は審査を経て公開され、直ちに公開されることはありません。\n以上に同意する場合は、下のボタンをタップしてください',
			'agreeAndUpload' => '同意してアップロード',
			'notLocationPermissionHint' => '位置情報へのアクセスが許可されていません',
			'locationNotNearSchool' => '大学の近くにいないため、投稿できません',
			'unknownTime' => '時刻不明',
			'success' => '成功',
			'optionComfirm' => '確認',
			'optionCancel' => 'キャンセル',
			'openingBrowserContent' => 'ブラウザーで外部サイトを開きます。続行しますか？',
			'openingBrowserTitle' => '外部サイトを開く',
			'visitingUnSafeLink' => '安全でないリンクです。URLが正しいか確認してください',
			'enrollCertificate.title' => '在学証明書',
			'enrollCertificate.regenerate' => '再取得',
			'enrollCertificate.retry' => '再試行',
			'enrollCertificate.download' => 'ダウンロード／エクスポート',
			'enrollCertificate.fileName' => '在学証明書',
			'enrollCertificate.loadingCached' => '保存済みの在学証明書を読み込んでいます...',
			'enrollCertificate.retrieving' => '大学のシステムから在学証明書を取得しています...',
			'enrollCertificate.missingAccount' => 'アカウントが見つかりません。在学証明書を取得する前に、アプリにログインしてください。',
			'enrollCertificate.missingCredentials' => '保存済みのログイン情報が見つかりません。再取得する前に、アプリにログインし直してください。',
			'enrollCertificate.saveFailed' => '書類は取得できましたが、端末のキャッシュを更新できませんでした。',
			'enrollCertificate.notObtained' => '在学証明書をまだ取得できていません。もう一度お試しください。',
			'enrollCertificate.requestTimedOut' => '大学のシステムからの応答がタイムアウトしました。しばらくしてから再取得してください。',
			'enrollCertificate.requestFailed' => '大学のシステムから在学証明書を取得できませんでした。ネットワーク接続を確認して、もう一度お試しください。',
			'enrollCertificate.invalidResponse' => '大学のシステムから有効な在学証明書のPDFが返されませんでした。ログイン情報を確認するか、しばらくしてからもう一度お試しください。',
			'enrollCertificate.downloadFailed' => '在学証明書をダウンロード／エクスポートできませんでした。しばらくしてからもう一度お試しください。',
			'enrollCertificate.openBrowserFailed' => 'ブラウザーを開けませんでした。もう一度お試しください。',
			'enrollCertificate.registrationTitle' => 'オンライン学籍登録',
			'enrollCertificate.registrationRequired' => '大学から在学証明書が発行されませんでした。学籍登録システムで必要事項を確認・入力してから再取得してください。',
			'enrollCertificate.registrationSessionUnavailable' => '以前の学籍登録セッションを安全に削除できませんでした。アカウントを保護するため、このページを閉じて再試行するか、外部ブラウザーを使用してください。',
			'enrollCertificate.registrationComplete' => '入力を完了して再取得',
			_ => null,
		};
	}
}
