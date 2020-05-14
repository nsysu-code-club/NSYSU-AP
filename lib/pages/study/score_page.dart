import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/item_picker.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/scaffold/score_scaffold.dart';

class ScorePage extends StatefulWidget {
  static const String routerName = "/score";

  @override
  ScorePageState createState() => ScorePageState();
}

class ScorePageState extends State<ScorePage> {
  ApLocalizations ap;

  ScoreState state = ScoreState.loading;
  bool isOffline = false;

  ScoreSemesterData scoreSemesterData;
  ScoreData scoreData;

  List<String> years;
  List<String> semesters;

  var currentYearsIndex = 0;
  var currentSemesterIndex = 0;

  bool get hasPreScore {
    bool _hasPreScore = false;
    scoreData?.scores?.forEach((score) {
      if (score.isPreScore) _hasPreScore = true;
    });
    return _hasPreScore;
  }

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance.setCurrentScreen("ScorePage", "score_page.dart");
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
      customHint: hasPreScore ? AppLocalizations.of(context).hasPreScoreHint : null,
      itemPicker: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ItemPicker(
            width: MediaQuery.of(context).size.width * 0.45,
            dialogTitle: ap.picksSemester,
            items: years,
              currentIndex: currentYearsIndex,
              onSelected: (int index) {
                setState(() {
                  currentYearsIndex = index;
                });
              _getSemesterScore();
            },
          ),
          ItemPicker(
            width: MediaQuery.of(context).size.width * 0.45,
            dialogTitle: ap.picksSemester,
            items: semesters,
              currentIndex: currentSemesterIndex,
              onSelected: (int index) {
                setState(() {
                  currentSemesterIndex = index;
                });
              _getSemesterScore();
            },
          ),
        ],
      ),
      onRefresh: () async {
        _getSemesterScore();
      },
      finalScoreBuilder: (int index) {
        return ScoreTextBorder(
          text: scoreData.scores[index].finalScore,
          style: TextStyle(
            fontSize: 15.0,
            color: scoreData.scores[index].isPreScore
                ? ApTheme.of(context).yellow
                : null,
          ),
        );
      },
      details: (scoreData == null)
          ? null
          : [
              '${ap.creditsTakenEarned}：'
                  '${scoreData.detail.creditTaken ?? ''}'
                  '${scoreData.detail.isCreditEmpty ? '' : ' / '}'
                  '${scoreData.detail.creditEarned ?? ''}',
              '${ap.average}：${scoreData.detail.average ?? ''}',
              '${ap.rank}：${scoreData.detail.classRank ?? ''}',
              '${ap.percentage}：${scoreData.detail.classPercentage ?? ''}',
            ],
    );
  }

  Function get _onFailure => (DioError e) => setState(() {
        state = ScoreState.error;
        switch (e.type) {
          case DioErrorType.CONNECT_TIMEOUT:
          case DioErrorType.SEND_TIMEOUT:
          case DioErrorType.RECEIVE_TIMEOUT:
          case DioErrorType.RESPONSE:
          case DioErrorType.CANCEL:
            break;
          case DioErrorType.DEFAULT:
            throw e;
            break;
        }
      });

  Function get _onError => (_) => setState(() => state = ScoreState.error);

  void _getSemester() async {
    SelcrsHelper.instance.getScoreSemesterData(
      callback: GeneralCallback(
        onFailure: _onFailure,
        onError: _onError,
        onSuccess: (ScoreSemesterData data) {
          scoreSemesterData = data;
          years = [];
          semesters = [];
          scoreSemesterData.years.forEach((option) {
            years.add(option.text);
          });
          scoreSemesterData.semesters.forEach((option) {
            semesters.add(option.text);
          });
          _getSemesterScore();
        },
      ),
    );
  }

  void _getSemesterScore() async {
    if (scoreSemesterData == null) {
      _getSemester();
      return;
    }
    SelcrsHelper.instance.getScoreData(
      year: scoreSemesterData.years[currentYearsIndex].value,
      semester: scoreSemesterData.semesters[currentSemesterIndex].value,
      callback: GeneralCallback(
        onFailure: _onFailure,
        onError: _onError,
        onSuccess: (ScoreData data) {
          scoreData = data;
          if (mounted && this.scoreData != null) {
            setState(() {
              if (scoreData.scores == null || scoreData.scores.length == 0) {
                state = ScoreState.empty;
              } else {
                state = ScoreState.finish;
              }
            });
          }
        },
      ),
    );
  }
}
