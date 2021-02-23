import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  String get hasPreScoreHint => _vocabularies['hasPreScoreHint'];

  AppLocalizations(Locale locale) {
    AppLocalizations.locale = locale;
  }

  static Locale locale;

  String get minute => _vocabularies['minute'];

  String get busEmpty => _vocabularies['busEmpty'];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Map get _vocabularies {
    return _localizedValues[locale.languageCode] ?? _localizedValues['en'];
  }

  String get appName => _vocabularies['app_name'];

  String get updateNoteContent => _vocabularies['update_note_content'];

  String get aboutOpenSourceContent =>
      _vocabularies['about_open_source_content'];

  String get graduationCheckChecklist =>
      _vocabularies['graduationCheckChecklist'];

  String get missingRequiredCourses => _vocabularies['missingRequiredCourses'];

  String get generalEducationCourse => _vocabularies['generalEducationCourse'];

  String get otherEducationsCourse => _vocabularies['otherEducationsCourse'];

  String get check => _vocabularies['check'];

  String get shouldCredits => _vocabularies['shouldCredits'];

  String get actualCredits => _vocabularies['actualCredits'];

  String get totalCredits => _vocabularies['totalCredits'];

  String get practiceSituation => _vocabularies['practiceSituation'];

  String get courseClickHint => _vocabularies['courseClickHint'];

  String get graduationCheckChecklistHint =>
      _vocabularies['graduationCheckChecklistHint'];

  String get graduationCheckChecklistEmpty =>
      _vocabularies['graduationCheckChecklistEmpty'];

  String get noData => _vocabularies['noData'];

  String get graduationCheckChecklistSummary =>
      _vocabularies['graduationCheckChecklistSummary'];

  String get firstLoginHint => _vocabularies['firstLoginHint'];

  String get tuitionAndFees => _vocabularies['tuitionAndFees'];

  String get tuitionAndFeesItemTitleFormat =>
      _vocabularies['tuitionAndFeesItemTitleFormat'];

  String get tuitionAndFeesPageHint => _vocabularies['tuitionAndFeesPageHint'];

  String get tuitionAndFeesPageDialogTitle =>
      _vocabularies['tuitionAndFeesPageDialogTitle'];

  String get courseYear => _vocabularies['courseYear'];

  String get continuingSummerEducationProgram =>
      _vocabularies['continuingSummerEducationProgram'];

  String get fallSemester => _vocabularies['fallSemester'];

  String get springSemester => _vocabularies['springSemester'];

  String get summerSemester => _vocabularies['summerSemester'];

  String get tuitionAndFeesEmpty => _vocabularies['tuitionAndFeesEmpty'];

  String get pleaseConfirmForm => _vocabularies['pleaseConfirmForm'];

  String get bus => _vocabularies['bus'];

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'NSYSU AP',
      'update_note_content': '* Improve bus system.',
      'about_open_source_content':
          'https://github.com/abc873693/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright &#169; 2019 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      'graduationCheckChecklist': 'Graduation check checklist',
      'missingRequiredCourses': 'Missing Required Courses',
      'generalEducationCourse': 'General Education Courses',
      'otherEducationsCourse': 'Other Education Courses',
      'check': 'Check',
      'shouldCredits': 'Should Credits',
      'actualCredits': 'Actual Credits',
      'totalCredits': 'Total Credits',
      'practiceSituation': 'Practice Situation',
      'courseClickHint': 'Click subject show more.',
      'graduationCheckChecklistHint':
          'The selected credits for this semester are considered as passing prequalification.\nThe information is for reference only. Please refer to the school service system.',
      'graduationCheckChecklistEmpty': 'No graduation check information yet',
      'graduationCheckChecklistSummary': 'Summary',
      'firstLoginHint':
          'For first-time login, please fill in the last six number of your ID as your password',
      'tuitionAndFees': 'Tuition Payment Status',
      'tuitionAndFeesItemTitleFormat': 'Amount：%s\nDate of Payment：%s',
      'admissionGuide': 'Admission Guide',
      'tuitionAndFeesPageHint': 'Click to view the receipt or fees bill',
      'tuitionAndFeesPageDialogTitle': 'Pick method of export.',
      'courseYear': 'Year',
      'continuingSummerEducationProgram': 'Continuing Summer Education Program',
      'fallSemester': 'Fall Semester',
      'springSemester': 'Spring Semester',
      'summerSemester': 'Summer Semester',
      'tuitionAndFeesEmpty': 'Oops！No tuition and fees data～\uD83D\uDE0B',
      'hasPreScoreHint': 'Yellow Text not final score, proved by instructor.',
      'pleaseConfirmForm': 'Please fill out confirm form before login.',
      'bus': 'Bus System',
      'minute': 'Min',
      "busEmpty": "Oops! No bus currently~\n Please choose another bus 😋",
    },
    'zh': {
      'app_name': '中山校務通',
      'update_note_content': '* 改善校車系統',
      'about_open_source_content':
          'https://github.com/abc873693/NSYSU-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright &#169; 2019 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
      'graduationCheckChecklist': '應屆畢業生成績檢核表',
      'missingRequiredCourses': '學系必修課程缺修',
      'generalEducationCourse': '通識課程',
      'otherEducationsCourse': '其他：請務必依各學系之專業選修規定，或加修之雙主修／輔系規定檢查',
      'check': '檢核',
      'shouldCredits': '應修學分',
      'actualCredits': '實得學分',
      'totalCredits': '累計學分',
      'practiceSituation': '修習情形',
      'courseClickHint': '點擊科目名稱可看詳細資訊',
      'graduationCheckChecklistHint': '本學期已選學分視同及格預審\n資料僅供參考詳細請參考校務系統',
      'graduationCheckChecklistEmpty': '尚未有任何畢業檢核資料',
      'graduationCheckChecklistSummary': '總結',
      'firstLoginHint': '首次登入密碼預設為身分證末六碼',
      'tuitionAndFees': '學雑費繖費狀況查詢',
      'tuitionAndFeesItemTitleFormat': '金額：%s\n繳費日期：%s',
      'admissionGuide': '入學指南',
      'tuitionAndFeesPageHint': '點擊可查看收據或繳費單',
      'tuitionAndFeesPageDialogTitle': '請選擇匯出方式',
      'courseYear': '學年度',
      'continuingSummerEducationProgram': '碩專署',
      'fallSemester': '上學期',
      'springSemester': '下學期',
      'summerSemester': '暑假',
      'tuitionAndFeesEmpty': 'Oops！查無任何學雜費資料哦～\uD83D\uDE0B',
      'hasPreScoreHint': '黃字為授課老師開放成績查詢 並非最終成績',
      'pleaseConfirmForm': '請先填寫確認表單再進行登入',
      'bus': '校園公車',
      'minute': '分',
      'busEmpty': 'Oops！目前校車沒上班喔～\n請選擇其他班次 😋',
    },
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
