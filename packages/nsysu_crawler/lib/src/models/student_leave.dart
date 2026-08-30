import 'dart:typed_data';

import 'package:characters/characters.dart';

class StudentLeaveSemester {
  const StudentLeaveSemester({required this.schoolYear, required this.semester})
    : assert(semester == 1 || semester == 2);

  final int schoolYear;
  final int semester;

  String get code => '$schoolYear$semester';

  StudentLeaveSemester get previous => semester == 2
      ? StudentLeaveSemester(schoolYear: schoolYear, semester: 1)
      : StudentLeaveSemester(schoolYear: schoolYear - 1, semester: 2);

  factory StudentLeaveSemester.current({DateTime? now}) {
    final DateTime date = now ?? DateTime.now();
    final int rocYear = date.year - 1911;
    if (date.month >= 8) {
      return StudentLeaveSemester(schoolYear: rocYear, semester: 1);
    }
    if (date.month == 1) {
      return StudentLeaveSemester(schoolYear: rocYear - 1, semester: 1);
    }
    return StudentLeaveSemester(schoolYear: rocYear - 1, semester: 2);
  }

  static List<StudentLeaveSemester> recent({int count = 8, DateTime? now}) {
    assert(count > 0);
    final List<StudentLeaveSemester> semesters = <StudentLeaveSemester>[];
    StudentLeaveSemester semester = StudentLeaveSemester.current(now: now);
    for (int index = 0; index < count; index++) {
      semesters.add(semester);
      semester = semester.previous;
    }
    return semesters;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentLeaveSemester &&
          schoolYear == other.schoolYear &&
          semester == other.semester;

  @override
  int get hashCode => Object.hash(schoolYear, semester);
}

class StudentLeaveType {
  const StudentLeaveType({required this.code, required this.name});

  final String code;
  final String name;

  static const List<StudentLeaveType> values = <StudentLeaveType>[
    StudentLeaveType(code: '11', name: '公假'),
    StudentLeaveType(code: '12', name: '事假'),
    StudentLeaveType(code: '13', name: '病假'),
    StudentLeaveType(code: '14', name: '喪假'),
    StudentLeaveType(code: '15', name: '生理假'),
    StudentLeaveType(code: '16', name: '婚假'),
    StudentLeaveType(code: '17', name: '產假'),
    StudentLeaveType(code: '18', name: '家庭照顧假'),
    StudentLeaveType(code: '19', name: '其他'),
    StudentLeaveType(code: '20', name: '心理不適'),
    StudentLeaveType(code: '21', name: '新冠肺炎相關'),
    StudentLeaveType(code: '22', name: '原住民族歲時祭儀'),
  ];
}

enum StudentLeaveRequestIssue {
  invalidLeaveClass,
  invalidLeaveType,
  invalidDateRange,
  invalidTime,
  emptyReason,
  reasonTooLong,
  invalidAttachment,
  emptyAttachment,
  attachmentTooLarge,
}

class StudentLeaveFormConstraints {
  StudentLeaveFormConstraints({
    required List<StudentLeaveType> leaveTypes,
    required this.firstStartDate,
    required this.lastStartDate,
    required this.firstEndDate,
    required this.lastEndDate,
    required List<String> startTimes,
    required List<String> endTimes,
    required this.maxReasonLength,
    required List<String> allowedAttachmentExtensions,
    required this.maxAttachmentBytes,
  }) : leaveTypes = List<StudentLeaveType>.unmodifiable(leaveTypes),
       startTimes = List<String>.unmodifiable(startTimes),
       endTimes = List<String>.unmodifiable(endTimes),
       allowedAttachmentExtensions = List<String>.unmodifiable(
         allowedAttachmentExtensions.map(
           (String value) => value.trim().toLowerCase(),
         ),
       ) {
    if (this.leaveTypes.isEmpty) {
      throw ArgumentError.value(leaveTypes, 'leaveTypes', 'must not be empty');
    }
    if (firstStartDate.isAfter(lastStartDate) ||
        firstEndDate.isAfter(lastEndDate) ||
        firstStartDate.isAfter(lastEndDate) ||
        lastStartDate.isAfter(lastEndDate)) {
      throw ArgumentError('Invalid student leave date range');
    }
    if (this.startTimes.isEmpty ||
        this.endTimes.isEmpty ||
        !this.startTimes.every(_isValidTimeValue) ||
        !this.endTimes.every(_isValidTimeValue)) {
      throw ArgumentError('Invalid student leave time options');
    }
    final int earliestStartMinutes = this.startTimes
        .map(_timeMinutes)
        .reduce((int first, int second) => first < second ? first : second);
    final int latestEndMinutes = this.endTimes
        .map(_timeMinutes)
        .reduce((int first, int second) => first > second ? first : second);
    final DateTime earliestStart = _dateOnly(
      firstStartDate,
    ).add(Duration(minutes: earliestStartMinutes));
    final DateTime latestEnd = _dateOnly(
      lastEndDate,
    ).add(Duration(minutes: latestEndMinutes));
    if (!latestEnd.isAfter(earliestStart)) {
      throw ArgumentError('Student leave period has no valid end time');
    }
    if (maxReasonLength <= 0 || maxAttachmentBytes <= 0) {
      throw ArgumentError('Student leave limits must be positive');
    }
    if (this.allowedAttachmentExtensions.isEmpty ||
        this.allowedAttachmentExtensions.any(
          (String value) => !RegExp(r'^[a-z0-9]{1,10}$').hasMatch(value),
        )) {
      throw ArgumentError('Invalid attachment extension allowlist');
    }
  }

  final List<StudentLeaveType> leaveTypes;
  final DateTime firstStartDate;
  final DateTime lastStartDate;
  final DateTime firstEndDate;
  final DateTime lastEndDate;
  final List<String> startTimes;
  final List<String> endTimes;
  final int maxReasonLength;
  final List<String> allowedAttachmentExtensions;
  final int maxAttachmentBytes;

  StudentLeaveRequestIssue? validate(
    StudentLeaveRequest request, {
    int? attachmentSizeBytes,
  }) {
    if (request.leaveClass != '1') {
      return StudentLeaveRequestIssue.invalidLeaveClass;
    }
    if (!leaveTypes.any(
      (StudentLeaveType type) => type.code == request.type.code,
    )) {
      return StudentLeaveRequestIssue.invalidLeaveType;
    }

    final DateTime startDate = _dateOnly(request.startDateTime);
    final DateTime endDate = _dateOnly(request.endDateTime);
    if (startDate.isBefore(_dateOnly(firstStartDate)) ||
        startDate.isAfter(_dateOnly(lastStartDate)) ||
        endDate.isBefore(_dateOnly(firstEndDate)) ||
        endDate.isAfter(_dateOnly(lastEndDate)) ||
        request.endDateTime.isBefore(request.startDateTime) ||
        request.endDateTime.isAtSameMomentAs(request.startDateTime)) {
      return StudentLeaveRequestIssue.invalidDateRange;
    }
    if (!startTimes.contains(_timeValue(request.startDateTime)) ||
        !endTimes.contains(_timeValue(request.endDateTime))) {
      return StudentLeaveRequestIssue.invalidTime;
    }

    final String reason = request.reason.trim();
    if (reason.isEmpty) return StudentLeaveRequestIssue.emptyReason;
    if (reason.characters.length > maxReasonLength) {
      return StudentLeaveRequestIssue.reasonTooLong;
    }

    final StudentLeaveAttachment? attachment = request.attachment;
    if (attachment == null) return null;
    if (!attachment.hasData || !allowsAttachmentFileName(attachment.fileName)) {
      return StudentLeaveRequestIssue.invalidAttachment;
    }
    final int? size = attachmentSizeBytes ?? attachment.bytes?.length;
    if (size != null && size <= 0) {
      return StudentLeaveRequestIssue.emptyAttachment;
    }
    if (size != null && size > maxAttachmentBytes) {
      return StudentLeaveRequestIssue.attachmentTooLarge;
    }
    return null;
  }

  bool allowsAttachmentFileName(String fileName) {
    final String normalizedName = fileName.trim();
    if (normalizedName.isEmpty ||
        normalizedName.contains('/') ||
        normalizedName.contains(r'\')) {
      return false;
    }
    final int extensionSeparator = normalizedName.lastIndexOf('.');
    if (extensionSeparator <= 0 ||
        extensionSeparator == normalizedName.length - 1) {
      return false;
    }
    final String extension = normalizedName
        .substring(extensionSeparator + 1)
        .toLowerCase();
    return allowedAttachmentExtensions.contains(extension);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _timeValue(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static bool _isValidTimeValue(String value) {
    final RegExpMatch? match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  static int _timeMinutes(String value) {
    final List<String> parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class StudentLeaveRecord {
  const StudentLeaveRecord({
    required this.number,
    required this.schoolYear,
    required this.semester,
    required this.category,
    required this.dateRange,
    required this.tutorStatus,
    required this.chairStatus,
    required this.instructorStatus,
    required this.proofText,
    this.proofUrl,
    this.printUrl,
    this.canDelete = false,
  });

  final String number;
  final String schoolYear;
  final String semester;
  final String category;
  final String dateRange;
  final String tutorStatus;
  final String chairStatus;
  final String instructorStatus;
  final String proofText;
  final String? proofUrl;
  final String? printUrl;
  final bool canDelete;
}

enum StudentLeaveReviewStatus { approved, pending, rejected, noReview, unknown }

StudentLeaveReviewStatus resolveStudentLeaveReviewStatus(String value) {
  final String status = value.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  if (status.contains('免審核') ||
      status.contains('不需審核') ||
      status.contains('無需審核') ||
      status.contains('不須確認') ||
      status.contains('不需確認') ||
      status.contains('免確認') ||
      status.contains('noreview') ||
      status.contains('notrequired') ||
      status.contains('exempt')) {
    return StudentLeaveReviewStatus.noReview;
  }
  if (status.contains('未確認') ||
      status.contains('未審核') ||
      status.contains('待') ||
      status.contains('pending') ||
      status.contains('unconfirmed') ||
      status.contains('notconfirmed')) {
    return StudentLeaveReviewStatus.pending;
  }
  if (status.contains('退') ||
      status.contains('拒') ||
      status.contains('未通過') ||
      status.contains('不通過') ||
      status.contains('未核准') ||
      status.contains('不核准') ||
      status.contains('未核可') ||
      status.contains('不核可') ||
      status.contains('未完成') ||
      status.contains('失敗') ||
      status.contains('notapproved') ||
      status.contains('unapproved') ||
      status.contains('disapproved') ||
      status.contains('notpassed') ||
      status.contains('notcompleted') ||
      status.contains('reject') ||
      status.contains('declined') ||
      status.contains('failed') ||
      status.contains('denied')) {
    return StudentLeaveReviewStatus.rejected;
  }
  if (status.contains('已確認') ||
      status.contains('通過') ||
      status.contains('核准') ||
      status.contains('完成') ||
      status.contains('approved') ||
      status.contains('confirmed')) {
    return StudentLeaveReviewStatus.approved;
  }
  return StudentLeaveReviewStatus.unknown;
}

StudentLeaveReviewStatus resolveStudentLeaveOverallStatus(
  StudentLeaveRecord record,
) {
  final List<StudentLeaveReviewStatus> statuses = <StudentLeaveReviewStatus>[
    resolveStudentLeaveReviewStatus(record.tutorStatus),
    resolveStudentLeaveReviewStatus(record.chairStatus),
    resolveStudentLeaveReviewStatus(record.instructorStatus),
  ];
  if (statuses.contains(StudentLeaveReviewStatus.rejected)) {
    return StudentLeaveReviewStatus.rejected;
  }
  if (statuses.contains(StudentLeaveReviewStatus.pending)) {
    return StudentLeaveReviewStatus.pending;
  }
  if (statuses.contains(StudentLeaveReviewStatus.unknown)) {
    return StudentLeaveReviewStatus.unknown;
  }
  if (statuses.contains(StudentLeaveReviewStatus.approved)) {
    return StudentLeaveReviewStatus.approved;
  }
  return StudentLeaveReviewStatus.noReview;
}

class StudentLeaveRequest {
  const StudentLeaveRequest({
    required this.type,
    required this.startDateTime,
    required this.endDateTime,
    required this.reason,
    this.attachment,
    this.leaveClass = '1',
  });

  final String leaveClass;
  final StudentLeaveType type;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String reason;
  final StudentLeaveAttachment? attachment;
}

class StudentLeaveAttachment {
  const StudentLeaveAttachment({
    required this.fileName,
    this.filePath,
    this.bytes,
  });

  final String fileName;
  final String? filePath;
  final Uint8List? bytes;

  bool get hasData {
    final bool hasFilePath = filePath?.trim().isNotEmpty ?? false;
    return hasFilePath || bytes != null;
  }
}

class StudentLeaveSubmitResult {
  const StudentLeaveSubmitResult({
    required this.statusCode,
    required this.body,
    required this.confirmation,
  });

  final int? statusCode;
  final String body;
  final StudentLeaveConfirmation confirmation;

  bool? get looksSuccessful {
    if (body.contains('不成功') ||
        body.contains('失敗') ||
        body.contains('錯誤') ||
        body.contains('未完成') ||
        body.contains('異常')) {
      return false;
    }
    if (body.contains('成功') ||
        body.contains('完成') ||
        body.contains('已新增') ||
        body.contains('存檔')) {
      return true;
    }
    return null;
  }
}

class StudentLeaveDeleteResult {
  const StudentLeaveDeleteResult({
    required this.statusCode,
    required this.body,
  });

  final int? statusCode;
  final String body;

  bool? get looksSuccessful {
    if (body.contains('不成功') ||
        body.contains('失敗') ||
        body.contains('錯誤') ||
        body.contains('未完成') ||
        body.contains('異常')) {
      return false;
    }
    if (body.contains('刪除') && (body.contains('成功') || body.contains('完成'))) {
      return true;
    }
    return null;
  }
}

class StudentLeavePreviewResult {
  const StudentLeavePreviewResult({
    required this.statusCode,
    required this.body,
    required this.confirmation,
    required this.confirmForm,
  });

  final int? statusCode;
  final String body;
  final StudentLeaveConfirmation confirmation;
  final StudentLeaveConfirmForm confirmForm;
}

class StudentLeaveConfirmForm {
  const StudentLeaveConfirmForm({required this.action, required this.fields})
    : _sessionIdentity = null;

  StudentLeaveConfirmForm._bound({
    required this.action,
    required Map<String, String> fields,
    required Object sessionIdentity,
  }) : fields = Map<String, String>.unmodifiable(fields),
       _sessionIdentity = sessionIdentity;

  final String action;
  final Map<String, String> fields;
  final Object? _sessionIdentity;

  StudentLeaveConfirmForm bindToSession(Object sessionIdentity) {
    return StudentLeaveConfirmForm._bound(
      action: action,
      fields: fields,
      sessionIdentity: sessionIdentity,
    );
  }

  bool isBoundToSession(Object sessionIdentity) =>
      identical(_sessionIdentity, sessionIdentity);
}

class StudentLeaveConfirmation {
  const StudentLeaveConfirmation({
    required this.sections,
    required this.messages,
    required this.rawText,
    this.noticeLines = const <String>[],
  });

  final List<StudentLeaveConfirmationSection> sections;
  final List<String> messages;
  final String rawText;
  final List<String> noticeLines;

  bool get hasStructuredData =>
      sections.any(
        (StudentLeaveConfirmationSection section) => section.fields.isNotEmpty,
      ) ||
      messages.isNotEmpty;
}

class StudentLeaveConfirmationSection {
  const StudentLeaveConfirmationSection({
    required this.title,
    required this.fields,
  });

  final String title;
  final List<StudentLeaveConfirmationField> fields;
}

class StudentLeaveConfirmationField {
  const StudentLeaveConfirmationField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
