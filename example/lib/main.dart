import 'package:flutter/material.dart';
import 'package:tinylogs/tinylogs.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise TinyLogs avec une configuration personnalisée
  await TinyLogs.instance.init(
    const TinyLogsConfig(
      retentionDuration: Duration(days: 30), // Garde les logs pendant 30 jours
      databaseName: 'example_logs.db',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyLogs Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LogsHomePage(),
    );
  }
}

class LogsHomePage extends StatefulWidget {
  const LogsHomePage({super.key});

  @override
  State<LogsHomePage> createState() => _LogsHomePageState();
}

class _LogsHomePageState extends State<LogsHomePage> {
  final TextEditingController _logController = TextEditingController();
  List<LogEntry> _logs = [];
  int _logCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _logController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await TinyLogs.instance.getAllLogs();
      final count = await TinyLogs.instance.getLogCount();

      setState(() {
        _logs = logs;
        _logCount = count;
      });
    } catch (e) {
      _showSnackBar('Erreur lors du chargement: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addLog() async {
    if (_logController.text.trim().isEmpty) {
      _showSnackBar('Le contenu ne peut pas être vide', isError: true);
      return;
    }

    try {
      await TinyLogs.instance.log(_logController.text.trim());
      _logController.clear();
      _showSnackBar('Log enregistré avec succès');
      await _loadLogs();
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _getLogsAround() async {
    final now = DateTime.now();

    try {
      final logs = await TinyLogs.instance.getLogsAround(now);

      setState(() => _logs = logs);

      _showSnackBar(
          '${logs.length} log(s) trouvé(s) dans les 12h autour de maintenant');
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _getLogsFromLastHour() async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    try {
      final logs = await TinyLogs.instance.getLogsInRange(oneHourAgo, now);

      setState(() => _logs = logs);

      _showSnackBar('${logs.length} log(s) de la dernière heure');
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _clearAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer tous les logs ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final count = await TinyLogs.instance.clearAllLogs();
        _showSnackBar('$count log(s) supprimé(s)');
        await _loadLogs();
      } catch (e) {
        _showSnackBar('Erreur: $e', isError: true);
      }
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      final count = await TinyLogs.instance.cleanupOldLogs();
      _showSnackBar('$count ancien(s) log(s) supprimé(s)');
      await _loadLogs();
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TinyLogs Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'around':
                  _getLogsAround();
                  break;
                case 'lastHour':
                  _getLogsFromLastHour();
                  break;
                case 'cleanup':
                  _cleanupOldLogs();
                  break;
                case 'clear':
                  _clearAllLogs();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'around',
                child: Text('Logs autour de maintenant (±12h)'),
              ),
              const PopupMenuItem(
                value: 'lastHour',
                child: Text('Logs de la dernière heure'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'cleanup',
                child: Text('Nettoyer les anciens logs'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child:
                    Text('Tout supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'ajout de log
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _logController,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau log',
                    hintText: 'Entrez le contenu du log...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSubmitted: (_) => _addLog(),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addLog,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un log'),
                ),
              ],
            ),
          ),

          // Compteur de logs
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blue[50],
            child: Text(
              'Total: $_logCount log(s)',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),

          // Liste des logs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun log.\nAjoutez-en un pour commencer !',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${log.id}'),
                              ),
                              title: Text(log.content),
                              subtitle: Text(_formatTimestamp(log.timestamp)),
                              trailing: Icon(
                                Icons.article,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
