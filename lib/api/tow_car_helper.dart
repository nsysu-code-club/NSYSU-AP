import 'dart:async';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show required;
import 'package:nsysu_ap/models/tow_car_login_data.dart';

import '../models/tow_car_alert_data.dart';

export 'package:ap_common/callback/general_callback.dart';
export 'package:ap_common/models/announcement_login_data.dart';

enum AnnouncementLoginType {
  normal,
  google,
  apple,
}

extension DioErrorExtension on DioError {
  bool get isUnauthorized =>
      type == DioErrorType.response && response.statusCode == 401;

  bool get isNotPermission =>
      type == DioErrorType.response && response.statusCode == 403;

  bool get isNotFoundAnnouncement =>
      type == DioErrorType.response && response.statusCode == 404;
}

class TowCarHelper {
  static const USER_DATA_ERROR = 1401;
  static const TOKEN_EXPIRE = 401;
  static const NOT_PERMISSION = 403;

  static TowCarHelper _instance;

  static String host = 'nsysu.taki.dog';

  Dio dio;

  AnnouncementLoginType loginType = AnnouncementLoginType.normal;

  String username;
  String password;

  String code;

  ///firebase cloud message token
  String fcmToken;

  TowCarHelper() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://$host',
        connectTimeout: 10000,
        receiveTimeout: 10000,
      ),
    );
  }

  static TowCarHelper get instance {
    if (_instance == null) {
      _instance = TowCarHelper();
    }
    return _instance;
  }

  static reInstance({
    String host,
  }) {
    if (host != null) TowCarHelper.host = host;
    _instance = TowCarHelper();
  }

  void setAuthorization(String key) {
    dio.options.headers['Authorization'] = 'Bearer $key';
  }

  void clearSetting() {
    username = null;
    password = null;
  }

  void handleCrudError(DioError dioError, GeneralCallback<Response> callback) {
    if (dioError.isNotPermission)
      callback.onError(
        GeneralResponse(
          statusCode: NOT_PERMISSION,
          message: ApLocalizations.current.noPermissionHint,
        ),
      );
    else if (dioError.isNotFoundAnnouncement)
      callback.onError(
        GeneralResponse(
          statusCode: NOT_PERMISSION,
          message: ApLocalizations.current.notFoundData,
        ),
      );
    else
      callback.onFailure(dioError);
  }

  Future<TowCarLoginData> login({
    @required String username,
    @required String password,
    @required GeneralCallback<TowCarLoginData> callback,
  }) async {
    try {
      var response = await dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          "fcmToken": fcmToken,
        },
      );
      var loginData = TowCarLoginData.fromJson(response.data);
      setAuthorization(loginData.key);
      this.username = username;
      this.password = password;
      this.loginType = AnnouncementLoginType.normal;
      return callback == null ? loginData : callback.onSuccess(loginData);
    } on DioError catch (dioError) {
      if (callback == null)
        throw dioError;
      else {
        if (dioError.isUnauthorized)
          callback.onError(
            GeneralResponse(
              statusCode: 401,
              message: ApLocalizations.current.loginFail,
            ),
          );
        callback.onFailure(dioError);
      }
    }
    return null;
  }

  Future<List<TowCarAlert>> getAllTowCarAlert({
    @required GeneralCallback<List<TowCarAlert>> callback,
  }) async {
    try {
      var response = await dio.get(
        "/alert",
      );
      var data = TowCarAlertData(data: []);
      if (response.statusCode != 204) {
        data = TowCarAlertData.fromJson(response.data);
      }
      return (callback == null) ? data.data : callback.onSuccess(data.data);
    } on DioError catch (dioError) {
      if (callback == null)
        throw dioError;
      else
        return callback.onFailure(dioError);
    }
  }

  Future<TowCarAlert> getTowCarAlert({
    @required String alertId,
    GeneralCallback<TowCarAlert> callback,
  }) async {
    try {
      var response = await dio.get(
        "/alert/$alertId",
      );
      var data = TowCarAlert.fromJson(response.data);
      return (callback == null) ? data : callback.onSuccess(data);
    } on DioError catch (dioError) {
      if (callback == null)
        throw dioError;
      else
        callback.onFailure(dioError);
    }
    return null;
  }

  Future<Response> addApplication({
    @required TowCarAlert data,
    @required GeneralCallback<Response> callback,
    String languageCode,
  }) async {
    try {
      var response = await dio.post(
        "/alert/report",
        data: data.toUpdateJson(),
      );
      return callback == null ? response : callback.onSuccess(response);
    } on DioError catch (dioError) {
      if (callback == null)
        throw dioError;
      else
        handleCrudError(dioError, callback);
    }
    return null;
  }
}
