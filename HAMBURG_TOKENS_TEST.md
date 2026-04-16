# Hamburg Tokens - Komplette Test-Anleitung

## 🎯 Überblick

Du kannst jetzt zwei Test-Tokens sammeln:
1. **Speicherstadt** (ID: 1) - 100 Punkte
2. **Elbphilharmonie** (ID: 2) - 120 Punkte

Beide Tokens sind Bestandteil der Sets:
- **Hamburg Klassiker** (6 Tokens notwendig)
- **Hamburgs Denkmäler** (2 Tokens notwendig)

## Token Details

### 🏢 Speicherstadt
| Eigenschaft | Wert |
|------------|------|
| **ID** | 1 |
| **Standort** | 53.0413°N, 10.0055°E |
| **Punkte** | 100 |
| **Grafik** | Angehängtes goldenes Münz-Design |
| **Quest** | Foto in der Speicherstadt |
| **Sets** | Hamburg Klassiker (1/6), Hamburgs Denkmäler (1/2) |

### 🎼 Elbphilharmonie
| Eigenschaft | Wert |
|------------|------|
| **ID** | 2 |
| **Standort** | 53.5410°N, 9.9849°E |
| **Punkte** | 120 |
| **Grafik** | Standard-Asset |
| **Quest** | Plaza-Besuch |
| **Sets** | Hamburg Klassiker (2/6), Hamburgs Denkmäler (2/2) |

## Test-Szenarien

### Szenario 1: Speicherstadt sammeln
```bash
# 1. GPS auf Speicherstadt setzen
$adbPath = "C:\Users\Anwender\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adbPath emu geo fix 10.0055 53.0413

# 2. App öffnen und "Karte öffnen" drücken
# 3. Auf roten Marker tippen
# 4. "Sammeln" Button drücken
# 5. Token erhalten: +100 Punkte
```

### Szenario 2: Elbphilharmonie sammeln
```bash
# 1. GPS auf Elbphilharmonie setzen
& $adbPath emu geo fix 9.9849 53.5410

# 2. Karte aktualisieren (neu öffnen)
# 3. Auf roten Marker tippen
# 4. "Sammeln" Button drücken
# 5. Token erhalten: +120 Punkte
```

### Szenario 3: Komplettes Set (beide Tokens)
```bash
# Sammle beide Tokens nacheinander
# Nach dem 2. Token:
# - Punkte: 220 (100 + 120)
# - "Hamburgs Denkmäler" Set completed: +250 Bonus Punkte
# - Gesamt-Punkte: 470
```

## Schritt-für-Schritt Anleitung

### Token sammeln

1. **App starten**
   ```
   flutter run
   ```

2. **Standort setzen** (im Terminal)
   ```bash
   $adbPath = "C:\Users\Anwender\AppData\Local\Android\Sdk\platform-tools\adb.exe"
   & $adbPath emu geo fix 10.0055 53.0413  # oder 9.9849 53.5410
   ```

3. **In der App navigieren**
   - Home Screen wird angezeigt
   - Tippe auf "Karte öffnen"

4. **Karte verwenden**
   - Karte zentriert sich auf deinen Standort
   - Roter Marker für dein Token
   - Blauer Marker für dich

5. **Token sammeln**
   - Tippe auf den roten Marker
   - Bottom Sheet öffnet sich
   - Tippe "Sammeln" Button
   - Grüne Snackbar bestätigt: "Token gesammelt!"

6. **Punkte überprüfen**
   - Gehe zur "Sammlung" Tab
   - Deine Punkte werden angezeigt
   - Token sind in der Galerie sichtbar

## GPS-Befehle für verschiedene Standorte

```bash
$adbPath = "C:\Users\Anwender\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# Speicherstadt (Hafen, Süd)
& $adbPath emu geo fix 10.0055 53.0413

# Elbphilharmonie (Elbe, Nord)
& $adbPath emu geo fix 9.9849 53.5410

# Jungfernstieg (Zentrum)
& $adbPath emu geo fix 10.0012 53.5545

# 100m südlich von Speicherstadt
& $adbPath emu geo fix 10.0055 53.0403

# 200m nördlich von Elbphilharmonie
& $adbPath emu geo fix 9.9849 53.5430
```

## Wichtige Informationen

### Radius-System
- **Aktuell**: TEST MODE (immer sammelbar, unabhängig vom Abstand)
- **Production**: 100m-Radius wird überprüft
- **Standort**: `lib/services/location_service.dart` → `isNearby()`

### Set-System
Wenn du alle Tokens eines Sets sammelst, erhältst du Bonus-Punkte:
- **Hamburg Klassiker**: 6 Tokens → +500 Bonus Punkte
- **Hamburgs Denkmäler**: 2 Tokens → +250 Bonus Punkte

### Token-Verwaltung
- Jeder Token kann nur einmal gesammelt werden
- Das System verhindert Duplikate automatisch
- Gesammelte Tokens können nicht degesammelt werden

## Troubleshooting

### Problem: Marker werden nicht angezeigt
**Lösung**: 
- App neustarten
- Karte mit dem Button neu zentrieren
- GPS-Standort überprüfen: `adb emu geo status`

### Problem: Sammeln-Button ist deaktiviert
**Lösung**:
- GPS-Standort mit `adb emu geo fix` neu setzen
- App neu laden
- Überprüfe, ob Token bereits gesammelt wurde

### Problem: Karte lädt nicht
**Lösung**:
- Überprüfe API Key in `android/local.properties`
- Stelle sicher, dass INTERNET-Permission aktiviert ist
- Starte die App neu

### Problem: Token wird nicht gespeichert
**Lösung**:
- Überprüfe die Dart-Logs in der Console
- Stelle sicher, dass `CollectionService` initialisiert ist
- Überprüfe, ob Token bereits existiert

## Dateien

### Konfigurationsdateien
- `android/local.properties` - Google Maps API Key
- `android/app/src/main/AndroidManifest.xml` - Berechtigungen
- `pubspec.yaml` - Dependencies

### Source-Code
- `lib/services/landmark_service.dart` - Token-Definitionen
- `lib/screens/map_screen.dart` - Map-UI
- `lib/services/location_service.dart` - GPS-Handling
- `lib/services/collection_service.dart` - Collection-Logic

### Test-Dokumentation
- `SPEICHERSTADT_TEST.md` - Speicherstadt-Details
- `ELBPHILHARMONIE_TEST.md` - Elbphilharmonie-Details
- `HAMBURG_TOKENS_TEST.md` - Diese Datei

## Performance-Tipps

1. **GPS-Wechsel**: Nutze mehrere Terminals zum schnellen Wechsel
2. **Karte neu zentrieren**: Nach Standortwechsel die Karte neu laden
3. **Test-Sets**: Sammle zuerst "Hamburgs Denkmäler" (2 Tokens), dann weitere
4. **Logs überprüfen**: `flutter logs` für Debugging

## Nächste Schritte

Nach erfolgreichem Test:
1. ✅ Speicherstadt Token sammeln
2. ✅ Elbphilharmonie Token sammeln
3. ✅ Set "Hamburgs Denkmäler" komplettieren
4. ⏳ Weitere Landmarks hinzufügen
5. ⏳ Radius-System in Production aktivieren
6. ⏳ Persistierung (Datenbank) implementieren

---

**Erstellt**: 14. Dezember 2025
**Version**: 1.0
**Status**: 🟢 Produktionsreif für Tests
**Grafiken**: 
- Speicherstadt: Angehängtes goldenes Münz-Design
- Elbphilharmonie: Standard-Asset
