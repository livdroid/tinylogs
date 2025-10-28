import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/log_entry.dart';

/// Helper pour gérer la base de données SQLite
class DatabaseHelper {
  static const String _tableName = 'logs';
  static const int _databaseVersion = 1;

  Database? _database;
  final String databaseName;

  DatabaseHelper({required this.databaseName});

  /// Obtient l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Crée la table lors de la première ouverture
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        content TEXT NOT NULL
      )
    ''');

    // Index sur le timestamp pour des requêtes rapides
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');
  }

  /// Insère un log dans la base de données
  Future<int> insertLog(LogEntry log) async {
    final db = await database;
    return await db.insert(
      _tableName,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les logs
  Future<List<LogEntry>> getAllLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return LogEntry.fromMap(maps[i]);
    });
  }

  /// Récupère les logs dans une plage de temps
  Future<List<LogEntry>> getLogsInRange(
      int startTimestamp, int endTimestamp) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return LogEntry.fromMap(maps[i]);
    });
  }

  /// Récupère les logs autour d'une date (±12h par défaut)
  Future<List<LogEntry>> getLogsAround(
    DateTime dateTime, {
    Duration margin = const Duration(hours: 12),
  }) async {
    final centerTimestamp = dateTime.millisecondsSinceEpoch;
    final marginMs = margin.inMilliseconds;

    return await getLogsInRange(
      centerTimestamp - marginMs,
      centerTimestamp + marginMs,
    );
  }

  /// Supprime les logs plus anciens que la durée spécifiée
  Future<int> deleteOldLogs(Duration retentionDuration) async {
    final db = await database;
    final cutoffTimestamp =
        DateTime.now().subtract(retentionDuration).millisecondsSinceEpoch;

    return await db.delete(
      _tableName,
      where: 'timestamp < ?',
      whereArgs: [cutoffTimestamp],
    );
  }

  /// Compte le nombre total de logs
  Future<int> getLogCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Supprime tous les logs
  Future<int> deleteAllLogs() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Supprime complètement la base de données
  Future<void> deleteDatabase() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    await databaseFactory.deleteDatabase(path);
  }
}
