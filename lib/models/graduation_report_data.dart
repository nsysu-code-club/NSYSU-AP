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

class MissingRequiredCourse {
  String? name;
  String? credit;
  String? description;

  MissingRequiredCourse({
    required this.name,
    required this.credit,
    required this.description,
  });

  factory MissingRequiredCourse.fromJson(Map<String, dynamic> json) {
    return MissingRequiredCourse(
      name: json['name'],
      credit: json['credit'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['credit'] = this.credit;
    data['description'] = this.description;
    return data;
  }
}

class GeneralEducationCourse {
  String? type;
  List<GeneralEducationItem>? generalEducationItem;

  GeneralEducationCourse({this.type, this.generalEducationItem});

  GeneralEducationCourse.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json['generalEducationItem'] != null) {
      generalEducationItem = [];
      json['generalEducationItem'].forEach((v) {
        generalEducationItem!.add(new GeneralEducationItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.generalEducationItem != null) {
      data['generalEducationItem'] =
          this.generalEducationItem!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GeneralEducationItem {
  String? name;
  String? credit;
  String? check;
  String? actualCredits;
  String? totalCredits;
  String? practiceSituation;

  GeneralEducationItem(
      {this.name,
      this.credit,
      this.check,
      this.actualCredits,
      this.totalCredits,
      this.practiceSituation}) {
    this.credit = this.credit!.replaceAll('�', '\\');
    this.check = this.check!.replaceAll('�', '\\');
  }

  GeneralEducationItem.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    credit = json['credit'];
    check = json['check'];
    actualCredits = json['actualCredits'];
    totalCredits = json['totalCredits'];
    practiceSituation = json['practiceSituation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['credit'] = this.credit;
    data['check'] = this.check;
    data['actualCredits'] = this.actualCredits;
    data['totalCredits'] = this.totalCredits;
    data['practiceSituation'] = this.practiceSituation;
    return data;
  }
}

class OtherEducationsCourse {
  String? name;
  String? semester;
  String? credit;

  OtherEducationsCourse({this.name, this.semester, this.credit});

  OtherEducationsCourse.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    semester = json['semester'];
    credit = json['credit'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['semester'] = this.semester;
    data['credit'] = this.credit;
    return data;
  }
}
