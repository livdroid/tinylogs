import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinylogs/src/database/database_helper.dart';
import 'package:tinylogs/src/models/log_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialise sqflite pour les tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper(
          databaseName:
              'test_logs_${DateTime.now().millisecondsSinceEpoch}.db');
    });

    tearDown(() async {
      await dbHelper.deleteDatabase();
    });

    test('insère un log et le récupère', () async {
      final log = LogEntry.now('Test log');
      final id = await dbHelper.insertLog(log);

      expect(id, greaterThan(0));

      final logs = await dbHelper.getAllLogs();
      expect(logs.length, 1);
      expect(logs.first.content, 'Test log');
      expect(logs.first.id, id);
    });

    test('insère plusieurs logs', () async {
      await dbHelper.insertLog(LogEntry.now('Log 1'));
      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));

      final logs = await dbHelper.getAllLogs();
      expect(logs.length, 3);
    });

    test('getAllLogs retourne les logs triés par timestamp décroissant',
        () async {
      final log1 = LogEntry(
        timestamp: DateTime.now()
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        content: 'Ancien',
      );
      final log2 = LogEntry(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        content: 'Récent',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);

      final logs = await dbHelper.getAllLogs();
      expect(logs.first.content, 'Récent');
      expect(logs.last.content, 'Ancien');
    });

    test('getLogsInRange récupère les logs dans la plage', () async {
      final now = DateTime.now();
      final log1 = LogEntry(
        timestamp:
            now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        content: 'Avant plage',
      );
      final log2 = LogEntry(
        timestamp:
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        content: 'Dans plage',
      );
      final log3 = LogEntry(
        timestamp: now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        content: 'Après plage',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);

      final startTime =
          now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      final endTime = now.millisecondsSinceEpoch;

      final logs = await dbHelper.getLogsInRange(startTime, endTime);

      expect(logs.length, 1);
      expect(logs.first.content, 'Dans plage');
    });

    test('getLogsAround récupère les logs autour d\'une date', () async {
      final centerTime = DateTime.now();

      final log1 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 15))
            .millisecondsSinceEpoch,
        content: 'Trop ancien',
      );
      final log2 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 6))
            .millisecondsSinceEpoch,
        content: 'Avant centre',
      );
      final log3 = LogEntry(
        timestamp: centerTime.millisecondsSinceEpoch,
        content: 'Centre',
      );
      final log4 = LogEntry(
        timestamp:
            centerTime.add(const Duration(hours: 6)).millisecondsSinceEpoch,
        content: 'Après centre',
      );
      final log5 = LogEntry(
        timestamp:
            centerTime.add(const Duration(hours: 15)).millisecondsSinceEpoch,
        content: 'Trop récent',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);
      await dbHelper.insertLog(log4);
      await dbHelper.insertLog(log5);

      final logs = await dbHelper.getLogsAround(centerTime);

      expect(logs.length, 3);
      expect(logs.any((log) => log.content == 'Avant centre'), isTrue);
      expect(logs.any((log) => log.content == 'Centre'), isTrue);
      expect(logs.any((log) => log.content == 'Après centre'), isTrue);
      expect(logs.any((log) => log.content == 'Trop ancien'), isFalse);
      expect(logs.any((log) => log.content == 'Trop récent'), isFalse);
    });

    test('getLogsAround accepte une marge personnalisée', () async {
      final centerTime = DateTime.now();

      final log1 = LogEntry(
        timestamp: centerTime
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        content: 'Trop ancien',
      );
      final log2 = LogEntry(
        timestamp: centerTime.millisecondsSinceEpoch,
        content: 'Centre',
      );
      final log3 = LogEntry(
        timestamp:
            centerTime.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
        content: 'Proche',
      );

      await dbHelper.insertLog(log1);
      await dbHelper.insertLog(log2);
      await dbHelper.insertLog(log3);

      final logs = await dbHelper.getLogsAround(
        centerTime,
        margin: const Duration(hours: 1),
      );

      expect(logs.length, 2);
      expect(logs.any((log) => log.content == 'Centre'), isTrue);
      expect(logs.any((log) => log.content == 'Proche'), isTrue);
      expect(logs.any((log) => log.content == 'Trop ancien'), isFalse);
    });

    test('deleteOldLogs supprime les anciens logs', () async {
      final now = DateTime.now();
      final oldLog = LogEntry(
        timestamp:
            now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
        content: 'Ancien',
      );
      final recentLog = LogEntry(
        timestamp: now.millisecondsSinceEpoch,
        content: 'Récent',
      );

      await dbHelper.insertLog(oldLog);
      await dbHelper.insertLog(recentLog);

      final deletedCount =
          await dbHelper.deleteOldLogs(const Duration(days: 7));

      expect(deletedCount, 1);

      final remainingLogs = await dbHelper.getAllLogs();
      expect(remainingLogs.length, 1);
      expect(remainingLogs.first.content, 'Récent');
    });

    test('getLogCount retourne le nombre correct de logs', () async {
      expect(await dbHelper.getLogCount(), 0);

      await dbHelper.insertLog(LogEntry.now('Log 1'));
      expect(await dbHelper.getLogCount(), 1);

      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));
      expect(await dbHelper.getLogCount(), 3);
    });

    test('deleteAllLogs supprime tous les logs', () async {
      await dbHelper.insertLog(LogEntry.now('Log 1'));
      await dbHelper.insertLog(LogEntry.now('Log 2'));
      await dbHelper.insertLog(LogEntry.now('Log 3'));

      final deletedCount = await dbHelper.deleteAllLogs();

      expect(deletedCount, 3);
      expect(await dbHelper.getLogCount(), 0);
    });

    test('close ferme la base de données', () async {
      await dbHelper.database; // Initialise la db
      await dbHelper.close();

      // Après close, accéder à database devrait réinitialiser
      final db = await dbHelper.database;
      expect(db, isNotNull);
    });
  });
}
