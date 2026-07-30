import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/l10n/strings.g.dart';
import 'package:nsysu_ap/pages/student_leave_page.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerApCommonService(analytics: const _FakeAnalyticsUtil());
  });

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.zhHantTw);
  });

  testWidgets('new leave form is clear and fits a phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(const StudentLeaveAddPage()));
    await tester.pumpAndSettle();

    expect(find.text(app.studentLeaveRequestDetails), findsOneWidget);
    expect(find.text(app.studentLeavePeriod), findsOneWidget);
    expect(find.text(app.studentLeaveReason), findsOneWidget);
    expect(find.text(app.studentLeaveSubmit), findsOneWidget);

    final TextFormField reasonField = tester.widget<TextFormField>(
      find.byType(TextFormField),
    );
    expect(reasonField.controller?.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leave semester selector updates the selected semester', (
    WidgetTester tester,
  ) async {
    const List<StudentLeaveSemester> options = <StudentLeaveSemester>[
      StudentLeaveSemester(schoolYear: 114, semester: 2),
      StudentLeaveSemester(schoolYear: 114, semester: 1),
    ];
    StudentLeaveSemester selected = options.first;

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return StudentLeaveSemesterSelector(
                options: options,
                selected: selected,
                onSelected: (StudentLeaveSemester? value) {
                  if (value == null) return;
                  setState(() => selected = value);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text(app.studentLeaveYearSemester(year: 114, semester: 2)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(app.studentLeaveYearSemester(year: 114, semester: 1)).last,
    );
    await tester.pumpAndSettle();

    expect(selected, options.last);
    expect(
      find.text(app.studentLeaveYearSemester(year: 114, semester: 1)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview page presents structured fields and final action', (
    WidgetTester tester,
  ) async {
    const StudentLeaveConfirmation confirmation = StudentLeaveConfirmation(
      messages: <String>['請確認假單資料'],
      rawText: '',
      noticeLines: <String>[
        '請同學注意以下說明：',
        '(1)不需課程請假期間：依校務系統顯示為準。',
        '(2)請同學檢查請假單內容是否正確，如有錯誤請回上一頁修改。',
      ],
      sections: <StudentLeaveConfirmationSection>[
        StudentLeaveConfirmationSection(
          title: '假單資料',
          fields: <StudentLeaveConfirmationField>[
            StudentLeaveConfirmationField(label: '假別', value: '事假'),
            StudentLeaveConfirmationField(
              label: '請假時間',
              value: '2026-07-14 09:00 - 12:00',
            ),
          ],
        ),
      ],
    );
    const StudentLeavePreviewResult preview = StudentLeavePreviewResult(
      statusCode: 200,
      body: '',
      confirmation: confirmation,
      confirmForm: StudentLeaveConfirmForm(
        action: 'SLAMS_stuLeave_add_act.php',
        fields: <String, String>{'confirm': '1'},
      ),
    );

    await tester.pumpWidget(
      _testApp(const StudentLeaveResultPage(previewResult: preview)),
    );
    await tester.pumpAndSettle();

    expect(find.text(app.studentLeaveFinalCheck), findsOneWidget);
    expect(find.text(app.studentLeaveNoticeTitle), findsOneWidget);
    expect(find.text('請同學注意以下說明：'), findsOneWidget);
    expect(find.text('(1)不需課程請假期間：依校務系統顯示為準。'), findsOneWidget);
    expect(find.text('(2)請同學檢查請假單內容是否正確，如有錯誤請回上一頁修改。'), findsOneWidget);
    expect(find.text('請確認假單資料'), findsNothing);

    await tester.tap(find.text(app.studentLeaveNoticeTitle));
    await tester.pumpAndSettle();

    expect(find.text('假單資料'), findsOneWidget);
    expect(find.text('事假'), findsOneWidget);
    expect(find.text(app.studentLeaveFinalSubmit), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitted result keeps the server response message', (
    WidgetTester tester,
  ) async {
    const StudentLeaveSubmitResult result = StudentLeaveSubmitResult(
      statusCode: 200,
      body: '假單新增成功',
      confirmation: StudentLeaveConfirmation(
        messages: <String>['假單新增成功'],
        rawText: '假單新增成功',
        sections: <StudentLeaveConfirmationSection>[],
      ),
    );

    await tester.pumpWidget(
      _testApp(const StudentLeaveResultPage(submitResult: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text('假單新增成功'), findsOneWidget);
    expect(find.text(app.studentLeaveNoticeTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed submitted result does not use the success header', (
    WidgetTester tester,
  ) async {
    const StudentLeaveSubmitResult result = StudentLeaveSubmitResult(
      statusCode: 200,
      body: '假單送出失敗，請稍後再試',
      confirmation: StudentLeaveConfirmation(
        messages: <String>['假單送出失敗，請稍後再試'],
        rawText: '假單送出失敗，請稍後再試',
        sections: <StudentLeaveConfirmationSection>[],
      ),
    );

    await tester.pumpWidget(
      _testApp(const StudentLeaveResultPage(submitResult: result)),
    );
    await tester.pumpAndSettle();

    expect(find.text(app.studentLeaveSubmitFailedTitle), findsOneWidget);
    expect(find.text(app.studentLeaveSubmitSuccess), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAnalyticsUtil extends AnalyticsUtil {
  const _FakeAnalyticsUtil();

  @override
  Future<void> logApiEvent(
    String type,
    int status, {
    String message = '',
  }) async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logTimeEvent(String name, double seconds) async {}

  @override
  Future<void> logUserInfo(UserInfo userInfo) async {}

  @override
  Future<void> setCurrentScreen(
    String screenName,
    String screenClassOverride,
  ) async {}

  @override
  Future<void> setUserId(String id) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}
}

Widget _testApp(Widget child) {
  return TranslationProvider(
    child: MaterialApp(
      locale: const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocaleUtils.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: child,
    ),
  );
}
