# App Icon Einrichtung (ohne weißen Rand)

## Problem

Ein rundes Icon auf einem quadratischen PNG hat weiße Ecken.
Android und iOS zeigen dadurch einen **weißen Rand** um das App-Icon.

- **Android** nutzt seit Android 8 **Adaptive Icons** – das System schneidet das Icon in eine Form (rund, Squircle etc.). Weiße Ecken werden dabei sichtbar.
- **iOS** erlaubt keine Transparenz bei App-Icons und füllt transparente Bereiche automatisch mit Weiß.

## Voraussetzungen

- Das Paket `flutter_launcher_icons` muss in `pubspec.yaml` unter `dev_dependencies` stehen:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

- Das Original-Icon (`img/final.png`) in 1024x1024 Pixel.

## Schritt 1: Icon-Varianten erstellen

Es werden zwei Varianten des Icons benötigt:

### 1. `final_filled.png` (für iOS + Legacy-Android)

Die weißen Ecken werden mit der **Hintergrundfarbe des Icons** (Teal `#1f636a`) gefüllt.

### 2. `final_adaptive_fg.png` (Foreground für Android Adaptive Icons)

Das Icon wird auf **ca. 72%** verkleinert und auf einem Teal-Hintergrund zentriert.
Das ist nötig, weil Android Adaptive Icons nur die **inneren ~66%** des Foreground-Layers garantiert anzeigen ("Safe Zone"). Ohne Verkleinerung werden Elemente am Rand (z.B. Pfeile) abgeschnitten.

### Python-Skript zur Erstellung

```python
from PIL import Image
import math

img = Image.open('img/final.png').convert('RGBA')
w, h = img.size
cx, cy = w // 2, h // 2

# --- final_filled.png ---
# Radius des Kreises im Bild ermitteln
radii = []
for angle_deg in range(0, 360, 1):
    angle = math.radians(angle_deg)
    for r_test in range(520, 400, -1):
        x = int(cx + r_test * math.cos(angle))
        y = int(cy + r_test * math.sin(angle))
        if 0 <= x < w and 0 <= y < h:
            r, g, b, a = img.getpixel((x, y))
            if not (r > 230 and g > 230 and b > 230):
                radii.append(r_test)
                break

radius = sum(radii) / len(radii)
bg_color = (31, 99, 106, 255)  # Teal #1f636a

filled = img.copy()
fp = filled.load()
for y in range(h):
    for x in range(w):
        dist = math.sqrt((x - cx)**2 + (y - cy)**2)
        if dist >= radius - 3:
            r, g, b, a = fp[x, y]
            if r > 220 and g > 220 and b > 220:
                fp[x, y] = bg_color

filled.save('img/final_filled.png')

# --- final_adaptive_fg.png ---
scale = 0.72
new_size = int(w * scale)
resized = img.resize((new_size, new_size), Image.LANCZOS)

foreground = Image.new('RGBA', (w, h), bg_color)
offset = (w - new_size) // 2
foreground.paste(resized, (offset, offset), resized)
foreground.save('img/final_adaptive_fg.png')
```

## Schritt 2: `pubspec.yaml` konfigurieren

Am Ende der `pubspec.yaml` folgende Konfiguration einfügen:

```yaml
flutter_launcher_icons:
  image_path: "img/final_filled.png"
  android: true
  ios: true
  remove_alpha_ios: true
  adaptive_icon_background: "#1f636a"
  adaptive_icon_foreground: "img/final_adaptive_fg.png"
```

| Eigenschaft                  | Beschreibung                                                         |
| ---------------------------- | -------------------------------------------------------------------- |
| `image_path`                 | Haupticon mit gefüllten Ecken (für iOS + Legacy-Android)             |
| `remove_alpha_ios`           | Entfernt Transparenz für iOS (sonst wird Transparent zu Schwarz)     |
| `adaptive_icon_background`   | Hintergrundfarbe für Android Adaptive Icons                          |
| `adaptive_icon_foreground`   | Verkleinertes Icon als Vordergrund-Layer für Android Adaptive Icons  |

## Schritt 3: Icons generieren

```bash
flutter pub run flutter_launcher_icons
```

Generierte Dateien:

- **Android**: `mipmap-*/ic_launcher.png` (Legacy) + `drawable-*/ic_launcher_foreground.png` (Adaptive) + `values/colors.xml`
- **iOS**: `Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`

## Schritt 4: App neu bauen

```bash
flutter build apk
```

## Hintergrundwissen: Android Adaptive Icons

Adaptive Icons bestehen aus **zwei Layern**:

```
┌──────────────────────┐
│    Background        │  ← Einfarbig (#1f636a) oder Bild
│  ┌────────────────┐  │
│  │   Foreground    │  │  ← Dein Icon (verkleinert)
│  │  ┌──────────┐  │  │
│  │  │ Safe Zone│  │  │  ← Nur dieser Bereich ist garantiert sichtbar (~66%)
│  │  └──────────┘  │  │
│  └────────────────┘  │
└──────────────────────┘
```

Das System kann diese Layer in verschiedene Formen schneiden (rund, Squircle, abgerundetes Rechteck) und Parallax-Animationen darauf anwenden. Deshalb muss das wichtige Bildmaterial in der **Safe Zone** liegen.
