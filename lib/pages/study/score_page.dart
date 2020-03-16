import 'package:ap_common/widgets/item_picker.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/scaffold/score_scaffold.dart';

class ScorePage extends StatefulWidget {
  static const String routerName = "/score";

  @override
  ScorePageState createState() => ScorePageState();
}

class ScorePageState extends State<ScorePage> {
  AppLocalizations app;

  ScoreState state = ScoreState.loading;
  bool isOffline = false;

  ScoreSemesterData scoreSemesterData;
  ScoreData scoreData;

  List<String> years;
  List<String> semesters;

  var currentYearsIndex = 0;
  var currentSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("ScorePage", "score_page.dart");
    _getSemester();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return ScoreScaffold(
      state: state,
      scoreData: scoreData,
      isOffline: isOffline,
      middleTitle: app.credits,
      isShowConductScore: false,
      isShowCredit: true,
      itemPicker: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ItemPicker(
            width: MediaQuery.of(context).size.width * 0.45,
            dialogTitle: app.picksSemester,
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
            dialogTitle: app.picksSemester,
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
    );
  }

  void _getSemester() async {
    try {
      scoreSemesterData = await Helper.instance.getScoreSemesterData();
    } catch (e) {
      setState(() {
        state = ScoreState.error;
      });
    } finally {
      if (scoreSemesterData.years.length != 0 &&
          scoreSemesterData.semesters.length != 0) {
        years = [];
        semesters = [];
        scoreSemesterData.years.forEach((option) {
          years.add(option.text);
        });
        scoreSemesterData.semesters.forEach((option) {
          semesters.add(option.text);
        });
        _getSemesterScore();
      } else {
        setState(() {
          state = ScoreState.error;
        });
      }
    }
  }

  void _getSemesterScore() async {
    setState(() {
      state = ScoreState.loading;
    });
    Helper.instance
        .getScoreData(
      year: scoreSemesterData.years[currentYearsIndex].value,
      semester: scoreSemesterData.semesters[currentSemesterIndex].value,
    )
        .then((scoreData) {
      this.scoreData = scoreData;
      if (mounted) {
        setState(() {
          if (scoreData.scores.length == 0) {
            state = ScoreState.empty;
          } else {
            state = ScoreState.finish;
          }
        });
      }
    });
  }
}
