import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/resources/image_assets.dart';

void main() {
  test('Japanese notes fall back to English and retain list formatting', () {
    expect(
      FileAssets.changelogContent(<String, dynamic>{
        'en-US': <String>['Fix login', 'Update translations'],
        'zh-TW': '修正登入',
      }, 'ja'),
      '* Fix login\n* Update translations',
    );
  });

  test('selected translation takes precedence over fallback', () {
    expect(
      FileAssets.changelogContent(<String, dynamic>{
        'ja': '更新しました',
        'en-US': 'Updated',
      }, 'ja'),
      '更新しました',
    );
  });

  test('empty or malformed notes try the next fallback', () {
    expect(
      FileAssets.changelogContent(<String, dynamic>{
        'ja': <String>[],
        'en-US': false,
        'zh-TW': '更新',
      }, 'ja'),
      '更新',
    );
    expect(FileAssets.changelogContent(null, 'ja'), isNull);
    expect(
      FileAssets.changelogContent(<String, dynamic>{'en-US': '  '}, 'ja'),
      isNull,
    );
  });
}
