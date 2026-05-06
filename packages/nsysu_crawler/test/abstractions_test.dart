import 'package:nsysu_crawler/nsysu_crawler.dart';
import 'package:test/test.dart';

void main() {
  group('NoOpCrashReporter', () {
    test('swallows recordError silently', () {
      const NoOpCrashReporter reporter = NoOpCrashReporter();
      expect(
        () => reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          reason: 'test',
        ),
        returnsNormally,
      );
    });

    test('swallows setCustomKey silently', () {
      const NoOpCrashReporter reporter = NoOpCrashReporter();
      expect(
        () => reporter.setCustomKey('crawler_error_test', 'value'),
        returnsNormally,
      );
    });
  });

  group('NoOpAnalyticsLogger', () {
    test('swallows logTimeEvent silently', () {
      const NoOpAnalyticsLogger logger = NoOpAnalyticsLogger();
      expect(
        () => logger.logTimeEvent('parser', 0.123),
        returnsNormally,
      );
    });
  });
}
