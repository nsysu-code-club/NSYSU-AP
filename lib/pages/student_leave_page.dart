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

  @override
  void initState() {
    super.initState();
    AnalyticsUtil.instance.setCurrentScreen(
      'StudentLeavePage',
      'student_leave_page.dart',
    );
    _getRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(app.studentLeave)),
      body: Column(
        children: <Widget>[
          Expanded(child: _body()),
          SafeArea(
            minimum: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openAddPage,
                icon: const Icon(Icons.add),
                label: Text(app.studentLeaveAdd),
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
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              itemCount: records.length,
              itemBuilder: (BuildContext context, int index) =>
                  _LeaveRecordCard(record: records[index]),
            ),
          ),
    );
  }

  Future<void> _openAddPage() async {
    final bool? shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const StudentLeaveAddPage()),
    );
    if (shouldRefresh == true) {
      await _getRecords();
    }
  }

  Future<void> _getRecords() async {
    setState(() => state = const DataLoading<List<StudentLeaveRecord>>());
    final ApiResult<List<StudentLeaveRecord>> result = await StudentLeaveHelper
        .instance
        .getLeaveRecords(
          username: SelcrsHelper.instance.username,
          password: SelcrsHelper.instance.password,
        );
    if (!mounted) return;
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
}

class StudentLeaveAddPage extends StatefulWidget {
  const StudentLeaveAddPage({super.key});

  @override
  State<StudentLeaveAddPage> createState() => _StudentLeaveAddPageState();
}

class _StudentLeaveAddPageState extends State<StudentLeaveAddPage> {
  final TextEditingController _reasonController = TextEditingController(
    text: '身體不適',
  );
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            DropdownButtonFormField<StudentLeaveType>(
              initialValue: _type,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: app.studentLeaveType,
              ),
              items: StudentLeaveType.values
                  .map(
                    (StudentLeaveType type) =>
                        DropdownMenuItem<StudentLeaveType>(
                          value: type,
                          child: Text(type.name),
                        ),
                  )
                  .toList(),
              onChanged: (StudentLeaveType? value) {
                if (value == null) return;
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16.0),
            _DateTimeTile(
              title: app.studentLeaveStart,
              dateTime: _startDateTime,
              onTap: () => _pickDateTime(isStart: true),
            ),
            const SizedBox(height: 12.0),
            _DateTimeTile(
              title: app.studentLeaveEnd,
              dateTime: _endDateTime,
              onTap: () => _pickDateTime(isStart: false),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: app.studentLeaveReason,
                hintText: app.studentLeaveReasonHint,
              ),
              minLines: 3,
              maxLines: 5,
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) return ap.doNotEmpty;
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            _AttachmentTile(
              file: _attachmentFile,
              onPick: _pickAttachment,
              onRemove: () => setState(() => _attachmentFile = null),
            ),
            const SizedBox(height: 24.0),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: Text(app.studentLeaveSubmit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime current = isStart ? _startDateTime : _endDateTime;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
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
    final FilePickerResult? result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _attachmentFile = result.files.first);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_endDateTime.isAfter(_startDateTime)) {
      UiUtil.instance.showToast(context, app.studentLeaveTimeInvalid);
      return;
    }
    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(app.studentLeaveSubmitConfirmTitle),
        content: Text(app.studentLeaveSubmitConfirmContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(app.optionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(app.optionComfirm),
          ),
        ],
      ),
    );
    if (shouldSubmit != true || !mounted) return;

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
      case ApiError<StudentLeavePreviewResult>():
        UiUtil.instance.showToast(context, app.studentLeaveLoginFailed);
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

class _LeaveRecordCard extends StatelessWidget {
  const _LeaveRecordCard({required this.record});

  final StudentLeaveRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _localizedConfirmationText(record.category),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              app.studentLeaveYearSemester(
                year: record.schoolYear,
                semester: record.semester,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12.0),
            _RecordRow(label: app.studentLeaveNumber, value: record.number),
            _RecordRow(label: app.studentLeaveStart, value: record.dateRange),
            _RecordRow(
              label: app.studentLeaveTutorStatus,
              value: _localizedConfirmationText(record.tutorStatus),
            ),
            _RecordRow(
              label: app.studentLeaveChairStatus,
              value: _localizedConfirmationText(record.chairStatus),
            ),
            _RecordRow(
              label: app.studentLeaveInstructorStatus,
              value: _localizedConfirmationText(record.instructorStatus),
            ),
            _RecordRow(
              label: app.studentLeaveAttachment,
              value: _localizedConfirmationText(record.proofText),
              url: record.proofUrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.value,
    this.url,
  });

  final String label;
  final String value;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final String? url = this.url;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: url == null
                ? Text(value.isEmpty ? '-' : value)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => PlatformUtil.instance.launchUrl(url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        value.isEmpty ? app.studentLeaveAttachment : value,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

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
    return Card(
      child: ListTile(
        title: Text(app.studentLeaveAttachment),
        subtitle: Text(
          file == null
              ? app.studentLeaveAttachmentHint
              : '${file.name}\n${_formatBytes(file.size)}',
        ),
        isThreeLine: file != null,
        trailing: file == null
            ? TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.attach_file),
                label: Text(app.studentLeavePickAttachment),
              )
            : IconButton(
                tooltip: app.studentLeaveRemoveAttachment,
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
        onTap: onPick,
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

class StudentLeaveResultPage extends StatefulWidget {
  const StudentLeaveResultPage({
    super.key,
    required this.previewResult,
    this.submitResult,
  });

  final StudentLeavePreviewResult? previewResult;
  final StudentLeaveSubmitResult? submitResult;

  @override
  State<StudentLeaveResultPage> createState() => _StudentLeaveResultPageState();
}

class _StudentLeaveResultPageState extends State<StudentLeaveResultPage> {
  StudentLeaveSubmitResult? submitResult;

  StudentLeaveConfirmation get confirmation =>
      submitResult?.confirmation ??
      widget.submitResult?.confirmation ??
      widget.previewResult!.confirmation;

  StudentLeaveConfirmForm? get confirmForm =>
      submitResult == null && widget.submitResult == null
      ? widget.previewResult?.confirmForm
      : null;

  @override
  void initState() {
    super.initState();
    submitResult = widget.submitResult;
  }

  @override
  Widget build(BuildContext context) {
    final StudentLeaveConfirmForm? confirmForm = this.confirmForm;
    return Scaffold(
      appBar: AppBar(title: Text(app.studentLeaveResult)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          if (confirmation.messages.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final String message in confirmation.messages)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _localizedConfirmationText(message),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          for (final StudentLeaveConfirmationSection section
              in confirmation.sections)
            _ConfirmationSectionCard(section: section),
          if (!confirmation.hasStructuredData)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  confirmation.rawText.isEmpty
                      ? ap.noData
                      : confirmation.rawText,
                ),
              ),
            ),
          if (confirmForm != null) ...<Widget>[
            const SizedBox(height: 16.0),
            FilledButton.icon(
              onPressed: () => _confirm(confirmForm),
              icon: const Icon(Icons.check),
              label: Text(app.studentLeaveFinalSubmit),
            ),
          ],
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
        UiUtil.instance.showToast(
          context,
          data.looksSuccessful
              ? app.studentLeaveSubmitSuccess
              : app.studentLeaveSubmitUnknownResult,
        );
        Navigator.of(context).pop(true);
      case ApiError<StudentLeaveSubmitResult>():
        UiUtil.instance.showToast(context, app.studentLeaveLoginFailed);
      case ApiFailure<StudentLeaveSubmitResult>(:final DioException exception):
        UiUtil.instance.showToast(
          context,
          exception.i18nMessage ?? ap.somethingError,
        );
    }
  }
}

class _ConfirmationSectionCard extends StatelessWidget {
  const _ConfirmationSectionCard({required this.section});

  final StudentLeaveConfirmationSection section;

  @override
  Widget build(BuildContext context) {
    final String title = _localizedConfirmationText(section.title);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title.isNotEmpty) ...<Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12.0),
            ],
            for (final StudentLeaveConfirmationField field in section.fields)
              _ConfirmationFieldRow(field: field),
          ],
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
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(_formatDateTime(dateTime)),
        trailing: const Icon(Icons.edit_calendar),
        onTap: onTap,
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }
}
