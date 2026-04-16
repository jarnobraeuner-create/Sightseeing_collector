# Sightseeing Collector - Entwickler Dokumentation

## Architektur Übersicht

Die App folgt einer **schichtbasierten Architektur**:

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens & Widgets)    │
├─────────────────────────────────────────┤
│    Business Logic Layer (Services)      │
├─────────────────────────────────────────┤
│       Data Layer (Models & DB)          │
└─────────────────────────────────────────┘
```

## Datenmodelle (lib/models/)

### Landmark
Repräsentiert eine Sehenswürdigkeit mit:
- **id**: Eindeutige Identifikation
- **Koordinaten**: latitude, longitude (WGS84)
- **Kategorie**: 'travel' oder 'sightseeing'
- **Quests**: Zugehörige Aufgaben
- **relatedSetIds**: Zugehörige Sammlungs-Sets

**Methoden:**
- `getDistance(lat, lon)`: Berechnet Entfernung zum Benutzer (Haversine-Formel)

### Token
Repräsentiert einen gesammelten Token mit:
- **id**: UUID
- **landmarkId**: Referenz zur Sehenswürdigkeit
- **collectedAt**: Sammelzeitpunkt
- **points**: Verdiente Punkte
- **setIds**: Zugehörige Sets

### CollectionSet
Repräsentiert eine Sammlungs-Set mit:
- **requiredTokenIds**: Erforderliche Tokens zum Abschluss
- **collectedTokenIds**: Bereits gesammelte Tokens
- **bonusPoints**: Bonuspunkte für Abschluss
- **completed**: Abschluss-Status

**Eigenschaften:**
- `completionPercentage`: Fortschritts-Prozentsatz

## Services (lib/services/)

### LocationService (ChangeNotifier)
Verwaltet GPS und Standort-Updates:

**Public API:**
```dart
// Properties
Position? currentPosition          // Aktuelle Position
bool isServiceEnabled             // GPS aktiviert?
bool isLocationAccessGranted      // Berechtigung vorhanden?
Stream<Position> positionStream   // Live Position-Updates

// Methoden
Future<void> refreshLocation()                        // Position neu laden
double calculateDistance(lat, lon)                    // Entfernung berechnen
bool isNearby(lat, lon, {radius})                     // In Nähe?
```

**Internals:**
- Nutzt `geolocator` für GPS-Zugriff
- Nutzt `permission_handler` für Berechtigung
- Aktualisiert automatisch bei 10m+ Abweichung
- Notified Listeners bei Position-Änderung

### LandmarkService (ChangeNotifier)
Verwaltet Sehenswürdigkeits-Daten:

**Public API:**
```dart
// Properties
List<Landmark> landmarks          // Alle Sehenswürdigkeiten
List<Landmark> filteredLandmarks  // Nach Kategorie gefiltert
String selectedCategory           // Aktuelle Kategorie

// Methoden
void setCategory(category)        // Filter nach Kategorie
Landmark? getLandmarkById(id)     // Eine Sehenswürdigkeit laden
List<Landmark> getNearby(lat, lon, {radius})         // In der Nähe
List<Landmark> searchLandmarks(query)                // Suche
```

**Beispiel: Sehenswürdigkeit hinzufügen**
```dart
void _loadLandmarks() {
  _landmarks.add(
    Landmark(
      id: '6',
      name: 'Sagrada Familia',
      // ... weitere Parameter
      quests: [
        Quest(
          id: 'q7',
          title: 'Fotografiere die Architektur',
          taskType: 'photo',
          completed: false,
        ),
      ],
    ),
  );
}
```

### CollectionService (ChangeNotifier)
Verwaltet Token und Sets:

**Public API:**
```dart
// Properties
List<Token> tokens                // Gesammelte Tokens
List<CollectionSet> sets          // Verfügbare Sets
int totalPoints                   // Gesamt-Punkte

// Methoden
void collectToken(...)            // Token sammeln
bool hasCollectedToken(landmarkId) // Bereits gesammelt?
Token? getToken(landmarkId)       // Token abrufen
List<Token> getTokensByCategory(category)
CollectionSet? getSetById(setId)
int getSetCompletionPercentage(setId)
List<CollectionSet> getCompletedSets()
Map<String, int> getStatistics()  // Statistiken
```

## UI Layer (lib/screens/ & lib/widgets/)

### HomeScreen (Tabbed Navigation)
Hauptbildschirm mit vier Tabs:
1. **Erkunden**: Sehenswürdigkeiten-Liste mit Filterung
2. **Karte**: Google Maps Integration (Placeholder)
3. **Sammlung**: Token & Set-Verwaltung
4. **Profil**: Benutzerstatistiken

### LandmarkDetailScreen
Detaillansicht einer Sehenswürdigkeit:
- Bild und Beschreibung
- Entfernung zum Benutzer
- Quests-Liste
- "Token sammeln" Button (nur aktiviert wenn nah genug)

### CollectionScreen
Zeigt:
- **Tokens-Tab**: Grid-View der gesammelten Tokens
- **Sets-Tab**: Liste der Sammlungs-Sets mit Fortschrittsbalken

### ProfileScreen
Benutzer Dashboard:
- Benutzer-Avatar & Level
- Statistiken (Tokens, Punkte, Sets)
- Standortinformationen

## Datenfluss (Provider Pattern)

```
LocationService ┐
                ├─→ HomeScreen ──────┬─→ LandmarkCard
LandmarkService ┤                    ├─→ LandmarkDetailScreen
                ├─→ CollectionScreen ├─→ ProfileScreen
CollectionService┘                   ├─→ MapScreen
                                     └─→ Alle anderen Widgets
```

**Beispiel: Token sammeln**
```
HomeScreen
  └─→ LandmarkDetailScreen
      └─→ ElevatedButton.onPressed()
          └─→ collectionService.collectToken()
              ├─→ Erstelle Token
              ├─→ Aktualisiere gesammelte Tokens
              ├─→ Aktualisiere Set-Status
              ├─→ Erhöhe totalPoints
              └─→ notifyListeners() → UI aktualisiert
```

## Token-Sammlung Logik

### Bedingungen für Sammlung:
1. Benutzer muss sich **< 100m** von der Sehenswürdigkeit entfernt befinden
2. Token darf **nicht bereits** gesammelt sein
3. GPS muss **aktiviert** sein
4. Standortberechtigung muss **gewährt** sein

### Bei erfolgreicher Sammlung:
1. Neuer Token wird erstellt
2. Token wird zu `collectionService.tokens` hinzugefügt
3. `totalPoints` wird erhöht
4. Zugehörige Sets werden aktualisiert
5. Wenn Set vollständig → `bonusPoints` hinzufügen
6. UI wird aktualisiert

**Code-Beispiel:**
```dart
ElevatedButton.onPressed: () {
  collectionService.collectToken(
    landmark.id,
    landmark.name,
    landmark.category,
    landmark.pointsReward,
    landmark.relatedSetIds,
  );
  // UI aktualisiert automatisch durch Provider
}
```

## Entfernung-Berechnung

Nutzt die **Haversine-Formel**:
```dart
double getDistance(double userLat, double userLon) {
  const double earthRadius = 6371; // km
  // Berechnet Großkreis-Entfernung zwischen zwei Koordinaten
}
```

## Erweiterbarkeit

### Neue Sehenswürdigkeit hinzufügen:
1. `landmark_service.dart` → `_loadLandmarks()`
2. Neues `Landmark` mit Quests hinzufügen

### Neue Quest-Typen:
1. `models/landmark.dart` → `Quest.taskType` Wert hinzufügen
2. `LandmarkDetailScreen` → Quest-UI für neuen Typ
3. Quest-Validierung in `CollectionService`

### Neue Sets hinzufügen:
1. `collection_service.dart` → `_initializeSets()`
2. Neues `CollectionSet` mit Token-Anforderungen

### Google Maps aktivieren:
1. `map_screen.dart` → Ersetze Container durch `GoogleMap`
2. Zeige alle `LandmarkService.filteredLandmarks` als Marker

## Testing

### Unit Tests für Services:
```bash
flutter test test/services/
```

### Widget Tests für Screens:
```bash
flutter test test/widgets/
```

### Integration Tests:
```bash
flutter drive --target=test_driver/app.dart
```

## Performance-Überlegungen

1. **LocationService**: Nutzt `distanceFilter` um unnötige Updates zu vermeiden
2. **LandmarkService**: Cacht Landmarks in Memory (könnte mit DB erweitert werden)
3. **CollectionService**: Nutzt `firstWhere` effizient
4. **UI**: Nutzt `Consumer` Widgets für granulare Updates

## Bekannte Einschränkungen & TODOs

- [ ] Google Maps Implementation (noch Placeholder)
- [ ] Datenbankintegration mit sqflite
- [ ] Benutzerauthentifizierung (Firebase)
- [ ] Echtzeit-Synchronisierung mit Backend
- [ ] Offline-Modus
- [ ] Bildgalerie für Tokens
- [ ] Mehrsprachigkeit
- [ ] Dark Mode korrekt implementieren

---

**Für Fragen oder Erweiterungen, siehe README.md oder SETUP_GUIDE.md**
