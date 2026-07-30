import 'package:ap_common/ap_common.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/l10n/strings.g.dart' as nsysu_l10n;
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';

class StudentLeavePage extends StatefulWidget {
  static const String routerName = '/studentLeave';

  const StudentLeavePage({super.key});

  @override
  State<StudentLeavePage> createState() => _StudentLeavePageState();
}

class _StudentLeavePageState extends State<StudentLeavePage> {
  DataState<List<StudentLeaveRecord>> state =
      const DataLoading<List<StudentLeaveRecord>>();
  late final List<StudentLeaveSemester> _semesterOptions;
  late StudentLeaveSemester _selectedSemester;
  int _recordsRequestId = 0;

  @override
  void initState() {
    super.initState();
    _semesterOptions = StudentLeaveSemester.recent();
    _selectedSemester = _semesterOptions.first;
    AnalyticsUtil.instance.setCurrentScreen(
      'StudentLeavePage',
      'student_leave_page.dart',
    );
    _getRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(app.studentLeave),
        actions: <Widget>[
          IconButton(
            tooltip: app.studentLeaveRefresh,
            onPressed: _getRecords,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                  child: StudentLeaveSemesterSelector(
                    options: _semesterOptions,
                    selected: _selectedSemester,
                    onSelected: _selectSemester,
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openAddPage,
                  icon: const Icon(Icons.add),
                  label: Text(app.studentLeaveAdd),
                ),
              ),
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
        onTap: _getRecords,
        child: HintContent(icon: Icons.assignment, content: ap.clickToRetry),
      ),
      empty: (String? hint) => InkWell(
        onTap: _getRecords,
        child: HintContent(
          icon: Icons.assignment,
          content: app.studentLeaveEmpty,
        ),
      ),
      loaded: (List<StudentLeaveRecord> records, String? hint) =>
          RefreshIndicator(
            onRefresh: _getRecords,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
              itemCount: records.length + 1,
              separatorBuilder: (_, int index) =>
                  SizedBox(height: index == 0 ? 12.0 : 10.0),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return _RecordListHeader(recordCount: records.length);
                }
                return _LeaveRecordCard(record: records[index - 1]);
              },
            ),
          ),
    );
  }

  Future<void> _openAddPage() async {
    final bool? shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const StudentLeaveAddPage()),
    );
    if (!mounted) return;
    if (shouldRefresh == true) {
      await _getRecords();
    }
  }

  Future<void> _getRecords() async {
    final int requestId = ++_recordsRequestId;
    setState(() => state = const DataLoading<List<StudentLeaveRecord>>());
    final ApiResult<List<StudentLeaveRecord>> result = await StudentLeaveHelper
        .instance
        .getLeaveRecords(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
          semester: _selectedSemester,
        );
    if (!mounted || requestId != _recordsRequestId) return;
    switch (result) {
      case ApiSuccess<List<StudentLeaveRecord>>(
        :final List<StudentLeaveRecord> data,
      ):
        setState(() {
          state = data.isEmpty
              ? const DataEmpty<List<StudentLeaveRecord>>()
              : DataLoaded<List<StudentLeaveRecord>>(data);
        });
      case ApiError<List<StudentLeaveRecord>>():
        setState(() => state = const DataError<List<StudentLeaveRecord>>());
      case ApiFailure<List<StudentLeaveRecord>>(:final DioException exception):
        if (exception.i18nMessage != null) {
          UiUtil.instance.showToast(context, exception.i18nMessage!);
        }
        setState(() => state = const DataError<List<StudentLeaveRecord>>());
    }
  }

  void _selectSemester(StudentLeaveSemester? semester) {
    if (semester == null || semester == _selectedSemester) return;
    setState(() => _selectedSemester = semester);
    _getRecords();
  }
}

@visibleForTesting
class StudentLeaveSemesterSelector extends StatelessWidget {
  const StudentLeaveSemesterSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<StudentLeaveSemester> options;
  final StudentLeaveSemester selected;
  final ValueChanged<StudentLeaveSemester?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<StudentLeaveSemester>(
      key: ValueKey<String>(selected.code),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: app.studentLeaveSelectSemester,
        prefixIcon: const Icon(Icons.school_outlined),
      ),
      items: options
          .map(
            (StudentLeaveSemester option) =>
                DropdownMenuItem<StudentLeaveSemester>(
                  value: option,
                  child: Text(
                    app.studentLeaveYearSemester(
                      year: option.schoolYear,
                      semester: option.semester,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          )
          .toList(),
      onChanged: onSelected,
    );
  }
}

class StudentLeaveAddPage extends StatefulWidget {
  const StudentLeaveAddPage({super.key});

  @override
  State<StudentLeaveAddPage> createState() => _StudentLeaveAddPageState();
}

class _StudentLeaveAddPageState extends State<StudentLeaveAddPage> {
  static const int _maxAttachmentBytes = 10 * 1024 * 1024;

  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  StudentLeaveType _type = StudentLeaveType.values[1];
  DateTime _startDateTime = _initialStartDateTime();
  DateTime _endDateTime = _initialEndDateTime();
  PlatformFile? _attachmentFile;

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen(
      'StudentLeaveAddPage',
      'student_leave_page.dart',
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(app.studentLeaveAdd)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                children: <Widget>[
                  _FormSectionHeader(
                    icon: Icons.description_outlined,
                    title: app.studentLeaveRequestDetails,
                  ),
                  DropdownButtonFormField<StudentLeaveType>(
                    initialValue: _type,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: app.studentLeaveType,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: StudentLeaveType.values
                        .map(
                          (StudentLeaveType type) =>
                              DropdownMenuItem<StudentLeaveType>(
                                value: type,
                                child: Text(
                                  _localizedLeaveType(type),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        )
                        .toList(),
                    onChanged: (StudentLeaveType? value) {
                      if (value == null) return;
                      setState(() => _type = value);
                    },
                  ),
                  const SizedBox(height: 20.0),
                  _FormSectionHeader(
                    icon: Icons.date_range_outlined,
                    title: app.studentLeavePeriod,
                  ),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final bool useRow = constraints.maxWidth >= 560;
                          final Widget startTile = _DateTimeTile(
                            title: app.studentLeaveStart,
                            dateTime: _startDateTime,
                            onTap: () => _pickDateTime(isStart: true),
                          );
                          final Widget endTile = _DateTimeTile(
                            title: app.studentLeaveEnd,
                            dateTime: _endDateTime,
                            onTap: () => _pickDateTime(isStart: false),
                          );
                          if (useRow) {
                            return Row(
                              children: <Widget>[
                                Expanded(child: startTile),
                                const SizedBox(width: 12.0),
                                Expanded(child: endTile),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              startTile,
                              const SizedBox(height: 10.0),
                              endTile,
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 20.0),
                  _FormSectionHeader(
                    icon: Icons.edit_note_outlined,
                    title: app.studentLeaveReason,
                  ),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: app.studentLeaveReasonHint,
                      alignLabelWithHint: true,
                    ),
                    textInputAction: TextInputAction.newline,
                    minLines: 3,
                    maxLines: 5,
                    validator: (String? value) {
                      if ((value ?? '').trim().isEmpty) return ap.doNotEmpty;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  _FormSectionHeader(
                    icon: Icons.attach_file,
                    title: app.studentLeaveAttachment,
                  ),
                  _AttachmentTile(
                    file: _attachmentFile,
                    onPick: _pickAttachment,
                    onRemove: () => setState(() => _attachmentFile = null),
                  ),
                ],
              ),
            ),
          ),
          _SubmitBar(
            duration: _endDateTime.difference(_startDateTime),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime current = isStart ? _startDateTime : _endDateTime;
    final DateTime now = DateTime.now();
    final DateTime computedFirstDate = now.subtract(const Duration(days: 30));
    final DateTime computedLastDate = now.add(const Duration(days: 365));
    final DateTime firstDate = current.isBefore(computedFirstDate)
        ? current
        : computedFirstDate;
    final DateTime lastDate = current.isAfter(computedLastDate)
        ? current
        : computedLastDate;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final DateTime value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startDateTime = value;
        if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 1));
        }
      } else {
        _endDateTime = value;
      }
    });
  }

  Future<void> _pickAttachment() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      withData: false,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    if (file.path == null && file.bytes == null) {
      UiUtil.instance.showToast(context, app.studentLeaveAttachmentUnavailable);
      return;
    }
    if (file.size > _maxAttachmentBytes) {
      UiUtil.instance.showToast(
        context,
        app.studentLeaveAttachmentTooLarge(maxSize: '10 MB'),
      );
      return;
    }
    setState(() => _attachmentFile = file);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_endDateTime.isAfter(_startDateTime)) {
      UiUtil.instance.showToast(context, app.studentLeaveTimeInvalid);
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: ProgressDialog(app.studentLeaveSubmitting),
      ),
      barrierDismissible: false,
    );
    final ApiResult<StudentLeavePreviewResult> result = await StudentLeaveHelper
        .instance
        .previewLeave(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
          request: StudentLeaveRequest(
            type: _type,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            reason: _reasonController.text.trim(),
            attachment: _attachment(),
          ),
        );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    switch (result) {
      case ApiSuccess<StudentLeavePreviewResult>(
        :final StudentLeavePreviewResult data,
      ):
        final bool? submitted = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => StudentLeaveResultPage(previewResult: data),
          ),
        );
        if (!mounted) return;
        if (submitted == true) Navigator.of(context).pop(true);
      case ApiError<StudentLeavePreviewResult>(:final GeneralResponse response):
        _showStudentLeaveApiError(context, response);
      case ApiFailure<StudentLeavePreviewResult>(:final DioException exception):
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? ap.somethingError,
        );
    }
  }

  StudentLeaveAttachment? _attachment() {
    final PlatformFile? file = _attachmentFile;
    if (file == null) return null;
    return StudentLeaveAttachment(
      fileName: file.name,
      filePath: file.path,
      bytes: file.bytes,
    );
  }

  static DateTime _initialStartDateTime() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 9);
  }

  static DateTime _initialEndDateTime() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 12);
  }
}

class _RecordListHeader extends StatelessWidget {
  const _RecordListHeader({required this.recordCount});

  final int recordCount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            app.studentLeaveRecords,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          app.studentLeaveRecordsCount(count: recordCount),
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LeaveRecordCard extends StatelessWidget {
  const _LeaveRecordCard({required this.record});

  final StudentLeaveRecord record;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _LeaveStatusTone overallTone = _overallStatusTone(record);
    final String? proofUrl = record.proofUrl;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _localizedConfirmationText(record.category),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        app.studentLeaveYearSemester(
                          year: record.schoolYear,
                          semester: record.semester,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                _StatusBadge(tone: overallTone),
              ],
            ),
            const SizedBox(height: 16.0),
            _RecordHighlight(
              icon: Icons.calendar_month_outlined,
              label: app.studentLeavePeriod,
              value: record.dateRange,
            ),
            const SizedBox(height: 16.0),
            Divider(height: 1.0, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 14.0),
            Text(
              app.studentLeaveReviewProgress,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            _ReviewStatusRow(
              label: app.studentLeaveTutorStatus,
              value: _localizedConfirmationText(record.tutorStatus),
            ),
            _ReviewStatusRow(
              label: app.studentLeaveChairStatus,
              value: _localizedConfirmationText(record.chairStatus),
            ),
            _ReviewStatusRow(
              label: app.studentLeaveInstructorStatus,
              value: _localizedConfirmationText(record.instructorStatus),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Icon(
                  Icons.tag,
                  size: 16.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    record.number.isEmpty ? '-' : record.number,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (record.proofText.isNotEmpty ||
                    proofUrl != null) ...<Widget>[
                  Icon(
                    Icons.attach_file,
                    size: 16.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      _localizedConfirmationText(record.proofText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (proofUrl != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: app.studentLeaveOpenAttachment,
                      onPressed: () =>
                          PlatformUtil.instance.launchUrl(proofUrl),
                      icon: const Icon(Icons.open_in_new, size: 20.0),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordHighlight extends StatelessWidget {
  const _RecordHighlight({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40.0,
          height: 40.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 21.0, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value.isEmpty ? '-' : value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewStatusRow extends StatelessWidget {
  const _ReviewStatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final _LeaveStatusTone tone = _statusTone(value);
    final _ToneStyle style = _toneStyle(context, tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 28.0,
            height: 28.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, size: 16.0, color: style.foreground),
          ),
          const SizedBox(width: 10.0),
          Expanded(child: Text(label)),
          const SizedBox(width: 12.0),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: style.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.tone});

  final _LeaveStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final _ToneStyle style = _toneStyle(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: 16.0, color: style.foreground),
          const SizedBox(width: 6.0),
          Text(
            _statusLabel(tone),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _LeaveStatusTone { approved, pending, rejected, neutral }

class _ToneStyle {
  const _ToneStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

_LeaveStatusTone _statusTone(String value) {
  final String status = value.toLowerCase().replaceAll(' ', '');
  if (status.contains('退') ||
      status.contains('拒') ||
      status.contains('不通過') ||
      status.contains('失敗') ||
      status.contains('reject') ||
      status.contains('denied')) {
    return _LeaveStatusTone.rejected;
  }
  if (status.contains('未確認') ||
      status.contains('待') ||
      status.contains('pending') ||
      status.contains('unconfirmed')) {
    return _LeaveStatusTone.pending;
  }
  if (status.contains('已確認') ||
      status.contains('通過') ||
      status.contains('核准') ||
      status.contains('完成') ||
      status.contains('approved') ||
      status.contains('confirmed')) {
    return _LeaveStatusTone.approved;
  }
  return _LeaveStatusTone.neutral;
}

_LeaveStatusTone _overallStatusTone(StudentLeaveRecord record) {
  final List<_LeaveStatusTone> tones = <_LeaveStatusTone>[
    _statusTone(record.tutorStatus),
    _statusTone(record.chairStatus),
    _statusTone(record.instructorStatus),
  ];
  if (tones.contains(_LeaveStatusTone.rejected)) {
    return _LeaveStatusTone.rejected;
  }
  if (tones.contains(_LeaveStatusTone.pending)) {
    return _LeaveStatusTone.pending;
  }
  if (tones.contains(_LeaveStatusTone.approved)) {
    return _LeaveStatusTone.approved;
  }
  return _LeaveStatusTone.neutral;
}

_ToneStyle _toneStyle(BuildContext context, _LeaveStatusTone tone) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  return switch (tone) {
    _LeaveStatusTone.approved => _ToneStyle(
      background: colors.primaryContainer,
      foreground: colors.onPrimaryContainer,
      icon: Icons.check_circle_outline,
    ),
    _LeaveStatusTone.pending => _ToneStyle(
      background: colors.tertiaryContainer,
      foreground: colors.onTertiaryContainer,
      icon: Icons.schedule,
    ),
    _LeaveStatusTone.rejected => _ToneStyle(
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
      icon: Icons.error_outline,
    ),
    _LeaveStatusTone.neutral => _ToneStyle(
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurfaceVariant,
      icon: Icons.remove_circle_outline,
    ),
  };
}

String _statusLabel(_LeaveStatusTone tone) => switch (tone) {
  _LeaveStatusTone.approved => app.studentLeaveStatusApproved,
  _LeaveStatusTone.pending => app.studentLeaveStatusPending,
  _LeaveStatusTone.rejected => app.studentLeaveStatusRejected,
  _LeaveStatusTone.neutral => app.studentLeaveStatusNoReview,
};

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final PlatformFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final PlatformFile? file = this.file;
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 44.0,
                height: 44.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  file == null
                      ? Icons.upload_file_outlined
                      : Icons.description_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      file?.name ?? app.studentLeavePickAttachment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      file == null
                          ? app.studentLeaveAttachmentHint
                          : _formatBytes(file.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              if (file == null)
                const Icon(Icons.chevron_right)
              else
                IconButton(
                  tooltip: app.studentLeaveRemoveAttachment,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20.0, color: theme.colorScheme.primary),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.duration, required this.onSubmit});

  final Duration duration;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.schedule,
              size: 20.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                app.studentLeaveDuration(duration: _formatDuration(duration)),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.arrow_forward),
              label: Text(app.studentLeaveSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentLeaveResultPage extends StatefulWidget {
  const StudentLeaveResultPage({
    super.key,
    this.previewResult,
    this.submitResult,
  }) : assert(
         previewResult != null || submitResult != null,
         'Either previewResult or submitResult must be provided.',
       );

  final StudentLeavePreviewResult? previewResult;
  final StudentLeaveSubmitResult? submitResult;

  @override
  State<StudentLeaveResultPage> createState() => _StudentLeaveResultPageState();
}

class _StudentLeaveResultPageState extends State<StudentLeaveResultPage> {
  StudentLeaveConfirmation get confirmation =>
      widget.submitResult?.confirmation ?? widget.previewResult!.confirmation;

  StudentLeaveConfirmForm? get confirmForm =>
      widget.submitResult == null ? widget.previewResult?.confirmForm : null;

  @override
  Widget build(BuildContext context) {
    final StudentLeaveConfirmForm? confirmForm = this.confirmForm;
    return Scaffold(
      appBar: AppBar(title: Text(app.studentLeaveResult)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
              children: <Widget>[
                _ConfirmationHeader(
                  isPreview: confirmForm != null,
                  submitResult: widget.submitResult,
                ),
                if (confirmForm != null) ...<Widget>[
                  const SizedBox(height: 12.0),
                  _StudentLeaveNotice(lines: confirmation.noticeLines),
                ] else if (confirmation.messages.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12.0),
                  _ConfirmationMessages(messages: confirmation.messages),
                ],
                const SizedBox(height: 20.0),
                for (final StudentLeaveConfirmationSection section
                    in confirmation.sections)
                  _ConfirmationSectionCard(section: section),
                if (!confirmation.hasStructuredData)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SelectableText(
                      confirmation.rawText.isEmpty
                          ? ap.noData
                          : confirmation.rawText,
                    ),
                  ),
              ],
            ),
          ),
          if (confirmForm != null)
            _ConfirmationSubmitBar(onConfirm: () => _confirm(confirmForm)),
        ],
      ),
    );
  }

  Future<void> _confirm(StudentLeaveConfirmForm confirmForm) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: ProgressDialog(app.studentLeaveSubmitting),
      ),
      barrierDismissible: false,
    );
    final ApiResult<StudentLeaveSubmitResult> result = await StudentLeaveHelper
        .instance
        .confirmLeave(confirmForm: confirmForm);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    switch (result) {
      case ApiSuccess<StudentLeaveSubmitResult>(
        :final StudentLeaveSubmitResult data,
      ):
        final bool? looksSuccessful = data.looksSuccessful;
        UiUtil.instance.showToast(context, switch (looksSuccessful) {
          true => app.studentLeaveSubmitSuccess,
          false => app.studentLeaveSubmitFailed,
          null => app.studentLeaveSubmitUnknownResult,
        });
        if (looksSuccessful == false) return;
        Navigator.of(context).pop(true);
      case ApiError<StudentLeaveSubmitResult>(:final GeneralResponse response):
        _showStudentLeaveApiError(context, response);
      case ApiFailure<StudentLeaveSubmitResult>(:final DioException exception):
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? ap.somethingError,
        );
    }
  }
}

void _showStudentLeaveApiError(BuildContext context, GeneralResponse response) {
  final String message = response.statusCode == 401
      ? app.studentLeaveLoginFailed
      : response.message.isNotEmpty
      ? response.message
      : ap.somethingError;
  UiUtil.instance.showToast(context, message);
}

class _ConfirmationSectionCard extends StatelessWidget {
  const _ConfirmationSectionCard({required this.section});

  final StudentLeaveConfirmationSection section;

  @override
  Widget build(BuildContext context) {
    final String title = _localizedConfirmationText(section.title);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title.isNotEmpty) ...<Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10.0),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: <Widget>[
                for (final StudentLeaveConfirmationField field
                    in section.fields)
                  _ConfirmationFieldRow(field: field),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  const _ConfirmationHeader({
    required this.isPreview,
    required this.submitResult,
  });

  final bool isPreview;
  final StudentLeaveSubmitResult? submitResult;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool? looksSuccessful = submitResult?.looksSuccessful;
    final Color backgroundColor = isPreview
        ? theme.colorScheme.primaryContainer
        : switch (looksSuccessful) {
            false => theme.colorScheme.errorContainer,
            null => theme.colorScheme.tertiaryContainer,
            true => theme.colorScheme.secondaryContainer,
          };
    final Color foregroundColor = isPreview
        ? theme.colorScheme.onPrimaryContainer
        : switch (looksSuccessful) {
            false => theme.colorScheme.onErrorContainer,
            null => theme.colorScheme.onTertiaryContainer,
            true => theme.colorScheme.onSecondaryContainer,
          };
    final IconData icon = isPreview
        ? Icons.fact_check_outlined
        : switch (looksSuccessful) {
            false => Icons.error_outline,
            null => Icons.help_outline,
            true => Icons.check_circle_outline,
          };
    final String title = isPreview
        ? app.studentLeaveFinalCheck
        : switch (looksSuccessful) {
            false => app.studentLeaveSubmitFailedTitle,
            null => app.studentLeaveSubmitUnknownTitle,
            true => app.studentLeaveSubmitSuccess,
          };
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 28.0, color: foregroundColor),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationMessages extends StatelessWidget {
  const _ConfirmationMessages({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 20.0,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (
                  int index = 0;
                  index < messages.length;
                  index++
                ) ...<Widget>[
                  if (index > 0) const SizedBox(height: 6.0),
                  Text(_localizedConfirmationText(messages[index])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentLeaveNotice extends StatelessWidget {
  const _StudentLeaveNotice({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 2.0,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14.0, 0, 14.0, 14.0),
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            app.studentLeaveNoticeTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          children: <Widget>[
            for (int i = 0; i < lines.length; i++)
              _NoticeLine(text: lines[i], showDivider: i != lines.length - 1),
          ],
        ),
      ),
    );
  }
}

class _NoticeLine extends StatelessWidget {
  const _NoticeLine({required this.text, required this.showDivider});

  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 32.0,
                height: 32.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18.0,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1.0, color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}

class _ConfirmationSubmitBar extends StatelessWidget {
  const _ConfirmationSubmitBar({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
            label: Text(app.studentLeaveFinalSubmit),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationFieldRow extends StatelessWidget {
  const _ConfirmationFieldRow({required this.field});

  final StudentLeaveConfirmationField field;

  @override
  Widget build(BuildContext context) {
    final String label = _localizedConfirmationText(field.label);
    final String value = _localizedConfirmationText(field.value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

String _localizedConfirmationText(String text) {
  final String cleaned = text.trim();
  if (cleaned.isEmpty) return cleaned;
  final bool isEnglish =
      nsysu_l10n.LocaleSettings.currentLocale == nsysu_l10n.AppLocale.en;
  if (cleaned == '空') return isEnglish ? 'Empty' : cleaned;
  if (isEnglish) {
    return _englishConfirmationText(cleaned);
  }
  return _chineseConfirmationText(cleaned);
}

String _englishConfirmationText(String text) {
  const Map<String, String> titleMap = <String, String>{
    '請假期間課程名稱': 'Courses During Leave',
    '證明文件': 'Certified documents',
    '無': 'None',
    '未確認': 'Unconfirmed',
    '不須確認': 'Not required',
  };
  if (titleMap.containsKey(text)) return titleMap[text]!;

  final Iterable<RegExpMatch> matches = RegExp(
    r'\(([^()]*)\)',
  ).allMatches(text);
  if (matches.isNotEmpty) {
    return matches
        .map((RegExpMatch match) => match.group(1)!.trim())
        .where((String value) => value.isNotEmpty)
        .join(' ')
        .trim();
  }
  return text;
}

String _chineseConfirmationText(String text) {
  return text
      .replaceAll(RegExp(r'\([^()]*\)'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.title,
    required this.dateTime,
    required this.onTap,
  });

  final String title;
  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: <Widget>[
              Container(
                width: 42.0,
                height: 42.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 20.0,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      localizations.formatMediumDate(dateTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(dateTime),
                  alwaysUse24HourFormat: true,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final Duration safeDuration = duration.isNegative ? Duration.zero : duration;
  final int hours = safeDuration.inHours;
  final int minutes = safeDuration.inMinutes.remainder(60);
  final bool isEnglish =
      nsysu_l10n.LocaleSettings.currentLocale == nsysu_l10n.AppLocale.en;
  if (hours == 0) return isEnglish ? '${minutes}m' : '$minutes 分鐘';
  if (minutes == 0) return isEnglish ? '${hours}h' : '$hours 小時';
  return isEnglish ? '${hours}h ${minutes}m' : '$hours 小時 $minutes 分鐘';
}

String _localizedLeaveType(StudentLeaveType type) {
  final bool isEnglish =
      nsysu_l10n.LocaleSettings.currentLocale == nsysu_l10n.AppLocale.en;
  if (!isEnglish) return type.name;
  return switch (type.code) {
    '11' => 'Official leave',
    '12' => 'Personal leave',
    '13' => 'Sick leave',
    '14' => 'Bereavement leave',
    '15' => 'Menstrual leave',
    '16' => 'Marriage leave',
    '17' => 'Maternity leave',
    '18' => 'Family care leave',
    '19' => 'Other',
    '20' => 'Mental health leave',
    '21' => 'COVID-19 related',
    '22' => 'Indigenous ceremonial leave',
    _ => type.name,
  };
}
