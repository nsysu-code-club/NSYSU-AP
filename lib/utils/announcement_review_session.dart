import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nsysu_ap/utils/announcement_access.dart';

/// Restores the announcement account previously linked by the active campus
/// user. Authorization and the application list come from the review service.
class AnnouncementReviewSession extends ChangeNotifier {
  AnnouncementReviewSession({
    required PreferenceUtil preferences,
    @visibleForTesting AnnouncementHelper Function()? createClient,
    @visibleForTesting Future<String?> Function()? getGoogleIdToken,
    @visibleForTesting Future<void> Function()? signOutGoogle,
  }) : _preferences = preferences,
       _createClient = createClient ?? _ReviewClient.new,
       _getGoogleIdToken = getGoogleIdToken ?? _restoreGoogleIdToken,
       _signOutGoogle = signOutGoogle ?? _signOutGoogleAccount;

  static const String _linkedReviewerKey = 'pref_linked_announcement_reviewer';
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  final PreferenceUtil _preferences;
  final AnnouncementHelper Function() _createClient;
  final Future<String?> Function() _getGoogleIdToken;
  final Future<void> Function() _signOutGoogle;
  String? _schoolAccount;
  bool _reviewOpen = false;
  int _revision = 0;
  Future<void>? _refreshInFlight;
  int? _pendingCount;

  int? get pendingCount => _pendingCount;

  void setSchoolAccount(String? username) {
    final String normalized = username?.trim().toUpperCase() ?? '';
    final String? account = normalized.isEmpty ? null : normalized;
    if (account == _schoolAccount) return;
    _schoolAccount = account;
    _invalidateRequests();
    _updateCount(null);
    final AnnouncementLoginData? saved = _savedReviewer();
    if (saved != null && (account == null || !_isLinked(account, saved))) {
      unawaited(_suspendReviewer());
    }
    if (account != null) unawaited(refresh());
  }

  Future<void> refresh() {
    final String? account = _schoolAccount;
    if (account == null || _reviewOpen) return Future<void>.value();
    if (_refreshInFlight case final Future<void> inFlight) return inFlight;
    final int request = _revision;
    return _refreshInFlight = _refresh(account, request).whenComplete(() {
      if (request == _revision) _refreshInFlight = null;
    });
  }

  Future<void> _refresh(String account, int request) async {
    final AnnouncementLoginData? saved = _savedReviewer();
    if (saved == null || !_isLinked(account, saved)) {
      _updateCount(null);
      return;
    }

    final AnnouncementHelper client = _createClient();
    try {
      AnnouncementLoginData reviewer = saved;
      ApiResult<List<Announcement>>? applications;
      if (!saved.isExpired) {
        client.setAuthorization(saved.key);
        applications = await _getReviewApplications(client, saved, request);
      }
      if (request != _revision) return;

      if ((applications == null || _errorCode(applications) == 401) &&
          _isGoogleSession) {
        final String? token = await _getGoogleIdToken();
        if (request != _revision) return;
        if (token != null && token.isNotEmpty) {
          final ApiResult<AnnouncementLoginData> result = await client
              .googleLogin(idToken: token);
          if (request != _revision) return;
          if (result case ApiSuccess<AnnouncementLoginData>(
            :final AnnouncementLoginData data,
          ) when _reviewerIdentity(data) == _reviewerIdentity(saved)) {
            reviewer = data;
            client.setAuthorization(data.key);
            applications = await _getReviewApplications(client, data, request);
          }
        }
      }
      if (request != _revision) return;

      if (applications case ApiSuccess<List<Announcement>>(
        :final List<Announcement> data,
      )) {
        if (reviewer.key != saved.key) reviewer.save();
        await _preferences.setBool(ApConstants.announcementIsLogin, true);
        if (request != _revision) return;
        _updateCount(
          data.where((Announcement item) => item.reviewStatus == null).length,
        );
      } else {
        if (applications == null ||
            _errorCode(applications) == 401 ||
            _errorCode(applications) == 403) {
          await _suspendReviewer();
        }
        if (request == _revision) _updateCount(null);
      }
    } on Object {
      if (request == _revision) _updateCount(null);
    } finally {
      client.dio.close();
    }
  }

  Future<ApiResult<List<Announcement>>> _getReviewApplications(
    AnnouncementHelper client,
    AnnouncementLoginData reviewer,
    int request,
  ) async {
    final ApiResult<PermissionLevel> access = await client.getAuthenticatedRole(
      reviewer,
    );
    return switch (access) {
      ApiSuccess<PermissionLevel>(:final PermissionLevel data)
          when request == _revision && data != PermissionLevel.user =>
        client.getApplications(),
      ApiError<PermissionLevel>(:final GeneralResponse response) =>
        ApiError<List<Announcement>>(response),
      ApiFailure<PermissionLevel>(:final DioException exception) =>
        ApiFailure<List<Announcement>>(exception),
      _ => const ApiError<List<Announcement>>(
        GeneralResponse(statusCode: 403, message: ''),
      ),
    };
  }

  /// Only a sign-in through the review entry establishes a campus account link.
  Future<void> openPage(
    Future<void> Function() open, {
    bool linkReviewer = true,
  }) async {
    if (_reviewOpen) return;
    _reviewOpen = true;
    _invalidateRequests();
    final String? account = _schoolAccount;
    try {
      final AnnouncementLoginData? savedLogin = _savedLogin();
      final AnnouncementLoginData? saved =
          savedLogin != null && _reviewerIdentity(savedLogin) != null
          ? savedLogin
          : null;
      final bool isLinked =
          saved != null && account != null && _isLinked(account, saved);
      final bool wasRestored =
          saved != null &&
          isLinked &&
          !saved.isExpired &&
          _preferences.getBool(ApConstants.announcementIsLogin, false);
      bool canLink = true;
      if (savedLogin == null || (saved != null && !wasRestored)) {
        await _suspendReviewer();
        if (saved != null && !isLinked && _isGoogleSession) {
          // The review page's Google button can otherwise reuse the last
          // account silently even when the active campus account changed.
          try {
            await _signOutGoogle();
          } on Object {
            canLink = false;
          }
        }
      }
      await open();
      if (account != _schoolAccount) {
        if (_savedReviewer() != null) await _suspendReviewer();
        return;
      }
      if (account == null || !canLink) return;

      if (_preferences.getBool(ApConstants.announcementIsLogin, false)) {
        final AnnouncementLoginData? reviewer = _savedReviewer();
        if (linkReviewer && reviewer != null && !reviewer.isExpired) {
          await _preferences.setStringSecurity(
            _linkedReviewerKey,
            _link(account, reviewer),
          );
        }
      } else if (wasRestored) {
        // Explicit sign-out in the review screen revokes automatic restoration.
        _clearAuthorization();
        await _preferences.remove(_linkedReviewerKey);
      }
    } finally {
      _reviewOpen = false;
      unawaited(refresh());
    }
  }

  AnnouncementLoginData? _savedReviewer() {
    final AnnouncementLoginData? data = _savedLogin();
    return data != null && _reviewerIdentity(data) != null ? data : null;
  }

  AnnouncementLoginData? _savedLogin() {
    try {
      final AnnouncementLoginData? data = AnnouncementLoginData.load();
      if (data != null) {
        // Decode legacy cache entries before the upstream page reads them.
        _reviewerIdentity(data);
        data.isExpired;
      }
      return data;
    } on Object {
      // Package preferences can contain malformed or legacy tokens.
      return null;
    }
  }

  static String? _reviewerIdentity(AnnouncementLoginData data) {
    final PermissionLevel level = data.level;
    final String? username = data.username;
    if (level == PermissionLevel.user || username == null || username.isEmpty) {
      return null;
    }
    return '${data.loginType}:$username';
  }

  static String _link(String account, AnnouncementLoginData data) =>
      '$account\n${_reviewerIdentity(data)}';

  bool _isLinked(String account, AnnouncementLoginData data) {
    try {
      return _preferences.getStringSecurity(_linkedReviewerKey, '') ==
          _link(account, data);
    } on Object {
      return false;
    }
  }

  bool get _isGoogleSession =>
      _preferences.getInt(ApConstants.announcementLoginType, -1) ==
      AnnouncementLoginType.google.index;

  static int? _errorCode(ApiResult<List<Announcement>> result) =>
      result is ApiError<List<Announcement>>
      ? result.response.statusCode
      : null;

  static Future<String?> _restoreGoogleIdToken() async {
    final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    return (await account?.authentication)?.idToken;
  }

  static Future<void> _signOutGoogleAccount() async {
    await _googleSignIn.signOut();
  }

  void _updateCount(int? count) {
    if (_pendingCount == count) return;
    _pendingCount = count;
    notifyListeners();
  }

  static void _clearAuthorization() {
    final AnnouncementHelper helper = AnnouncementHelper.instance;
    helper.dio.options.headers.remove('Authorization');
    helper.clearSetting();
    helper.code = null;
  }

  Future<void> _suspendReviewer() async {
    _clearAuthorization();
    await _preferences.setBool(ApConstants.announcementIsLogin, false);
  }

  void _invalidateRequests() {
    _revision++;
    _refreshInFlight = null;
  }

  @override
  void dispose() {
    _invalidateRequests();
    _schoolAccount = null;
    super.dispose();
  }
}

class _ReviewClient extends AnnouncementHelper {
  // The package's default retry is coupled to the active review page's login.
  // Use only the credential explicitly restored for this request.
  @override
  Future<ApiResult<bool>> reLogin() async =>
      const ApiError<bool>(GeneralResponse(statusCode: 401, message: ''));
}
