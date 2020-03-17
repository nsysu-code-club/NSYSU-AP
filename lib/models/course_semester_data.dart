import 'options.dart';

class CourseSemesterData {
  List<SemesterOptions> semesters;

  int selectSemesterIndex = 0;

  SemesterOptions get semester => semesters.length == 0
      ? SemesterOptions(text: '1072', value: '1072')
      : semesters[selectSemesterIndex];

  void setDefault(String text) {
    for (var i = 0; i < semesters.length; i++) {
      if (semesters[i].text == text) selectSemesterIndex = i;
    }
  }

  CourseSemesterData({this.semesters});
}
