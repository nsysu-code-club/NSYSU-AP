import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/default_dialog.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/api/graduation_helper.dart';
import 'package:nsysu_ap/api/selcrs_helper.dart';
import 'package:nsysu_ap/models/graduation_report_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

enum _State { loading, finish, error, empty, offlineEmpty }

class GraduationReportPage extends StatefulWidget {
  static const String routerName = '/graduationReport';

  const GraduationReportPage({Key? key}) : super(key: key);

  @override
  GraduationReportPageState createState() => GraduationReportPageState();
}

class GraduationReportPageState extends State<GraduationReportPage>
    with SingleTickerProviderStateMixin {
  late AppLocalizations app;
  late ApLocalizations ap;

  _State state = _State.loading;
  bool isOffline = false;

  List<TableRow> scoreWeightList = <TableRow>[];

  GraduationReportData? graduationReportData;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance.setCurrentScreen(
      'GraduationReportPage',
      'graduation_report_page.dart',
    );
    if (GraduationHelper.instance.isLogin) {
      _getGraduationReport();
    } else {
      _login();
    }
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
      body: Flex(
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
                FirebaseAnalyticsUtils.instance
                    .logEvent('graduation_report_refresh');
                return;
              },
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (state) {
      case _State.loading:
        return Container(
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      case _State.error:
      case _State.empty:
        return InkWell(
          onTap: () {
            _getGraduationReport();
            FirebaseAnalyticsUtils.instance.logEvent('click_retry');
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              children: <Widget>[
                Text(
                  app.graduationCheckChecklistHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ApTheme.of(context).greyText,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  app.missingRequiredCourses,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                if (graduationReportData!.missingRequiredCourse.isEmpty)
                  Text(
                    ap.noData,
                    style: TextStyle(
                      color: ApTheme.of(context).grey,
                      fontSize: 14.0,
                    ),
                  )
                else
                  BorderContainer(
                    child: Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.symmetric(
                        inside: BorderSide(
                          color: ApTheme.of(context).grey,
                          width: 0.5,
                        ),
                      ),
                      children: <TableRow>[
                        TableRow(
                          children: <Widget>[
                            _scoreTextBorder(ap.subject, true),
                            _scoreTextBorder(ap.credits, true),
                            _scoreTextBorder(ap.description, true),
                          ],
                        ),
                        for (final MissingRequiredCourse missingRequiredCourse
                            in graduationReportData!.missingRequiredCourse)
                          TableRow(
                            children: <Widget>[
                              _scoreTextBorder(
                                missingRequiredCourse.name,
                                false,
                              ),
                              _scoreTextBorder(
                                missingRequiredCourse.credit,
                                false,
                              ),
                              _scoreTextBorder(
                                missingRequiredCourse.description,
                                false,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                Text(
                  graduationReportData!.missingRequiredCoursesCredit,
                  style: _textBlueStyle(),
                ),
                Divider(color: ApTheme.of(context).grey),
                Text(
                  app.generalEducationCourse,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                Text(
                  graduationReportData!.generalEducationCourse.isNotEmpty
                      ? app.courseClickHint
                      : ap.noData,
                  style: TextStyle(
                    color: ApTheme.of(context).grey,
                    fontSize: 14.0,
                  ),
                ),
                for (final GeneralEducationCourse generalEducationCourse
                    in graduationReportData!
                        .generalEducationCourse) ...<Widget>[
                  Text(
                    generalEducationCourse.type ?? '',
                    textAlign: TextAlign.start,
                    style: _textBlueStyle(),
                  ),
                  BorderContainer(
                    child: Table(
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder.symmetric(
                        inside: BorderSide(
                          color: ApTheme.of(context).grey,
                          width: 0.5,
                        ),
                      ),
                      children: <TableRow>[
                        TableRow(
                          children: <Widget>[
                            _scoreTextBorder(ap.subject, true),
                            _scoreTextBorder(app.check, true),
                          ],
                        ),
                        for (final GeneralEducationItem item
                            in generalEducationCourse.generalEducationItem!)
                          TableRow(
                            children: <Widget>[
                              InkWell(
                                child: _scoreTextBorder(item.name, false),
                                onTap: () {
                                  _showGeneralEducationCourseDetail(item);
                                },
                              ),
                              _scoreTextBorder(item.check, false),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                if (graduationReportData!.generalEducationCourse.isNotEmpty)
                  Text(
                    graduationReportData!.generalEducationCourseDescription,
                    style: _textBlueStyle(),
                  )
                else
                  const SizedBox(),
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
                      1: FlexColumnWidth(),
                      2: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: ApTheme.of(context).grey,
                        width: 0.5,
                      ),
                    ),
                    children: <TableRow>[
                      TableRow(
                        children: <Widget>[
                          _scoreTextBorder(ap.subject, true),
                          _scoreTextBorder(ap.semester, true),
                          _scoreTextBorder(ap.credits, true),
                        ],
                      ),
                      for (final OtherEducationsCourse course
                          in graduationReportData!.otherEducationsCourse)
                        TableRow(
                          children: <Widget>[
                            _scoreTextBorder(course.name, false),
                            _scoreTextBorder(course.semester, false),
                            _scoreTextBorder(course.credit, false),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  graduationReportData!.otherEducationsCourseCredit,
                  style: _textBlueStyle(),
                ),
                Divider(color: ApTheme.of(context).grey),
                Text(
                  app.graduationCheckChecklistSummary,
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 4),
                Text(
                  graduationReportData!.totalDescription,
                  textAlign: TextAlign.start,
                  style: _textBlueStyle(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
    }
  }

  TextStyle _textBlueStyle() {
    return TextStyle(color: ApTheme.of(context).blueText, fontSize: 16.0);
  }

  TextStyle _textStyle() {
    return const TextStyle(fontSize: 14.0);
  }

  Widget _scoreTextBorder(String? text, bool isTitle) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      alignment: Alignment.center,
      child: Text(
        text ?? '',
        textAlign: TextAlign.center,
        style: isTitle ? _textBlueStyle() : _textStyle(),
      ),
    );
  }

  Function(DioException) get _onFailure => (DioException e) => setState(() {
        state = _State.error;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.connectionError:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.badResponse:
          case DioExceptionType.cancel:
          case DioExceptionType.badCertificate:
            break;
          case DioExceptionType.unknown:
            throw e;
        }
      });

  Function(GeneralResponse) get _onError =>
      (_) => setState(() => state = _State.error);

  void _login() {
    GraduationHelper.instance.login(
      username: SelcrsHelper.instance.username,
      password: SelcrsHelper.instance.password,
      callback: GeneralCallback<GeneralResponse>(
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
      callback: GeneralCallback<GraduationReportData?>(
        onError: _onError,
        onFailure: _onFailure,
        onSuccess: (GraduationReportData? data) {
          graduationReportData = data;
          setState(() {
            if (data == null) {
              state = _State.empty;
            } else {
              state = _State.finish;
            }
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
              color: ApTheme.of(context).grey,
              height: 1.3,
              fontSize: 16.0,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${ap.subject}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${course.name}\n'),
              TextSpan(
                text: '${app.shouldCredits}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${course.credit}\n'),
              TextSpan(
                text: '${app.actualCredits}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${course.actualCredits}\n'),
              TextSpan(
                text: '${app.totalCredits}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${course.totalCredits}\n'),
              TextSpan(
                text: '${app.practiceSituation}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${course.practiceSituation}'),
            ],
          ),
        ),
      ),
    );
  }
}

class BorderContainer extends StatelessWidget {
  final Widget child;

  const BorderContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
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
