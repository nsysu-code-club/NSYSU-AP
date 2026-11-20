import 'dart:async';
import 'dart:convert';

import 'package:ap_common/ap_common.dart'
    hide AppLocale, AppLocaleUtils, LocaleSettings, TranslationProvider;
import 'package:ap_common_flutter_core/ap_common_flutter_core.dart'
    as ap_l10n
    show AppLocale, TranslationProvider, setApLocale;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as q;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:nsysu_ap/pages/announcement_review/announcement_review_card.dart';
import 'package:nsysu_ap/pages/announcement_review/announcement_review_page.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_article.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_submission_page.dart';
import 'package:nsysu_ap/theme/liquid_glass_theme.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class _Preferences extends Fake implements PreferenceUtil {
  final Map<String, Object> values = <String, Object>{};

  @override
  bool getBool(String key, bool fallback) => values[key] as bool? ?? fallback;

  @override
  int getInt(String key, int fallback) => values[key] as int? ?? fallback;

  @override
  String getStringSecurity(String key, String fallback) =>
      values[key] as String? ?? fallback;

  @override
  Future<void> setStringSecurity(String key, String data) async =>
      values[key] = data;
}

class _ReviewClient extends AnnouncementHelper {
  _ReviewClient() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.headers['Authorization'], startsWith('Bearer '));
          if (options.path.startsWith('/user/application/')) {
            ownApplicationReads++;
            expect(
              options.path,
              '/user/application/reviewer%40example.invalid',
            );
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'data': <Object>[]},
              ),
            );
            return;
          }
          expect(options.path, '/user/info');
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'permission_level': serverRole.index},
            ),
          );
        },
      ),
    );
  }

  PermissionLevel serverRole = PermissionLevel.user;
  int blacklistReads = 0;
  int ownApplicationReads = 0;
  int applicationReads = 0;
  List<Announcement> applications = <Announcement>[
    Announcement.empty().copyWith(
      title: '校園藝文活動',
      description: '公告投稿內容',
      applicationId: 'request-1',
      applicant: 'announcement-review-fixture@g-mail.nsysu.edu.tw',
      expireTime: '2026-11-26T19:00:00Z',
      tags: <String>['校園'],
    ),
    Announcement.empty().copyWith(
      title: '已審核講座',
      applicationId: 'request-2',
      reviewStatus: true,
    ),
  ];
  bool failLoading = false;
  (String?, String?, bool)? decision;
  String? deletedApplication;
  int? deletedAnnouncement;

  @override
  Future<ApiResult<List<Announcement>>> getApplications() async {
    applicationReads++;
    return failLoading
        ? const ApiError<List<Announcement>>(
            GeneralResponse(statusCode: 503, message: ''),
          )
        : ApiSuccess<List<Announcement>>(applications);
  }

  @override
  Future<ApiResult<List<String>>> getBlackList() async {
    blacklistReads++;
    return const ApiSuccess<List<String>>(<String>[]);
  }

  final List<Announcement> submissions = <Announcement>[];
  Completer<ApiResult<Response<dynamic>>>? pendingSubmission;

  @override
  Future<ApiResult<Response<dynamic>>> addApplication({
    required Announcement data,
    String? languageCode,
  }) {
    submissions.add(data);
    return pendingSubmission?.future ??
        Future<ApiResult<Response<dynamic>>>.value(_success());
  }

  List<Announcement> published = <Announcement>[
    Announcement.empty().copyWith(id: 1, title: '校園通知', tags: <String>['校園']),
    Announcement.empty().copyWith(id: 2, title: '社團通知', tags: <String>['社團']),
  ];

  @override
  Future<ApiResult<List<Announcement>>> getAllAnnouncements() async =>
      ApiSuccess<List<Announcement>>(published);

  @override
  Future<ApiResult<Response<dynamic>>> removeApplication({
    required String applicationId,
  }) async {
    deletedApplication = applicationId;
    applications = applications
        .where((Announcement item) => item.applicationId != applicationId)
        .toList();
    return _success();
  }

  @override
  Future<ApiResult<Response<dynamic>>> deleteAnnouncement({
    required Announcement data,
  }) async {
    deletedAnnouncement = data.id;
    published = published
        .where((Announcement item) => item.id != data.id)
        .toList();
    return _success();
  }

  @override
  Future<ApiResult<Response<dynamic>>> approveApplication({
    required String? applicationId,
    String? reviewDescription,
  }) async => _record(applicationId, reviewDescription, true);

  @override
  Future<ApiResult<Response<dynamic>>> rejectApplication({
    required String? applicationId,
    String? reviewDescription,
  }) async => _record(applicationId, reviewDescription, false);

  ApiResult<Response<dynamic>> _record(
    String? id,
    String? note,
    bool approved,
  ) {
    decision = (id, note, approved);
    applications = <Announcement>[
      for (final Announcement item in applications)
        item.applicationId == id ? item.copyWith(reviewStatus: approved) : item,
    ];
    return _success();
  }

  ApiResult<Response<dynamic>> _success() => ApiSuccess<Response<dynamic>>(
    Response<dynamic>(requestOptions: RequestOptions(), statusCode: 200),
  );
}

void main() {
  final _Preferences prefs = _Preferences();
  late _ReviewClient client;

  setUpAll(() async {
    registerApCommonCore(preference: prefs);
    await ap_l10n.setApLocale(ap_l10n.AppLocale.zhHantTw);
    await LocaleSettings.setLocale(AppLocale.zhHantTw);
  });

  setUp(() {
    prefs.values.clear();
    client = _ReviewClient();
  });

  void signInAs(PermissionLevel role, {PermissionLevel? serverRole}) {
    client.serverRole = serverRole ?? role;
    final String payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode(<String, Object>{
              'exp':
                  DateTime.now()
                      .add(const Duration(hours: 1))
                      .millisecondsSinceEpoch ~/
                  1000,
              'user': <String, Object>{
                'permission_level': role.index,
                'username': 'reviewer@example.invalid',
                'login_type': 'Oauth2',
              },
            }),
          ),
        )
        .replaceAll('=', '');
    prefs.values[ApConstants.announcementIsLogin] = true;
    AnnouncementLoginData(key: 'e30.$payload.fixture').save();
  }

  Widget appHost({bool submissionOnly = false, Widget? home}) =>
      ap_l10n.TranslationProvider(
        child: TranslationProvider(
          child: MaterialApp(
            locale: const Locale('zh', 'TW'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppleLiquidTheme.harmonize(ApTheme.light(Colors.blue)),
            darkTheme: AppleLiquidTheme.harmonize(ApTheme.dark(Colors.blue)),
            home:
                home ??
                AnnouncementReviewPage(
                  organizationDomain: '@g-mail.nsysu.edu.tw',
                  linkToCampusAccount: true,
                  submissionOnly: submissionOnly,
                  client: client,
                ),
          ),
        ),
      );

  testWidgets(
    'reviewers start with pending and a confirmed approval updates the queue',
    (WidgetTester tester) async {
      signInAs(PermissionLevel.editor);
      await tester.pumpWidget(appHost());
      await tester.pumpAndSettle();
      expect(find.text(app.pendingAnnouncementCount(count: 1)), findsOneWidget);
      expect(find.text('校園藝文活動'), findsOneWidget);
      expect(find.text('已審核講座'), findsNothing);
      final Finder card = find.byType(AnnouncementReviewCard);
      final Finder email = find.text(client.applications.first.applicant!);
      final DateTime deadline = DateTime.parse(
        client.applications.first.expireTime!,
      ).toLocal();
      final String date = MaterialLocalizations.of(
        tester.element(card),
      ).formatShortDate(deadline);
      final Finder deadlineLabel = find.text(
        app.announcementDeadline(date: date),
      );
      expect(tester.getCenter(deadlineLabel).dx, tester.getCenter(card).dx);
      expect(
        tester.getBottomLeft(deadlineLabel).dy,
        lessThan(tester.getTopLeft(email).dy),
      );
      expect(tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace, isNull);

      await tester.tap(find.text(app.approveAnnouncement));
      await tester.pumpAndSettle();
      expect(client.decision, isNull);
      await tester.enterText(find.byType(TextField), '資料完整');
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilledButton, app.approveAnnouncement),
        ),
      );
      await tester.pumpAndSettle();
      expect(client.decision, ('request-1', '資料完整', true));
      expect(find.text(app.pendingAnnouncementCount(count: 0)), findsOneWidget);
      expect(find.text('校園藝文活動'), findsNothing);

      final Finder approvedFilter = find.widgetWithText(
        ChoiceChip,
        ap.reviewApproval,
      );
      Focus.of(
        tester.element(
          find.descendant(
            of: approvedFilter,
            matching: find.text(ap.reviewApproval),
          ),
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('已審核講座'), findsOneWidget);
      await tester.tap(find.text(app.publishedAnnouncements));
      await tester.pumpAndSettle();
      expect(find.text('校園通知'), findsOneWidget);
      expect(find.text('社團通知'), findsOneWidget);
      expect(deadlineLabel, findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '社團 (1)'));
      await tester.pumpAndSettle();
      expect(find.text('校園通知'), findsNothing);
      expect(find.text('社團通知'), findsOneWidget);
    },
  );

  testWidgets(
    'reject confirmation adapts to narrow dark large text and can be canceled',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            highContrast: true,
            disableAnimations: true,
          );
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      signInAs(PermissionLevel.admin);
      await tester.pumpWidget(appHost());
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((Widget widget) => widget is DropdownButton),
        findsNWidgets(2),
      );
      final Finder reject = find.text(app.rejectAnnouncement);
      await tester.ensureVisible(reject);
      await tester.pumpAndSettle();
      await tester.tap(reject);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Finder sheet = find.byType(BottomSheet);
      expect(
        tester.widget<BottomSheet>(sheet).backgroundColor,
        Theme.of(tester.element(sheet)).colorScheme.surface,
      );
      final Finder cancel = find.descendant(
        of: sheet,
        matching: find.byType(TextButton),
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(client.decision, isNull);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      final Finder confirm = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(FilledButton),
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(client.decision, ('request-1', '', false));
    },
  );

  testWidgets(
    'signed-out and ordinary accounts have the appropriate entry and retry',
    (WidgetTester tester) async {
      await tester.pumpWidget(appHost());
      await tester.pumpAndSettle();
      expect(find.text(app.announcementGoogleSignIn), findsOneWidget);
      expect(find.text(app.announcementReviewLinkHint), findsOneWidget);
      expect(find.text(app.approveAnnouncement), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      signInAs(PermissionLevel.admin, serverRole: PermissionLevel.user);
      client.failLoading = true;
      await tester.pumpWidget(appHost());
      await tester.pumpAndSettle();
      expect(find.text(ap.clickToRetry), findsOneWidget);
      expect(find.text(app.publishedAnnouncements), findsNothing);
      client.failLoading = false;
      await tester.tap(find.text(ap.clickToRetry));
      await tester.pumpAndSettle();
      expect(find.text('校園藝文活動'), findsOneWidget);
      expect(find.text(app.announcementSubmissionSystem), findsOneWidget);
      expect(find.text(app.approveAnnouncement), findsNothing);
      expect(client.blacklistReads, 0);
      expect(find.byTooltip(ap.addApplication), findsOneWidget);
      expect(
        find.byTooltip(app.announcementItemActions(title: '校園藝文活動')),
        findsNothing,
      );
    },
  );

  testWidgets('homepage submissions stay in submission mode for reviewers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(appHost(submissionOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('首頁輪播投稿系統'), findsOneWidget);
    expect(find.text(app.announcementReviewLinkHint), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    signInAs(PermissionLevel.admin);
    await tester.pumpWidget(appHost(submissionOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('首頁輪播投稿系統'), findsOneWidget);
    expect(find.text(app.publishedAnnouncements), findsNothing);
    expect(find.text(app.pendingAnnouncementCount(count: 1)), findsNothing);
    expect(find.text(app.approveAnnouncement), findsNothing);
    expect(client.blacklistReads, 0);
    expect(client.applicationReads, 0);
    expect(client.ownApplicationReads, 1);
    await tester.tap(find.byTooltip(ap.addApplication));
    await tester.pumpAndSettle();
    expect(find.byType(CarouselSubmissionPage), findsOneWidget);
    expect(find.text(ap.submit), findsNothing);
  });

  testWidgets(
    'checks formatted submissions before sending and retains edits on return',
    (WidgetTester tester) async {
      int uploads = 0;
      const String cover = 'https://example.invalid/test-cover.jpg';
      await tester.pumpWidget(
        appHost(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                child: Text(ap.addApplication),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => CarouselSubmissionPage(
                        client: client,
                        pickImage: () async => XFile('cover.jpg'),
                        uploadImage: (XFile file) async => ++uploads == 1
                            ? const ApiError<String>(
                                GeneralResponse(statusCode: 503, message: ''),
                              )
                            : const ApiSuccess<String>(cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text(ap.addApplication));
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expect(find.text(ap.imageUrl), findsNothing);
      expect(find.textContaining('ImgBB'), findsOneWidget);
      await tap(find.text(app.carouselCheck));
      expect(find.text(app.carouselImageRequired), findsOneWidget);
      expect(find.text(ap.doNotEmpty), findsOneWidget);
      await tap(find.text(app.carouselPick));
      expect(find.text(app.carouselUploadFailed), findsOneWidget);
      await tap(find.text(app.carouselPick));
      expect(find.text(app.carouselReplace), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '天文社觀星夜');
      await tester.enterText(find.byType(TextFormField).last, '活動');
      await tap(find.text(app.carouselCheck));
      expect(find.text(app.carouselLinkError), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'https://example.invalid/event',
      );

      final q.QuillController body = tester
          .widget<q.QuillEditor>(find.byType(q.QuillEditor))
          .controller;
      body.replaceText(
        0,
        0,
        '準備物品',
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
      await tap(find.byTooltip(app.carouselBold));
      await tap(find.byTooltip(app.carouselItalic));
      await tap(find.byTooltip(app.carouselSize));
      await tap(find.text(app.carouselLarge));
      await tap(find.byTooltip(app.carouselIndent));
      await tap(find.text(app.carouselCheck));
      final Announcement indented = tester
          .widget<CarouselArticle>(find.byType(CarouselArticle))
          .item;
      final RegExp indentation = RegExp(r'padding-left:\s*3(?:\.0)?em');
      expect(indented.description, matches(indentation));
      expect(
        tester.widget<HtmlWidget>(find.byType(HtmlWidget)).html,
        matches(indentation),
      );
      await tap(find.byType(BackButton));
      await tap(find.byTooltip(app.carouselOutdent));
      await tap(find.byTooltip(app.carouselOrdered));
      await tap(find.text(app.carouselCheck));
      expect(
        tester
            .widget<CarouselArticle>(find.byType(CarouselArticle))
            .item
            .description,
        contains('<ol>'),
      );
      await tap(find.byType(BackButton));
      await tap(find.byTooltip(app.carouselBullet));
      await tap(find.text(app.carouselCheck));
      expect(client.submissions, isEmpty);
      final Announcement preview = tester
          .widget<CarouselArticle>(find.byType(CarouselArticle))
          .item;
      expect(preview.imgUrl, cover);
      expect(carouselExcerpt(preview.description), '準備物品');
      expect(preview.description, contains('<strong'));
      expect(preview.description, contains('<em>'));
      expect(preview.description, contains('1.5em'));
      expect(preview.description, contains('<ul>'));
      expect(preview.expireTime, isNull);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(body.document.toPlainText().trim(), '準備物品');
      expect(find.text('天文社觀星夜'), findsOneWidget);
      await tap(find.text(app.carouselCheck));
      final Finder submit = find.widgetWithText(FilledButton, ap.submit);
      await tester.ensureVisible(submit);
      client.pendingSubmission = Completer<ApiResult<Response<dynamic>>>();
      await tester.tap(submit);
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(client.submissions.single.description, preview.description);
      client.pendingSubmission!.complete(
        const ApiError<Response<dynamic>>(
          GeneralResponse(statusCode: 503, message: ''),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(app.carouselSubmitFailed), findsOneWidget);
      client.pendingSubmission = null;
      await tap(submit);
      expect(client.submissions, hasLength(2));
      expect(find.byType(CarouselSubmissionPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expiry choices share a row in a narrow dark large-text editor', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 680);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      appHost(home: CarouselSubmissionPage(client: client)),
    );
    await tester.pumpAndSettle();
    final Finder setDate = find.text(app.carouselSetExpiry);
    final Finder noExpiry = find.text(app.carouselNoExpiry);
    await tester.ensureVisible(setDate);
    expect(
      tester.getCenter(noExpiry).dx,
      greaterThan(tester.getCenter(setDate).dx),
    );
    expect(
      tester.getCenter(noExpiry).dy,
      closeTo(tester.getCenter(setDate).dy, 1),
    );
    Future<void> choose(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await choose(setDate);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    final MaterialLocalizations locale = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await choose(find.text(locale.okButtonLabel));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await choose(find.text(locale.okButtonLabel));
    final String picked = locale.formatMediumDate(
      DateTime.now().add(const Duration(days: 7)),
    );
    expect(find.textContaining(picked), findsOneWidget);
    await choose(noExpiry);
    expect(find.textContaining(picked), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide editor keeps focus order and actions reachable above the keyboard',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 820);
      tester.view.padding = const FakeViewPadding(top: 28, left: 24, right: 24);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        appHost(home: CarouselSubmissionPage(client: client)),
      );
      await tester.pumpAndSettle();
      final Finder fields = find.byType(TextFormField);
      expect(tester.getSize(fields.first).width, lessThanOrEqualTo(640));
      expect(tester.getRect(fields.first).left, greaterThan(24));
      await tester.tap(fields.first);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final EditableText link = tester.widget<EditableText>(
        find.descendant(of: fields.last, matching: find.byType(EditableText)),
      );
      expect(link.focusNode.hasFocus, isTrue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final Finder check = find.widgetWithText(FilledButton, app.carouselCheck);
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      expect(tester.getRect(check).bottom, lessThanOrEqualTo(520));
      expect(tester.getSemantics(check).label, contains(app.carouselCheck));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deleting a submission or published item uses the matching API', (
    WidgetTester tester,
  ) async {
    signInAs(PermissionLevel.editor);
    await tester.pumpWidget(appHost());
    await tester.pumpAndSettle();

    Future<void> askToDelete(String title) async {
      await tester.tap(
        find.byTooltip(app.announcementItemActions(title: title)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(ap.delete));
      await tester.pumpAndSettle();
      expect(
        find.text(app.confirmAnnouncementDeletion(title: title)),
        findsOneWidget,
      );
    }

    final Finder confirmation = find.byType(AlertDialog);
    final Finder delete = find.descendant(
      of: confirmation,
      matching: find.text(ap.delete),
    );

    await askToDelete('校園藝文活動');
    expect(find.text(app.deleteReviewApplication), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: confirmation,
        matching: find.text(
          MaterialLocalizations.of(
            tester.element(confirmation),
          ).cancelButtonLabel,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(client.deletedApplication, isNull);

    await askToDelete('校園藝文活動');
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(client.deletedApplication, 'request-1');
    expect(client.deletedAnnouncement, isNull);
    expect(find.text(app.pendingAnnouncementCount(count: 0)), findsOneWidget);
    expect(find.text('校園藝文活動'), findsNothing);

    await tester.tap(find.text(app.publishedAnnouncements));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '校園 (1)'));
    await tester.pumpAndSettle();
    await askToDelete('校園通知');
    expect(find.text(ap.deleteNewsTitle), findsOneWidget);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(client.deletedAnnouncement, 1);
    expect(find.text('校園通知'), findsNothing);
    expect(find.text('社團通知'), findsOneWidget);
  });
}
