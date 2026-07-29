enum EnrollCertificatePhase {
  preparing,
  captchaLoading,
  captchaRecognizing,
  loginSubmitting,
  loginValidating,
  sessionValidating,
  registrationLoading,
  registrationValidating,
  certificateGenerating,
  pdfDownloading,
  pdfValidating,
  saving,
  completed,
  recoverableError,
  fatalError,
  manual,
}

class EnrollCertificateProgress {
  const EnrollCertificateProgress({
    required this.phase,
    required this.primary,
    this.secondary = '',
  });

  const EnrollCertificateProgress.preparing()
    : this(
        phase: EnrollCertificatePhase.preparing,
        primary: '正在準備自動取得在學證明',
        secondary: '正在建立安全連線',
      );

  final EnrollCertificatePhase phase;
  final String primary;
  final String secondary;

  bool get isTerminal =>
      phase == EnrollCertificatePhase.completed ||
      phase == EnrollCertificatePhase.fatalError ||
      phase == EnrollCertificatePhase.manual;

  bool get shouldOfferRetry =>
      phase == EnrollCertificatePhase.recoverableError ||
      phase == EnrollCertificatePhase.fatalError;
}

class EnrollCertificateAttemptTracker {
  EnrollCertificateAttemptTracker({
    this.maxLoginAttempts = 3,
    this.maxOcrRefreshes = 5,
  });

  final int maxLoginAttempts;
  final int maxOcrRefreshes;

  int loginFailures = 0;
  int ocrRefreshes = 0;

  int get currentLoginAttempt => (loginFailures + 1).clamp(1, maxLoginAttempts);

  bool get canAttemptLogin => loginFailures < maxLoginAttempts;
  bool get canRefreshCaptcha => ocrRefreshes < maxOcrRefreshes;

  void recordLoginFailure() {
    loginFailures++;
    ocrRefreshes = 0;
  }

  void recordOcrRefresh() {
    ocrRefreshes++;
  }

  void recordValidCaptcha() {
    ocrRefreshes = 0;
  }

  void reset() {
    loginFailures = 0;
    ocrRefreshes = 0;
  }
}

class EnrollCertificateRunTracker {
  EnrollCertificateRunTracker() : _current = _allocateRunId();

  static int _nextRunId = 0;

  int _current;

  int get current => _current;

  int startNewRun() {
    _current = _allocateRunId();
    return _current;
  }

  bool isCurrent(int runId) => runId == _current;

  void invalidate() {
    _current = -1;
  }

  static int _allocateRunId() => ++_nextRunId;
}

class EnrollCertificateNavigationTracker {
  int _registrationLoads = 0;
  int _certificateRequestRunId = -1;

  bool beginRegistrationLoad() {
    if (_registrationLoads >= 1) {
      return false;
    }
    _registrationLoads++;
    return true;
  }

  bool beginCertificateRequest(int runId) {
    if (_certificateRequestRunId == runId) {
      return false;
    }
    _certificateRequestRunId = runId;
    return true;
  }

  void reset() {
    _registrationLoads = 0;
    _certificateRequestRunId = -1;
  }
}

class EnrollCertificateRetryGate {
  bool _isLocked = false;

  bool tryLock() {
    if (_isLocked) {
      return false;
    }
    _isLocked = true;
    return true;
  }

  void release() {
    _isLocked = false;
  }
}
