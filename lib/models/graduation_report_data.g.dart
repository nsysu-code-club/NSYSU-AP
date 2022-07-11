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
