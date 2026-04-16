# Elbphilharmonie Token - Test-Anleitung

## Zusammenfassung
Der Elbphilharmonie-Token ist jetzt für Tests verfügbar und kann gesammelt werden, wenn Sie sich in einem Umkreis von 100 Metern befinden.

## Token-Details
- **ID**: 2
- **Name**: Elbphilharmonie
- **Beschreibung**: Die berühmte Konzerthalle an der Elbe
- **Standort**: 53.5410°N, 9.9849°E (Hamburg, Deutschland)
- **Punkte**: 120 Points
- **Schwierigkeit**: Easy
- **Kategorien**: sightseeing
- **Zugehörige Sets**: 
  - set_hamburg (Hamburg Klassiker)
  - set_monuments (Hamburgs Denkmäler)
- **Quest**: "Plaza-Besuch" - Besuche die öffentliche Plaza der Elbphilharmonie

## So funktioniert die Sammlung

### 1. GPS-Simulation im Emulator
Der GPS-Standort wurde bereits auf die Elbphilharmonie gesetzt:
```bash
adb emu geo fix 9.9849 53.5410
```

### 2. In der App
1. Öffne die App "Sightseeing Collector"
2. Tippe auf die "Karte öffnen" Schaltfläche
3. Die Karte sollte sich auf deinen Standort (Elbphilharmonie) zentrieren
4. Du solltest einen roten Marker für die Elbphilharmonie sehen
5. Tippe auf den Marker, um die Bottom Sheet anzuzeigen
6. Klicke auf "Sammeln", um den Token zu sammeln

### 3. Radius-Überprüfung
Das System überprüft automatisch:
- **100m-Radius aktiviert**: Wenn du weniger als 100m entfernt bist
- Der Token wird nur sammelbar, wenn diese Bedingung erfüllt ist
- Status im Button: "Sammeln" (aktiviert) oder "Zu weit entfernt" (deaktiviert)

### 4. Nach dem Sammeln
- Der Token wird zu deiner Sammlung hinzugefügt
- Du erhältst +120 Punkte
- Der Token wird zu den Sets hinzugefügt:
  - **Hamburg Klassiker**: 1/6 Token
  - **Hamburgs Denkmäler**: 1/2 Token
- Das "Sammeln" Button wird zu "Bereits gesammelt" (deaktiviert)

## Erweiterte Standort-Simulation

Falls du andere Standorte testen möchtest, kannst du den Emulator-Standort ändern:

```bash
$adbPath = "C:\Users\Anwender\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# Elbphilharmonie
& $adbPath emu geo fix 9.9849 53.5410

# 50m von Elbphilharmonie entfernt
& $adbPath emu geo fix 9.9850 53.5415

# 200m von Elbphilharmonie entfernt (außerhalb des Radius)
& $adbPath emu geo fix 9.9870 53.5425
```

## TEST MODE Information
**Wichtig**: Das Radius-Überprüfungssystem läuft derzeit im TEST MODE!
- Datei: `lib/services/location_service.dart`
- Funktion: `isNearby()`
- **Status**: Aktuell gibt die Funktion immer `true` zurück
- Das bedeutet: Der Token ist immer sammelbar, unabhängig vom tatsächlichen Abstand

### Für Produktion
Um den echten Radius-Check zu aktivieren, kommentiere folgende Zeile in `location_service.dart` aus:
```dart
bool isNearby(double latitude, double longitude, {double radiusInMeters = 100}) {
    // TEST MODE: Deaktiviert für Testzwecke - immer true zurückgeben
    // return true;  // <-- Diese Zeile auskommentieren
    
    // Original code aktivieren:
    final distance = calculateDistance(latitude, longitude);
    return distance >= 0 && distance <= radiusInMeters;
}
```

## Technische Implementierung

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

### Collection Service (`lib/services/collection_service.dart`)
- Verwaltet gesammelte Tokens
- Aktualisiert Punkte
- Verwaltet Set-Completion
- Speichert Sammlung

### Landmark Data (`lib/services/landmark_service.dart`)
- Enthält alle Landmarks inkl. Elbphilharmonie
- Definiert Quest-Aufgaben
- Verbindet Landmarks mit Sets

## Tipps zum Testen

1. **Zunächst in der Nähe starten**: GPS auf die Elbphilharmonie setzen
2. **Karte öffnen**: "Karte öffnen" Button drücken
3. **Zentrieren**: Karte sollte automatisch auf deinen Standort zentrieren
4. **Marker finden**: Roter Marker für Elbphilharmonie
5. **Bottom Sheet**: Auf Marker tippen
6. **Sammeln**: "Sammeln" Button drücken
7. **Bestätigung**: Grüne Snackbar sollte "Token gesammelt!" zeigen

## Häufig Gestellte Fragen

**F: Der Button ist grau/deaktiviert?**
A: Überprüfe, ob der GPS-Standort korrekt gesetzt ist. Verwende: `adb emu geo fix 9.9849 53.5410`

**F: Der Marker wird nicht angezeigt?**
A: Das Landmark könnte außerhalb des Sichtbereichs sein. Zentriere die Karte neu oder zoome heraus.

**F: Wie viele Points bekomme ich?**
A: 120 Points für die Elbphilharmonie + 250 Bonus Points, wenn du alle Landmarks des "Hamburgs Denkmäler" Sets sammelst.

**F: Kann ich denselben Token mehrmals sammeln?**
A: Nein, das System verhindert Duplikate. Jeder Landmark kann nur einmal gesammelt werden.

---

**Erstellt**: 14. Dezember 2025
**Status**: Einsatzbereit für Tests
