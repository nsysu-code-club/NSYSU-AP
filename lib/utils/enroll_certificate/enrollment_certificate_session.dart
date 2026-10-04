import 'dart:async';

/// Cancels enrollment work synchronously, then drains writes before logout
/// removes account data. Disposed pages stay registered until cleanup finishes.
class EnrollmentCertificateSession {
  EnrollmentCertificateSession({required this.onCancel}) {
    _active.add(this);
  }

  static final Set<EnrollmentCertificateSession> _active =
      <EnrollmentCertificateSession>{};

  final Future<void>? Function() onCancel;
  bool isCancelled = false;
  Future<void>? _pendingWrite;
  Future<void>? _closing;

  Future<void> write(Future<void> Function() action) async {
    if (isCancelled) return;
    final Future<void> pending = Future<void>.sync(action);
    _pendingWrite = pending;
    try {
      await pending;
    } finally {
      if (identical(_pendingWrite, pending)) _pendingWrite = null;
    }
  }

  Future<void> close() {
    if (_closing != null) return _closing!;
    isCancelled = true;
    final Future<void> cleanup = Future<void>.sync(onCancel);
    return _closing = _drain(cleanup);
  }

  Future<void> _drain(Future<void> cleanup) async {
    try {
      await Future.wait<void>(<Future<void>>[
        cleanup,
        if (_pendingWrite != null) _pendingWrite!,
      ]);
    } catch (_) {
      // Retrieval reports write failures. Logout must still clear all data.
    } finally {
      _active.remove(this);
    }
  }

  static Future<void> cancelAll() async {
    await Future.wait<void>(
      List<EnrollmentCertificateSession>.of(
        _active,
      ).map((EnrollmentCertificateSession session) => session.close()),
    );
  }
}
