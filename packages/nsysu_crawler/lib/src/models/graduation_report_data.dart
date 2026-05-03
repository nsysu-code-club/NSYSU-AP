import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'graduation_report_data.g.dart';

@JsonSerializable(explicitToJson: true)
class GraduationReportData {
  String title;
  String name;
  String time;
  String missingRequiredCoursesCredit;
  String generalEducationCourseDescription;
  String otherEducationsCourseCredit;
  String totalDescription;
  List<MissingRequiredCourse> missingRequiredCourse;
  List<GeneralEducationCourse> generalEducationCourse;
  List<OtherEducationsCourse> otherEducationsCourse;

  GraduationReportData({
    this.title = '',
    this.name = '',
    this.time = '',
    this.missingRequiredCoursesCredit = '',
    this.generalEducationCourseDescription = '',
    this.otherEducationsCourseCredit = '',
    this.totalDescription = '',
    required this.missingRequiredCourse,
    required this.generalEducationCourse,
    required this.otherEducationsCourse,
  });

  factory GraduationReportData.fromJson(Map<String, dynamic> json) =>
      _$GraduationReportDataFromJson(json);

  Map<String, dynamic> toJson() => _$GraduationReportDataToJson(this);

  factory GraduationReportData.fromRawJson(String str) =>
      GraduationReportData.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());
}

@JsonSerializable()
class MissingRequiredCourse {
  String? name;
  String? credit;
  String? description;

  MissingRequiredCourse({
    required this.name,
    required this.credit,
    required this.description,
  });

  factory MissingRequiredCourse.fromJson(Map<String, dynamic> json) =>
      _$MissingRequiredCourseFromJson(json);

  Map<String, dynamic> toJson() => _$MissingRequiredCourseToJson(this);

  factory MissingRequiredCourse.fromRawJson(String str) =>
      MissingRequiredCourse.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());
}

@JsonSerializable()
class GeneralEducationCourse {
  String? type;
  List<GeneralEducationItem>? generalEducationItem;

  GeneralEducationCourse({this.type, this.generalEducationItem});

  factory GeneralEducationCourse.fromJson(Map<String, dynamic> json) =>
      _$GeneralEducationCourseFromJson(json);

  Map<String, dynamic> toJson() => _$GeneralEducationCourseToJson(this);

  factory GeneralEducationCourse.fromRawJson(String str) =>
      GeneralEducationCourse.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());
}

@JsonSerializable()
class GeneralEducationItem {
  String? name;
  String? credit;
  String? check;
  String? actualCredits;
  String? totalCredits;
  String? practiceSituation;

  GeneralEducationItem({
    this.name,
    this.credit,
    this.check,
    this.actualCredits,
    this.totalCredits,
    this.practiceSituation,
  }) {
    credit = credit!.replaceAll('�', '\\');
    check = check!.replaceAll('�', '\\');
  }

  factory GeneralEducationItem.fromJson(Map<String, dynamic> json) =>
      _$GeneralEducationItemFromJson(json);

  Map<String, dynamic> toJson() => _$GeneralEducationItemToJson(this);

  factory GeneralEducationItem.fromRawJson(String str) =>
      GeneralEducationItem.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());
}

@JsonSerializable()
class OtherEducationsCourse {
  String? name;
  String? semester;
  String? credit;

  OtherEducationsCourse({this.name, this.semester, this.credit});

  factory OtherEducationsCourse.fromJson(Map<String, dynamic> json) =>
      _$OtherEducationsCourseFromJson(json);

  Map<String, dynamic> toJson() => _$OtherEducationsCourseToJson(this);

  factory OtherEducationsCourse.fromRawJson(String str) =>
      OtherEducationsCourse.fromJson(
        json.decode(str) as Map<String, dynamic>,
      );

  String toRawJson() => jsonEncode(toJson());
}
