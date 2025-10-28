import 'package:flutter/foundation.dart';
import 'config/tinylogs_config.dart';
import 'database/database_helper.dart';
import 'models/log_entry.dart';

/// Classe principale pour gérer les logs avec TinyLogs
class TinyLogs {
  static TinyLogs? _instance;
  late DatabaseHelper _databaseHelper;
  late TinyLogsConfig _config;
  bool _initialized = false;

  TinyLogs._();

  /// Obtient l'instance singleton de TinyLogs
  static TinyLogs get instance {
    _instance ??= TinyLogs._();
    return _instance!;
  }

  /// Initialise TinyLogs avec la configuration
  Future<void> init([TinyLogsConfig? config]) async {
    if (_initialized) {
      debugPrint('TinyLogs: Déjà initialisé');
      return;
    }

    _config = config ?? const TinyLogsConfig();

    // Validation de la configuration
    if (_config.retentionDuration.inSeconds <= 0) {
      throw ArgumentError('La durée de rétention doit être positive');
    }
    _databaseHelper = DatabaseHelper(databaseName: _config.databaseName);

    // Initialise la base de données
    await _databaseHelper.database;

    _initialized = true;

    // Nettoie les anciens logs au démarrage
    final deletedCount =
        await _databaseHelper.deleteOldLogs(_config.retentionDuration);
    if (deletedCount > 0) {
      debugPrint(
          'TinyLogs: $deletedCount ancien(s) log(s) supprimé(s) au démarrage');
    }

    debugPrint('TinyLogs: Initialisé avec succès');
  }

  /// Vérifie que TinyLogs est initialisé
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'TinyLogs n\'est pas initialisé. Appelez TinyLogs.instance.init() d\'abord.',
      );
    }
  }

  /// Enregistre un log
  Future<int> log(String content) async {
    _ensureInitialized();

    if (content.isEmpty) {
      throw ArgumentError('Le contenu du log ne peut pas être vide');
    }

    final logEntry = LogEntry.now(content);
    final id = await _databaseHelper.insertLog(logEntry);
    return id;
  }

  /// Récupère tous les logs
  Future<List<LogEntry>> getAllLogs() async {
    _ensureInitialized();
    return await _databaseHelper.getAllLogs();
  }

  /// Récupère les logs dans une plage de temps
  Future<List<LogEntry>> getLogsInRange(DateTime start, DateTime end) async {
    _ensureInitialized();

    if (start.isAfter(end)) {
      throw ArgumentError('La date de début doit être avant la date de fin');
    }

    return await _databaseHelper.getLogsInRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
  }

  /// Récupère les logs autour d'une date précise (±12h par défaut)
  ///
  /// [dateTime] La date centrale
  /// [margin] La marge avant et après (par défaut 12 heures)
  Future<List<LogEntry>> getLogsAround(
    DateTime dateTime, {
    Duration margin = const Duration(hours: 12),
  }) async {
    _ensureInitialized();
    return await _databaseHelper.getLogsAround(dateTime, margin: margin);
  }

  /// Nettoie les logs plus anciens que la durée de rétention configurée
  Future<int> cleanupOldLogs() async {
    _ensureInitialized();
    final deletedCount =
        await _databaseHelper.deleteOldLogs(_config.retentionDuration);

    if (deletedCount > 0) {
      debugPrint('TinyLogs: $deletedCount ancien(s) log(s) supprimé(s)');
    }

    return deletedCount;
  }

  /// Compte le nombre total de logs
  Future<int> getLogCount() async {
    _ensureInitialized();
    return await _databaseHelper.getLogCount();
  }

  /// Supprime tous les logs (attention: irréversible!)
  Future<int> clearAllLogs() async {
    _ensureInitialized();
    final deletedCount = await _databaseHelper.deleteAllLogs();
    debugPrint(
        'TinyLogs: Tous les logs ont été supprimés ($deletedCount logs)');
    return deletedCount;
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (_initialized) {
      await _databaseHelper.close();
      _initialized = false;
      debugPrint('TinyLogs: Base de données fermée');
    }
  }

  /// Réinitialise complètement TinyLogs (pour les tests principalement)
  @visibleForTesting
  Future<void> reset() async {
    if (_initialized) {
      await _databaseHelper.deleteDatabase();
    }
    _initialized = false;
    _instance = null;
    debugPrint('TinyLogs: Réinitialisé');
  }

  /// Obtient la configuration actuelle
  TinyLogsConfig get config {
    _ensureInitialized();
    return _config;
  }

  /// Vérifie si TinyLogs est initialisé
  bool get isInitialized => _initialized;
}
