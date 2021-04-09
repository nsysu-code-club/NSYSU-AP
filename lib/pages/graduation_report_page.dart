import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/graduation_helper.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:ap_common/widgets/default_dialog.dart';
import 'package:ap_common/widgets/hint_content.dart';

enum _State { loading, finish, error, empty, offlineEmpty }

class GraduationReportPage extends StatefulWidget {
  static const String routerName = "/graduationReport";

  const GraduationReportPage({Key key}) : super(key: key);

  @override
  GraduationReportPageState createState() => GraduationReportPageState();
}

class GraduationReportPageState extends State<GraduationReportPage>
    with SingleTickerProviderStateMixin {
  AppLocalizations app;
  ApLocalizations ap;

  _State state = _State.loading;
  bool isOffline = false;

  List<TableRow> scoreWeightList = [];

  GraduationReportData graduationReportData;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance.setCurrentScreen(
        "GraduationReportPage", "graduation_report_page.dart");
    if (GraduationHelper.instance.isLogin)
      _getGraduationReport();
    else
      _login();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.graduationCheckChecklist),
        backgroundColor: ApTheme.of(context).blue,
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
                      ap.offlineScore,
                      style: TextStyle(color: ApTheme.of(context).grey),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _getGraduationReport();
                  FirebaseAnalyticsUtils.instance.logAction('refresh', 'swipe');
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
        return InkWell(
          onTap: () {
            _getGraduationReport();
            FirebaseAnalyticsUtils.instance.logAction('retry', 'click');
          },
          child: HintContent(
            icon: Icons.assignment,
            content: state == _State.error
                ? ap.clickToRetry
                : app.graduationCheckChecklistEmpty,
          ),
        );
      case _State.offlineEmpty:
        return HintContent(
          icon: Icons.class_,
          content: ap.noOfflineData,
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ApTheme.of(context).greyText, fontSize: 16.0),
                ),
                SizedBox(height: 8.0),
                Text(
                  app.missingRequiredCourses,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                graduationReportData.missingRequiredCourse.length == 0
                    ? Text(
                        ap.noData,
                        style: TextStyle(
                            color: ApTheme.of(context).grey, fontSize: 14.0),
                      )
                    : BorderContainer(
                        child: Table(
                          columnWidths: const <int, TableColumnWidth>{
                            0: FlexColumnWidth(2.5),
                            1: FlexColumnWidth(1.0),
                            2: FlexColumnWidth(1.0),
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          border: TableBorder.symmetric(
                            inside: BorderSide(
                              color: ApTheme.of(context).grey,
                              width: 0.5,
                            ),
                          ),
                          children: [
                            TableRow(
                              children: <Widget>[
                                _scoreTextBorder(ap.subject, true),
                                _scoreTextBorder(ap.credits, true),
                                _scoreTextBorder(ap.description, true),
                              ],
                            ),
                            for (var missingRequiredCourse
                                in graduationReportData.missingRequiredCourse)
                              TableRow(children: <Widget>[
                                _scoreTextBorder(
                                    missingRequiredCourse.name, false),
                                _scoreTextBorder(
                                    missingRequiredCourse.credit, false),
                                _scoreTextBorder(
                                    missingRequiredCourse.description, false),
                              ]),
                          ],
                        ),
                      ),
                Text(
                  graduationReportData.missingRequiredCoursesCredit,
                  style: _textBlueStyle(),
                ),
                Divider(color: ApTheme.of(context).grey),
                Text(
                  app.generalEducationCourse,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                Text(
                  graduationReportData.generalEducationCourse.length != 0
                      ? app.courseClickHint
                      : ap.noData,
                  style: TextStyle(
                      color: ApTheme.of(context).grey, fontSize: 14.0),
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
                          color: ApTheme.of(context).grey,
                          width: 0.5,
                        ),
                      ),
                      children: [
                        TableRow(
                          children: <Widget>[
                            _scoreTextBorder(ap.subject, true),
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
                graduationReportData.generalEducationCourse.length != 0
                    ? Text(
                        graduationReportData.generalEducationCourseDescription,
                        style: _textBlueStyle(),
                      )
                    : SizedBox(),
                Divider(color: ApTheme.of(context).grey),
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
                        color: ApTheme.of(context).grey,
                        width: 0.5,
                      ),
                    ),
                    children: [
                      TableRow(
                        children: <Widget>[
                          _scoreTextBorder(ap.subject, true),
                          _scoreTextBorder(ap.semester, true),
                          _scoreTextBorder(ap.credits, true),
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
                Text(
                  graduationReportData.otherEducationsCourseCredit,
                  style: _textBlueStyle(),
                ),
                Divider(color: ApTheme.of(context).grey),
                Text(
                  app.graduationCheckChecklistSummary,
                  style: TextStyle(fontSize: 16.0),
                ),
                SizedBox(height: 4),
                Text(
                  graduationReportData.totalDescription ?? '',
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
    }
  }

  _textBlueStyle() {
    return TextStyle(color: ApTheme.of(context).blueText, fontSize: 16.0);
  }

  _textStyle() {
    return TextStyle(fontSize: 14.0);
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

  Function get _onFailure => (DioError e) => setState(() {
        state = _State.error;
        switch (e.type) {
          case DioErrorType.connectTimeout:
          case DioErrorType.sendTimeout:
          case DioErrorType.receiveTimeout:
          case DioErrorType.response:
          case DioErrorType.cancel:
            break;
          case DioErrorType.other:
            throw e;
            break;
        }
      });

  Function get _onError => (_) => setState(() => state = _State.error);

  void _login() {
    GraduationHelper.instance.login(
      username: SelcrsHelper.instance.username,
      password: SelcrsHelper.instance.password,
      callback: GeneralCallback(
        onError: _onError,
        onFailure: _onFailure,
        onSuccess: (GeneralResponse data) {
          _getGraduationReport();
        },
      ),
    );
  }

  void _getGraduationReport() {
    GraduationHelper.instance.getGraduationReport(
      username: SelcrsHelper.instance.username,
      callback: GeneralCallback(
        onError: _onError,
        onFailure: _onFailure,
        onSuccess: (GraduationReportData data) {
          graduationReportData = data;
          setState(() {
            if (graduationReportData == null)
              state = _State.empty;
            else
              state = _State.finish;
          });
        },
      ),
    );
  }

  void _showGeneralEducationCourseDetail(GeneralEducationItem course) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DefaultDialog(
        title: ap.courseDialogTitle,
        actionText: ap.iKnow,
        actionFunction: () =>
            Navigator.of(context, rootNavigator: true).pop('dialog'),
        contentWidget: RichText(
          text: TextSpan(
              style: TextStyle(
                  color: ApTheme.of(context).grey, height: 1.3, fontSize: 16.0),
              children: [
                TextSpan(
                    text: '${ap.subject}：',
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
        border: Border.all(color: ApTheme.of(context).grey, width: 1.5),
      ),
      child: child,
    );
  }
}
