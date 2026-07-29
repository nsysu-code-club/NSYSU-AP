import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:nsysu_ap/utils/captcha_ocr/captcha_ocr.dart';

void main() {
  const CaptchaImagePreprocessor preprocessor = CaptchaImagePreprocessor();

  test('creates three decodable upscaled captcha variants', () {
    final image.Image source = image.Image(width: 124, height: 24);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    for (int x = 8; x < 116; x++) {
      final int y = 4 + (x % 16);
      source.setPixelRgba(x, y, 255, 230, 0, 255);
    }

    final List<CaptchaImageVariant> variants = preprocessor.createVariants(
      Uint8List.fromList(image.encodeBmp(source)),
    );

    expect(
      variants.map((CaptchaImageVariant variant) => variant.name),
      <String>['segmented', 'segmented-thick', 'color-upscaled'],
    );
    expect(variants, hasLength(3));
    for (final CaptchaImageVariant variant in variants) {
      final image.Image? decoded = image.decodePng(variant.bytes);
      expect(decoded, isNotNull, reason: variant.name);
      expect(decoded!.width, greaterThanOrEqualTo(992), reason: variant.name);
      expect(decoded.height, greaterThanOrEqualTo(192), reason: variant.name);
    }
  });

  test('falls back to original bytes when decoding fails', () {
    final Uint8List source = Uint8List.fromList(<int>[1, 2, 3]);

    final List<CaptchaImageVariant> variants = preprocessor.createVariants(
      source,
    );

    expect(variants, hasLength(1));
    expect(variants.single.name, 'original');
    expect(variants.single.bytes, source);
  });
}
