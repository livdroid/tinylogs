/// Log severity levels (ordered by severity)
enum LogLevel {
  /// Detailed debug information
  debug,

  /// General operational information
  info,

  /// Abnormal but non-critical situations
  warning,

  /// Errors requiring attention
  error,
}

extension LogLevelExtension on LogLevel {
  /// Returns the uppercase name for display
  String get displayName => name.toUpperCase();

  /// Returns the numeric value for sorting and filtering
  /// Uses enum index directly (debug=0, info=1, warning=2, error=3)
  int get value => index;

  /// Creates a LogLevel from a string
  static LogLevel fromString(String value) {
    return LogLevel.values.firstWhere(
      (level) => level.name == value.toLowerCase(),
      orElse: () => LogLevel.info,
    );
  }
}
