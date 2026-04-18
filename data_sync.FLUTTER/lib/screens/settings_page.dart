import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:data_sync_flutter/models/settings.dart';
import 'package:data_sync_flutter/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isLoading = true;

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
    super.initState(); // Wichtig: Immer super.initState() aufrufen!

    // Lade die gespeicherten Einstellungen aus der Datenbank
    _loadSettings();
  }

  /// Lädt die gespeicherten Einstellungen und aktualisiert den Ladezustand.
  Future<void> _loadSettings() async {
    try {
      // Rufe den Service auf, um alle Einstellungen zu laden
      final loadedSettings = await SettingsService().getAllSettings();

      // Verhindert setState nach dispose.
      if (!mounted) {
        return;
      }

      // Teile Flutter mit, dass sich die Daten geändert haben
      setState(() {
        settings = loadedSettings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Einstellungen konnten nicht geladen werden.', isError: true);
    }
  }

  /// Öffnet einen Dialog zur Bearbeitung der API-URL.
  Future<void> _enterApiUrl() async {
    // Vorbelegung mit dem aktuell gespeicherten Wert.
    final controller = TextEditingController(text: settings?.apiUrl ?? '');

    final enteredUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API-URL eingeben'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'z.B. http://localhost:5009 oder https://mein-server.de/api',
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

    if (!mounted) {
      return;
    }

    // Abbruch oder leere Eingabe erzeugen keine Änderung.
    if (enteredUrl == null || enteredUrl.isEmpty) return;

    // Akzeptiert nur vollständige HTTP- oder HTTPS-Adressen.
    if (!_isValidApiUrl(enteredUrl)) {
      _showMessage('Bitte gib eine gueltige API-URL ein.', isError: true);
      return;
    }

      setState(() {
        settings = Settings(
          syncPath: settings?.syncPath,
          apiUrl: enteredUrl,
          allowInsecureTlsForLocalhost:
              settings?.allowInsecureTlsForLocalhost ?? false,
        );
      });

    try {
      await SettingsService().saveSetting('apiUrl', enteredUrl);

      if (!mounted) {
        return;
      }

      _showMessage('API-URL gespeichert.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('API-URL konnte nicht gespeichert werden.', isError: true);
    }
  }

  /// Öffnet den Dialog zur Auswahl des lokalen Sync-Verzeichnisses.
  Future<void> _selectSyncDirectory() async {
    try {
      if (Platform.isAndroid) {
        await _ensureAndroidFileAccess();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(e.toString(), isError: true);
      return;
    }

    final selectedPath = await FilePicker.platform.getDirectoryPath();

    // Abbruch oder dispose erzeugen keine Änderung.
    if (!mounted || selectedPath == null) {
      return;
    }

      setState(() {
        // Übernimmt den neuen Pfad und behält die übrigen Werte bei.
        settings = Settings(
          syncPath: selectedPath,
          apiUrl: settings?.apiUrl,
          allowInsecureTlsForLocalhost:
              settings?.allowInsecureTlsForLocalhost ?? false,
        );
      });

    // Speichere den neuen Pfad in der Datenbank
    try {
      await SettingsService().saveSetting('syncPath', selectedPath);

      if (!mounted) {
        return;
      }

      _showMessage(
        Platform.isAndroid
            ? 'Sync-Verzeichnis gespeichert. Auf Android sollte das ein sichtbarer Ordner wie Documents/data_sync sein.'
            : 'Sync-Verzeichnis gespeichert.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Sync-Verzeichnis konnte nicht gespeichert werden.',
        isError: true,
      );
    }
  }

  /// Fordert auf Android den Vollzugriff auf den gemeinsamen Speicher an.
  Future<void> _ensureAndroidFileAccess() async {
    final currentStatus = await Permission.manageExternalStorage.status;

    if (currentStatus.isGranted) {
      return;
    }

    final requestedStatus = await Permission.manageExternalStorage.request();

    if (requestedStatus.isGranted) {
      return;
    }

    throw Exception(
      'Android braucht "Alle Dateien verwalten", damit ein sichtbarer Ordner '
      'wie Documents/data_sync voll synchronisiert werden kann. Bitte die '
      'Berechtigung erlauben und das Verzeichnis danach erneut auswaehlen.',
    );
  }

  /// Prüft auf eine vollständige HTTP- oder HTTPS-URL.
  bool _isValidApiUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Speichert, ob lokale HTTPS-Zertifikate fuer localhost akzeptiert werden.
  Future<void> _toggleLocalhostCertificateOverride(bool value) async {
    final currentSettings = settings ?? Settings();

    setState(() {
      settings = Settings(
        syncPath: currentSettings.syncPath,
        apiUrl: currentSettings.apiUrl,
        allowInsecureTlsForLocalhost: value,
      );
    });

    try {
      await SettingsService().saveSetting(
        'allowInsecureTlsForLocalhost',
        value.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        value
            ? 'Lokale HTTPS-Zertifikate fuer localhost sind aktiviert.'
            : 'Lokale HTTPS-Zertifikate fuer localhost sind deaktiviert.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        settings = Settings(
          syncPath: currentSettings.syncPath,
          apiUrl: currentSettings.apiUrl,
          allowInsecureTlsForLocalhost:
              currentSettings.allowInsecureTlsForLocalhost,
        );
      });

      _showMessage(
        'Die TLS-Einstellung konnte nicht gespeichert werden.',
        isError: true,
      );
    }
  }

  /// Zeigt eine einheitliche Rückmeldung für Erfolg oder Fehler.
  void _showMessage(String message, {bool isError = false}) {
    final backgroundColor = isError
        ? Theme.of(context).colorScheme.error
        : null;
    final foregroundColor = isError
        ? Theme.of(context).colorScheme.onError
        : null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: isError
            ? SnackBarAction(
                label: 'Schliessen',
                textColor: foregroundColor,
                onPressed: () {},
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usesAndroidSharedDirectory = Platform.isAndroid;
    // Beide Werte bestimmen den Einrichtungsstand im Kopfbereich.
    final hasApiUrl = settings?.apiUrl?.isNotEmpty ?? false;
    final hasSyncPath = settings?.syncPath?.isNotEmpty ?? false;
    final completedSteps = (hasApiUrl ? 1 : 0) + (hasSyncPath ? 1 : 0);

    return ListView(
      // Hält Abstand zur unteren Navigation.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // Fasst Einrichtungsstand und kurze Einordnung zusammen.
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.settings_suggest_outlined),
                  ),
                  const Spacer(),
                  _StatusChip(
                    label: '$completedSteps von 2 fertig',
                    isComplete: completedSteps == 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Alles Wichtige an einem Ort',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hier richtest du die Verbindung zum Backend und dein lokales Sync-Verzeichnis ein. Sobald beides gesetzt ist, ist die App bereit fuer den ersten echten Lauf.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _OverviewRow(
                icon: Icons.language_outlined,
                title: 'API-URL',
                isComplete: hasApiUrl,
              ),
              const SizedBox(height: 12),
              _OverviewRow(
                icon: Icons.folder_outlined,
                title: 'Sync-Verzeichnis',
                isComplete: hasSyncPath,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Enthält die bearbeitbaren Einstellungen.
        Text(
          'Konfiguration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _SettingCard(
          icon: Icons.language_outlined,
          title: 'API-URL',
          value: settings?.apiUrl ?? 'Noch keine Adresse hinterlegt',
          description:
              'Die Android-App nutzt diese Adresse spaeter fuer Upload, Download und den Manifest-Abgleich.',
          actionLabel: hasApiUrl ? 'Adresse aendern' : 'Adresse eintragen',
          isComplete: hasApiUrl,
          isLoading: _isLoading,
          onTap: _enterApiUrl,
        ),
        const SizedBox(height: 12),
        _SettingCard(
          icon: Icons.folder_outlined,
          title: 'Sync-Verzeichnis',
          value: settings?.syncPath ?? 'Noch kein Verzeichnis ausgewaehlt',
          description:
              usesAndroidSharedDirectory
                  ? 'Auf Android kannst du mit der zusaetzlichen Berechtigung einen sichtbaren Ordner wie Documents/data_sync verwenden. So bleiben die Dateien ausserhalb der App auffindbar.'
                  : 'Dieser Ordner ist die lokale Quelle fuer Dateien, die hoch- oder heruntergeladen werden sollen.',
          actionLabel: usesAndroidSharedDirectory
              ? (hasSyncPath
                    ? 'Sichtbaren Ordner aendern'
                    : 'Sichtbaren Ordner waehlen')
              : (hasSyncPath
                    ? 'Verzeichnis aendern'
                    : 'Verzeichnis waehlen'),
          isComplete: hasSyncPath,
          isLoading: _isLoading,
          onTap: _selectSyncDirectory,
        ),
        const SizedBox(height: 12),
        _ToggleSettingCard(
          icon: Icons.https_outlined,
          title: 'Lokale HTTPS-Zertifikate erlauben',
          description:
              'Erlaubt fuer https://localhost und https://127.0.0.1 auch selbstsignierte Zertifikate. Fuer die Entwicklung ist sonst meist http://localhost:5009 die einfachere Wahl.',
          value: settings?.allowInsecureTlsForLocalhost ?? false,
          isLoading: _isLoading,
          onChanged: _toggleLocalhostCertificateOverride,
        ),
      ],
    );
  }
}

/// Zeigt den Einrichtungsstatus einer einzelnen Voraussetzung.
class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.isComplete,
  });

  final IconData icon;
  final String title;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _StatusChip(
          label: isComplete ? 'Fertig' : 'Offen',
          isComplete: isComplete,
        ),
      ],
    );
  }
}

/// Visuell hervorgehobene Karte fuer eine einzelne Einstellung.
class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.actionLabel,
    required this.isComplete,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final String actionLabel;
  final bool isComplete;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _StatusChip(
                          label: isComplete ? 'Eingerichtet' : 'Noch offen',
                          isComplete: isComplete,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isLoading ? 'Wird geladen ...' : actionLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isLoading
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Schalterkarte fuer boolesche Einstellungen.
class _ToggleSettingCard extends StatelessWidget {
  const _ToggleSettingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: isLoading ? null : onChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value ? 'Aktiviert' : 'Deaktiviert',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kleine Statusanzeige fuer Karten und Uebersichten.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isComplete,
  });

  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isComplete
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isComplete
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
