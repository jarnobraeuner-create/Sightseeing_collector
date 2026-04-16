# Speicherstadt Token - Test-Anleitung

## Zusammenfassung
Der Speicherstadt-Token ist nun für Tests verfügbar und kann gesammelt werden, wenn Sie sich in einem Umkreis von 100 Metern befinden.

## Token-Details
- **ID**: 1
- **Name**: Speicherstadt
- **Beschreibung**: Historischer Hafen und Lagerhauskomplex in Hamburg
- **Standort**: 53.0413°N, 10.0055°E (Hamburg, Deutschland)
- **Punkte**: 100 Points
- **Schwierigkeit**: Easy
- **Kategorien**: sightseeing
- **Zugehörige Sets**: 
  - set_hamburg (Hamburg Klassiker)
  - set_monuments (Hamburgs Denkmäler)
- **Quest**: "Foto in der Speicherstadt" - Mache ein Foto in der Speicherstadt

## Token-Grafik
Das Token wird mit der angehängten Grafik der Speicherstadt dargestellt:
- **Datei**: `assets/images/speicherstadt.png`
- **Motiv**: Goldenes Münz-Design mit der Speicherstadt-Skyline
- **Format**: PNG mit goldenen Rahmen

## So funktioniert die Sammlung

### 1. GPS-Simulation im Emulator
Der GPS-Standort wurde bereits auf die Speicherstadt gesetzt:
```bash
adb emu geo fix 10.0055 53.0413
```

### 2. In der App
1. Öffne die App "Sightseeing Collector"
2. Tippe auf die "Karte öffnen" Schaltfläche
3. Die Karte sollte sich auf deinen Standort (Speicherstadt) zentrieren
4. Du solltest einen roten Marker für die Speicherstadt sehen
5. Tippe auf den Marker, um die Bottom Sheet anzuzeigen
6. Klicke auf "Sammeln", um den Token zu sammeln

### 3. Radius-Überprüfung
Das System überprüft automatisch:
- **100m-Radius aktiviert**: Wenn du weniger als 100m entfernt bist
- Der Token wird nur sammelbar, wenn diese Bedingung erfüllt ist
- Status im Button: "Sammeln" (aktiviert) oder "Zu weit entfernt" (deaktiviert)

### 4. Nach dem Sammeln
- Der Token wird zu deiner Sammlung hinzugefügt
- Du erhältst +100 Punkte
- Der Token wird zu den Sets hinzugefügt:
  - **Hamburg Klassiker**: 1/6 Token
  - **Hamburgs Denkmäler**: 1/2 Token
- Das "Sammeln" Button wird zu "Bereits gesammelt" (deaktiviert)

## Vergleich: Elbphilharmonie vs. Speicherstadt

| Aspekt | Speicherstadt | Elbphilharmonie |
|--------|---------------|-----------------|
| ID | 1 | 2 |
| Punkte | 100 | 120 |
| Koordinaten | 53.0413°N, 10.0055°E | 53.5410°N, 9.9849°E |
| Abstand | ~50 km nördlich (Hafen) | ~50 km südlich (Elbe) |
| Quest-Typ | Photo | Check-in |
| Sets | Hamburg + Denkmäler | Hamburg + Denkmäler |

## Standort-Simulation für verschiedene Orte

Wenn du verschiedene Standorte testen möchtest, nutze diese Kommandos:

```bash
$adbPath = "C:\Users\Anwender\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# Speicherstadt
& $adbPath emu geo fix 10.0055 53.0413

# Elbphilharmonie
& $adbPath emu geo fix 9.9849 53.5410

# Jungfernstieg (weitere Sehenswürdigkeit)
& $adbPath emu geo fix 10.0012 53.5545
```

## Technische Implementierung

Die Implementierung nutzt die gleiche Architektur wie die Elbphilharmonie:

### Map-Screen (`lib/screens/map_screen.dart`)
- Lädt alle Landmarks (Sehenswürdigkeiten)
- Zeigt Marker auf der Karte an
- Überprüft `isNearby()` für jeden Landmark
- Zeigt Bottom Sheet mit Sammeln-Button an
- Verwaltet die Sammlung über `CollectionService`

### Location Service (`lib/services/location_service.dart`)
- Verwaltet GPS-Position des Benutzers
- Berechnet Entfernung zu Landmarks
- Überprüft 100m-Radius
- Sendet Standort-Updates an die Map

### Landmark Data (`lib/services/landmark_service.dart`)
- **Speicherstadt-Eintrag** mit korrekten Koordinaten
- Definition des Photo-Quest
- Verbindung zu Sets: hamburg (1/6) und monuments (1/2)

## Tipps zum Testen

1. **Test-Reihenfolge**: Zuerst Speicherstadt sammeln, dann Elbphilharmonie
2. **GPS Wechsel**: Nutze die adb-Kommandos zum schnellen Standortwechsel
3. **Karte aktualisieren**: Nach Standortwechsel die Karte neu zentrieren
4. **Sets beobachten**: Nach 2 Tokens sind beide Sets zu 50% voll

## Häufig Gestellte Fragen

**F: Welche Datei wurde aktualisiert?**
A: `lib/services/landmark_service.dart` - Koordinaten wurden auf genauer wert aktualisiert

**F: Kann ich beide Tokens sammeln?**
A: Ja! Du kannst nacheinander GPS-Standorte wechseln und beide Tokens sammeln

**F: Was sind die Bonuspunkte?**
A: Für "Hamburg Klassiker": 500 Punkte beim Komplettieren aller 6 Tokens
   Für "Hamburgs Denkmäler": 250 Punkte beim Sammeln beide (Speicherstadt + Elbphilharmonie)

**F: Warum sind die Koordinaten unterschiedlich?**
A: Die beiden Landmarks befinden sich an völlig verschiedenen Orten in Hamburg:
   - Speicherstadt: Historischer Hafen im Südosten
   - Elbphilharmonie: Moderne Konzerthalle an der Elbe im Norden

---

**Erstellt**: 14. Dezember 2025
**Status**: Einsatzbereit für Tests
**Grafik**: Angehängtes PNG-Bild der Speicherstadt
