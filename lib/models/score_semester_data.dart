import 'options.dart';

class ScoreSemesterData {
  List<Options> years;
  List<Options> semesters;

  int selectYearsIndex = 0;
  int selectSemesterIndex = 0;

  Options get year => years.length == 0
      ? Options(text: '107', value: '107')
      : years[selectYearsIndex];

  Options get semester => semesters.length == 0
      ? Options(text: '上學期', value: '1')
      : semesters[selectSemesterIndex];

  ScoreSemesterData({this.years, this.semesters});
}
