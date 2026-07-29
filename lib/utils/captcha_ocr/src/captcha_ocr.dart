import 'package:flutter_native_ocr/flutter_native_ocr.dart';

class CaptchaOcr {
  CaptchaOcr({FlutterNativeOcr? ocr}) : _ocr = ocr ?? FlutterNativeOcr();

  final FlutterNativeOcr _ocr;

  Future<String> recognizeTextFromImagePath(String imagePath) async {
    final String result = await _ocr.recognizeText(imagePath);
    return result.trim();
  }
}
