import 'options.dart';

class CourseSemesterData {
  List<Options> semesters;

  int selectSemesterIndex = 0;

  Options get semester => semesters.length == 0
      ? Options(text: '1072', value: '1072')
      : semesters[selectSemesterIndex];

  CourseSemesterData({this.semesters});
}
