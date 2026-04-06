import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class ScorePage extends StatefulWidget {
  static const String routerName = '/score';

  @override
  ScorePageState createState() => ScorePageState();
}

class ScorePageState extends State<ScorePage> {
  ScoreState state = ScoreState.loading;
  bool isOffline = false;

  ScoreSemesterData? scoreSemesterData;
  SemesterData? semesterData;
  ScoreData? scoreData;

  final SemesterPickerController _pickerController = SemesterPickerController();

  bool get hasPreScore {
    for (final Score score in scoreData?.scores ?? <Score>[]) {
      if (score.isPreScore) return true;
    }
    return false;
  }

  bool get hasPreAverage {
    if (scoreData?.detail.average != 0.0 && scoreData?.detail.classRank == '') {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen('ScorePage', 'score_page.dart');
    _getSemester();
  }

  @override
  void dispose() {
    _pickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScoreScaffold(
      state: state,
      scoreData: scoreData,
      semesterData: semesterData,
      semesterPickerController: _pickerController,
      onSelect: (int index) {
        semesterData = semesterData!.copyWith(currentIndex: index);
        _getSemesterScore();
      },
      middleTitle: ap.credits,
      customHint: hasPreScore ? app.hasPreScoreHint : null,
      onRefresh: () {
        _getSemesterScore();
      },
      finalScoreBuilder: (int index) {
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        return Text(
          scoreData!.scores[index].finalScore ?? '',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: scoreData!.scores[index].isPreScore
                ? colorScheme.tertiary
                : null,
          ),
        );
      },
    );
  }

  SemesterData _toSemesterData(ScoreSemesterData data) {
    final List<Semester> semesters = <Semester>[];
    for (final yearOption in data.years) {
      for (final semOption in data.semesters) {
        semesters.add(
          Semester(
            year: yearOption.value,
            value: semOption.value,
            text: '${yearOption.text} ${semOption.text}',
          ),
        );
      }
    }
    final int defaultIndex =
        data.selectYearsIndex * data.semesters.length + data.selectSemesterIndex;
    final Semester defaultSemester = semesters[defaultIndex];
    return SemesterData(
      data: semesters,
      defaultSemester: defaultSemester,
      currentIndex: defaultIndex,
    );
  }

  Future<void> _getSemester() async {
    final ApiResult<ScoreSemesterData> result =
        await SelcrsHelper.instance.getScoreSemesterData();
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<ScoreSemesterData>(:final ScoreSemesterData data):
        scoreSemesterData = data;
        setState(() {
          semesterData = _toSemesterData(data);
        });
        _getSemesterScore();
      case ApiFailure<ScoreSemesterData>():
        setState(() => state = ScoreState.error);
      case ApiError<ScoreSemesterData>():
        setState(() => state = ScoreState.error);
    }
  }

  Future<void> _getSemesterScore() async {
    if (semesterData == null) {
      _getSemester();
      return;
    }
    final Semester current = semesterData!.currentSemester;
    final int month = DateTime.now().month;
    final ApiResult<ScoreData> result =
        await SelcrsHelper.instance.getScoreData(
      year: current.year,
      semester: current.value,
      searchPreScore: month == 6 || month == 7 || month == 1 || month == 2,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<ScoreData>(:final ScoreData data):
        scoreData = data;
        setState(() {
          if (scoreData!.scores.isEmpty) {
            state = ScoreState.empty;
            _pickerController.markSemesterEmpty(current);
          } else {
            state = ScoreState.finish;
            _pickerController.markSemesterHasData(current);
          }
        });
      case ApiFailure<ScoreData>():
        _pickerController.markSemesterHasData(current);
        setState(() => state = ScoreState.error);
      case ApiError<ScoreData>():
        _pickerController.markSemesterHasData(current);
        setState(() => state = ScoreState.error);
    }
  }
}
