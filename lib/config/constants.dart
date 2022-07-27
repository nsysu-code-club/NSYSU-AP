import 'package:encrypt/encrypt.dart';

class Constants {
  Constants._();

  static bool get isInDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  static final Key key = Key.fromUtf8('l9r1W3wcsnJTayxCXwoFt62w1i4sQ5J9');
  static final IV iv = IV.fromUtf8('auc9OV5r0nLwjCAH');

  static const String defaultYear = '109';
  static const String defaultSemester = '1';

  static const String admissionGuideUrl =
      'https://leslietsai1.wixsite.com/nsysufreshman';

  static const String prefFirstEnterApp = 'pref_first_enter_app';
  static const String prefCurrentVersion = 'pref_current_version';
  static const String prefRememberPassword = 'pref_remember_password';
  static const String prefAutoLogin = 'pref_auto_login';
  static const String prefUsername = 'pref_username';
  static const String prefPassword = 'pref_password';

  static const String prefCourseNotify = 'pref_course_notify';
  static const String prefBusNotify = 'pref_bus_notify';
  static const String prefCourseNotifyData = 'pref_course_notify_data';
  static const String prefBusNotifyData = 'pref_bus_notify_data';
  static const String prefCourseVibrate = 'pref_course_vibrate';
  static const String prefCourseVibrateData = 'pref_course_vibrate_data';
  static const String prefCourseVibrateUserSetting =
      'pref_course_vibrate_user_setting';
  static const String prefDisplayPicture = 'pref_display_picture';
  static const String prefScoreData = 'pref_score_data';
  static const String prefCourseData = 'pref_course_data';
  static const String prefLeaveData = 'pref_leave_data';
  static const String prefSemesterData = 'pref_semester_data';
  static const String prefScheduleData = 'pref_schedule_datae';
  static const String prefUserInfo = 'pref_user_info';
  static const String prefBusReservationsData = 'pref_bus_reservevations_data';

  static const String prefLanguageCode = 'pref_language_code';
  static const String prefThemeModeIndex = 'pref_theme_mode_index';

  static const String prefApEnable = 'pref_ap_enable';
  static const String prefBusEnable = 'pref_bus_enable';
  static const String prefLeaveEnable = 'pref_leave_enable';

  static const String prefIsOfflineLogin = 'pref_is_offline_login';
  static const String prefIsShowCourseSearchButton =
      'pref_is_show_course_search_button';

  static const String scheduleData = 'schedule_data';
  static const String androidAppVersion = 'android_app_version';
  static const String iosAppVersion = 'ios_app_version';
  static const String appVersion = 'app_version';
  static const String newVersionContentZh = 'new_version_content_zh';
  static const String newVersionContentEn = 'new_version_content_en';
  static const String newsData = 'news_data_v2';
  static const String defaultCourseSemesterCode =
      'default_course_semester_code';
  static const String timeCodeConfig = 'time_code_config';
  static const String schedulePdfUrl = 'schedule_pdf_url';

  static const String tagStudentPicture = 'tag_student_picture';
  static const String tagNewsPicture = 'tag_news_picture';
  static const String tagNewsIcon = 'tag_news_icon';
  static const String tagNewsTitle = 'tag_news_title';

  static const String carParkAreaSubscription = 'car_park_area_subscription';
  static const String agreeTowCarPolicy = 'agree_tow_car_policy';

  static const String busInfoData = 'bus_info_data';

  static const String confirmFormUrl = 'confirm_form_url';

  static const String fansPageId = '301942414015612';
}
