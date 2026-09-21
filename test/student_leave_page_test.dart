import 'dart:async';

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

  setUpAll(() async {
    registerApCommonService(analytics: const _FakeAnalyticsUtil());
    await LocaleSettings.setLocale(AppLocale.en);
    LocaleSettings.setLocaleSync(AppLocale.zhHantTw);
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

    await tester.pumpWidget(
      _testApp(StudentLeaveAddPage(initialConstraints: _testConstraints())),
    );
    await tester.pumpAndSettle();

    expect(find.text(app.studentLeaveRequestDetails), findsOneWidget);
    expect(find.text(app.studentLeavePeriod), findsOneWidget);
    expect(find.text(app.studentLeaveReason), findsOneWidget);
    expect(find.text(app.studentLeaveSubmit), findsOneWidget);

    final TextField reasonField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(reasonField.controller?.text, isEmpty);
    expect(reasonField.maxLength, 100);
    expect(find.textContaining('PDF'), findsOneWidget);
    expect(find.textContaining('1.5 MB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial start skips a day with no valid end time', (
    WidgetTester tester,
  ) async {
    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    final DateTime yesterday = todayOnly.subtract(const Duration(days: 1));
    final StudentLeaveFormConstraints constraints = StudentLeaveFormConstraints(
      leaveTypes: StudentLeaveType.values,
      firstStartDate: yesterday,
      lastStartDate: todayOnly,
      firstEndDate: yesterday,
      lastEndDate: todayOnly,
      startTimes: const <String>['23:00'],
      endTimes: const <String>['22:00'],
      maxReasonLength: 100,
      allowedAttachmentExtensions: const <String>['pdf'],
      maxAttachmentBytes: 1572864,
    );

    await tester.pumpWidget(
      _testApp(StudentLeaveAddPage(initialConstraints: constraints)),
    );
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(
      find.byType(StudentLeaveAddPage),
    );
    final String expectedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(yesterday);
    expect(find.text(expectedDate), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);
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

  testWidgets('record refresh is disabled while one load is in progress', (
    WidgetTester tester,
  ) async {
    final _FakeStudentLeaveHelper helper = _FakeStudentLeaveHelper();
    addTearDown(helper.dio.close);

    await tester.pumpWidget(_testApp(StudentLeavePage(helper: helper)));
    await tester.pump();

    expect(helper.recordRequestCount, 1);
    final Finder refreshButtonFinder = find.ancestor(
      of: find.byIcon(Icons.refresh),
      matching: find.byType(IconButton),
    );
    IconButton refreshButton = tester.widget<IconButton>(refreshButtonFinder);
    expect(refreshButton.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(helper.recordRequestCount, 1);

    helper.completeNextRecords(const <StudentLeaveRecord>[
      StudentLeaveRecord(
        number: 'SL1130001',
        schoolYear: '113',
        semester: '1',
        category: '事假',
        dateRange: '2026-08-11 09:00 ~ 2026-08-11 10:00',
        tutorStatus: '已通過',
        chairStatus: '已通過',
        instructorStatus: '免審核',
        proofText: '無',
      ),
    ]);
    await tester.pumpAndSettle();

    refreshButton = tester.widget<IconButton>(refreshButtonFinder);
    expect(refreshButton.onPressed, isNotNull);
    expect(helper.recordRequestCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an uncertain deletion refreshes the list without retrying', (
    WidgetTester tester,
  ) async {
    final _FakeStudentLeaveHelper helper = _FakeStudentLeaveHelper();
    addTearDown(helper.dio.close);
    await tester.pumpWidget(
      _testApp(
        ApTheme(
          themeMode: ThemeMode.light,
          preferences: _FakePreferences(),
          child: StudentLeavePage(helper: helper),
        ),
      ),
    );
    await tester.pump();
    helper.completeNextRecords(const <StudentLeaveRecord>[
      StudentLeaveRecord(
        number: 'SL1130001',
        schoolYear: '113',
        semester: '1',
        category: '事假',
        dateRange: '2026-08-11 09:00 ~ 2026-08-11 10:00',
        tutorStatus: '未確認',
        chairStatus: '未確認',
        instructorStatus: '未確認',
        proofText: '無',
        canDelete: true,
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(app.optionComfirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(helper.deleteRequestCount, 1);
    expect(helper.recordRequestCount, 2);
    expect(find.text(app.studentLeaveDeleteUnknownResult), findsOneWidget);
    expect(find.text(app.studentLeaveDeleteFailed), findsNothing);

    helper.completeNextRecords(const <StudentLeaveRecord>[]);
    await tester.pumpAndSettle();
    expect(find.text(app.studentLeaveEmpty), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(helper.deleteRequestCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semester changes during a load fetch only the latest semester', (
    WidgetTester tester,
  ) async {
    final List<StudentLeaveSemester> options = StudentLeaveSemester.recent();
    final _FakeStudentLeaveHelper helper = _FakeStudentLeaveHelper();
    addTearDown(helper.dio.close);

    await tester.pumpWidget(_testApp(StudentLeavePage(helper: helper)));
    await tester.pump();

    expect(helper.requestedSemesters, <StudentLeaveSemester>[options.first]);

    await tester.tap(
      find.text(
        app.studentLeaveYearSemester(
          year: options.first.schoolYear,
          semester: options.first.semester,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find
          .text(
            app.studentLeaveYearSemester(
              year: options[1].schoolYear,
              semester: options[1].semester,
            ),
          )
          .last,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(helper.recordRequestCount, 1);
    helper.completeNextRecords(const <StudentLeaveRecord>[
      StudentLeaveRecord(
        number: 'SL-old',
        schoolYear: '113',
        semester: '1',
        category: '事假',
        dateRange: '2026-08-11 09:00 ~ 2026-08-11 10:00',
        tutorStatus: '已通過',
        chairStatus: '已通過',
        instructorStatus: '免審核',
        proofText: '無',
      ),
    ]);
    await tester.pump();

    expect(helper.requestedSemesters, <StudentLeaveSemester>[
      options.first,
      options[1],
    ]);

    helper.completeNextRecords(const <StudentLeaveRecord>[
      StudentLeaveRecord(
        number: 'SL-new',
        schoolYear: '113',
        semester: '2',
        category: '病假',
        dateRange: '2026-08-12 09:00 ~ 2026-08-12 10:00',
        tutorStatus: '已通過',
        chairStatus: '已通過',
        instructorStatus: '免審核',
        proofText: '無',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('SL-old'), findsNothing);
    expect(find.text('SL-new'), findsOneWidget);
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

    await tester.tap(find.text(app.studentLeaveFinalSubmit));
    await tester.pumpAndSettle();

    expect(find.text(app.studentLeaveSubmitConfirmTitle), findsOneWidget);
    expect(find.text(app.studentLeaveSubmitConfirmContent), findsOneWidget);
    await tester.tap(find.text(app.optionCancel));
    await tester.pumpAndSettle();

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

  testWidgets('English leave review values translate 檢視 as View', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.zhHantTw));
    const StudentLeavePreviewResult preview = StudentLeavePreviewResult(
      statusCode: 200,
      body: '',
      confirmation: StudentLeaveConfirmation(
        messages: <String>[],
        rawText: '',
        sections: <StudentLeaveConfirmationSection>[
          StudentLeaveConfirmationSection(
            title: '假單資料',
            fields: <StudentLeaveConfirmationField>[
              StudentLeaveConfirmationField(label: '課程審核', value: '檢視'),
              StudentLeaveConfirmationField(
                label: '假別',
                value: '事假(Personal leave)',
              ),
              StudentLeaveConfirmationField(
                label: '備註',
                value: 'Doctor visit (follow-up)',
              ),
            ],
          ),
        ],
      ),
      confirmForm: StudentLeaveConfirmForm(
        action: 'SLAMS_stuLeave_add_act.php',
        fields: <String, String>{'confirm': '1'},
      ),
    );

    await tester.pumpWidget(
      _testApp(const StudentLeaveResultPage(previewResult: preview)),
    );
    await tester.pumpAndSettle();

    expect(find.text('View'), findsOneWidget);
    expect(find.text('Personal leave'), findsOneWidget);
    expect(find.text('Doctor visit (follow-up)'), findsOneWidget);
    expect(find.text('follow-up'), findsNothing);
    expect(find.text('檢視'), findsNothing);
  });

  testWidgets('Chinese confirmation values preserve arbitrary parentheses', (
    WidgetTester tester,
  ) async {
    const StudentLeavePreviewResult preview = StudentLeavePreviewResult(
      statusCode: 200,
      body: '',
      confirmation: StudentLeaveConfirmation(
        messages: <String>[],
        rawText: '',
        sections: <StudentLeaveConfirmationSection>[
          StudentLeaveConfirmationSection(
            title: '假單資料',
            fields: <StudentLeaveConfirmationField>[
              StudentLeaveConfirmationField(
                label: '備註',
                value: 'Doctor visit (follow-up)',
              ),
            ],
          ),
        ],
      ),
      confirmForm: StudentLeaveConfirmForm(
        action: 'SLAMS_stuLeave_add_act.php',
        fields: <String, String>{'confirm': '1'},
      ),
    );

    await tester.pumpWidget(
      _testApp(const StudentLeaveResultPage(previewResult: preview)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doctor visit (follow-up)'), findsOneWidget);
    expect(find.text('Doctor visit'), findsNothing);
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

class _FakePreferences extends Fake implements PreferenceUtil {}

class _FakeStudentLeaveHelper extends StudentLeaveHelper {
  final List<Completer<ApiResult<List<StudentLeaveRecord>>>> _recordRequests =
      <Completer<ApiResult<List<StudentLeaveRecord>>>>[];
  final List<StudentLeaveSemester> requestedSemesters =
      <StudentLeaveSemester>[];

  int get recordRequestCount => _recordRequests.length;
  int deleteRequestCount = 0;

  @override
  Future<ApiResult<StudentLeaveDeleteResult>> checkAndDeleteLeave({
    required String username,
    required String password,
    required String leaveNumber,
  }) async {
    deleteRequestCount++;
    return const ApiSuccess<StudentLeaveDeleteResult>(
      StudentLeaveDeleteResult(statusCode: 503, body: 'Service Unavailable'),
    );
  }

  @override
  Future<ApiResult<List<StudentLeaveRecord>>> getLeaveRecords({
    required String username,
    required String password,
    StudentLeaveSemester? semester,
  }) {
    final Completer<ApiResult<List<StudentLeaveRecord>>> completer =
        Completer<ApiResult<List<StudentLeaveRecord>>>();
    requestedSemesters.add(semester ?? StudentLeaveSemester.current());
    _recordRequests.add(completer);
    return completer.future;
  }

  void completeNextRecords(List<StudentLeaveRecord> records) {
    _recordRequests
        .firstWhere(
          (Completer<ApiResult<List<StudentLeaveRecord>>> completer) =>
              !completer.isCompleted,
        )
        .complete(ApiSuccess<List<StudentLeaveRecord>>(records));
  }
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

StudentLeaveFormConstraints _testConstraints() {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  return StudentLeaveFormConstraints(
    leaveTypes: StudentLeaveType.values,
    firstStartDate: today.subtract(const Duration(days: 30)),
    lastStartDate: today.add(const Duration(days: 30)),
    firstEndDate: today.subtract(const Duration(days: 30)),
    lastEndDate: today.add(const Duration(days: 30)),
    startTimes: const <String>['07:00', '09:00', '12:00'],
    endTimes: const <String>['07:30', '09:30', '12:00'],
    maxReasonLength: 100,
    allowedAttachmentExtensions: const <String>['pdf'],
    maxAttachmentBytes: 1572864,
  );
}
