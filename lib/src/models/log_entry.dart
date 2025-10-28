/// Modèle représentant une entrée de log
class LogEntry {
  /// Identifiant unique auto-généré
  final int? id;

  /// Horodatage de la création du log (en millisecondes depuis l'epoch)
  final int timestamp;

  /// Contenu du log (non null)
  final String content;

  LogEntry({
    this.id,
    required this.timestamp,
    required this.content,
  }) : assert(content.isNotEmpty, 'Le contenu ne peut pas être vide');

  /// Crée un LogEntry avec un timestamp automatique
  factory LogEntry.now(String content) {
    return LogEntry(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      content: content,
    );
  }

  /// Convertit le LogEntry en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'content': content,
    };
  }

  /// Crée un LogEntry depuis une Map SQLite
  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int?,
      timestamp: map['timestamp'] as int,
      content: map['content'] as String,
    );
  }

  /// Retourne la DateTime correspondant au timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'LogEntry{id: $id, timestamp: $timestamp (${dateTime.toIso8601String()}), content: $content}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          content == other.content;

  @override
  int get hashCode => id.hashCode ^ timestamp.hashCode ^ content.hashCode;

  /// Copie le LogEntry avec des modifications optionnelles
  LogEntry copyWith({
    int? id,
    int? timestamp,
    String? content,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      content: content ?? this.content,
    );
  }
}
