/// Configuration pour TinyLogs
class TinyLogsConfig {
  /// Durée de conservation des logs (par défaut: 7 jours)
  final Duration retentionDuration;

  /// Nom de la base de données (par défaut: tinylogs.db)
  final String databaseName;

  const TinyLogsConfig({
    this.retentionDuration = const Duration(days: 7),
    this.databaseName = 'tinylogs.db',
  });

  @override
  String toString() {
    return 'TinyLogsConfig{retentionDuration: $retentionDuration, databaseName: $databaseName}';
  }
}
