import 'package:flutter/material.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/res/resource.dart' as Resource;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/utils/helper.dart';
import 'package:nsysu_ap/widgets/default_dialog.dart';
import 'package:nsysu_ap/widgets/hint_content.dart';

enum _State { loading, finish, error, empty, offlineEmpty }

class GraduationReportPageRoute extends MaterialPageRoute {
  GraduationReportPageRoute()
      : super(builder: (BuildContext context) => GraduationReportPage());

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(opacity: animation, child: GraduationReportPage());
  }
}

class GraduationReportPage extends StatefulWidget {
  static const String routerName = "/graduationReport";

  @override
  GraduationReportPageState createState() => GraduationReportPageState();
}

class GraduationReportPageState extends State<GraduationReportPage>
    with SingleTickerProviderStateMixin {
  AppLocalizations app;
  _State state = _State.loading;
  bool isOffline = false;

  List<TableRow> scoreWeightList = [];

  GraduationReportData graduationReportData;

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("GraduationReportPage", "graduation_report_page.dart");
    _getGraduationReport();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.graduationCheckChecklist),
        backgroundColor: Resource.Colors.blue,
      ),
      body: Container(
        child: Flex(
          direction: Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
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
                  _getGraduationReport();
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
            _getGraduationReport();
            FA.logAction('retry', 'click');
          },
          child: HintContent(
            icon: Icons.assignment,
            content: state == _State.error
                ? app.clickToRetry
                : app.graduationCheckChecklistEmpty,
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
                Text(
                  app.graduationCheckChecklistHint,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Resource.Colors.grey, fontSize: 16.0),
                ),
                SizedBox(height: 4.0),
                Text(
                  app.missingRequiredCourses,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                BorderContainer(
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
                      TableRow(
                        children: <Widget>[
                          _scoreTextBorder(app.subject, true),
                          _scoreTextBorder(app.credits, true),
                          _scoreTextBorder(app.description, true),
                        ],
                      ),
                      for (var missingRequiredCourse
                          in graduationReportData.missingRequiredCourse)
                        TableRow(children: <Widget>[
                          _scoreTextBorder(missingRequiredCourse.name, false),
                          _scoreTextBorder(missingRequiredCourse.credit, false),
                          _scoreTextBorder(
                              missingRequiredCourse.description, false),
                        ]),
                    ],
                  ),
                ),
                Text(
                  app.generalEducationCourse,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                Text(
                  app.courseClickHint,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Resource.Colors.grey, fontSize: 14.0),
                ),
                for (var generalEducationCourse
                    in graduationReportData.generalEducationCourse) ...[
                  Text(
                    generalEducationCourse.type ?? "",
                    textAlign: TextAlign.start,
                    style: _textBlueStyle(),
                  ),
                  BorderContainer(
                    child: Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(1.0),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.symmetric(
                        inside: BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                      children: [
                        TableRow(
                          children: <Widget>[
                            _scoreTextBorder(app.subject, true),
                            _scoreTextBorder(app.check, true),
                          ],
                        ),
                        for (var item
                            in generalEducationCourse.generalEducationItem)
                          TableRow(children: <Widget>[
                            InkWell(
                              child: _scoreTextBorder(item.name, false),
                              onTap: () {
                                _showGeneralEducationCourseDetail(item);
                              },
                            ),
                            _scoreTextBorder(item.check, false),
                          ]),
                      ],
                    ),
                  ),
                ],
                Text(
                  app.otherEducationsCourse,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                BorderContainer(
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
                      TableRow(
                        children: <Widget>[
                          _scoreTextBorder(app.subject, true),
                          _scoreTextBorder(app.semester, true),
                          _scoreTextBorder(app.credits, true),
                        ],
                      ),
                      for (var course
                          in graduationReportData.otherEducationsCourse)
                        TableRow(children: <Widget>[
                          _scoreTextBorder(course.name, false),
                          _scoreTextBorder(course.semester, false),
                          _scoreTextBorder(course.credit, false),
                        ]),
                    ],
                  ),
                ),
                SizedBox(height: 20.0),
                Text(
                  graduationReportData.totalDescription ?? '',
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
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

  void _getGraduationReport() async {
    setState(() {
      state = _State.loading;
    });
    Helper.instance.getGraduationReport().then((data) async {
      graduationReportData = data;
      setState(() {
        if (graduationReportData == null)
          state = _State.empty;
        else
          state = _State.finish;
      });
    });
  }

  void _showGeneralEducationCourseDetail(GeneralEducationItem course) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DefaultDialog(
            title: app.courseDialogTitle,
            actionText: app.iKnow,
            actionFunction: () =>
                Navigator.of(context, rootNavigator: true).pop('dialog'),
            contentWidget: RichText(
              text: TextSpan(
                  style: TextStyle(
                      color: Resource.Colors.grey, height: 1.3, fontSize: 16.0),
                  children: [
                    TextSpan(
                        text: '${app.subject}：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${course.name}\n'),
                    TextSpan(
                        text: '${app.shouldCredits}：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${course.credit}\n'),
                    TextSpan(
                        text: '${app.actualCredits}：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${course.actualCredits}\n'),
                    TextSpan(
                        text: '${app.totalCredits}：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${course.totalCredits}\n'),
                    TextSpan(
                        text: '${app.practiceSituation}：',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${course.practiceSituation}'),
                  ]),
            ),
          ),
    );
  }
}

class BorderContainer extends StatelessWidget {
  final Widget child;

  const BorderContainer({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(
            10.0,
          ),
        ),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: child,
    );
  }
}
