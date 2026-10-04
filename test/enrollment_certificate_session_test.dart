import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsysu_ap/utils/enroll_certificate/enrollment_certificate_session.dart';

void main() {
  test('logout waits for writes even after the owning page closes', () async {
    final Completer<void> write = Completer<void>();
    int cancellations = 0;
    final EnrollmentCertificateSession session = EnrollmentCertificateSession(
      onCancel: () {
        cancellations++;
        return null;
      },
    );
    final Future<void> saving = session.write(() => write.future);
    final Future<void> disposed = session.close();
    bool logoutFinished = false;
    final Future<void> logout = EnrollmentCertificateSession.cancelAll().then(
      (_) => logoutFinished = true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.isCancelled, isTrue);
    expect(logoutFinished, isFalse);
    expect(cancellations, 1);
    await session.write(() async => fail('Cannot write after cancellation'));
    write.complete();
    await Future.wait<void>(<Future<void>>[saving, disposed, logout]);
    expect(logoutFinished, isTrue);
  });

  test('write failure does not prevent the remaining logout cleanup', () async {
    final Completer<void> write = Completer<void>();
    final EnrollmentCertificateSession session = EnrollmentCertificateSession(
      onCancel: () => null,
    );
    final Future<void> saving = session.write(() => write.future);
    final Future<void> failure = expectLater(saving, throwsStateError);
    final Future<void> logout = EnrollmentCertificateSession.cancelAll();
    write.completeError(StateError('disk full'));
    await Future.wait<void>(<Future<void>>[failure, logout]);
  });
}
