import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class CoursePage extends StatefulWidget {
  static const String routerName = '/course';

  @override
  CoursePageState createState() => CoursePageState();
}

class CoursePageState extends State<CoursePage> {
  late ApLocalizations ap;

  CourseState state = CourseState.loading;

  late TimeCodeConfig timeCodeConfig;

  SemesterData? semesterData;
  CourseData courseData = CourseData.empty();
  CourseNotifyData? notifyData;

  String? customStateHint;
  String? customHint;

  bool isOffline = false;

  String defaultSemesterCode = '';

  String get courseNotifyCacheKey =>
      semesterData?.defaultSemester.code ?? '1091';

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen('CoursePage', 'course_page.dart');
    //TODO: 確認是否需要
    // CourseNotifyData.clearOldVersionNotification(
    //   tag: '${SelcrsHelper.instance.username}_latest',
    //   newTag: courseNotifyCacheKey,
    // );
    Future<void>.microtask(() => _getSemester());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return CourseScaffold(
      state: state,
      courseData: courseData,
      notifyData: notifyData,
      semesterData: semesterData,
      onSelect: (int index) {
        semesterData!.currentIndex = index;
        _getCourseTables();
      },
      onRefresh: _getCourseTables,
      customHint: isOffline ? ap.offlineCourse : null,
      enableNotifyControl: semesterData != null &&
          semesterData?.currentSemester.code == defaultSemesterCode,
      courseNotifySaveKey: courseNotifyCacheKey,
      enableCaptureCourseTable: true,
      actions: const <Widget>[],
    );
  }

  Future<void> _getSemester() async {
    FirebaseRemoteConfig remoteConfig;
    try {
      //TODO improve
      remoteConfig = FirebaseRemoteConfigUtils.instance.remoteConfig!;
      await remoteConfig.fetch();
      await remoteConfig.activate();
      defaultSemesterCode =
          remoteConfig.getString(Constants.defaultCourseSemesterCode);
      final String rawTimeCodeConfig =
          remoteConfig.getString(Constants.timeCodeConfig);
      timeCodeConfig = TimeCodeConfig.fromRawJson(rawTimeCodeConfig);
      PreferenceUtil.instance.setString(
        Constants.defaultCourseSemesterCode,
        defaultSemesterCode,
      );
      PreferenceUtil.instance.setString(
        Constants.timeCodeConfig,
        rawTimeCodeConfig,
      );
    } catch (exception) {
      defaultSemesterCode = PreferenceUtil.instance.getString(
        Constants.defaultCourseSemesterCode,
        '${Constants.defaultYear}${Constants.defaultSemester}',
      );
      timeCodeConfig = TimeCodeConfig.fromRawJson(
        PreferenceUtil.instance.getString(
          Constants.timeCodeConfig,
          //ignore: lines_longer_than_80_chars
          '{  "timeCodes":[{"title":"A",         "startTime": "7:00"         ,"endTime": "7:50"        },{       "title":"1",         "startTime": "8:10"         ,"endTime": "9:00"        },{       "title":"2",         "startTime": "9:10"         ,"endTime": "10:00"        },{       "title":"3",         "startTime": "10:10"         ,"endTime": "11:00"        },{       "title":"4",         "startTime": "11:10"         ,"endTime": "12:00"        },{       "title":"B",         "startTime": "12:10"         ,"endTime": "13:00"        },{       "title":"5",         "startTime": "13:10"         ,"endTime": "14:00"        },{       "title":"6",         "startTime": "14:10"         ,"endTime": "15:00"        },{       "title":"7",         "startTime": "15:10"         ,"endTime": "16:00"        },{       "title":"8",         "startTime": "16:10"         ,"endTime": "17:00"        },{       "title":"9",         "startTime": "17:10"         ,"endTime": "18:00"        },{       "title":"C",         "startTime": "18:20"         ,"endTime": "19:10"        },{       "title":"D",         "startTime": "19:15"         ,"endTime": "20:05"        },{       "title":"E",         "startTime": "20:10"         ,"endTime": "21:00"        },{       "title":"F",         "startTime": "21:05"         ,"endTime": "21:55"        }] }',
        ),
      );
    }
    final Semester defaultSemester = Semester(
      year: defaultSemesterCode.substring(0, 3),
      value: defaultSemesterCode.substring(3),
      text: parser(defaultSemesterCode),
    );
    try {
      final SemesterData data =
          await SelcrsHelper.instance.getCourseSemesterData(
        defaultSemester: defaultSemester,
      );
      semesterData = data;
      final String semester = PreferenceUtil.instance.getString(
        ApConstants.currentSemesterCode,
        ApConstants.semesterLatest,
      );
      if (semester != defaultSemesterCode) {
        PreferenceUtil.instance.setString(
          ApConstants.currentSemesterCode,
          defaultSemesterCode,
        );
      }
      for (final Semester option in semesterData!.data) {
        option.text = parser(option.text);
      }
      semesterData!.currentIndex = semesterData!.defaultIndex;
      _getCourseTables();
    } catch (e) {
      setState(() {
        switch (e) {
          case DioException():
            customHint = ap.offlineCourse;
            state = CourseState.finish;
          default:
            state = CourseState.error;
        }
      });
    }
  }

  String parser(String text) {
    final AppLocalizations app = AppLocalizations.of(context);
    if (text.length == 4) {
      final String lastCode = text.substring(3);
      String last = '';
      switch (lastCode) {
        case '0':
          last = app.continuingSummerEducationProgram;
        case '1':
          last = app.fallSemester;
        case '2':
          last = app.springSemester;
        case '3':
          last = app.summerSemester;
      }
      String first;
      if (Intl.defaultLocale!.contains('en')) {
        int year = int.parse(text.substring(0, 3));
        year += 1911;
        first = '$year~${year + 1}';
      } else {
        first = '${text.substring(0, 3)}${app.courseYear}';
      }
      return '$first $last';
    } else {
      return text;
    }
  }

  Future<void> _getCourseTables() async {
    if (semesterData == null) {
      _getSemester();
      return;
    }
    notifyData = CourseNotifyData.load(courseNotifyCacheKey);
    try {
      final CourseData data = await SelcrsHelper.instance.getCourseData(
        username: SelcrsHelper.instance.username,
        timeCodeConfig: timeCodeConfig,
        semester: semesterData!.currentSemester.code,
      );
      courseData = data;
      courseData.save(courseNotifyCacheKey);
      if (mounted) {
        setState(() {
          if (courseData.courses.isEmpty) {
            state = CourseState.empty;
          } else {
            state = CourseState.finish;
          }
        });
      }
    } catch (e, s) {
      setState(() {
        switch (e) {
          case DioException():
            customHint = ap.offlineCourse;
            state = CourseState.finish;
          default:
            state = CourseState.error;
            CrashlyticsUtil.instance.recordError(e, s);
        }
      });
    }
  }
}
