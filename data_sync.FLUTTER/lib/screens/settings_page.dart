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

  /// Öffnet einen Dialog zum Eingeben der API-URL
  ///
  /// Ablauf:
  /// 1. AlertDialog mit TextField öffnen (vorbefüllt mit aktueller URL)
  /// 2. User gibt URL ein und klickt "Speichern"
  /// 3. setState() → UI aktualisiert sich
  /// 4. URL wird in der Datenbank gespeichert
  /// 5. Feedback via SnackBar
  Future<void> _enterApiUrl() async {
    // Controller hält den Text im TextField – so können wir ihn später auslesen
    final controller = TextEditingController(text: settings?.apiUrl ?? '');

    final enteredUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API-URL eingeben'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'z.B. https://mein-server.de/api',
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Abbrechen → null zurückgeben
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()), // Wert zurückgeben
            child: Text('Speichern'),
          ),
        ],
      ),
    );

    // Dialog wurde mit "Abbrechen" geschlossen oder URL ist leer
    if (enteredUrl == null || enteredUrl.isEmpty) return;

    setState(() {
      settings = Settings(
        syncPath: settings?.syncPath,
        apiUrl: enteredUrl,
      );
    });

    try {
      await SettingsService().saveSetting('apiUrl', enteredUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API-URL gespeichert: $enteredUrl'),
          duration: Duration(seconds: 2),
        ),
      );

      print('API-URL gespeichert: $enteredUrl');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      print('Fehler beim Speichern der API-URL: $e');
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
    return ListView(
      children: [
        // Abschnitt: Verbindung
        _SectionHeader(label: 'Verbindung'),
        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: const Text('API-URL'),
          subtitle: Text(
            settings?.apiUrl ?? 'Nicht gesetzt',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _enterApiUrl,
        ),
        const Divider(indent: 56),

        // Abschnitt: Dateisystem
        _SectionHeader(label: 'Dateisystem'),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Sync-Verzeichnis'),
          subtitle: Text(
            settings?.syncPath ?? 'Kein Verzeichnis ausgewählt',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectSyncDirectory,
        ),
      ],
    );
  }
}

/// Abschnitts-Überschrift für die Einstellungsseite
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
