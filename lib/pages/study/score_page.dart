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
  late ApLocalizations ap;

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
    ap = ApLocalizations.of(context);
    return ScoreScaffold(
      state: state,
      scoreData: scoreData,
      middleTitle: ap.credits,
      isShowSearchButton: false,
      customHint:
          hasPreScore ? AppLocalizations.of(context).hasPreScoreHint : null,
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
      onRefresh: () async {
        _getSemesterScore();
      },
      finalScoreBuilder: (int index) {
        return ScoreTextBorder(
          text: scoreData!.scores[index].finalScore,
          style: TextStyle(
            fontSize: 15.0,
            color: scoreData!.scores[index].isPreScore
                ? ApTheme.of(context).yellow
                : null,
          ),
        );
      },
      details: (scoreData == null)
          ? null
          : <String>[
              '${ap.creditsTakenEarned}：' +
                  '${scoreData!.detail.creditTaken ?? ''}'
                      '${scoreData!.detail.isCreditEmpty ? '' : ' / '}'
                      '${scoreData!.detail.creditEarned ?? ''}',
              '${ap.average}：${scoreData!.detail.average ?? ''}',
              '${ap.rank}：${scoreData!.detail.classRank ?? ''}',
              '${ap.percentage}：${scoreData!.detail.classPercentage ?? ''}',
            ],
    );
  }

  Future<void> _getSemester() async {
    try {
      final ScoreSemesterData data =
          await SelcrsHelper.instance.getScoreSemesterData();
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
    } catch (e, s) {
      setState(() {
        switch (e) {
          case DioException():
            state = ScoreState.error;
            if (e.type == DioExceptionType.unknown) {
              CrashlyticsUtil.instance.recordError(e, s);
            }
          case GeneralResponse():
            state = ScoreState.error;
        }
      });
    }
  }

  Future<void> _getSemesterScore() async {
    if (scoreSemesterData == null) {
      _getSemester();
      return;
    }
    final int month = DateTime.now().month;
    try {
      final ScoreData data = await SelcrsHelper.instance.getScoreData(
        year: scoreSemesterData!.years[currentYearsIndex].value,
        semester: scoreSemesterData!.semesters[currentSemesterIndex].value,
        searchPreScore: month == 6 || month == 7 || month == 1 || month == 2,
      );
      scoreData = data;
      if (mounted && scoreData != null) {
        setState(() {
          if (scoreData!.scores.isEmpty) {
            state = ScoreState.empty;
          } else {
            state = ScoreState.finish;
          }
        });
      }
    } catch (e, s) {
      setState(() {
        switch (e) {
          case DioException():
            state = ScoreState.error;
            if (e.type == DioExceptionType.unknown) {
              CrashlyticsUtil.instance.recordError(e, s);
            }
          case GeneralResponse():
            state = ScoreState.error;
        }
      });
    }
  }
}
