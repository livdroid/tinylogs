import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/log_entry.dart';
import '../models/log_level.dart';
import 'log_repository.dart';

/// SQLite implementation of LogRepository
class DatabaseHelper implements LogRepository {
  static const String _tableName = 'logs';
  static const int _databaseVersion = 2;

  Database? _database;
  final String databaseName;

  DatabaseHelper({required this.databaseName});

  /// Gets the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the table on first open
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        content TEXT NOT NULL,
        level TEXT NOT NULL DEFAULT 'info'
      )
    ''');

    // Index on timestamp for fast queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');

    // Index on level for filtering
    await db.execute('''
      CREATE INDEX idx_level ON $_tableName(level)
    ''');
  }

  /// Migration for previous versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add level column if it doesn't exist
      await db.execute('''
        ALTER TABLE $_tableName ADD COLUMN level TEXT NOT NULL DEFAULT 'info'
      ''');
      await db.execute('''
        CREATE INDEX idx_level ON $_tableName(level)
      ''');
    }
  }

  @override
  Future<int> insertLog(LogEntry log) async {
    final db = await database;
    return await db.insert(
      _tableName,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<int>> insertLogs(List<LogEntry> logs) async {
    if (logs.isEmpty) return [];

    final db = await database;
    final ids = <int>[];

    await db.transaction((txn) async {
      for (final log in logs) {
        final id = await txn.insert(
          _tableName,
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        ids.add(id);
      }
    });

    return ids;
  }

  @override
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

  @override
  Future<PaginatedLogs> getLogsPaginated({
    int page = 0,
    int pageSize = 50,
    LogLevel? minLevel,
  }) async {
    final db = await database;

    // Build WHERE clause if minimum level is specified
    String? where;
    List<dynamic>? whereArgs;

    if (minLevel != null) {
      final levels = LogLevel.values
          .where((l) => l.value >= minLevel.value)
          .map((l) => l.name)
          .toList();
      where = 'level IN (${levels.map((_) => '?').join(', ')})';
      whereArgs = levels;
    }

    // Count total
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $_tableName${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Retrieve the page
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: pageSize,
      offset: page * pageSize,
    );

    final logs = List.generate(maps.length, (i) => LogEntry.fromMap(maps[i]));

    return PaginatedLogs(
      logs: logs,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
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

  @override
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

  @override
  Future<List<LogEntry>> getLogsByLevel(LogLevel minLevel) async {
    final db = await database;

    final levels = LogLevel.values
        .where((l) => l.value >= minLevel.value)
        .map((l) => l.name)
        .toList();

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'level IN (${levels.map((_) => '?').join(', ')})',
      whereArgs: levels,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => LogEntry.fromMap(maps[i]));
  }

  @override
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

  @override
  Future<int> getLogCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> deleteAllLogs() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  @override
  Future<void> deleteRepository() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  /// Alias for deleteRepository (backward compatibility)
  Future<void> deleteDatabase() => deleteRepository();
}
