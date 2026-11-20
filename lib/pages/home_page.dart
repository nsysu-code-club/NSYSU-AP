import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

/// Owns NSYSU home data; navigation and account state come from AppNavigation.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.isLogin,
    required this.userInfo,
    required this.displayPicture,
    required this.onAvatarTap,
    required this.onLoginTap,
    required this.onOpenCourse,
    required this.onOpenAnnouncementSubmission,
    this.enableStartupSideEffects = true,
    this.refreshRevision = 0,
    this.additionalEntries = const <Widget>[],
    this.dashboardWidgets = const <Widget>[],
  });

  static const String routerName = '/home';
  final bool isLogin;
  final UserInfo? userInfo;
  final bool displayPicture;
  final VoidCallback onAvatarTap;
  final VoidCallback onLoginTap;
  final VoidCallback onOpenCourse;
  final VoidCallback onOpenAnnouncementSubmission;
  final bool enableStartupSideEffects;
  final int refreshRevision;
  final List<Widget> additionalEntries;
  final List<Widget> dashboardWidgets;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeState _state = HomeState.loading;
  List<Announcement> _announcements = <Announcement>[];
  CourseData? _courseData;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    if (!widget.enableStartupSideEffects) _state = HomeState.empty;
    if (widget.enableStartupSideEffects) _getAllAnnouncement();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLogin != widget.isLogin ||
        oldWidget.refreshRevision != widget.refreshRevision) {
      _loadCourseData();
    }
  }

  void _loadCourseData() {
    _courseData = widget.isLogin
        ? CourseData.load(
            PreferenceUtil.instance.getString(
              ApConstants.currentSemesterCode,
              ApConstants.semesterLatest,
            ),
          )
        : null;
  }

  Future<void> _getAllAnnouncement() async {
    final ApiResult<List<Announcement>> result = await AnnouncementHelper
        .instance
        .getAnnouncements(tags: <String>['nsysu']);
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<List<Announcement>>(:final List<Announcement> data):
        setState(() {
          _announcements = data;
          _state = data.isEmpty ? HomeState.empty : HomeState.finish;
        });
      case ApiError<List<Announcement>>() || ApiFailure<List<Announcement>>():
        setState(() => _state = HomeState.error);
    }
  }

  @override
  Widget build(BuildContext context) => ApHomeContent(
    title: app.appName,
    labels: ApHomeContentLabels(
      loginTitle: app.loginCardTitle,
      loginSubtitle: app.loginCardSubtitle,
      latestAnnouncements: app.latestAnnouncements,
      postAnnouncement: app.postAnnouncement,
      courseNotLoaded: app.courseNotLoaded,
    ),
    isLogin: widget.isLogin,
    userInfo: widget.userInfo,
    displayPicture: widget.displayPicture,
    announcementState: _state,
    announcements: _announcements,
    announcementExcerpt: (Announcement item) =>
        carouselExcerpt(item.description),
    courseData: _courseData,
    onAvatarTap: widget.onAvatarTap,
    onLoginTap: widget.onLoginTap,
    onOpenCourse: widget.onOpenCourse,
    onOpenAnnouncementReview: widget.onOpenAnnouncementSubmission,
    additionalEntries: widget.additionalEntries,
    dashboardWidgets: widget.dashboardWidgets,
    onAnnouncementTap: (Announcement announcement) {
      ApUtils.pushCupertinoStyle(
        context,
        CarouselArticlePage(item: announcement),
      );
    },
    onRefreshAnnouncements: _getAllAnnouncement,
  );
}
