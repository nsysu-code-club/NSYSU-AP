import 'options.dart';

class ScoreSemesterData {
  List<SemesterOptions> years;
  List<SemesterOptions> semesters;

  int selectYearsIndex = 0;
  int selectSemesterIndex = 0;

  SemesterOptions get year => years.length == 0
      ? SemesterOptions(text: '107', value: '107')
      : years[selectYearsIndex];

  SemesterOptions get semester => semesters.length == 0
      ? SemesterOptions(text: '上學期', value: '1')
      : semesters[selectSemesterIndex];

  ScoreSemesterData({
    required this.years,
    required this.semesters,
  });
}
