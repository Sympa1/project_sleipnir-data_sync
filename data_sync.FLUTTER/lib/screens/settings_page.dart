import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:data_sync_flutter/models/settings.dart';
import 'package:data_sync_flutter/services/settings_service.dart';


/// Die Settings-Seite der App
/// 
/// Diese Seite ermöglicht es dem User, seine Synchronisierungseinstellungen zu konfigurieren:
/// - Sync-Verzeichnis: Der lokale Ordner, der synchronisiert werden soll
/// - API-URL: Die Adresse des Sync-Backend-Servers
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Die aktuellen Einstellungen der App
  /// 
  /// Statt zwei separate Variablen zu haben (syncPath, apiUrl),
  /// nutzen wir das Settings-Modell. Das ist sauberer und macht es
  /// einfacher, die Settings später an andere Services zu übergeben.
  Settings? settings;

  /// Diese Methode wird aufgerufen, wenn die SettingsPage erstellt wird
  /// 
  /// Sie ist Teil des StatefulWidget Lifecycle:
  /// 1. Widget erstellen → initState()
  /// 2. initState() → build()
  /// 3. build() → UI wird angezeigt
  /// 
  /// Hier laden wir die Settings aus der Datenbank.
  @override
  void initState() {
    super.initState();  // Wichtig: Immer super.initState() aufrufen!
    
    // Lade die gespeicherten Einstellungen aus der Datenbank
    _loadSettings();
  }

  /// Lädt die Einstellungen aus der Datenbank
  /// 
  /// Diese Methode fragt den SettingsService ab:
  /// - Sie ruft getAllSettings() auf
  /// - Das gibt ein Settings-Objekt mit syncPath und apiUrl zurück
  /// - Wir speichern das Objekt in der Variable 'settings'
  /// - setState() teilt Flutter mit: "Zeichne die UI mit den neuen Werten!"
  Future<void> _loadSettings() async {
    try {
      // Rufe den Service auf, um alle Einstellungen zu laden
      final loadedSettings = await SettingsService().getAllSettings();
      
      // Teile Flutter mit, dass sich die Daten geändert haben
      setState(() {
        settings = loadedSettings;
      });
      
      // Zum Debuggen: Zeige in der Konsole, was geladen wurde
      print('Settings geladen - Sync-Pfad: ${settings?.syncPath}, API-URL: ${settings?.apiUrl}');
    } catch (e) {
      // Fehlerbehandlung: Wenn das Laden fehlschlägt
      print('Fehler beim Laden der Settings: $e');
    }
  }

  /// Öffnet einen Datei-Dialog zum Auswählen eines Synchronisierungsverzeichnisses
  /// 
  /// Diese Methode wird aufgerufen, wenn der User auf "Ändern" klickt.
  /// Sie öffnet den nativen Datei-Browser des Betriebssystems (Windows/Linux/Android).
  /// 
  /// Ablauf:
  /// 1. FilePicker öffnet einen Dialog zum Ordner wählen
  /// 2. Wenn der User einen Ordner wählt: wird es in settings gespeichert
  /// 3. setState() teilt Flutter mit: "Zeichne die UI mit den neuen Werten!"
  /// 4. Der neue Pfad wird in der Datenbank gespeichert
  /// 5. Der User bekommt ein Feedback via SnackBar
  Future<void> _selectSyncDirectory() async {
    // Öffne den Datei-Dialog und warte auf das Ergebnis
    // getDirectoryPath() gibt null zurück, wenn der User "Abbrechen" klickt
    final selectedPath = await FilePicker.platform.getDirectoryPath();

    if (selectedPath != null) {
      // Der User hat einen Ordner ausgewählt
      
      // setState() wird verwendet um Flutter zu sagen:
      // "Die Daten haben sich geändert, zeichne die UI!"
      setState(() {
        // Erstelle ein neues Settings-Objekt mit dem gewählten Pfad
        // Behalte die alte API-URL (settings?.apiUrl), damit sie nicht gelöscht wird
        settings = Settings(
          syncPath: selectedPath,
          apiUrl: settings?.apiUrl,  // ← Behalte den alten Wert
        );
      });
      
      // Speichere den neuen Pfad in der Datenbank
      try {
        await SettingsService().saveSetting('syncPath', selectedPath);
        
        // Zeige dem User eine Erfolgsmeldung
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync-Verzeichnis gespeichert: $selectedPath'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Zum Debuggen: Zeige den neuen Pfad in der Konsole
        print('Sync-Pfad gespeichert: $selectedPath');
      } catch (e) {
        // Fehlerbehandlung: Wenn das Speichern fehlschlägt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        print('Fehler beim Speichern des Sync-Pfads: $e');
      }
    } else {
      // Der User hat "Abbrechen" geklickt
      print('Kein Verzeichnis ausgewählt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('📁 Sync-Verzeichnis'),
                    SizedBox(height: 10),
                    // Zeige den ausgewählten Sync-Pfad an
                    // Wenn settings null ist oder syncPath null ist, zeige einen Placeholder
                    Text(
                      settings?.syncPath ?? 'Kein Verzeichnis ausgewählt',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff01696e)
                            : Color(0xff01696e),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _selectSyncDirectory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff01696e)
                            : Color(0xffeff5f5),
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff151c1d)
                            : Color(0xff01696e),
                      ),
                      child: Text('Ändern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('🌐 API-URL'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff01696e)
                            : Color(0xffeff5f5),
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xff151c1d)
                            : Color(0xff01696e),
                      ),
                      child: Text('Ändern'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 60),
      ],
    );
  }
}
