import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/score_data.dart';
import 'package:nsysu_ap/models/score_semester_data.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/helper.dart';
import 'package:nsysu_ap/widgets/hint_content.dart';

enum _State { loading, finish, error, empty, offlineEmpty }

class ScorePageRoute extends MaterialPageRoute {
  ScorePageRoute() : super(builder: (BuildContext context) => ScorePage());

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: ScorePage());
  }
}

class ScorePage extends StatefulWidget {
  static const String routerName = "/score";

  @override
  ScorePageState createState() => ScorePageState();
}

class ScorePageState extends State<ScorePage>
    with SingleTickerProviderStateMixin {
  AppLocalizations app;
  _State state = _State.loading;
  bool isOffline = false;

  List<TableRow> scoreWeightList = [];

  ScoreSemesterData scoreSemesterData;
  ScoreData scoreData;

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
    return Scaffold(
      // Appbar
      appBar: AppBar(
        // Title
        title: Text(app.score),
        backgroundColor: Resource.Colors.blue,
      ),
      body: Container(
        child: Flex(
          direction: Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                  onPressed: (scoreSemesterData != null) ? _selectYear : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        scoreSemesterData == null
                            ? ''
                            : scoreSemesterData.year.text,
                        style: TextStyle(
                            color: Resource.Colors.blue, fontSize: 18.0),
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Resource.Colors.blue,
                      )
                    ],
                  ),
                ),
                FlatButton(
                  onPressed:
                      (scoreSemesterData != null) ? _selectSemester : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        scoreSemesterData == null
                            ? ""
                            : scoreSemesterData.semester.text,
                        style: TextStyle(
                            color: Resource.Colors.blue, fontSize: 18.0),
                      ),
                      SizedBox(width: 8.0),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Resource.Colors.blue,
                      )
                    ],
                  ),
                ),
              ],
            ),
            Container(
              child: isOffline
                  ? Text(
                      app.offlineScore,
                      style: TextStyle(color: Resource.Colors.grey),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _getSemesterScore();
                  FA.logAction('refresh', 'swipe');
                  return null;
                },
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (state) {
      case _State.loading:
        return Container(
            child: CircularProgressIndicator(), alignment: Alignment.center);
      case _State.error:
      case _State.empty:
        return FlatButton(
          onPressed: () {
            if (state == _State.error)
              _getSemesterScore();
            else
              _selectSemester();
            FA.logAction('retry', 'click');
          },
          child: HintContent(
            icon: Icons.assignment,
            content: state == _State.error ? app.clickToRetry : app.scoreEmpty,
          ),
        );
      case _State.offlineEmpty:
        return HintContent(
          icon: Icons.class_,
          content: app.noOfflineData,
        );
      default:
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        10.0,
                      ),
                    ),
                    border: Border.all(color: Colors.grey, width: 1.5),
                  ),
                  child: Table(
                    columnWidths: const <int, TableColumnWidth>{
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.0),
                      2: FlexColumnWidth(1.0),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                    children: [
                      _scoreTitle(),
                      for (var score in scoreData.content.scores)
                        _scoreTableRowTitle(score),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        10.0,
                      ),
                    ),
                    border: Border.all(color: Colors.grey, width: 1.5),
                  ),
                  child: Column(
                    children: <Widget>[
                      _textBorder(
                          "${app.creditsTakenEarned}：${scoreData.content.detail.conduct}",
                          true),
                      _textBorder(
                          "${app.average}：${scoreData.content.detail.average}",
                          false),
                      _textBorder(
                          "${app.rank}：${scoreData.content.detail.classRank}",
                          false),
                      _textBorder(
                          "${app.percentage}：${scoreData.content.detail.classPercentage}",
                          false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  _textBlueStyle() {
    return TextStyle(color: Resource.Colors.blue, fontSize: 16.0);
  }

  _textStyle() {
    return TextStyle(color: Colors.black, fontSize: 14.0);
  }

  _scoreTitle() => TableRow(
        children: <Widget>[
          _scoreTextBorder(app.subject, true),
          _scoreTextBorder(app.credits, true),
          _scoreTextBorder(app.finalScore, true),
        ],
      );

  Widget _textBorder(String text, bool isTop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide.none
              : BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Text(
        text ?? "",
        textAlign: TextAlign.center,
        style: _textBlueStyle(),
      ),
    );
  }

  Widget _scoreTextBorder(String text, bool isTitle) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      alignment: Alignment.center,
      child: Text(
        text ?? "",
        textAlign: TextAlign.center,
        style: isTitle ? _textBlueStyle() : _textStyle(),
      ),
    );
  }

  TableRow _scoreTableRowTitle(Score score) {
    return TableRow(children: <Widget>[
      _scoreTextBorder(score.title, false),
      _scoreTextBorder(score.middleScore, false),
      _scoreTextBorder(score.finalScore, false)
    ]);
  }

  void _selectYear() {
    if (scoreSemesterData.years == null) return;
    var semesters = <SimpleDialogOption>[];
    for (var semester in scoreSemesterData.years) {
      semesters.add(_dialogItem(semesters.length, semester.text));
    }
    FA.logAction('pick_yms', 'click');
    showDialog<int>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            title: Text(app.picksSemester),
            children: semesters)).then<void>((int position) {
      if (position != null) {
        if (mounted) {
          setState(() {
            scoreSemesterData.selectYearsIndex = position;
          });
          _getSemesterScore();
        }
      }
    });
  }

  void _selectSemester() {
    if (scoreSemesterData.semesters == null) return;
    var semesters = <SimpleDialogOption>[];
    for (var semester in scoreSemesterData.semesters) {
      semesters.add(_dialogItem(semesters.length, semester.text));
    }
    FA.logAction('pick_yms', 'click');
    showDialog<int>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            title: Text(app.picksSemester),
            children: semesters)).then<void>((int position) {
      if (position != null) {
        if (mounted) {
          setState(() {
            scoreSemesterData.selectSemesterIndex = position;
          });
          _getSemesterScore();
        }
      }
    });
  }

  SimpleDialogOption _dialogItem(int index, String text) {
    return SimpleDialogOption(
      child: Text(text),
      onPressed: () {
        Navigator.pop(context, index);
      },
    );
  }

  _renderScoreDataWidget() {
    scoreWeightList.clear();
    scoreWeightList.add(_scoreTitle());
    for (var score in scoreData.content.scores) {
      scoreWeightList.add(_scoreTableRowTitle(score));
    }
  }

  void _getSemester() async {
    try {
      scoreSemesterData = await Helper.instance.getScoreSemesterData();
    } catch (e) {
      setState(() {
        state = _State.error;
      });
    } finally {
      if (scoreSemesterData.years.length != 0 &&
          scoreSemesterData.semesters.length != 0)
        _getSemesterScore();
      else {
        setState(() {
          state = _State.error;
        });
      }
    }
  }

  void _getSemesterScore() async {
    setState(() {
      state = _State.loading;
    });
    Helper.instance
        .getScoreData(
            scoreSemesterData.year.value, scoreSemesterData.semester.value)
        .then((scoreData) {
      this.scoreData = scoreData;
      if (mounted) {
        setState(() {
          if (scoreData.status == 200) {
            state = _State.finish;
          } else if (scoreData.status == 204) {
            state = _State.empty;
          } else {
            state = _State.error;
          }
        });
      }
    });
  }
}
