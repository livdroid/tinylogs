import 'package:flutter_test/flutter_test.dart';
import 'package:tinylogs/src/config/tinylogs_config.dart';

void main() {
  group('TinyLogsConfig', () {
    test('utilise les valeurs par défaut', () {
      const config = TinyLogsConfig();

      expect(config.retentionDuration, const Duration(days: 7));
      expect(config.databaseName, 'tinylogs.db');
    });

    test('accepte une durée de rétention personnalisée', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(days: 30),
      );

      expect(config.retentionDuration, const Duration(days: 30));
    });

    test('accepte un nom de base de données personnalisé', () {
      const config = TinyLogsConfig(
        databaseName: 'custom_logs.db',
      );

      expect(config.databaseName, 'custom_logs.db');
    });

    test('accepte tous les paramètres personnalisés', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(hours: 48),
        databaseName: 'my_app_logs.db',
      );

      expect(config.retentionDuration, const Duration(hours: 48));
      expect(config.databaseName, 'my_app_logs.db');
    });

    test('accepte une durée de rétention nulle ou négative à la construction',
        () {
      // La validation se fait à l'init, pas à la construction
      const config1 = TinyLogsConfig(retentionDuration: Duration.zero);
      expect(config1.retentionDuration, Duration.zero);

      const config2 = TinyLogsConfig(retentionDuration: Duration(days: -1));
      expect(config2.retentionDuration, const Duration(days: -1));
    });

    test('toString retourne une représentation lisible', () {
      const config = TinyLogsConfig(
        retentionDuration: Duration(days: 14),
        databaseName: 'test.db',
      );

      final str = config.toString();

      expect(str, contains('retentionDuration'));
      expect(str, contains('databaseName'));
    });
  });
}
