import 'package:nsysu_crawler/src/utils/codec_utils.dart';
import 'package:test/test.dart';

void main() {
  group('base64md5', () {
    test('matches the upstream NSYSU SSO encoding for a known input', () {
      // md5('hello') = 5d41402abc4b2a76b9719d911017c592
      // base64 of those raw bytes:
      expect(base64md5('hello'), equals('XUFAKrxLKna5cZ2REBfFkg=='));
    });

    test('produces a fixed-length 24-char base64 string', () {
      expect(base64md5('any_password').length, equals(24));
    });
  });

  group('uriEncodeBig5', () {
    test('passes ASCII through as %hex pairs', () {
      // 'A' = 0x41
      expect(uriEncodeBig5('A'), equals('%41'));
    });

    test('encodes 高 (Big5: 0xB0AA) as %b0%aa', () {
      expect(uriEncodeBig5('高'), equals('%b0%aa'));
    });
  });
}
