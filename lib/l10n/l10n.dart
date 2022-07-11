// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class AppLocalizations {
  AppLocalizations();

  static AppLocalizations? _current;

  static AppLocalizations get current {
    assert(_current != null,
        'No instance of AppLocalizations was loaded. Try to initialize the AppLocalizations delegate before accessing AppLocalizations.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<AppLocalizations> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = AppLocalizations();
      AppLocalizations._current = instance;

      return instance;
    });
  }

  static AppLocalizations of(BuildContext context) {
    final instance = AppLocalizations.maybeOf(context);
    assert(instance != null,
        'No instance of AppLocalizations present in the widget tree. Did you add AppLocalizations.delegate in localizationsDelegates?');
    return instance!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// `中山校務通`
  String get appName {
    return Intl.message(
      '中山校務通',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `* 修正部分裝置桌面小工具無法顯示`
  String get updateNoteContent {
    return Intl.message(
      '* 修正部分裝置桌面小工具無法顯示',
      name: 'updateNoteContent',
      desc: '',
      args: [],
    );
  }

  /// `https://github.com/abc873693/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2019 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.`
  String get aboutOpenSourceContent {
    return Intl.message(
      'https://github.com/abc873693/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright © 2019 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      name: 'aboutOpenSourceContent',
      desc: '',
      args: [],
    );
  }

  /// `應屆畢業生成績檢核表`
  String get graduationCheckChecklist {
    return Intl.message(
      '應屆畢業生成績檢核表',
      name: 'graduationCheckChecklist',
      desc: '',
      args: [],
    );
  }

  /// `學系必修課程缺修`
  String get missingRequiredCourses {
    return Intl.message(
      '學系必修課程缺修',
      name: 'missingRequiredCourses',
      desc: '',
      args: [],
    );
  }

  /// `通識課程`
  String get generalEducationCourse {
    return Intl.message(
      '通識課程',
      name: 'generalEducationCourse',
      desc: '',
      args: [],
    );
  }

  /// `其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查`
  String get otherEducationsCourse {
    return Intl.message(
      '其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查',
      name: 'otherEducationsCourse',
      desc: '',
      args: [],
    );
  }

  /// `檢核`
  String get check {
    return Intl.message(
      '檢核',
      name: 'check',
      desc: '',
      args: [],
    );
  }

  /// `應修學分`
  String get shouldCredits {
    return Intl.message(
      '應修學分',
      name: 'shouldCredits',
      desc: '',
      args: [],
    );
  }

  /// `實得學分`
  String get actualCredits {
    return Intl.message(
      '實得學分',
      name: 'actualCredits',
      desc: '',
      args: [],
    );
  }

  /// `累計學分`
  String get totalCredits {
    return Intl.message(
      '累計學分',
      name: 'totalCredits',
      desc: '',
      args: [],
    );
  }

  /// `修習情形`
  String get practiceSituation {
    return Intl.message(
      '修習情形',
      name: 'practiceSituation',
      desc: '',
      args: [],
    );
  }

  /// `點擊科目名稱可看詳細資訊`
  String get courseClickHint {
    return Intl.message(
      '點擊科目名稱可看詳細資訊',
      name: 'courseClickHint',
      desc: '',
      args: [],
    );
  }

  /// `本學期已選學分視同及格預審\n資料僅供參考詳細請參考校務系統`
  String get graduationCheckChecklistHint {
    return Intl.message(
      '本學期已選學分視同及格預審\n資料僅供參考詳細請參考校務系統',
      name: 'graduationCheckChecklistHint',
      desc: '',
      args: [],
    );
  }

  /// `尚未有任畢業檢核資料`
  String get graduationCheckChecklistEmpty {
    return Intl.message(
      '尚未有任畢業檢核資料',
      name: 'graduationCheckChecklistEmpty',
      desc: '',
      args: [],
    );
  }

  /// `總結`
  String get graduationCheckChecklistSummary {
    return Intl.message(
      '總結',
      name: 'graduationCheckChecklistSummary',
      desc: '',
      args: [],
    );
  }

  /// `首次登入密碼預設為身分證末六碼`
  String get firstLoginHint {
    return Intl.message(
      '首次登入密碼預設為身分證末六碼',
      name: 'firstLoginHint',
      desc: '',
      args: [],
    );
  }

  /// `學雜費繳費狀況查詢`
  String get tuitionAndFees {
    return Intl.message(
      '學雜費繳費狀況查詢',
      name: 'tuitionAndFees',
      desc: '',
      args: [],
    );
  }

  /// `金額：%s\n繳費日期：%s`
  String get tuitionAndFeesItemTitleFormat {
    return Intl.message(
      '金額：%s\n繳費日期：%s',
      name: 'tuitionAndFeesItemTitleFormat',
      desc: '',
      args: [],
    );
  }

  /// `入學指南`
  String get admissionGuide {
    return Intl.message(
      '入學指南',
      name: 'admissionGuide',
      desc: '',
      args: [],
    );
  }

  /// `點擊可查看收據或繳費單`
  String get tuitionAndFeesPageHint {
    return Intl.message(
      '點擊可查看收據或繳費單',
      name: 'tuitionAndFeesPageHint',
      desc: '',
      args: [],
    );
  }

  /// `請選擇匯出方式`
  String get tuitionAndFeesPageDialogTitle {
    return Intl.message(
      '請選擇匯出方式',
      name: 'tuitionAndFeesPageDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `學年度`
  String get courseYear {
    return Intl.message(
      '學年度',
      name: 'courseYear',
      desc: '',
      args: [],
    );
  }

  /// `碩專署`
  String get continuingSummerEducationProgram {
    return Intl.message(
      '碩專署',
      name: 'continuingSummerEducationProgram',
      desc: '',
      args: [],
    );
  }

  /// `上學期`
  String get fallSemester {
    return Intl.message(
      '上學期',
      name: 'fallSemester',
      desc: '',
      args: [],
    );
  }

  /// `下學期`
  String get springSemester {
    return Intl.message(
      '下學期',
      name: 'springSemester',
      desc: '',
      args: [],
    );
  }

  /// `暑假`
  String get summerSemester {
    return Intl.message(
      '暑假',
      name: 'summerSemester',
      desc: '',
      args: [],
    );
  }

  /// `Oops！查無任何學雜費資料哦～😋`
  String get tuitionAndFeesEmpty {
    return Intl.message(
      'Oops！查無任何學雜費資料哦～😋',
      name: 'tuitionAndFeesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `黃字為授課老師開放成績查詢 並非最終成績`
  String get hasPreScoreHint {
    return Intl.message(
      '黃字為授課老師開放成績查詢 並非最終成績',
      name: 'hasPreScoreHint',
      desc: '',
      args: [],
    );
  }

  /// `請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)`
  String get pleaseConfirmForm {
    return Intl.message(
      '請先填寫確認表單再進行登入\n若填寫完畢仍無法登入 點擊右上角透過其他瀏覽器填寫(ex. Chrome)',
      name: 'pleaseConfirmForm',
      desc: '',
      args: [],
    );
  }

  /// `開啟瀏覽器填寫`
  String get openBrowserToFill {
    return Intl.message(
      '開啟瀏覽器填寫',
      name: 'openBrowserToFill',
      desc: '',
      args: [],
    );
  }

  /// `分`
  String get minute {
    return Intl.message(
      '分',
      name: 'minute',
      desc: '',
      args: [],
    );
  }

  /// `拖車小幫手`
  String get towCarHelper {
    return Intl.message(
      '拖車小幫手',
      name: 'towCarHelper',
      desc: '',
      args: [],
    );
  }

  /// `訂閱區域`
  String get subscriptionArea {
    return Intl.message(
      '訂閱區域',
      name: 'subscriptionArea',
      desc: '',
      args: [],
    );
  }

  /// `最新消息`
  String get towCarNews {
    return Intl.message(
      '最新消息',
      name: 'towCarNews',
      desc: '',
      args: [],
    );
  }

  /// `訂閱區域`
  String get towCarSubscriptionArea {
    return Intl.message(
      '訂閱區域',
      name: 'towCarSubscriptionArea',
      desc: '',
      args: [],
    );
  }

  /// `狀況回報`
  String get towCarAlertReport {
    return Intl.message(
      '狀況回報',
      name: 'towCarAlertReport',
      desc: '',
      args: [],
    );
  }

  /// `可信度`
  String get credibility {
    return Intl.message(
      '可信度',
      name: 'credibility',
      desc: '',
      args: [],
    );
  }

  /// `多少人看過`
  String get viewCounts {
    return Intl.message(
      '多少人看過',
      name: 'viewCounts',
      desc: '',
      args: [],
    );
  }

  /// `發布時間`
  String get publishTime {
    return Intl.message(
      '發布時間',
      name: 'publishTime',
      desc: '',
      args: [],
    );
  }

  /// `警報內容`
  String get alertContent {
    return Intl.message(
      '警報內容',
      name: 'alertContent',
      desc: '',
      args: [],
    );
  }

  /// `回報區域`
  String get notificationArea {
    return Intl.message(
      '回報區域',
      name: 'notificationArea',
      desc: '',
      args: [],
    );
  }

  /// `上傳圖片`
  String get uploadImage {
    return Intl.message(
      '上傳圖片',
      name: 'uploadImage',
      desc: '',
      args: [],
    );
  }

  /// `全部區域`
  String get allArea {
    return Intl.message(
      '全部區域',
      name: 'allArea',
      desc: '',
      args: [],
    );
  }

  /// `處理中...`
  String get processing {
    return Intl.message(
      '處理中...',
      name: 'processing',
      desc: '',
      args: [],
    );
  }

  /// `請提供照片`
  String get pleaseProvideImage {
    return Intl.message(
      '請提供照片',
      name: 'pleaseProvideImage',
      desc: '',
      args: [],
    );
  }

  /// `拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕`
  String get towCarUploadPolicy {
    return Intl.message(
      '拖車小幫手系統\n\n可透過此功能回報校園狀況\n如果同意使用此系統\n將透過中山大學校務系統的帳號密碼作為驗證機制\n建立基本資料(不包含密碼)在我們的伺服器\n一切將遵守雙平台商店隱私政策運作\n\n回報時會以不具名提供資訊在此系統\n影音則是公開上傳至 Imgur\n任何資訊都會經過審查並非直接發佈\n若同意以上資訊請點擊下方按鈕',
      name: 'towCarUploadPolicy',
      desc: '',
      args: [],
    );
  }

  /// `同意並開始上傳`
  String get agreeAndUpload {
    return Intl.message(
      '同意並開始上傳',
      name: 'agreeAndUpload',
      desc: '',
      args: [],
    );
  }

  /// `尚未取得定位權限`
  String get notLocationPermissionHint {
    return Intl.message(
      '尚未取得定位權限',
      name: 'notLocationPermissionHint',
      desc: '',
      args: [],
    );
  }

  /// `您的位置尚未在學校附近，無法發布`
  String get locationNotNearSchool {
    return Intl.message(
      '您的位置尚未在學校附近，無法發布',
      name: 'locationNotNearSchool',
      desc: '',
      args: [],
    );
  }

  /// `未知時間`
  String get unknownTime {
    return Intl.message(
      '未知時間',
      name: 'unknownTime',
      desc: '',
      args: [],
    );
  }

  /// `成功`
  String get success {
    return Intl.message(
      '成功',
      name: 'success',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
