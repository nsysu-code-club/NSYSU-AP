abstract interface class CrashReporter {
  void recordError(Object error, StackTrace stack, {String? reason});

  void setCustomKey(String key, Object value);
}

class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  void recordError(Object error, StackTrace stack, {String? reason}) {}

  @override
  void setCustomKey(String key, Object value) {}
}
