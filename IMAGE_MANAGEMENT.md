# 🖼️ Image Management System - Anleitung

## Schnellstart: Neues Bild hinzufügen

### 1. Bild in Assets speichern
```
assets/images/
└── dein_neues_bild.png
```

### 2. ImageService aktualisieren
Öffne `lib/services/image_service.dart` und füge einen Eintrag in die `landmarkImages` Map hinzu:

```dart
'7': LandmarkImages(
  name: 'St. Michaelis',
  bronze: 'michel.png',
  silver: null,           // Null = nutze bronze
  gold: null,             // Null = nutze silver/bronze
),
```

### 3. Landmark-Service aktualisieren (optional)
Wenn du ein neues Landmark erstellst, nutze einfach die ID - das war's!

```dart
Landmark(
  id: '7',
  name: 'St. Michaelis',
  // ... andere Properties ...
  // Das Bild wird automatisch aus ImageService geladen!
)
```

---

## Bilder mit Tier-Unterstützung

Für Landmarks mit mehreren Tier-Varianten (Bronze, Silver, Gold):

```dart
'2': LandmarkImages(
  name: 'Elbphilharmonie',
  bronze: 'elbphilharmonie_bronze.png',
  silver: 'elbphilharmonie_silver.png',
  gold: 'Token_gold_elbphilharmonie.png',  // Münze
),
```

---

## Bilder in Code verwenden

### Alte Methode (NICHT mehr nötig):
```dart
// ❌ VERALTET - manuell in Landmark setzen
imageUrl: 'assets/images/Token_gold_elbphilharmonie.png',
imageUrlGold: 'assets/images/Token_gold_elbphilharmonie.png',
```

### Neue Methode (EMPFOHLEN):
```dart
// ✅ NEU - ImageService nutzen
String imageUrl = ImageService.getImageUrl('2', 'gold');

// In Widgets:
Image.asset(ImageService.getImageUrl('2', 'gold'))
```

---

## Automatisches Fallback-System

Wenn ein Bild fehlt, wird automatisch das nächste verfügbare verwendet:

```
Gold-Request → Gold vorhanden? → Ja ✓
            → Nein → Silver vorhanden? → Ja ✓
                  → Nein → Bronze vorhanden? → Ja ✓
                        → Nein → placeholder.png
```

---

## Debugging

Zeige alle konfigurierten Bilder:
```dart
ImageService.printRegistry();
```

Ausgabe:
```
📸 ImageService Registry:
  1 - Speicherstadt:
    Bronze: Token_gold_Speicherstadt.png
    Silver: Token_gold_Speicherstadt.png
    Gold: Token_gold_Speicherstadt.png
  2 - Elbphilharmonie:
    Bronze: Token_gold_elbphilharmonie.png
    Silver: Token_gold_elbphilharmonie.png
    Gold: Token_gold_elbphilharmonie.png
  ...
```

---

## Checkliste: Neues Landmark mit Bild

- [ ] PNG-Datei in `assets/images/` speichern
- [ ] Dateiname notieren (z.B. `neue_stadt.png`)
- [ ] Eintrag in `ImageService.landmarkImages` hinzufügen
- [ ] Optional: In `landmark_service.dart` das neue Landmark erstellen
- [ ] Fertig! Bild wird automatisch geladen

---

## Vorteile dieses Systems

✅ **Zentrale Verwaltung** - Alle Bilder an einem Ort  
✅ **Automatisches Fallback** - Keine Fehler bei fehlenden Dateien  
✅ **Einfach erweiterbar** - Nur 1 Map-Eintrag pro Landmark  
✅ **Debug-freundlich** - Logging für fehlende Bilder  
✅ **Schnell** - Keine manuellen Dateimanipulationen nötig  
✅ **Skalierbar** - Funktioniert für 10 oder 100 Landmarks
