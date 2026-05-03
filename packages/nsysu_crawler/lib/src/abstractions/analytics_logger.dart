abstract interface class AnalyticsLogger {
  void logTimeEvent(String name, double seconds);
}

class NoOpAnalyticsLogger implements AnalyticsLogger {
  const NoOpAnalyticsLogger();

  @override
  void logTimeEvent(String name, double seconds) {}
}
