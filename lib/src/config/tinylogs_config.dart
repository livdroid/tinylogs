/// Configuration for TinyLogs
class TinyLogsConfig {
  /// Log retention duration (default: 7 days)
  final Duration retentionDuration;

  /// Database name (default: tinylogs.db)
  final String databaseName;

  /// Enable debug prints (default: true in debug mode)
  /// When false, TinyLogs will not print any debug messages
  final bool enableLogs;

  const TinyLogsConfig({
    this.retentionDuration = const Duration(days: 7),
    this.databaseName = 'tinylogs.db',
    this.enableLogs = true,
  });

  @override
  String toString() {
    return 'TinyLogsConfig{retentionDuration: $retentionDuration, databaseName: $databaseName, enableLogs: $enableLogs}';
  }
}
