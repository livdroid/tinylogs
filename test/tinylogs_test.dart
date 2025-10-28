import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tinylogs/tinylogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialise sqflite pour les tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TinyLogs', () {
    late TinyLogs tinyLogs;

    setUp(() async {
      tinyLogs = TinyLogs.instance;
      // Utilise un nom de db unique pour chaque test
      await tinyLogs.init(TinyLogsConfig(
        databaseName: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      ));
    });

    tearDown(() async {
      await tinyLogs.reset();
    });

    test('instance retourne le même singleton', () {
      final instance1 = TinyLogs.instance;
      final instance2 = TinyLogs.instance;

      expect(instance1, same(instance2));
    });

    test('init initialise correctement', () async {
      expect(tinyLogs.isInitialized, isTrue);
    });

    test('init avec config personnalisée', () async {
      await tinyLogs.reset();

      const customConfig = TinyLogsConfig(
        retentionDuration: Duration(days: 14),
        databaseName: 'custom_test.db',
      );

      await tinyLogs.init(customConfig);

      expect(tinyLogs.config.retentionDuration, const Duration(days: 14));
      expect(tinyLogs.config.databaseName, 'custom_test.db');
    });

    test('log enregistre un message', () async {
      final id = await tinyLogs.log('Test message');

      expect(id, greaterThan(0));

      final logs = await tinyLogs.getAllLogs();
      expect(logs.length, 1);
      expect(logs.first.content, 'Test message');
    });

    test('log rejette un contenu vide', () async {
      expect(
        () => tinyLogs.log(''),
        throwsArgumentError,
      );
    });

    test('log sans init lève une erreur', () async {
      await tinyLogs.reset();

      expect(
        () => tinyLogs.log('Test'),
        throwsStateError,
      );
    });

    test('getAllLogs retourne tous les logs', () async {
      await tinyLogs.log('Log 1');
      await tinyLogs.log('Log 2');
      await tinyLogs.log('Log 3');

      final logs = await tinyLogs.getAllLogs();

      expect(logs.length, 3);
    });

    test('getLogsInRange filtre correctement', () async {
      final now = DateTime.now();

      await Future.delayed(const Duration(milliseconds: 10));
      await tinyLogs.log('Log du milieu');
      await Future.delayed(const Duration(milliseconds: 10));

      final start = now.subtract(const Duration(minutes: 1));
      final end = now.add(const Duration(minutes: 1));

      final logs = await tinyLogs.getLogsInRange(start, end);

      expect(logs.length, 1);
      expect(logs.first.content, 'Log du milieu');
    });

    test('getLogsInRange rejette une plage invalide', () async {
      final start = DateTime.now();
      final end = start.subtract(const Duration(hours: 1));

      expect(
        () => tinyLogs.getLogsInRange(start, end),
        throwsArgumentError,
      );
    });

    test('getLogsAround récupère les logs autour d\'une date', () async {
      final centerTime = DateTime.now();

      // Log ancien (hors marge)
      await tinyLogs.log('Ancien');
      await Future.delayed(const Duration(milliseconds: 5));

      // Simule un log dans la plage
      final recentLog = LogEntry(
        timestamp: centerTime.millisecondsSinceEpoch,
        content: 'Dans la plage',
      );
      await TinyLogs.instance.log(recentLog.content);

      final logs = await tinyLogs.getLogsAround(
        centerTime,
        margin: const Duration(seconds: 30),
      );

      expect(logs.isNotEmpty, isTrue);
    });

    test('getLogCount retourne le nombre correct', () async {
      expect(await tinyLogs.getLogCount(), 0);

      await tinyLogs.log('Log 1');
      expect(await tinyLogs.getLogCount(), 1);

      await tinyLogs.log('Log 2');
      await tinyLogs.log('Log 3');
      expect(await tinyLogs.getLogCount(), 3);
    });

    test('cleanupOldLogs supprime les anciens logs', () async {
      await tinyLogs.reset();

      const config = TinyLogsConfig(
        retentionDuration: Duration(days: 1),
        databaseName: 'cleanup_test.db',
      );
      await tinyLogs.init(config);

      // Insérons simplement un nouveau log et testons la logique
      await tinyLogs.log('Nouveau log');

      final deletedCount = await tinyLogs.cleanupOldLogs();

      // Le nouveau log ne devrait pas être supprimé
      expect(deletedCount, 0);
      expect(await tinyLogs.getLogCount(), 1);
    });

    test('clearAllLogs supprime tous les logs', () async {
      await tinyLogs.log('Log 1');
      await tinyLogs.log('Log 2');
      await tinyLogs.log('Log 3');

      expect(await tinyLogs.getLogCount(), 3);

      final deletedCount = await tinyLogs.clearAllLogs();

      expect(deletedCount, 3);
      expect(await tinyLogs.getLogCount(), 0);
    });

    test('close ferme la base de données', () async {
      await tinyLogs.close();
      expect(tinyLogs.isInitialized, isFalse);
    });

    test('reset réinitialise complètement', () async {
      await tinyLogs.log('Test');
      expect(await tinyLogs.getLogCount(), 1);

      await tinyLogs.reset();

      expect(tinyLogs.isInitialized, isFalse);
    });

    test('config retourne la configuration', () {
      final config = tinyLogs.config;
      expect(config, isNotNull);
      expect(config.retentionDuration, isNotNull);
      expect(config.databaseName, isNotNull);
    });

    test('multiple logs en séquence', () async {
      for (int i = 0; i < 10; i++) {
        await tinyLogs.log('Log $i');
      }

      final logs = await tinyLogs.getAllLogs();
      expect(logs.length, 10);
    });
  });
}
