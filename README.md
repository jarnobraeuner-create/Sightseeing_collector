# Sightseeing Collector

Eine interaktive Flutter-App für Android, in der Benutzer Tokens von weltberühmten Sehenswürdigkeiten sammeln können - wie in Pokémon Go, aber für Reisen und Sightseeing!

## Features

🎯 **GPS-basiertes Sammeln**: Sammle Tokens nur, wenn du unmittelbar vor einer Sehenswürdigkeit stehst
🗺️ **Kartenfunktion**: Erkunde Sehenswürdigkeiten in deiner Nähe mit Google Maps
🏆 **Token-Sammlung**: Baue deine Sammlung aus Sehenswürdigkeiten-Tokens auf
🎁 **Sets & Belohnungen**: Sammle Tokens zu Themensets und verdiene Bonuspunkte
📍 **Echtzeit-GPS**: Dein Standort wird in Echtzeit aktualisiert
📊 **Statistiken & Profil**: Verfolge deine Fortschritte und Achievements

## Projektstruktur

```
lib/
├── main.dart                 # App-Einstiegspunkt
├── models/                   # Datenmodelle
│   ├── landmark.dart        # Sehenswürdigkeits-Modell
│   ├── token.dart           # Token-Modell
│   └── collection_set.dart  # Set-Modell
├── services/                 # Business Logic
│   ├── location_service.dart    # GPS & Standort-Management
│   ├── landmark_service.dart    # Sehenswürdigkeits-Verwaltung
│   └── collection_service.dart  # Token- & Set-Verwaltung
├── screens/                  # UI-Bildschirme
│   ├── home_screen.dart     # Erkunden & Sehenswürdigkeits-Details
│   ├── map_screen.dart      # Kartenfunktion
│   ├── collection_screen.dart # Token-Sammlung
│   └── profile_screen.dart  # Benutzerprofil & Statistiken
└── widgets/                  # Wiederverwendbare UI-Komponenten
    ├── landmark_card.dart   # Sehenswürdigkeits-Kartenlayout
    ├── token_card.dart      # Token-Kartenlayout
    └── set_card.dart        # Set-Kartenlayout
```

## Abhängigkeiten

- **provider**: State Management
- **geolocator**: GPS & Standort-Services
- **google_maps_flutter**: Kartendarstellung
- **sqflite**: Lokale Datenspeicherung
- **shared_preferences**: Benutzereinstellungen
- **permission_handler**: Android-Berechtigungsverwaltung

## Installation & Setup

### Voraussetzungen
- Flutter SDK (3.0.0 oder höher)
- Android SDK 21 (minSdkVersion)
- Google Maps API Key

### Schritte

1. **Klone das Projekt**
   ```bash
   git clone <repository-url>
   cd sightseeing_collector
   ```

2. **Abhängigkeiten installieren**
   ```bash
   flutter pub get
   ```

3. **Google Maps konfigurieren** (Android)
   - Öffne `android/app/src/main/AndroidManifest.xml`
   - Füge deinen Google Maps API Key ein:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```

4. **App bauen und starten**
   ```bash
   flutter run
   ```

## Android-Berechtigungen

Die folgende Datei (`android/app/src/main/AndroidManifest.xml`) benötigt diese Berechtigungen:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Spielmechaniken

### Tokens sammeln
1. Navigiere zu einer Sehenswürdigkeit
2. Gehe an den Ort (innerhalb von 100m Radius)
3. Tippe "Token sammeln", wenn du nah genug bist
4. Der Token wird zu deiner Sammlung hinzugefügt

### Sets vervollständigen
- Sammle alle erforderlichen Tokens eines Sets
- Verdiene Bonuspunkte beim Abschluss
- Tracke deinen Fortschritt mit Fortschrittsbalken

### Quests
- Jede Sehenswürdigkeit hat zugehörige Quests
- Foto-Quests: Mache ein Foto an der Sehenswürdigkeit
- Check-in-Quests: Überprüfe deinen Standort
- Puzzle-Quests: Löse historische Rätsel

## Sehenswürdigkeits-Datenbank

Die App enthält derzeit folgende Sehenswürdigkeiten:
- Brandenburger Tor (Berlin)
- Eiffelturm (Paris)
- Colosseum (Rom)
- Big Ben (London)
- Freiheitsstatue (New York)

Diese können einfach erweitert werden!

## Entwicklung & Erweiterung

### Neue Sehenswürdigkeit hinzufügen
Bearbeite `lib/services/landmark_service.dart`:
```dart
Landmark(
  id: '6',
  name: 'Sagrada Familia',
  description: 'Gaudis Meisterwerk in Barcelona',
  latitude: 41.4036,
  longitude: 2.1744,
  category: 'sightseeing',
  imageUrl: 'assets/images/sagrada_familia.png',
  difficulty: 'medium',
  pointsReward: 150,
  relatedSetIds: ['set_spain', 'set_monuments'],
  quests: [...],
)
```

### Google Maps Integration
Die Google Maps-Integration ist vorbereitet in `map_screen.dart`. Aktiviere sie, indem du das Placeholder-Widget durch eine echte `GoogleMap` ersetzt.

### Datenbankintegration
Nutze `sqflite` für persistente Speicherung von:
- Gesammelten Tokens
- Benutzerfortschritt
- Lokale Cache der Sehenswürdigkeiten

## Testing

```bash
flutter test
```

## Troubleshooting

**Standort wird nicht aktualisiert?**
- Überprüfe, dass die Standortberechtigung auf dem Gerät aktiviert ist
- Überprüfe, dass der GPS deaktiviert ist
- Starte die App neu

**Maps werden nicht geladen?**
- Überprüfe, dass dein Google Maps API Key gültig ist
- Überprüfe, dass das Gerät eine Internetverbindung hat

**App startet nicht?**
- Führe `flutter clean` aus
- Führe `flutter pub get` aus
- Baue neu: `flutter run`

## Lizenz

Dieses Projekt ist für private Nutzung gedacht.

## Weitere Ressourcen

- [Flutter Dokumentation](https://flutter.dev/docs)
- [Geolocator Plugin](https://pub.dev/packages/geolocator)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Provider State Management](https://pub.dev/packages/provider)

---

**Viel Spaß beim Sammeln von Sehenswürdigkeits-Tokens! 🎯🗺️**
