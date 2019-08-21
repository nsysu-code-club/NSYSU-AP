import 'options.dart';

class CourseSemesterData {
  List<Options> semesters;

  int selectSemesterIndex = 0;

  Options get semester => semesters.length == 0
      ? Options(text: '1072', value: '1072')
      : semesters[selectSemesterIndex];

  void setDefault(String text) {
    for (var i = 0; i < semesters.length; i++) {
      if (semesters[i].text == text) selectSemesterIndex = i;
    }
  }

  CourseSemesterData({this.semesters});
}
