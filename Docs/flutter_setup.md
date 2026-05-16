# Flutter App – Einrichtung & Verwendung

## Überblick

Die Flutter-App ermöglicht die manuelle Synchronisation von Dateien über die Data Sync REST API. Sie läuft auf Android, Linux und Windows.

> **Hinweis:** Das Caddy-Zertifikat wird **nur für die Flutter App** (und andere Web-/App-Clients) benötigt. Das Python CLI Tool verbindet sich direkt über HTTP oder mit deaktivierter SSL-Prüfung.

---

## Voraussetzungen

- Flutter SDK (siehe [flutter.dev](https://flutter.dev/docs/get-started/install))
- Eine laufende Data Sync API (lokal oder auf einem Server im selben Netzwerk)
- Android-Gerät oder Emulator (für Android-Build)

---

## App bauen & installieren

### Debug-Build (Entwicklung)

```bash
cd data_sync.FLUTTER
flutter run
```

### Release-APK für Android

```bash
cd data_sync.FLUTTER
flutter build apk --release
```

Die fertige APK liegt danach unter:

```
data_sync.FLUTTER/build/app/outputs/flutter-apk/app-release.apk
```

Die APK kann per Datei-Transfer auf das Gerät übertragen und dort installiert werden.

---

## Einstellungen in der App

Nach dem ersten Start die API-URL in den **Einstellungen** eintragen:

| Protokoll | Beispiel-URL |
|-----------|-------------|
| HTTP | `http://<server-ip>:5000` |
| HTTPS | `https://<server-ip>:5001` |

Die Ports sind in `data_sync.API/compose.yaml` über `CADDY_HTTP_PORT` und `CADDY_HTTPS_PORT` konfiguriert.

> Die App ergänzt `/api/sync` automatisch – die Basis-URL ohne Pfad eintragen.

---

## HTTPS einrichten (Caddy-Zertifikat auf Android installieren)

Damit Android dem selbst-signierten Caddy-Zertifikat vertraut, muss das Root-Zertifikat einmalig auf dem Gerät installiert werden.

### Schritt 1 – Zertifikat exportieren (auf dem Server)

```bash
docker exec data-sync-caddy cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt
```

### Schritt 2 – Zertifikat auf Android übertragen

Das Zertifikat auf das Gerät übertragen (z. B. per ADB oder E-Mail).

### Schritt 3 – Zertifikat auf Android installieren

1. Die Datei `caddy-root.crt` im Datei-Manager antippen
2. Android fragt: **„Zertifikat installieren?"** → **CA-Zertifikat** wählen
3. Sicherheits-PIN oder Fingerabdruck bestätigen
4. Namen vergeben (z. B. `Caddy Local CA`) → **OK**

Falls der Tap nicht funktioniert, manuell über:

```
Einstellungen → Sicherheit → Mehr Sicherheitseinstellungen → Zertifikate installieren → CA-Zertifikat
```

### Schritt 4 – HTTPS in der App testen

In den App-Einstellungen die HTTPS-URL eintragen:

```
https://<server-ip>:5001
```

> Das Zertifikat wird von Caddy beim ersten Start einmalig generiert und im Docker-Volume `caddy_data` dauerhaft gespeichert.
> Es muss nur **einmal** auf dem Gerät installiert werden. Eine Neuinstallation ist nur nötig, wenn das Volume explizit gelöscht wird (`docker volume rm caddy_data` oder `docker compose down -v`).

---

## Fehlerbehebung

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `WRONG_VERSION_NUMBER` | HTTPS-URL zeigt auf HTTP-Port | Port prüfen: HTTP=5000, HTTPS=5001 |
| `HandshakeException` | Zertifikat nicht vertraut | Zertifikat installieren (siehe oben) |
| `No route to host` | Smartphone im falschen Netzwerk | WLAN prüfen, Router-Isolation ausschließen |
| `404 Not Found` | Falsche URL oder kein Pfad | URL ohne `/api/sync` eintragen |
| `Connection refused` | API-Container läuft nicht | `docker ps` auf dem Server prüfen |
