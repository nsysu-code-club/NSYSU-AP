class CourseSemesterData {
  List<Options> semesters;

  int selectSemesterIndex = 0;

  Options get semester => semesters.length == 0
      ? Options(text: '上學期', value: '1')
      : semesters[selectSemesterIndex];

  CourseSemesterData({this.semesters});
}

class Options {
  String text;
  String value;

  Options({this.text, this.value});
}
