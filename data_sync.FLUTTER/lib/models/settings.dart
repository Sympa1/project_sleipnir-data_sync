/// Speichert alle Sync-Einstellungen der App
/// 
/// Diese Klasse speichert die Konfiguration für die Datensynchronisation:
/// - syncPath: Der lokale Pfad zum Verzeichnis
/// - apiUrl: Die URL des Backend-Servers
/// - allowInsecureTlsForLocalhost: Erlaubt lokale HTTPS-Zertifikate fuer localhost
///
/// Die Klasse ist immutable (unveränderlich). Um Einstellungen zu ändern,
/// muss ein neues Settings-Objekt erstellt werden.
class Settings {
  final String? syncPath;       // ? bedeutet nullable (kann null sein)
  final String? apiUrl;
  final bool allowInsecureTlsForLocalhost;

  /// Erstellt eine neue Settings-Instanz
  ///
  /// Parameter:
  /// - [syncPath]: Optional. Der lokale Pfad zum Sync-Verzeichnis
  /// - [apiUrl]: Optional. Die URL der REST API
  /// - [allowInsecureTlsForLocalhost]: Optional. Erlaubt selbstsignierte lokale Zertifikate
  ///
  /// syncPath und apiUrl sind optional und können null sein.
  Settings({
    this.syncPath,
    this.apiUrl,
    this.allowInsecureTlsForLocalhost = false,
  });
}


/* Nutzung:
Settings()  // Beide null
Settings(syncPath: "/home/user")  // Nur syncPath gesetzt
*/
