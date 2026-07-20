import 'dart:convert';
import 'dart:typed_data';

import 'package:ap_common_core/ap_common_core.dart';
import 'package:dio/dio.dart';
import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  test('getLeaveRecords sends the selected academic semester', () async {
    final StudentLeaveHelper helper = StudentLeaveHelper();
    final _RecordingAdapter adapter = _RecordingAdapter();
    helper.dio.httpClientAdapter = adapter;
    helper
      ..isLogin = true
      ..username = 'student';
    addTearDown(helper.dio.close);

    final ApiResult<List<StudentLeaveRecord>> result = await helper
        .getLeaveRecords(
          username: 'student',
          password: 'password',
          semester: const StudentLeaveSemester(schoolYear: 113, semester: 1),
        );

    expect(result, isA<ApiSuccess<List<StudentLeaveRecord>>>());
    expect(adapter.requestUri?.queryParameters['school_year'], '113');
    expect(adapter.requestUri?.queryParameters['sem'], '1');
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  Uri? requestUri;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUri = options.uri;
    return ResponseBody.fromBytes(
      utf8.encode('<html><body></body></html>'),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/html'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
