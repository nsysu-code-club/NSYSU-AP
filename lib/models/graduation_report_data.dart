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

  GraduationReportData(
      {this.title,
      this.name,
      this.time,
      this.missingRequiredCoursesCredit,
      this.totalDescription,
      this.missingRequiredCourse,
      this.generalEducationCourse,
      this.otherEducationsCourse});

  GraduationReportData.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    name = json['name'];
    time = json['time'];
    missingRequiredCoursesCredit = json['missingRequiredCoursesCredit'];
    generalEducationCourseDescription =
        json['generalEducationCourseDescription'];
    otherEducationsCourseCredit = json['otherEducationsCourseCredit'];
    totalDescription = json['totalDescription'];
    if (json['missingRequiredCourse'] != null) {
      missingRequiredCourse = [];
      json['missingRequiredCourse'].forEach((v) {
        missingRequiredCourse.add(new MissingRequiredCourse.fromJson(v));
      });
    }
    if (json['generalEducationCourse'] != null) {
      generalEducationCourse = [];
      json['generalEducationCourse'].forEach((v) {
        generalEducationCourse.add(new GeneralEducationCourse.fromJson(v));
      });
    }
    if (json['otherEducationsCourse'] != null) {
      otherEducationsCourse = [];
      json['otherEducationsCourse'].forEach((v) {
        otherEducationsCourse.add(new OtherEducationsCourse.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['name'] = this.name;
    data['time'] = this.time;
    data['missingRequiredCoursesCredit'] = this.missingRequiredCoursesCredit;
    data['generalEducationCourseDescription'] =
        this.generalEducationCourseDescription;
    data['otherEducationsCourseCredit'] = this.otherEducationsCourseCredit;
    data['totalDescription'] = this.totalDescription;
    if (this.missingRequiredCourse != null) {
      data['missingRequiredCourse'] =
          this.missingRequiredCourse.map((v) => v.toJson()).toList();
    }
    if (this.generalEducationCourse != null) {
      data['generalEducationCourse'] =
          this.generalEducationCourse.map((v) => v.toJson()).toList();
    }
    if (this.otherEducationsCourse != null) {
      data['otherEducationsCourse'] =
          this.otherEducationsCourse.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MissingRequiredCourse {
  String name;
  String credit;
  String description;

  MissingRequiredCourse({this.name, this.credit, this.description});

  MissingRequiredCourse.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    credit = json['credit'];
    description = json['description'];
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
  String type;
  List<GeneralEducationItem> generalEducationItem;

  GeneralEducationCourse({this.type, this.generalEducationItem});

  GeneralEducationCourse.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json['generalEducationItem'] != null) {
      generalEducationItem = [];
      json['generalEducationItem'].forEach((v) {
        generalEducationItem.add(new GeneralEducationItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.generalEducationItem != null) {
      data['generalEducationItem'] =
          this.generalEducationItem.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GeneralEducationItem {
  String name;
  String credit;
  String check;
  String actualCredits;
  String totalCredits;
  String practiceSituation;

  GeneralEducationItem(
      {this.name,
      this.credit,
      this.check,
      this.actualCredits,
      this.totalCredits,
      this.practiceSituation}) {
    this.credit = this.credit.replaceAll('�', '\\');
    this.check = this.check.replaceAll('�', '\\');
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
  String name;
  String semester;
  String credit;

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
