import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/pages/enroll_certificate/widgets/enroll_certificate_progress_view.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_page_evidence.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enroll_certificate_progress.dart';

void main() {
  group('EnrollCertificateAttemptTracker', () {
    test('OCR refreshes do not consume login attempts', () {
      final EnrollCertificateAttemptTracker tracker =
          EnrollCertificateAttemptTracker();

      for (int index = 0; index < 5; index++) {
        tracker.recordOcrRefresh();
      }

      expect(tracker.loginFailures, 0);
      expect(tracker.currentLoginAttempt, 1);
      expect(tracker.ocrRefreshes, 5);
      expect(tracker.canRefreshCaptcha, isFalse);
      expect(tracker.canAttemptLogin, isTrue);
    });

    test('server rejections have a separate three-attempt limit', () {
      final EnrollCertificateAttemptTracker tracker =
          EnrollCertificateAttemptTracker();
      tracker.recordOcrRefresh();
      tracker.recordLoginFailure();

      expect(tracker.loginFailures, 1);
      expect(tracker.ocrRefreshes, 0);
      expect(tracker.currentLoginAttempt, 2);

      tracker.recordLoginFailure();
      tracker.recordLoginFailure();
      expect(tracker.canAttemptLogin, isFalse);
    });
  });

  test('starting a new run invalidates callbacks from the previous run', () {
    final EnrollCertificateRunTracker tracker = EnrollCertificateRunTracker();
    final int previousRun = tracker.current;

    final int currentRun = tracker.startNewRun();

    expect(tracker.isCurrent(previousRun), isFalse);
    expect(tracker.isCurrent(currentRun), isTrue);
  });

  test('separate page instances receive different run IDs', () {
    final EnrollCertificateRunTracker first = EnrollCertificateRunTracker();
    final EnrollCertificateRunTracker second = EnrollCertificateRunTracker();

    expect(second.current, isNot(first.current));
  });

  test('only stopped phases offer the regenerate action', () {
    expect(
      const EnrollCertificateProgress(
        phase: EnrollCertificatePhase.captchaLoading,
        primary: '正在嘗試 2/3',
      ).shouldOfferRetry,
      isFalse,
    );
    expect(
      const EnrollCertificateProgress(
        phase: EnrollCertificatePhase.recoverableError,
        primary: '自動登入已重試 3 次',
      ).shouldOfferRetry,
      isTrue,
    );
  });

  test(
    'natural and fallback navigation cannot duplicate protected requests',
    () {
      final EnrollCertificateNavigationTracker tracker =
          EnrollCertificateNavigationTracker();

      expect(tracker.beginRegistrationLoad(), isTrue);
      expect(tracker.beginRegistrationLoad(), isFalse);
      expect(tracker.beginCertificateRequest(1), isTrue);
      expect(tracker.beginCertificateRequest(1), isFalse);

      tracker.reset();
      expect(tracker.beginRegistrationLoad(), isTrue);
      expect(tracker.beginCertificateRequest(2), isTrue);
    },
  );

  test('only one retry can be scheduled for concurrent callbacks', () {
    final EnrollCertificateRetryGate gate = EnrollCertificateRetryGate();

    expect(gate.tryLock(), isTrue);
    expect(gate.tryLock(), isFalse);

    gate.release();
    expect(gate.tryLock(), isTrue);
  });

  group('EnrollCertificatePageEvidence', () {
    test('recognizes login and captcha error pages', () {
      final EnrollCertificatePageEvidence evidence =
          EnrollCertificatePageEvidence.fromHtml('''
<html><body>
  <form name="f1"><input name="ValidCode"></form>
  <p>驗證碼錯誤，請重新輸入</p>
</body></html>
''');

      expect(evidence.hasLoginForm, isTrue);
      expect(evidence.captchaError, isTrue);
      expect(evidence.hasRegistrationMarker, isFalse);
    });

    test('recognizes a valid registration page and certificate entry', () {
      final EnrollCertificatePageEvidence evidence =
          EnrollCertificatePageEvidence.fromHtml('''
<html><body>
  <h1>網路註冊</h1>
  <a href="/webreg/WRegMain3.asp?act=71&out=print/enrollcert.asp">
    產生在學證明 Certificate of Enrollment
  </a>
</body></html>
''');

      expect(evidence.hasLoginForm, isFalse);
      expect(evidence.systemError, isFalse);
      expect(evidence.hasRegistrationMarker, isTrue);
      expect(evidence.hasCertificateEntry, isTrue);
    });

    test('does not treat an ordinary f1 form as the login form', () {
      final EnrollCertificatePageEvidence evidence =
          EnrollCertificatePageEvidence.fromHtml('''
<html><body>
  <h1>網路註冊</h1>
  <form name="f1"><input name="fg_load" value="1"></form>
</body></html>
''');

      expect(evidence.hasLoginForm, isFalse);
      expect(evidence.hasRegistrationMarker, isTrue);
    });

    test('recognizes permission and expired-session errors', () {
      expect(
        EnrollCertificatePageEvidence.fromHtml('<p>您無使用本系統權限</p>').systemError,
        isTrue,
      );
      expect(
        EnrollCertificatePageEvidence.fromHtml(
          '<p>Session expired，請重新登入</p>',
        ).systemError,
        isTrue,
      );
      expect(
        EnrollCertificatePageEvidence.fromHtml(
          '<p>incorrect return code</p>',
        ).systemError,
        isTrue,
      );
    });
  });

  testWidgets('renders only the public-facing progress line', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EnrollCertificateProgressView(
            progress: EnrollCertificateProgress(
              phase: EnrollCertificatePhase.captchaRecognizing,
              primary: '正在嘗試 2/3',
              secondary: '可能需要至多 20 秒',
            ),
          ),
        ),
      ),
    );

    expect(find.text('正在嘗試 2/3'), findsOneWidget);
    expect(find.text('可能需要至多 20 秒'), findsOneWidget);
    expect(find.text('影像版本 2/3・正在處理強化圖片'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows regenerate action for a stopped flow', (
    WidgetTester tester,
  ) async {
    int retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnrollCertificateProgressView(
            progress: const EnrollCertificateProgress(
              phase: EnrollCertificatePhase.recoverableError,
              primary: '連續 5 組驗證碼無法辨識',
              secondary: '請點擊重新生成後再試',
            ),
            showIndicator: false,
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('重新生成'));

    expect(retries, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('keeps the progress panel stable when its state changes', (
    WidgetTester tester,
  ) async {
    const Key panelKey = ValueKey<String>('enroll-certificate-progress-panel');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EnrollCertificateProgressView(
            progress: EnrollCertificateProgress(
              phase: EnrollCertificatePhase.captchaRecognizing,
              primary: '嘗試 1/3・正在辨識驗證碼',
              secondary: '影像版本 1/3・正在處理強化圖片',
            ),
          ),
        ),
      ),
    );
    final Rect runningRect = tester.getRect(find.byKey(panelKey));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnrollCertificateProgressView(
            progress: const EnrollCertificateProgress(
              phase: EnrollCertificatePhase.recoverableError,
              primary: '連續 5 組驗證碼無法辨識',
              secondary: '請點擊重新生成後再試',
            ),
            showIndicator: false,
            onRetry: () {},
          ),
        ),
      ),
    );
    final Rect errorRect = tester.getRect(find.byKey(panelKey));

    expect(errorRect, runningRect);
  });
}
