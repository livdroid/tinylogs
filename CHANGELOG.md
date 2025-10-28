# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [1.0.0] - 2025-10-28

### Ajouté

- Première version stable de TinyLogs
- Enregistrement de logs dans une base de données SQLite locale
- Modèle de données `LogEntry` avec id, timestamp et content
- Configuration personnalisable via `TinyLogsConfig`
  - Durée de rétention des logs (par défaut 7 jours)
  - Nom de base de données personnalisable
- Méthodes de récupération des logs :
  - `getAllLogs()` : Récupère tous les logs
  - `getLogsInRange()` : Récupère les logs dans une plage de dates
  - `getLogsAround()` : Récupère les logs autour d'une date (±12h par défaut)
- Gestion automatique des anciens logs
- Méthode `cleanupOldLogs()` pour le nettoyage manuel
- Méthode `clearAllLogs()` pour supprimer tous les logs
- Méthode `getLogCount()` pour compter les logs
- Tests unitaires avec plus de 80% de couverture
- Application d'exemple complète
- Documentation complète en français
- Support pour iOS, Android et macOS

### Technique

- Utilisation de sqflite ^2.4.2
- Architecture singleton pour TinyLogs
- Index sur le timestamp pour des requêtes optimisées
- Gestion propre de l'initialisation et de la fermeture de la DB
