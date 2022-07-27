// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graduation_report_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GraduationReportData _$GraduationReportDataFromJson(
        Map<String, dynamic> json) =>
    GraduationReportData(
      title: json['title'] as String? ?? '',
      name: json['name'] as String? ?? '',
      time: json['time'] as String? ?? '',
      missingRequiredCoursesCredit:
          json['missingRequiredCoursesCredit'] as String? ?? '',
      generalEducationCourseDescription:
          json['generalEducationCourseDescription'] as String? ?? '',
      otherEducationsCourseCredit:
          json['otherEducationsCourseCredit'] as String? ?? '',
      totalDescription: json['totalDescription'] as String? ?? '',
      missingRequiredCourse: (json['missingRequiredCourse'] as List<dynamic>)
          .map((e) => MissingRequiredCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalEducationCourse: (json['generalEducationCourse'] as List<dynamic>)
          .map(
              (e) => GeneralEducationCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      otherEducationsCourse: (json['otherEducationsCourse'] as List<dynamic>)
          .map((e) => OtherEducationsCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GraduationReportDataToJson(
        GraduationReportData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'name': instance.name,
      'time': instance.time,
      'missingRequiredCoursesCredit': instance.missingRequiredCoursesCredit,
      'generalEducationCourseDescription':
          instance.generalEducationCourseDescription,
      'otherEducationsCourseCredit': instance.otherEducationsCourseCredit,
      'totalDescription': instance.totalDescription,
      'missingRequiredCourse':
          instance.missingRequiredCourse.map((e) => e.toJson()).toList(),
      'generalEducationCourse':
          instance.generalEducationCourse.map((e) => e.toJson()).toList(),
      'otherEducationsCourse':
          instance.otherEducationsCourse.map((e) => e.toJson()).toList(),
    };

MissingRequiredCourse _$MissingRequiredCourseFromJson(
        Map<String, dynamic> json) =>
    MissingRequiredCourse(
      name: json['name'] as String?,
      credit: json['credit'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$MissingRequiredCourseToJson(
        MissingRequiredCourse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'credit': instance.credit,
      'description': instance.description,
    };

GeneralEducationCourse _$GeneralEducationCourseFromJson(
        Map<String, dynamic> json) =>
    GeneralEducationCourse(
      type: json['type'] as String?,
      generalEducationItem: (json['generalEducationItem'] as List<dynamic>?)
          ?.map((e) => GeneralEducationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GeneralEducationCourseToJson(
        GeneralEducationCourse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'generalEducationItem': instance.generalEducationItem,
    };

GeneralEducationItem _$GeneralEducationItemFromJson(
        Map<String, dynamic> json) =>
    GeneralEducationItem(
      name: json['name'] as String?,
      credit: json['credit'] as String?,
      check: json['check'] as String?,
      actualCredits: json['actualCredits'] as String?,
      totalCredits: json['totalCredits'] as String?,
      practiceSituation: json['practiceSituation'] as String?,
    );

Map<String, dynamic> _$GeneralEducationItemToJson(
        GeneralEducationItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'credit': instance.credit,
      'check': instance.check,
      'actualCredits': instance.actualCredits,
      'totalCredits': instance.totalCredits,
      'practiceSituation': instance.practiceSituation,
    };

OtherEducationsCourse _$OtherEducationsCourseFromJson(
        Map<String, dynamic> json) =>
    OtherEducationsCourse(
      name: json['name'] as String?,
      semester: json['semester'] as String?,
      credit: json['credit'] as String?,
    );

Map<String, dynamic> _$OtherEducationsCourseToJson(
        OtherEducationsCourse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'semester': instance.semester,
      'credit': instance.credit,
    };
