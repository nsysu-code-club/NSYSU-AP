import 'dart:typed_data';

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

  bool get hasData => filePath != null || bytes != null;
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

  bool get looksSuccessful =>
      body.contains('成功') ||
      body.contains('完成') ||
      body.contains('已新增') ||
      body.contains('存檔');
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
  const StudentLeaveConfirmForm({required this.action, required this.fields});

  final String action;
  final Map<String, String> fields;
}

class StudentLeaveConfirmation {
  const StudentLeaveConfirmation({
    required this.sections,
    required this.messages,
    required this.rawText,
  });

  final List<StudentLeaveConfirmationSection> sections;
  final List<String> messages;
  final String rawText;

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
