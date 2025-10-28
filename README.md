# TinyLogs 📝

Un package Flutter simple et rapide pour logger des informations dans une base de données SQLite locale avec gestion automatique de l'historique.

## Caractéristiques

- **Stockage local** : Utilise SQLite via sqflite
- **Gestion automatique** : Nettoyage automatique des anciens logs
- **Recherche flexible** : Récupération de logs par plage de dates ou autour d'une date précise
- **Multi-plateforme** : Supporte iOS, Android, macOS (et autres plateformes compatibles avec sqflite)
- **Testé** : Plus de 95% de couverture de tests

## Utilisation de base

### Initialisation

Initialisez TinyLogs au démarrage de votre application :

```dart
import 'package:tinylogs/tinylogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation avec configuration par défaut (7 jours de rétention)
  await TinyLogs.instance.init();
  
  runApp(MyApp());
}
```

### Configuration personnalisée

Vous pouvez personnaliser la durée de rétention des logs et le nom de la base de données :

```dart
await TinyLogs.instance.init(
  const TinyLogsConfig(
    retentionDuration: Duration(days: 30), // Garde les logs pendant 30 jours
    databaseName: 'my_app_logs.db',       // Nom personnalisé de la DB
  ),
);
```

### Enregistrer un log

```dart
await TinyLogs.instance.log('Utilisateur connecté');
await TinyLogs.instance.log('Erreur lors du chargement des données');
```

### Récupérer tous les logs

```dart
final logs = await TinyLogs.instance.getAllLogs();

for (final log in logs) {
  print('${log.id}: ${log.content} - ${log.dateTime}');
}
```

### Récupérer les logs dans une plage de dates

```dart
final now = DateTime.now();
final yesterday = now.subtract(Duration(days: 1));

final logs = await TinyLogs.instance.getLogsInRange(yesterday, now);
```

### Récupérer les logs autour d'une date précise

Par défaut, récupère les logs ±12 heures autour de la date :

```dart
final specificTime = DateTime(2024, 10, 15, 14, 30);
final logs = await TinyLogs.instance.getLogsAround(specificTime);
```

Vous pouvez personnaliser la marge :

```dart
final logs = await TinyLogs.instance.getLogsAround(
  specificTime,
  margin: Duration(hours: 6), // ±6 heures
);
```

### Nettoyer les anciens logs

Le nettoyage est automatique au démarrage, mais vous pouvez aussi le faire manuellement :

```dart
final deletedCount = await TinyLogs.instance.cleanupOldLogs();
print('$deletedCount anciens logs supprimés');
```

### Compter les logs

```dart
final count = await TinyLogs.instance.getLogCount();
print('Nombre total de logs : $count');
```

### Supprimer tous les logs

```dart
await TinyLogs.instance.clearAllLogs();
```

## Modèle de données

Chaque log contient :

- `id` : Identifiant unique auto-généré (int)
- `timestamp` : Horodatage en millisecondes depuis l'epoch (int)
- `content` : Contenu du log (String, non null)

```dart
class LogEntry {
  final int? id;
  final int timestamp;
  final String content;
  
  DateTime get dateTime; // Conversion automatique du timestamp
}
```

## Configuration

### TinyLogsConfig

```dart
const TinyLogsConfig({
  Duration retentionDuration = const Duration(days: 7),  // Durée de conservation
  String databaseName = 'tinylogs.db',                   // Nom de la base de données
});
```

## Exemple complet

Consultez le dossier [`example/`](example/) pour une application complète démontrant toutes les fonctionnalités.

Pour exécuter l'exemple :

```bash
cd example
flutter run
```

## Plateforme supportées

- ✅ iOS
- ✅ Android
- ✅ macOS

## Licence

Ce projet est sous licence BSD-2-Clause. Voir le fichier [LICENSE](LICENSE) pour plus de détails.
