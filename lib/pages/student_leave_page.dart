import 'dart:typed_data';

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
  String? _deletingRecordNumber;
  String? _openingProofUrl;

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
                final StudentLeaveRecord record = records[index - 1];
                return _LeaveRecordCard(
                  record: record,
                  isDeleting: _deletingRecordNumber == record.number,
                  isOpeningProof: _openingProofUrl == record.proofUrl,
                  onOpenProof: record.proofUrl == null
                      ? null
                      : () => _openProof(record),
                  onDelete: record.canDelete
                      ? () => _deleteRecord(record)
                      : null,
                );
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

  Future<void> _deleteRecord(StudentLeaveRecord record) async {
    if (_deletingRecordNumber != null) return;
    setState(() => _deletingRecordNumber = record.number);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(app.studentLeaveDeleteConfirmTitle),
        content: Text(app.studentLeaveDeleteConfirmContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(app.optionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(app.optionComfirm),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _deletingRecordNumber = null);
      return;
    }

    final ApiResult<StudentLeaveDeleteResult> result = await StudentLeaveHelper
        .instance
        .checkAndDeleteLeave(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
          leaveNumber: record.number,
        );
    if (!mounted) return;
    setState(() => _deletingRecordNumber = null);
    switch (result) {
      case ApiSuccess<StudentLeaveDeleteResult>(
        :final StudentLeaveDeleteResult data,
      ):
        if (data.looksSuccessful == false) {
          _showDeleteFailure();
          return;
        }
        if (data.looksSuccessful == true) {
          UiUtil.instance.showToast(context, app.studentLeaveDeleteSuccess);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(app.studentLeaveDeleteUnknownResult),
                duration: const Duration(seconds: 5),
              ),
            );
        }
        await _getRecords();
      case ApiError<StudentLeaveDeleteResult>():
        _showDeleteFailure();
      case ApiFailure<StudentLeaveDeleteResult>(:final DioException exception):
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? app.studentLeaveDeleteFailed,
        );
    }
  }

  Future<void> _openProof(StudentLeaveRecord record) async {
    final String? proofUrl = record.proofUrl;
    if (proofUrl == null || _openingProofUrl != null) return;
    setState(() => _openingProofUrl = proofUrl);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          PopScope(canPop: false, child: ProgressDialog(ap.loading)),
      barrierDismissible: false,
    );
    final ApiResult<Uint8List> result = await StudentLeaveHelper.instance
        .downloadProof(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
          proofUrl: proofUrl,
        );
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _openingProofUrl = null);
    switch (result) {
      case ApiSuccess<Uint8List>(:final Uint8List data):
        ApUtils.pushCupertinoStyle(
          context,
          PdfView(state: PdfState.finish, data: data),
        );
      case ApiFailure<Uint8List>(:final DioException exception):
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? ap.somethingError,
        );
      case ApiError<Uint8List>():
        UiUtil.instance.showToast(context, ap.somethingError);
    }
  }

  void _showDeleteFailure() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(app.studentLeaveDeleteFailedTitle),
        content: Text(app.studentLeaveDeleteFailed),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(app.optionComfirm),
          ),
        ],
      ),
    );
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
  const StudentLeaveAddPage({super.key, this.initialConstraints});

  final StudentLeaveFormConstraints? initialConstraints;

  @override
  State<StudentLeaveAddPage> createState() => _StudentLeaveAddPageState();
}

class _StudentLeaveAddPageState extends State<StudentLeaveAddPage> {
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  StudentLeaveType _type = StudentLeaveType.values[1];
  DateTime _startDateTime = _initialStartDateTime();
  DateTime _endDateTime = _initialEndDateTime();
  PlatformFile? _attachmentFile;
  StudentLeaveFormConstraints? _constraints;
  bool _isLoadingConstraints = true;

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen(
      'StudentLeaveAddPage',
      'student_leave_page.dart',
    );
    final StudentLeaveFormConstraints? initialConstraints =
        widget.initialConstraints;
    if (initialConstraints != null) {
      _applyConstraints(initialConstraints);
      _isLoadingConstraints = false;
    } else {
      _loadConstraints();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StudentLeaveFormConstraints? constraints = _constraints;
    if (constraints == null) {
      return Scaffold(
        appBar: AppBar(title: Text(app.studentLeaveAdd)),
        body: _isLoadingConstraints
            ? const Center(child: CircularProgressIndicator())
            : InkWell(
                onTap: _loadConstraints,
                child: HintContent(
                  icon: Icons.assignment_late_outlined,
                  content: ap.clickToRetry,
                ),
              ),
      );
    }
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
                    items: constraints.leaveTypes
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
                    maxLength: constraints.maxReasonLength,
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
                    hint: _attachmentHint(constraints),
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

  Future<void> _loadConstraints() async {
    if (mounted) {
      setState(() {
        _isLoadingConstraints = true;
        _constraints = null;
      });
    }
    final ApiResult<StudentLeaveFormConstraints> result =
        await StudentLeaveHelper.instance.getLeaveFormConstraints(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
        );
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<StudentLeaveFormConstraints>(
        :final StudentLeaveFormConstraints data,
      ):
        setState(() {
          _applyConstraints(data);
          _isLoadingConstraints = false;
        });
      case ApiError<StudentLeaveFormConstraints>(
        :final GeneralResponse response,
      ):
        setState(() => _isLoadingConstraints = false);
        _showStudentLeaveApiError(context, response);
      case ApiFailure<StudentLeaveFormConstraints>(
        :final DioException exception,
      ):
        setState(() => _isLoadingConstraints = false);
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? ap.somethingError,
        );
    }
  }

  void _applyConstraints(StudentLeaveFormConstraints constraints) {
    _constraints = constraints;
    _type = constraints.leaveTypes.firstWhere(
      (StudentLeaveType type) => type.code == '12',
      orElse: () => constraints.leaveTypes.first,
    );

    final DateTime today = _dateOnly(DateTime.now());
    DateTime initialDate = today.isBefore(constraints.firstStartDate)
        ? constraints.firstStartDate
        : today.isAfter(constraints.lastStartDate)
        ? constraints.lastStartDate
        : today;
    List<String> validStartTimes = _availableStartTimesForDate(
      constraints,
      initialDate,
    );
    while (validStartTimes.isEmpty &&
        initialDate.isAfter(_dateOnly(constraints.firstStartDate))) {
      initialDate = initialDate.subtract(const Duration(days: 1));
      validStartTimes = _availableStartTimesForDate(constraints, initialDate);
    }
    final String startTime = validStartTimes.contains('09:00')
        ? '09:00'
        : validStartTimes.first;
    _startDateTime = _withTime(initialDate, startTime);
    _endDateTime =
        _nextEndDateTime(constraints, _startDateTime) ?? _startDateTime;
    _attachmentFile = null;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final StudentLeaveFormConstraints? constraints = _constraints;
    if (constraints == null) return;
    final DateTime current = isStart ? _startDateTime : _endDateTime;
    final DateTime firstDate = isStart
        ? constraints.firstStartDate
        : _startDateTime.isAfter(constraints.firstEndDate)
        ? _dateOnly(_startDateTime)
        : constraints.firstEndDate;
    final DateTime lastDate = isStart
        ? constraints.lastStartDate
        : constraints.lastEndDate;
    final DateTime currentDate = _dateOnly(current);
    final DateTime initialDate = currentDate.isBefore(firstDate)
        ? firstDate
        : currentDate.isAfter(lastDate)
        ? lastDate
        : currentDate;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final List<String> availableTimes = isStart
        ? _availableStartTimesForDate(constraints, date)
        : constraints.endTimes.where((String value) {
            final DateTime candidate = _withTime(date, value);
            return candidate.isAfter(_startDateTime);
          }).toList();
    if (availableTimes.isEmpty) {
      UiUtil.instance.showToast(context, app.studentLeaveTimeInvalid);
      return;
    }
    final String? time = await _pickTimeOption(
      options: availableTimes,
      selected: _formatTimeValue(current),
      title: isStart ? app.studentLeaveStart : app.studentLeaveEnd,
    );
    if (time == null || !mounted) return;
    final DateTime value = _withTime(date, time);
    setState(() {
      if (isStart) {
        _startDateTime = value;
        if (!_endDateTime.isAfter(_startDateTime)) {
          _endDateTime =
              _nextEndDateTime(constraints, _startDateTime) ?? _startDateTime;
        }
      } else {
        _endDateTime = value;
      }
    });
  }

  Future<String?> _pickTimeOption({
    required List<String> options,
    required String selected,
    required String title,
  }) {
    final double listHeight = options.length > 7
        ? 336.0
        : options.length * 48.0;
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320.0,
          height: listHeight,
          child: ListView.builder(
            itemExtent: 48.0,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final String option = options[index];
              return ListTile(
                title: Text(option),
                trailing: option == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(dialogContext).pop(option),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(app.optionCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final StudentLeaveFormConstraints? constraints = _constraints;
    if (constraints == null) return;
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: constraints.allowedAttachmentExtensions,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    if (file.path == null && file.bytes == null) {
      UiUtil.instance.showToast(context, app.studentLeaveAttachmentUnavailable);
      return;
    }
    if (file.size <= 0 || !constraints.allowsAttachmentFileName(file.name)) {
      UiUtil.instance.showToast(context, app.studentLeaveAttachmentUnavailable);
      return;
    }
    if (file.size > constraints.maxAttachmentBytes) {
      UiUtil.instance.showToast(
        context,
        app.studentLeaveAttachmentTooLarge(
          maxSize: _AttachmentTile.formatBytes(constraints.maxAttachmentBytes),
        ),
      );
      return;
    }
    setState(() => _attachmentFile = file);
  }

  Future<void> _submit() async {
    final StudentLeaveFormConstraints? constraints = _constraints;
    if (constraints == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_endDateTime.isAfter(_startDateTime)) {
      UiUtil.instance.showToast(context, app.studentLeaveTimeInvalid);
      return;
    }
    final StudentLeaveRequest request = StudentLeaveRequest(
      type: _type,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      reason: _reasonController.text.trim(),
      attachment: _attachment(),
    );
    final StudentLeaveRequestIssue? issue = constraints.validate(
      request,
      attachmentSizeBytes: _attachmentFile?.size,
    );
    if (issue != null) {
      _showConstraintIssue(issue, constraints);
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
          request: request,
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

  void _showConstraintIssue(
    StudentLeaveRequestIssue issue,
    StudentLeaveFormConstraints constraints,
  ) {
    final String message = switch (issue) {
      StudentLeaveRequestIssue.invalidDateRange ||
      StudentLeaveRequestIssue.invalidTime => app.studentLeaveTimeInvalid,
      StudentLeaveRequestIssue.attachmentTooLarge =>
        app.studentLeaveAttachmentTooLarge(
          maxSize: _AttachmentTile.formatBytes(constraints.maxAttachmentBytes),
        ),
      StudentLeaveRequestIssue.invalidAttachment ||
      StudentLeaveRequestIssue.emptyAttachment =>
        app.studentLeaveAttachmentUnavailable,
      StudentLeaveRequestIssue.invalidLeaveClass ||
      StudentLeaveRequestIssue.invalidLeaveType ||
      StudentLeaveRequestIssue.emptyReason ||
      StudentLeaveRequestIssue.reasonTooLong => ap.somethingError,
    };
    UiUtil.instance.showToast(context, message);
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

  String _attachmentHint(StudentLeaveFormConstraints constraints) {
    final String extensions = constraints.allowedAttachmentExtensions
        .map((String value) => value.toUpperCase())
        .join(', ');
    final String size = _AttachmentTile.formatBytes(
      constraints.maxAttachmentBytes,
    );
    return '${app.studentLeaveAttachmentHint} ($extensions, $size)';
  }

  static DateTime _initialStartDateTime() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 9);
  }

  static DateTime _initialEndDateTime() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 12);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _withTime(DateTime date, String time) {
    final List<String> parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static String _formatTimeValue(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static List<String> _availableStartTimesForDate(
    StudentLeaveFormConstraints constraints,
    DateTime date,
  ) => constraints.startTimes
      .where(
        (String value) =>
            _nextEndDateTime(constraints, _withTime(date, value)) != null,
      )
      .toList();

  static DateTime? _nextEndDateTime(
    StudentLeaveFormConstraints constraints,
    DateTime start,
  ) {
    final DateTime startDate = _dateOnly(start);
    final DateTime firstEndDate = _dateOnly(constraints.firstEndDate);
    final DateTime candidateDate = startDate.isBefore(firstEndDate)
        ? firstEndDate
        : startDate;
    if (candidateDate.isAfter(_dateOnly(constraints.lastEndDate))) return null;
    for (final String time in constraints.endTimes) {
      final DateTime candidate = _withTime(candidateDate, time);
      if (candidate.isAfter(start)) return candidate;
    }

    final DateTime nextDate = candidateDate.add(const Duration(days: 1));
    if (nextDate.isAfter(_dateOnly(constraints.lastEndDate))) return null;
    return _withTime(nextDate, constraints.endTimes.first);
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
  const _LeaveRecordCard({
    required this.record,
    required this.isDeleting,
    required this.isOpeningProof,
    this.onOpenProof,
    this.onDelete,
  });

  final StudentLeaveRecord record;
  final bool isDeleting;
  final bool isOpeningProof;
  final VoidCallback? onOpenProof;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StudentLeaveReviewStatus overallTone =
        resolveStudentLeaveOverallStatus(record);
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
                      onPressed: isOpeningProof ? null : onOpenProof,
                      icon: isOpeningProof
                          ? const SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Icon(Icons.open_in_new, size: 20.0),
                    ),
                ],
              ],
            ),
            if (onDelete != null) ...<Widget>[
              const SizedBox(height: 12.0),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    isDeleting
                        ? app.studentLeaveDeleting
                        : app.studentLeaveDelete,
                  ),
                ),
              ),
            ],
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
    final StudentLeaveReviewStatus tone = resolveStudentLeaveReviewStatus(
      value,
    );
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

  final StudentLeaveReviewStatus tone;

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

_ToneStyle _toneStyle(BuildContext context, StudentLeaveReviewStatus tone) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  return switch (tone) {
    StudentLeaveReviewStatus.approved => _ToneStyle(
      background: colors.primaryContainer,
      foreground: colors.onPrimaryContainer,
      icon: Icons.check_circle_outline,
    ),
    StudentLeaveReviewStatus.pending => _ToneStyle(
      background: colors.tertiaryContainer,
      foreground: colors.onTertiaryContainer,
      icon: Icons.schedule,
    ),
    StudentLeaveReviewStatus.rejected => _ToneStyle(
      background: colors.errorContainer,
      foreground: colors.onErrorContainer,
      icon: Icons.error_outline,
    ),
    StudentLeaveReviewStatus.noReview => _ToneStyle(
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurfaceVariant,
      icon: Icons.remove_circle_outline,
    ),
    StudentLeaveReviewStatus.unknown => _ToneStyle(
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurfaceVariant,
      icon: Icons.help_outline,
    ),
  };
}

String _statusLabel(StudentLeaveReviewStatus tone) => switch (tone) {
  StudentLeaveReviewStatus.approved => app.studentLeaveStatusApproved,
  StudentLeaveReviewStatus.pending => app.studentLeaveStatusPending,
  StudentLeaveReviewStatus.rejected => app.studentLeaveStatusRejected,
  StudentLeaveReviewStatus.noReview => app.studentLeaveStatusNoReview,
  StudentLeaveReviewStatus.unknown => app.studentLeaveStatusUnknown,
};

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.file,
    required this.hint,
    required this.onPick,
    required this.onRemove,
  });

  final PlatformFile? file;
  final String hint;
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
                      file == null ? hint : formatBytes(file.size),
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

  static String formatBytes(int bytes) {
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
  bool _confirmAttempted = false;

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
            _ConfirmationSubmitBar(
              onConfirm: _confirmAttempted ? null : () => _confirm(confirmForm),
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(StudentLeaveConfirmForm confirmForm) async {
    if (_confirmAttempted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(app.studentLeaveSubmitConfirmTitle),
        content: Text(app.studentLeaveSubmitConfirmContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(app.optionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(app.optionComfirm),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _confirmAttempted = true);
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
          exception.i18nMessage ?? app.studentLeaveSubmitFailed,
        );
    }
  }
}

void _showStudentLeaveApiError(BuildContext context, GeneralResponse response) {
  final String message = switch (response.statusCode) {
    401 => app.studentLeaveLoginFailed,
    400 || 408 || 409 || 422 || 503 => ap.somethingError,
    _ => ap.somethingError,
  };
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

  final VoidCallback? onConfirm;

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
    '檢視': 'View',
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
