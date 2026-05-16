# App Icon Generierung und Verwaltung

Eine Anleitung zur Erstellung und Aktualisierung von App Icons in Flutter.

## Überblick

App Icons werden in Flutter nicht zur Laufzeit (dynamisch) geladen, sondern beim **Build-Prozess** (zur Compile-Zeit) in die App integriert. Das bedeutet: Wenn du ein Icon änderst, muss die App **neu gebaut** werden, damit die Änderung sichtbar wird.

---

## Tool: flutter_launcher_icons

Unser Projekt nutzt das Package `flutter_launcher_icons`, das automatisch Icons für verschiedene Plattformen (iOS, Android, Web) aus einer Quellgrafik generiert.

**Warum ist das sinnvoll?**
- ✅ Ein Bild als Quelle, mehrere Plattformen als Output
- ✅ Automatische Skalierung für verschiedene Auflösungen
- ✅ Konsistente Icons über alle Plattformen hinweg
- ✅ Spart Zeit beim Erstellen verschiedener Größen

---

## Konfiguration (pubspec.yaml)

Die Icon-Einstellungen befinden sich in der `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  image_path: "img/final.png"           # Pfad zur Quellgrafik (PNG empfohlen)
  android: true                          # Icons für Android generieren
  ios: true                              # Icons für iOS generieren
  web: true                              # Icons für Web generieren
```

**Wichtig:**
- Die Quellgrafik muss mindestens **1024x1024 Pixel** groß sein
- Das Format sollte PNG sein
- Das Bild sollte quadratisch sein (1:1 Seitenverhältnis)

---

## Schritt-für-Schritt Anleitung

### 1. Neues Icon vorbereiten

Ersetze die aktuelle Icon-Datei (`img/final.png`) mit deinem neuen Icon:

```bash
# Beispiel: Neues Icon hochladen/ersetzen
# Stelle sicher, dass die Datei 1024x1024 Pixel oder größer ist
cp /pfad/zu/deinem/icon.png data_sync.FLUTTER/img/final.png
```

**Anforderungen an das Bild:**
- Mindestens 1024×1024 Pixel
- Format: PNG (mit oder ohne transparenter Hintergrund)
- Seitenverhältnis: 1:1 (quadratisch)

### 2. Icons generieren lassen

Führe den Flutter Launcher Icons Generator aus:

```bash
cd data_sync.FLUTTER
flutter pub run flutter_launcher_icons
```

Das Skript generiert automatisch Icons in allen benötigten Größen und speichert sie in den richtigen Verzeichnissen:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (iOS)
- `android/app/src/main/res/` (Android, verschiedene dpi-Ordner)
- `web/` (Web-Icons)

### 3. App neu bauen (wichtig!)

**Ohne den Rebuild wird die App die neuen Icons NICHT übernehmen!**

Je nach Zielplattform:

**Web-Version:**
```bash
cd data_sync.FLUTTER
flutter build web --release
```

**Android-Version:**
```bash
cd data_sync.FLUTTER
flutter build apk --release
```

**iOS-Version:**
```bash
cd data_sync.FLUTTER
flutter build ios --release
```

**Während der Entwicklung (mit Cache-Leerung):**
```bash
cd data_sync.FLUTTER
flutter clean
flutter pub get
flutter run --no-cache
```

---

## Kompletter Workflow (schnelle Referenz)

```bash
# 1. In das Flutter-Projekt navigieren
cd data_sync.FLUTTER

# 2. Neues Icon ersetzen
cp /dein/neues/icon.png img/final.png

# 3. Icons generieren lassen
flutter pub run flutter_launcher_icons

# 4. Projekt bereinigen (wichtig!)
flutter clean

# 5. Abhängigkeiten aktualisieren
flutter pub get

# 6. App neu bauen
flutter build web --release    # Für Web
# ODER
flutter build apk --release    # Für Android
# ODER
flutter build ios --release    # Für iOS
```

---

## Warum funktioniert das Ersetzen nicht sofort?

Es gibt mehrere Gründe:

1. **Icons sind kompiliert:** Icons werden während des Builds in die App eingebunden und nicht zur Laufzeit geladen
2. **Cache:** Der Flutter Build-Cache kann alte Icons speichern
3. **Platform-spezifische Caches:** Jede Plattform (iOS, Android, Web) hat eigene Cache-Mechanismen

**Lösung:** Immer nach dem Icon-Update `flutter clean` ausführen!

---

## Troubleshooting

### Icons werden immer noch nicht aktualisiert

```bash
# Gründliche Reinigung:
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
flutter build web --release
```

### flutter_launcher_icons funktioniert nicht

```bash
# Icons-Package aktualisieren
flutter pub get
# Oder erzwingen:
flutter pub upgrade flutter_launcher_icons
```

### Fehlermeldung: "Image file does not exist"

- Stelle sicher, dass `img/final.png` im Projekt-Root existiert
- Überprüfe den Pfad in der `pubspec.yaml`
- Das Bild muss mindestens 1024×1024 Pixel sein

---

## Best Practices

1. **Immer `flutter clean` vor dem Rebuild ausführen**
2. **Icon in hoher Auflösung vorbereiten** (mindestens 1024×1024)
3. **Nach Änderungen testen** – Icons können auf verschiedenen Geräten anders aussehen
4. **Versionskontrolle:** Die generierten Icons (in `ios/`, `android/`, `web/`) sollten versioniert werden, damit andere Entwickler nicht neu generieren müssen
5. **Transparenz nutzen:** Für bessere Flexibilität ein Icon mit transparentem Hintergrund verwenden

---

## Weitere Ressourcen

- [Flutter Launcher Icons Dokumentation](https://pub.dev/packages/flutter_launcher_icons)
- [Flutter Build-Dokumentation](https://docs.flutter.dev/deployment)
- [Material Design Icon Guidelines](https://m3.material.io/styles/icons)

