import 'dart:async';
import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/announcement_review_session.dart';

class _Preferences extends Fake implements PreferenceUtil {
  final Map<String, Object> values = <String, Object>{};

  @override
  bool getBool(String key, bool defaultValue) =>
      values[key] as bool? ?? defaultValue;

  @override
  Future<void> setBool(String key, bool data) async => values[key] = data;

  @override
  int getInt(String key, int defaultValue) =>
      values[key] as int? ?? defaultValue;

  @override
  String getStringSecurity(String key, String defaultValue) =>
      values[key] as String? ?? defaultValue;

  @override
  Future<void> setStringSecurity(String key, String data) async =>
      values[key] = data;

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
}

class _ReviewClient extends AnnouncementHelper {
  _ReviewClient({
    required this.read,
    required this.google,
    required PermissionLevel Function() getRole,
  }) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) =>
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'permission_level': getRole().index,
                    },
                  ),
                ),
      ),
    );
  }

  final Future<ApiResult<List<Announcement>>> Function() read;
  final AnnouncementLoginData Function() google;

  @override
  Future<ApiResult<List<Announcement>>> getApplications() => read();

  @override
  Future<ApiResult<AnnouncementLoginData>> googleLogin({
    String? idToken,
  }) async => ApiSuccess<AnnouncementLoginData>(google());
}

AnnouncementLoginData _session({
  String account = 'reviewer@example.invalid',
  PermissionLevel role = PermissionLevel.editor,
  bool expired = false,
}) {
  final DateTime expiry = DateTime.now().add(Duration(hours: expired ? -1 : 1));
  final String payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode(<String, Object>{
            'exp': expiry.millisecondsSinceEpoch ~/ 1000,
            'user': <String, Object>{
              'permission_level': role.index,
              'login_type': 'google',
              'username': account,
            },
          }),
        ),
      )
      .replaceAll('=', '');
  return AnnouncementLoginData(key: 'e30.$payload.fixture');
}

void main() {
  late _Preferences preferences;
  late AnnouncementReviewSession session;
  late Future<ApiResult<List<Announcement>>> Function() read;
  late AnnouncementLoginData Function() google;
  late int reads;
  late int renewals;
  late PermissionLevel role;
  const String campusId = 'B123456789';

  setUpAll(() {
    preferences = _Preferences();
    registerApCommonCore(preference: preferences);
  });

  setUp(() {
    preferences.values.clear();
    reads = 0;
    renewals = 0;
    role = PermissionLevel.editor;
    read = () async => const ApiSuccess<List<Announcement>>(<Announcement>[]);
    google = _session;
  });

  AnnouncementReviewSession createSession() => AnnouncementReviewSession(
    preferences: preferences,
    signOutGoogle: () async {},
    getGoogleIdToken: () async {
      renewals++;
      return 'fixture';
    },
    createClient: () => _ReviewClient(
      google: () => google(),
      getRole: () => role,
      read: () {
        reads++;
        return read();
      },
    ),
  );

  Future<void> useReviewPage(AnnouncementLoginData data) =>
      session.openPage(() async {
        data.save();
        preferences.values[ApConstants.announcementLoginType] =
            AnnouncementLoginType.google.index;
        await preferences.setBool(ApConstants.announcementIsLogin, true);
      });

  setUp(() => session = createSession());
  tearDown(() => session.dispose());

  test(
    'links after manual reviewer sign-in and restores for the same account',
    () async {
      session.setSchoolAccount(campusId);
      await session.refresh();
      expect(reads, 0);
      read = () async => ApiSuccess<List<Announcement>>(<Announcement>[
        Announcement.empty(),
        Announcement.empty().copyWith(reviewStatus: true),
        Announcement.empty().copyWith(reviewStatus: false),
        Announcement.empty(),
      ]);
      await useReviewPage(_session());
      await session.refresh();
      expect(session.pendingCount, 2);
      expect(reads, 1);

      session.setSchoolAccount(null);
      expect(session.pendingCount, isNull);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, true),
        isFalse,
      );
      session.dispose();
      session = createSession();
      session.setSchoolAccount('b123456789');
      await session.refresh();
      expect(session.pendingCount, 2);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, false),
        isTrue,
      );

      read = () async => const ApiSuccess<List<Announcement>>(<Announcement>[]);
      await session.openPage(() async {});
      await session.refresh();
      expect(session.pendingCount, 0);
    },
  );

  test(
    'does not fetch for normal users or for a different campus account',
    () async {
      session.setSchoolAccount(campusId);
      await useReviewPage(_session(role: PermissionLevel.user));
      await session.refresh();
      expect(reads, 0);
      expect(session.pendingCount, isNull);

      await useReviewPage(_session(role: PermissionLevel.admin));
      await session.refresh();
      expect(reads, 1);
      session.setSchoolAccount('B987654321');
      await session.refresh();
      expect(reads, 1);
      expect(session.pendingCount, isNull);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, true),
        isFalse,
      );
    },
  );

  test(
    'a late response from a previous campus account cannot restore its session',
    () async {
      final Completer<ApiResult<List<Announcement>>> pending =
          Completer<ApiResult<List<Announcement>>>();
      session.setSchoolAccount(campusId);
      read = () => pending.future;
      await useReviewPage(_session());
      final Future<void> refresh = session.refresh();
      session.setSchoolAccount('B987654321');
      pending.complete(
        ApiSuccess<List<Announcement>>(<Announcement>[Announcement.empty()]),
      );
      await refresh;
      expect(session.pendingCount, isNull);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, true),
        isFalse,
      );
    },
  );

  test(
    'renews the linked reviewer but discards a different Google account',
    () async {
      session.setSchoolAccount(campusId);
      await useReviewPage(_session());
      await session.refresh();
      _session(expired: true).save();
      await session.refresh();
      expect(renewals, 1);
      expect(session.pendingCount, 0);

      _session(expired: true).save();
      google = () => _session(account: 'different@example.invalid');
      await session.refresh();
      expect(renewals, 2);
      expect(session.pendingCount, isNull);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, true),
        isFalse,
      );
    },
  );

  test(
    'hides the number when forbidden and removes the link on review sign-out',
    () async {
      session.setSchoolAccount(campusId);
      await useReviewPage(_session());
      await session.refresh();
      await session.openPage(
        () => preferences.setBool(ApConstants.announcementIsLogin, false),
      );
      await session.refresh();
      expect(reads, 1);
      expect(session.pendingCount, isNull);

      await useReviewPage(_session());
      await session.refresh();
      read = () async => const ApiError<List<Announcement>>(
        GeneralResponse(statusCode: 403, message: ''),
      );
      await session.refresh();
      expect(session.pendingCount, isNull);
      expect(renewals, 0);
      expect(
        preferences.getBool(ApConstants.announcementIsLogin, true),
        isFalse,
      );
    },
  );

  test('clears the badge when the server removes review access', () async {
    session.setSchoolAccount(campusId);
    await useReviewPage(_session());
    await session.refresh();
    expect(session.pendingCount, 0);
    role = PermissionLevel.user;
    await session.refresh();
    expect(session.pendingCount, isNull);
    expect(reads, 1);
  });
}
