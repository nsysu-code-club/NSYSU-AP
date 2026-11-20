import 'package:ap_common/ap_common.dart';

extension AnnouncementAccess on AnnouncementHelper {
  /// Resolves the role using the same credential the moderation API receives.
  Future<ApiResult<PermissionLevel>> getAuthenticatedRole(
    AnnouncementLoginData session,
  ) async {
    try {
      final Response<Map<String, dynamic>> response = await dio.get(
        '/user/info',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer ${session.key}'},
          followRedirects: false,
        ),
      );
      final Object? level = response.data?['permission_level'];
      if (level is int && level >= 0 && level < PermissionLevel.values.length) {
        return ApiSuccess<PermissionLevel>(PermissionLevel.values[level]);
      }
    } on DioException catch (error) {
      final int? status = error.response?.statusCode;
      if (status != null && (status == 401 || status == 403)) {
        return ApiError<PermissionLevel>(
          GeneralResponse(statusCode: status, message: ''),
        );
      }
      return ApiFailure<PermissionLevel>(error);
    }
    return const ApiError<PermissionLevel>(
      GeneralResponse(statusCode: 500, message: ''),
    );
  }

  Future<ApiResult<List<Announcement>>> getOwnApplications(
    AnnouncementLoginData session,
  ) async {
    final String? username = session.username;
    if (username == null || username.isEmpty) {
      return const ApiError<List<Announcement>>(
        GeneralResponse(statusCode: 401, message: ''),
      );
    }
    try {
      final Response<Map<String, dynamic>> response = await dio.get(
        '/user/application/${Uri.encodeComponent(username)}',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer ${session.key}'},
          followRedirects: false,
        ),
      );
      if (response.statusCode == 204) {
        return const ApiSuccess<List<Announcement>>(<Announcement>[]);
      }
      return ApiSuccess<List<Announcement>>(
        AnnouncementData.fromJson(response.data!).sortedData,
      );
    } on DioException catch (error) {
      return ApiFailure<List<Announcement>>(error);
    }
  }
}
