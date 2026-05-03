import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';

class GraduationReportPage extends StatefulWidget {
  static const String routerName = '/graduationReport';

  const GraduationReportPage({super.key});

  @override
  GraduationReportPageState createState() => GraduationReportPageState();
}

class GraduationReportPageState extends State<GraduationReportPage>
    with SingleTickerProviderStateMixin {
  DataState<GraduationReportData> state = const DataLoading<GraduationReportData>();
  bool isOffline = false;

  List<TableRow> scoreWeightList = <TableRow>[];

  GraduationReportData? get graduationReportData => state.dataOrNull;

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen(
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

    return Scaffold(
      appBar: AppBar(
        title: Text(app.graduationCheckChecklist),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  )
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _getGraduationReport();
                AnalyticsUtil.instance.logEvent('graduation_report_refresh');
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
    return state.when(
      loading: () => Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (String? hint) => InkWell(
        onTap: () {
          _getGraduationReport();
          AnalyticsUtil.instance.logEvent('click_retry');
        },
        child: HintContent(
          icon: Icons.assignment,
          content: ap.clickToRetry,
        ),
      ),
      empty: (String? hint) => hint == ap.noOfflineData
          ? HintContent(
              icon: Icons.class_,
              content: ap.noOfflineData,
            )
          : InkWell(
              onTap: () {
                _getGraduationReport();
                AnalyticsUtil.instance.logEvent('click_retry');
              },
              child: HintContent(
                icon: Icons.assignment,
                content: app.graduationCheckChecklistEmpty,
              ),
            ),
      loaded: (GraduationReportData data, String? hint) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            children: <Widget>[
              Text(
                app.graduationCheckChecklistHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                app.missingRequiredCourses,
                textAlign: TextAlign.start,
                style: _textBlueStyle(),
              ),
              if (data.missingRequiredCourse.isEmpty)
                Text(
                  ap.noData,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          in data.missingRequiredCourse)
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
                data.missingRequiredCoursesCredit,
                style: _textBlueStyle(),
              ),
              Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
              Text(
                app.generalEducationCourse,
                textAlign: TextAlign.start,
                style: _textBlueStyle(),
              ),
              Text(
                data.generalEducationCourse.isNotEmpty
                    ? app.courseClickHint
                    : ap.noData,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14.0,
                ),
              ),
              for (final GeneralEducationCourse generalEducationCourse
                  in data
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              if (data.generalEducationCourse.isNotEmpty)
                Text(
                  data.generalEducationCourseDescription,
                  style: _textBlueStyle(),
                )
              else
                const SizedBox(),
              Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        in data.otherEducationsCourse)
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
                data.otherEducationsCourseCredit,
                style: _textBlueStyle(),
              ),
              Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
              Text(
                app.graduationCheckChecklistSummary,
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 4),
              Text(
                data.totalDescription,
                textAlign: TextAlign.start,
                style: _textBlueStyle(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _textBlueStyle() {
    return TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16.0);
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

  Future<void> _login() async {
    final ApiResult<GeneralResponse> result =
        await GraduationHelper.instance.login(
      username: SelcrsHelper.instance.username,
      password: SelcrsHelper.instance.password,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<GeneralResponse>():
        _getGraduationReport();
      case ApiFailure<GeneralResponse>():
        setState(() => state = const DataError<GraduationReportData>());
      case ApiError<GeneralResponse>():
        setState(() => state = const DataError<GraduationReportData>());
    }
  }

  Future<void> _getGraduationReport() async {
    final ApiResult<GraduationReportData?> result =
        await GraduationHelper.instance.getGraduationReport(
      username: SelcrsHelper.instance.username,
    );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<GraduationReportData?>(:final GraduationReportData? data):
        setState(() {
          if (data == null) {
            state = const DataEmpty<GraduationReportData>();
          } else {
            state = DataLoaded<GraduationReportData>(data);
          }
        });
      case ApiFailure<GraduationReportData?>():
        setState(() => state = const DataError<GraduationReportData>());
      case ApiError<GraduationReportData?>():
        setState(() => state = const DataError<GraduationReportData>());
    }
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    super.key,
    required this.child,
  });

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
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant, width: 1.5),
      ),
      child: child,
    );
  }
}
