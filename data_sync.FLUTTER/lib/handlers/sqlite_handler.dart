import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Singleton-Handler für alle SQLite-Datenbankoperationen
/// 
/// Verwaltet die Datenbankverbindung für die gesamte App-Laufzeit.
/// Es gibt nur eine Instanz (Singleton Pattern) - verhindert mehrfaches Öffnen/Schließen.
class SqliteHandler {
  // Statische Variable - nur einmal pro App instanziiert
  static final SqliteHandler _instance = SqliteHandler._internal();
  
  // Die Datenbankverbindung (nullable, wird bei Initialisierung gesetzt)
  late Database _database;
  
  // Flag um zu überprüfen, ob die DB bereits initialisiert wurde
  bool _isInitialized = false;
  
  /// Private Konstruktor - verhindert direkte Instanzierung von außen
  /// Das ist der Kern des Singleton-Patterns
  SqliteHandler._internal();
  
  /// Öffentlicher-Konstruktor - gibt immer die gleiche Instanz zurück
  /// 
  /// Nutzung:
  /// ```dart
  /// final handler = SqliteHandler();  // Immer dieselbe Instanz
  /// ```
  factory SqliteHandler() {
    return _instance;
  }
  
  /// Lazy Initialization - initialisiert die Datenbank BEIM ERSTEN ZUGRIFF
  /// 
  /// Parameter:
  /// - [databaseName]: Der Name der DB-Datei (Standard: 'data_sync_app.db')
  ///
  /// Diese Methode wird automatisch aufgerufen, wenn die DB zum ersten Mal gebraucht wird.
  /// Der Benutzer sieht kein Loading-Screen - die App ist sofort ready.
  /// 
  /// Vorteil: Schnellerer App-Start, DB wird nur bei Bedarf geladen
  Future<void> _initialize({String databaseName = 'data_sync_app.db'}) async {
    if (_isInitialized) {
      return; // Bereits initialisiert, nichts tun
    }
    
    try {
      // Nutzt das plattformspezifische App-Datenverzeichnis statt des Benutzer-Dokumentenordners.
      final applicationSupportDirectory = await getApplicationSupportDirectory();
      await applicationSupportDirectory.create(recursive: true);
      final databasePath = join(applicationSupportDirectory.path, databaseName);
      
      // Öffne die Datenbank
      // Wenn sie nicht existiert, wird sie erstellt
      _database = await openDatabase(
        databasePath,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async => _createTables(db),
      );
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Fehler beim Initialisieren der Datenbank: $e');
    }
  }
  
  /// Callback für Datenbankerstellung
  /// 
  /// Wird automatisch aufgerufen von [initialize], wenn die DB noch nicht existiert.
  /// Ruft [createTables] auf, um alle Tabellen zu initialisieren.
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  /// Stellt sicher, dass neue Tabellen auch in bestehenden Datenbanken angelegt werden.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createTables(db);
  }
  
  /// Erstellt alle notwendigen Datenbankstrukturen
  /// 
  /// Diese Methode ist modular - kann von außen oder von [_onCreate] aufgerufen werden.
  /// Parameter [db] ermöglicht flexible Nutzung (neue DB oder bestehende DB).
  ///
  /// Erstellt:
  /// - settings Tabelle: Speichert Einstellungen (syncPath, apiUrl, etc.)
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY,
        key TEXT UNIQUE NOT NULL,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS last_sync_state (
        file_path TEXT PRIMARY KEY,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        hash_value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_modified TEXT NOT NULL
      )
    ''');
  }
  
  /// Modulare Methode zur Ausführung von SQL-Queries mit automatischer Lazy-Initialization
  /// 
  /// Diese Methode ist der Kern der Modularität. Sie führt beliebige SQL-Befehle aus
  /// und gibt optional Ergebnisse zurück.
  ///
  /// WICHTIG: Bei der ERSTEN Nutzung wird die DB automatisch initialisiert!
  /// Das passiert im Hintergrund - der User merkt es nicht.
  ///
  /// Parameter:
  /// - [query]: Die SQL-Abfrage als String (z.B. "SELECT * FROM settings WHERE key = ?")
  /// - [params]: Optionale Parameter für die Query (z.B. [['syncPath']] für Parametrisierung)
  /// - [returnResult]: Wenn true, wird das Ergebnis zurückgegeben (Standard: true für SELECT)
  ///
  /// Rückgabewert:
  /// - Bei SELECT: Liste von Maps (jeder Map = eine Zeile)
  /// - Bei INSERT/UPDATE/DELETE: Empty List (wenn returnResult=false) oder Anzahl betroffener Zeilen
  ///
  /// Beispiele:
  /// ```dart
  /// // SELECT
  /// final results = await handler.executeQuery(
  ///   'SELECT * FROM settings WHERE key = ?',
  ///   ['syncPath']
  /// );
  /// 
  /// // INSERT
  /// await handler.executeQuery(
  ///   'INSERT INTO settings (key, value) VALUES (?, ?)',
  ///   ['syncPath', '/home/user'],
  ///   returnResult: false
  /// );
  /// 
  /// // UPDATE
  /// await handler.executeQuery(
  ///   'UPDATE settings SET value = ? WHERE key = ?',
  ///   ['/new/path', 'syncPath'],
  ///   returnResult: false
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> executeQuery(
    String query, {
    List<dynamic>? params,
    bool returnResult = true,
  }) async {
    // Lazy Initialization: Wenn noch nicht initialisiert, mach das jetzt
    // Das passiert automatisch beim ersten Datenbankzugriff
    if (!_isInitialized) {
      await _initialize();
    }
    
    try {
      if (returnResult) {
        // SELECT Queries - geben Ergebnisse zurück
        final results = await _database.rawQuery(query, params);
        return results;
      } else {
        // INSERT, UPDATE und DELETE werden abhängig vom SQL-Befehl ausgeführt.
        final normalizedQuery = query.trimLeft().toUpperCase();

        if (normalizedQuery.startsWith('INSERT')) {
          await _database.rawInsert(query, params);
        } else if (normalizedQuery.startsWith('UPDATE')) {
          await _database.rawUpdate(query, params);
        } else if (normalizedQuery.startsWith('DELETE')) {
          await _database.rawDelete(query, params);
        } else {
          await _database.execute(query, params);
        }
        return [];
      }
    } catch (e) {
      throw Exception('Fehler bei der Datenbankabfrage: $e\nQuery: $query');
    }
  }
}
