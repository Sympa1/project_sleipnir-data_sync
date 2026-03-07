/// Speichert alle Sync-Einstellungen der App
/// 
/// Diese Klasse speichert die Konfiguration für die Datensynchronisation:
/// - syncPath: Der lokale Pfad zum Verzeichnis
/// - apiUrl: Die URL des Backend-Servers
///
/// Die Klasse ist immutable (unveränderlich). Um Einstellungen zu ändern,
/// muss ein neues Settings-Objekt erstellt werden.
class Settings {
  final String? syncPath;       // ? bedeutet nullable (kann null sein)
  final String? apiUrl;

  /// Erstellt eine neue Settings-Instanz
  ///
  /// Parameter:
  /// - [syncPath]: Optional. Der lokale Pfad zum Sync-Verzeichnis
  /// - [apiUrl]: Optional. Die URL der REST API
  ///
  /// Beide Parameter sind optional und können null sein.
  Settings({
    this.syncPath,
    this.apiUrl,
  });
}


/* Nutzung:
Settings()  // Beide null
Settings(syncPath: "/home/user")  // Nur syncPath gesetzt
*/
