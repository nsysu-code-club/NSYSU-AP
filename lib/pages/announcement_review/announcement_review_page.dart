import 'dart:async';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nsysu_ap/pages/announcement_review/announcement_review_card.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_article.dart';
import 'package:nsysu_ap/pages/announcement_review/carousel_submission_page.dart';
import 'package:nsysu_ap/utils/announcement_access.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/widgets/liquid_glass/apple_page_header.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AnnouncementReviewPage extends StatefulWidget {
  const AnnouncementReviewPage({
    super.key,
    required this.organizationDomain,
    required this.linkToCampusAccount,
    this.submissionOnly = false,
    @visibleForTesting this.client,
  });

  final String organizationDomain;
  final bool linkToCampusAccount;
  final bool submissionOnly;
  final AnnouncementHelper? client;

  @override
  State<AnnouncementReviewPage> createState() => _AnnouncementReviewPageState();
}

enum _Section { applications, published }

enum _Filter { pending, all, approved, rejected }

enum _Menu { blacklist, editors, signOut }

enum _ItemAction { edit, delete }

class _AnnouncementReviewPageState extends State<AnnouncementReviewPage> {
  late final AnnouncementHelper _client =
      widget.client ?? AnnouncementHelper.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );
  final PreferenceUtil _preferences = PreferenceUtil.instance;

  AnnouncementLoginData? _session;
  PermissionLevel? _role;
  Future<ApiResult<List<Announcement>>>? _applications;
  Future<ApiResult<List<Announcement>>>? _published;
  Set<String> _blacklist = <String>{};
  _Section _section = _Section.applications;
  _Filter _filter = _Filter.all;
  String? _tag;
  bool _signingIn = false;
  bool _saving = false;

  bool get _canReview =>
      !widget.submissionOnly &&
      (_role == PermissionLevel.editor || _role == PermissionLevel.admin);

  bool get _canManageEditors => _canReview && _role == PermissionLevel.admin;

  String get _title =>
      widget.submissionOnly || (_session != null && !_canReview)
      ? app.announcementSubmissionSystem
      : ap.announcementReviewSystem;

  @override
  void initState() {
    super.initState();
    if (!_preferences.getBool(ApConstants.announcementIsLogin, false)) return;
    try {
      final AnnouncementLoginData? session = AnnouncementLoginData.load();
      if (session == null) return;
      if (!session.isExpired) {
        final int provider = _preferences.getInt(
          ApConstants.announcementLoginType,
          0,
        );
        if (provider >= 0 && provider < AnnouncementLoginType.values.length) {
          _client.loginType = AnnouncementLoginType.values[provider];
          if (_client.loginType != AnnouncementLoginType.normal) {
            _client.code = _preferences.getStringSecurity(
              ApConstants.announcementIdToken,
              '',
            );
          }
        }
        _signingIn = true;
        unawaited(_restoreSession(session));
      } else if (_preferences.getInt(ApConstants.announcementLoginType, 0) ==
          AnnouncementLoginType.google.index) {
        _signingIn = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(
              _signIn(
                AnnouncementLoginType.google,
                previouslySignedIn: session,
              ),
            );
          }
        });
      }
    } on Object {
      // Legacy or malformed preferences should fall back to the sign-in form.
      _session = null;
      _role = null;
      _clearClientAuthorization();
    }
  }

  Future<void> _restoreSession(AnnouncementLoginData session) async {
    try {
      final ApiResult<PermissionLevel> result = await _client
          .getAuthenticatedRole(session);
      if (!mounted) return;
      if (result case ApiSuccess<PermissionLevel>(
        :final PermissionLevel data,
      )) {
        _client.setAuthorization(session.key);
        setState(() => _showSession(session, data));
      } else {
        _clearClientAuthorization();
      }
    } on Object {
      if (mounted) _clearClientAuthorization();
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  void _showSession(AnnouncementLoginData session, PermissionLevel role) {
    _session = session;
    _role = role;
    _section = _Section.applications;
    _filter = _canReview ? _Filter.pending : _Filter.all;
    _tag = null;
    _applications = _request(_Section.applications);
    _published = null;
    if (_canReview) unawaited(_loadBlacklist());
  }

  Future<void> _signIn(
    AnnouncementLoginType provider, {
    AnnouncementLoginData? previouslySignedIn,
  }) async {
    final bool silent = previouslySignedIn != null;
    if (_signingIn && !silent) return;
    setState(() => _signingIn = true);
    try {
      final String? token;
      switch (provider) {
        case AnnouncementLoginType.google:
          final GoogleSignInAccount? account = silent
              ? await _googleSignIn.signInSilently()
              : await _googleSignIn.signIn();
          token = (await account?.authentication)?.idToken;
        case AnnouncementLoginType.apple:
          final AuthorizationCredentialAppleID credential =
              await SignInWithApple.getAppleIDCredential(
                scopes: <AppleIDAuthorizationScopes>[
                  AppleIDAuthorizationScopes.email,
                ],
              );
          token = credential.identityToken;
        case AnnouncementLoginType.normal:
          return;
      }
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        if (!silent) _message(ap.thirdPartyLoginFail);
        return;
      }
      final ApiResult<AnnouncementLoginData> result =
          provider == AnnouncementLoginType.google
          ? await _client.googleLogin(idToken: token)
          : await _client.appleLogin(idToken: token);
      if (!mounted) return;
      if (result case ApiSuccess<AnnouncementLoginData>(
        :final AnnouncementLoginData data,
      )) {
        if (previouslySignedIn != null &&
            (data.username == null ||
                data.username != previouslySignedIn.username)) {
          _client.dio.options.headers.remove('Authorization');
          _client.code = null;
          await _googleSignIn.signOut();
          return;
        }
        if (data.isExpired) {
          if (!silent) _message(ap.thirdPartyLoginFail);
          return;
        }
        final ApiResult<PermissionLevel> access = await _client
            .getAuthenticatedRole(data);
        if (!mounted) return;
        if (access is! ApiSuccess<PermissionLevel>) {
          if (!silent) _message(ap.thirdPartyLoginFail);
          return;
        }
        data.save();
        await _preferences.setStringSecurity(
          ApConstants.announcementIdToken,
          token,
        );
        await _preferences.setInt(
          ApConstants.announcementLoginType,
          provider.index,
        );
        await _preferences.setBool(ApConstants.announcementIsLogin, true);
        if (!mounted) return;
        setState(() => _showSession(data, access.data));
      } else if (!silent) {
        result.showErrorToast(context);
      }
    } on SignInWithAppleAuthorizationException catch (error) {
      if (mounted && error.code != AuthorizationErrorCode.canceled && !silent) {
        _message(ap.thirdPartyLoginFail);
      }
    } on Object {
      if (mounted && !silent) _message(ap.thirdPartyLoginFail);
    } finally {
      if (mounted) {
        if (_session == null) _clearClientAuthorization();
        setState(() => _signingIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    final bool google = _client.loginType == AnnouncementLoginType.google;
    final Future<void> disableLogin = _preferences.setBool(
      ApConstants.announcementIsLogin,
      false,
    );
    _clearClientAuthorization();
    setState(() {
      _session = null;
      _role = null;
      _applications = null;
      _published = null;
      _blacklist = <String>{};
      _signingIn = google;
    });
    try {
      await disableLogin;
      if (google) await _googleSignIn.signOut();
    } on Object {
      if (mounted) _message(ap.unknownError);
    } finally {
      if (mounted && google) setState(() => _signingIn = false);
    }
  }

  void _clearClientAuthorization() {
    _client.dio.options.headers.remove('Authorization');
    _client.clearSetting();
    _client.code = null;
  }

  Future<ApiResult<List<Announcement>>> _request(_Section section) async {
    try {
      if (widget.submissionOnly) {
        return await _client.getOwnApplications(_session!);
      }
      return await (section == _Section.applications
          ? _client.getApplications()
          : _client.getAllAnnouncements());
    } on Object {
      return const ApiError<List<Announcement>>(
        GeneralResponse(statusCode: 500, message: ''),
      );
    }
  }

  Future<void> _loadBlacklist() async {
    final AnnouncementLoginData? session = _session;
    try {
      final ApiResult<List<String>> result = await _client.getBlackList();
      if (!mounted || _session != session) return;
      if (result case ApiSuccess<List<String>>(:final List<String> data)) {
        setState(() => _blacklist = data.toSet());
      }
    } on Object {
      // A metadata refresh shouldn't prevent reviewing applications.
    }
  }

  Future<void> _refresh() async {
    final Future<ApiResult<List<Announcement>>> future = _request(_section);
    setState(() {
      switch (_section) {
        case _Section.applications:
          _applications = future;
        case _Section.published:
          _published = future;
      }
    });
    final ApiResult<List<Announcement>> result = await future;
    if (!mounted || _published != future || _tag == null) return;
    if (result
        case ApiSuccess<List<Announcement>>(:final List<Announcement> data)
        when !data.any(
          (Announcement item) => item.tags?.contains(_tag) ?? false,
        )) {
      setState(() => _tag = null);
    }
  }

  void _selectSection(_Section section) {
    if (!_canReview || section == _section) return;
    setState(() {
      _section = section;
      if (section == _Section.published && _published == null) {
        _tag = null;
        _published = _request(section);
      }
    });
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _showEditor(Mode mode, {Announcement? announcement}) async {
    if (_session == null ||
        _saving ||
        (mode != Mode.application && !_canReview)) {
      return;
    }
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => mode == Mode.application
            ? CarouselSubmissionPage(client: _client)
            : AnnouncementEditPage(
                mode: mode,
                announcement: announcement,
                blackList: _blacklist,
                organizationDomain: widget.organizationDomain,
              ),
      ),
    );
    if (!mounted || changed != true) return;
    if (mode == Mode.application) _message(ap.applicationSubmitSuccess);
    await _reloadAfterChange();
  }

  Future<void> _reloadAfterChange() async {
    if (_section == _Section.applications) {
      _published = null;
    } else {
      _applications = _request(_Section.applications);
    }
    await _refresh();
  }

  Future<void> _runChange(
    Future<ApiResult<Response<dynamic>>> Function() request, {
    String? successMessage,
  }) async {
    if (!_canReview || _saving) return;
    setState(() => _saving = true);
    try {
      final ApiResult<Response<dynamic>> result = await request();
      if (!mounted) return;
      if (result.isSuccess) {
        await _reloadAfterChange();
        if (mounted) _message(successMessage ?? ap.updateSuccess);
      } else {
        result.showErrorToast(context);
      }
    } on Object {
      if (mounted) _message(ap.clickToRetry);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _review(Announcement item, {required bool approve}) async {
    final String? id = item.applicationId;
    if (id == null || id.isEmpty || !_canReview || _saving) return;
    final String? note = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => _DecisionSheet(title: item.title, approve: approve),
    );
    if (note == null || !mounted) return;
    await _runChange(
      () => approve
          ? _client.approveApplication(
              applicationId: id,
              reviewDescription: note,
            )
          : _client.rejectApplication(
              applicationId: id,
              reviewDescription: note,
            ),
    );
  }

  Future<void> _delete(Announcement item, {required bool isApplication}) async {
    if (!_canReview || _saving || !_canDelete(item, isApplication)) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(
          isApplication ? app.deleteReviewApplication : ap.deleteNewsTitle,
        ),
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        content: Text(app.confirmAnnouncementDeletion(title: item.title)),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ap.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _runChange(
        () => isApplication
            ? _client.removeApplication(applicationId: item.applicationId!)
            : _client.deleteAnnouncement(data: item),
        successMessage: ap.deleteSuccess,
      );
    }
  }

  bool _canDelete(Announcement item, bool isApplication) => isApplication
      ? (item.applicationId?.isNotEmpty ?? false)
      : item.id != null;

  Future<void> _menuAction(_Menu item) async {
    switch (item) {
      case _Menu.blacklist:
        if (!_canReview || _saving) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const BlackListPage()),
        );
        if (mounted) await _loadBlacklist();
      case _Menu.editors:
        if (!_canManageEditors || _saving) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const EditorListPage()),
        );
      case _Menu.signOut:
        await _signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_signingIn && !_saving,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          actions: <Widget>[
            if (_session != null) ...<Widget>[
              IconButton(
                tooltip: _canReview
                    ? app.addPublishedAnnouncement
                    : ap.addApplication,
                onPressed: _saving
                    ? null
                    : () =>
                          _showEditor(_canReview ? Mode.add : Mode.application),
                icon: const Icon(Icons.add_rounded),
              ),
              PopupMenuButton<_Menu>(
                tooltip: ap.settings,
                enabled: !_saving,
                onSelected: _menuAction,
                itemBuilder: (_) => <PopupMenuEntry<_Menu>>[
                  if (_canReview)
                    PopupMenuItem<_Menu>(
                      value: _Menu.blacklist,
                      child: Text(ap.blackList),
                    ),
                  if (_canManageEditors)
                    PopupMenuItem<_Menu>(
                      value: _Menu.editors,
                      child: Text(ap.editorList),
                    ),
                  PopupMenuItem<_Menu>(
                    value: _Menu.signOut,
                    child: Text(ap.logout),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: SafeArea(
          top: false,
          child: AppleContentContainer(
            child: _session == null
                ? _buildSignIn(colors)
                : _buildWorkspace(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildSignIn(ColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: <Widget>[
        _Heading(title: _title),
        const SizedBox(height: 22),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${ap.newsRuleDescription1(arg1: widget.organizationDomain)}'
                  '${ap.newsRuleDescription3}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (widget.linkToCampusAccount &&
                    !widget.submissionOnly) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    app.announcementReviewLinkHint,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 20),
                if (_signingIn) const LinearProgressIndicator(),
                FilledButton.icon(
                  onPressed: _signingIn
                      ? null
                      : () => _signIn(AnnouncementLoginType.google),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(app.announcementGoogleSignIn),
                ),
                if (!kIsWeb &&
                    <TargetPlatform>[
                      TargetPlatform.iOS,
                      TargetPlatform.macOS,
                    ].contains(defaultTargetPlatform)) ...<Widget>[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _signingIn
                        ? null
                        : () => _signIn(AnnouncementLoginType.apple),
                    icon: const Icon(Icons.apple),
                    label: Text(app.announcementAppleSignIn),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspace(ColorScheme colors) {
    final bool isApplications = _section == _Section.applications;
    return FutureBuilder<ApiResult<List<Announcement>>>(
      key: ValueKey<_Section>(_section),
      future: isApplications ? _applications : _published,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<ApiResult<List<Announcement>>> snapshot,
          ) {
            final ApiResult<List<Announcement>>? result = snapshot.data;
            final List<Announcement>? items =
                result is ApiSuccess<List<Announcement>> ? result.data : null;
            final String? tag =
                _tag != null &&
                    (items?.any(
                          (Announcement item) =>
                              item.tags?.contains(_tag) ?? false,
                        ) ??
                        false)
                ? _tag
                : null;
            final List<Announcement> filtered = items == null
                ? const <Announcement>[]
                : items
                      .where((Announcement item) => _matchesFilter(item, tag))
                      .toList();
            final int? pending = items != null && isApplications && _canReview
                ? items
                      .where((Announcement item) => item.reviewStatus == null)
                      .length
                : null;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _Heading(title: _title),
                          if (pending != null) ...<Widget>[
                            const SizedBox(height: 7),
                            Text(
                              app.pendingAnnouncementCount(count: pending),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                          if (!_canReview) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              app.carouselGuidelines,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                          _buildControls(items, tag),
                          if (_saving) const LinearProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                  if (items == null || filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildStatus(
                        snapshot.connectionState,
                        items != null,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        itemBuilder: (_, int index) =>
                            _buildCard(filtered[index], isApplications),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                      ),
                    ),
                ],
              ),
            );
          },
    );
  }

  bool _matchesFilter(Announcement item, String? tag) {
    if (_section == _Section.published) {
      return tag == null || (item.tags?.contains(tag) ?? false);
    }
    return switch (_filter) {
      _Filter.all => true,
      _Filter.pending => item.reviewStatus == null,
      _Filter.approved => item.reviewStatus == true,
      _Filter.rejected => item.reviewStatus == false,
    };
  }

  Widget _buildControls(List<Announcement>? items, String? tag) =>
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.4;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_canReview) ...<Widget>[
                SizedBox(height: compact ? 12 : 20),
                _buildSectionPicker(compact),
              ],
              if (items != null) ...<Widget>[
                SizedBox(height: compact ? 8 : 12),
                if (_section == _Section.applications)
                  _buildFilters(compact)
                else
                  _buildTags(items, tag, compact),
              ],
            ],
          );
        },
      );

  Widget _buildSectionPicker(bool compact) {
    final Map<_Section, String> labels = <_Section, String>{
      _Section.applications: app.announcementReviewQueue,
      _Section.published: app.publishedAnnouncements,
    };
    if (compact) {
      return _CompactPicker<_Section>(
        labels: labels,
        value: _section,
        onSelected: _selectSection,
      );
    }
    return SegmentedButton<_Section>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: <ButtonSegment<_Section>>[
        for (final MapEntry<_Section, String> label in labels.entries)
          ButtonSegment<_Section>(value: label.key, label: Text(label.value)),
      ],
      selected: <_Section>{_section},
      onSelectionChanged: (Set<_Section> value) => _selectSection(value.single),
    );
  }

  Widget _buildFilters(bool compact) {
    final Map<_Filter, String> labels = <_Filter, String>{
      _Filter.pending: ap.waitingForReview,
      _Filter.all: ap.all,
      _Filter.approved: ap.reviewApproval,
      _Filter.rejected: ap.reviewReject,
    };
    if (compact) {
      return _CompactPicker<_Filter>(
        labels: labels,
        value: _filter,
        onSelected: (_Filter value) => setState(() => _filter = value),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        for (final MapEntry<_Filter, String> label in labels.entries)
          ChoiceChip(
            label: Text(label.value),
            selected: _filter == label.key,
            onSelected: (_) => setState(() => _filter = label.key),
          ),
      ],
    );
  }

  Widget _buildTags(
    List<Announcement> items,
    String? selectedTag,
    bool compact,
  ) {
    final Map<String, int> tags = <String, int>{};
    for (final Announcement item in items) {
      for (final String tag in item.tags?.toSet() ?? <String>{}) {
        if (tag.isEmpty) continue;
        tags.update(tag, (int count) => count + 1, ifAbsent: () => 1);
      }
    }
    final List<String> sorted = tags.keys.toList()..sort();
    if (sorted.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return _CompactPicker<String>(
        labels: <String, String>{
          '': ap.all,
          for (final String tag in sorted) tag: '$tag (${tags[tag]})',
        },
        value: selectedTag ?? '',
        onSelected: (String tag) =>
            setState(() => _tag = tag.isEmpty ? null : tag),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        ChoiceChip(
          label: Text(ap.all),
          selected: selectedTag == null,
          onSelected: (_) => setState(() => _tag = null),
        ),
        for (final String tag in sorted)
          ChoiceChip(
            label: Text('$tag (${tags[tag]})'),
            selected: selectedTag == tag,
            onSelected: (_) =>
                setState(() => _tag = selectedTag == tag ? null : tag),
          ),
      ],
    );
  }

  Widget _buildStatus(ConnectionState state, bool isEmpty) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
    child: Center(
      child: switch (state) {
        ConnectionState.waiting || ConnectionState.active =>
          CircularProgressIndicator(semanticsLabel: ap.loading),
        _ when isEmpty => Text(ap.noData),
        _ => OutlinedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: Text(ap.clickToRetry),
        ),
      },
    ),
  );

  Widget _buildCard(Announcement item, bool isApplications) {
    final bool isPending = isApplications && item.reviewStatus == null;
    final bool canDelete = _canReview && _canDelete(item, isApplications);
    final bool canEdit = canDelete && (!isApplications || isPending);
    final Color error = Theme.of(context).colorScheme.error;
    return AnnouncementReviewCard(
      announcement: item,
      showReviewStatus: isApplications,
      showApplicant: _canReview,
      isBlocked: _blacklist.contains(item.applicant),
      menu: canDelete
          ? PopupMenuButton<_ItemAction>(
              tooltip: app.announcementItemActions(title: item.title),
              enabled: !_saving,
              onSelected: (_ItemAction action) async {
                switch (action) {
                  case _ItemAction.edit:
                    await _showEditor(
                      isApplications ? Mode.editApplication : Mode.edit,
                      announcement: item,
                    );
                  case _ItemAction.delete:
                    await _delete(item, isApplication: isApplications);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<_ItemAction>>[
                if (canEdit)
                  PopupMenuItem<_ItemAction>(
                    value: _ItemAction.edit,
                    child: Text(ap.update),
                  ),
                PopupMenuItem<_ItemAction>(
                  value: _ItemAction.delete,
                  child: Text(ap.delete, style: TextStyle(color: error)),
                ),
              ],
            )
          : null,
      onOpen: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CarouselArticlePage(item: item),
        ),
      ),
      actions: <Widget>[
        if (canDelete && isPending) ...<Widget>[
          TextButton(
            onPressed: _saving ? null : () => _review(item, approve: false),
            style: TextButton.styleFrom(foregroundColor: error),
            child: Text(app.rejectAnnouncement),
          ),
          FilledButton.tonal(
            onPressed: _saving ? null : () => _review(item, approve: true),
            child: Text(app.approveAnnouncement),
          ),
        ],
      ],
    );
  }
}

class _CompactPicker<T> extends StatelessWidget {
  const _CompactPicker({
    required this.labels,
    required this.value,
    required this.onSelected,
  });

  final Map<T, String> labels;
  final T value;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          itemHeight: null,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
          borderRadius: BorderRadius.circular(12),
          items: <DropdownMenuItem<T>>[
            for (final MapEntry<T, String> label in labels.entries)
              DropdownMenuItem<T>(value: label.key, child: Text(label.value)),
          ],
          onChanged: (T? selection) {
            if (selection != null) onSelected(selection);
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _DecisionSheet extends StatefulWidget {
  const _DecisionSheet({required this.title, required this.approve});

  final String title;
  final bool approve;

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String action = widget.approve
        ? app.approveAnnouncement
        : app.rejectAnnouncement;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Heading(title: action),
            const SizedBox(height: 4),
            Text(widget.title, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: ap.reviewDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _note.text.trim()),
                  style: widget.approve
                      ? null
                      : FilledButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                        ),
                  child: Text(action),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
