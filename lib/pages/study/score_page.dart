import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/models/options.dart';
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
  ScoreData? scoreData;

  List<String> years = <String>[];
  List<String> semesters = <String>[];

  int currentYearsIndex = 0;
  int currentSemesterIndex = 0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScoreScaffold(
      state: state,
      scoreData: scoreData,
      middleTitle: ap.credits,
      customHint: hasPreScore
          ? app.hasPreScoreHint
          : null,
      itemPicker: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: ItemPicker(
              dialogTitle: ap.pickSemester,
              items: years,
              currentIndex: currentYearsIndex,
              onSelected: (int index) {
                setState(() {
                  currentYearsIndex = index;
                });
                _getSemesterScore();
              },
            ),
          ),
          Expanded(
            child: ItemPicker(
              dialogTitle: ap.pickSemester,
              items: semesters,
              currentIndex: currentSemesterIndex,
              onSelected: (int index) {
                setState(() {
                  currentSemesterIndex = index;
                });
                _getSemesterScore();
              },
            ),
          ),
        ],
      ),
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

  Future<void> _getSemester() async {
    final ApiResult<ScoreSemesterData> result =
        await SelcrsHelper.instance.getScoreSemesterData();
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<ScoreSemesterData>(:final ScoreSemesterData data):
        scoreSemesterData = data;
        years = <String>[];
        semesters = <String>[];
        for (final SemesterOptions option in scoreSemesterData!.years) {
          years.add(option.text);
        }
        for (final SemesterOptions option in scoreSemesterData!.semesters) {
          semesters.add(option.text);
        }
        _getSemesterScore();
      case ApiFailure<ScoreSemesterData>():
        setState(() => state = ScoreState.error);
      case ApiError<ScoreSemesterData>():
        setState(() => state = ScoreState.error);
    }
  }

  Future<void> _getSemesterScore() async {
    if (scoreSemesterData == null) {
      _getSemester();
      return;
    }
    final int month = DateTime.now().month;
    final ApiResult<ScoreData> result =
        await SelcrsHelper.instance.getScoreData(
      year: scoreSemesterData!.years[currentYearsIndex].value,
      semester: scoreSemesterData!.semesters[currentSemesterIndex].value,
      searchPreScore: month == 6 || month == 7 || month == 1 || month == 2,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<ScoreData>(:final ScoreData data):
        scoreData = data;
        setState(() {
          if (scoreData!.scores.isEmpty) {
            state = ScoreState.empty;
          } else {
            state = ScoreState.finish;
          }
        });
      case ApiFailure<ScoreData>():
        setState(() => state = ScoreState.error);
      case ApiError<ScoreData>():
        setState(() => state = ScoreState.error);
    }
  }
}
