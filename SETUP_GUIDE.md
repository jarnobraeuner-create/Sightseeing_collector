# Sightseeing Collector Flutter App Setup Guide

## Voraussetzungen installieren

### 1. Flutter SDK installieren
- Lade Flutter von https://flutter.dev/docs/get-started/install herunter
- Folge den Installationsanweisungen für Windows
- Verifiziere die Installation:
  ```bash
  flutter --version
  flutter doctor
  ```

### 2. Android Studio & SDK einrichten
- Lade Android Studio herunter
- Installiere das Android SDK (API Level 21+ erforderlich)
- Installiere die Android Emulator

### 3. Google Maps API Key besorgen
- Gehe zu https://console.cloud.google.com/
- Erstelle ein neues Projekt
- Aktiviere die Maps SDK for Android
- Generiere einen API Key
- Aktualisiere `android/app/src/main/AndroidManifest.xml`

## Projekt Setup

1. **Navigiere zum Projektverzeichnis:**
   ```bash
   cd sightseeing_collector
   ```

2. **Hole die Flutter-Abhängigkeiten:**
   ```bash
   flutter pub get
   ```

3. **Generiere die JSON-Serialisierungsdateien:**
   ```bash
   flutter pub run build_runner build
   ```

4. **Starte einen Emulator oder verbinde ein Gerät:**
   ```bash
   flutter emulators --launch <emulator_name>
   ```

5. **Starten Sie die App:**
   ```bash
   flutter run
   ```

## Android-Emulator konfigurieren

```bash
# Emulator mit GPS-Unterstützung starten
emulator -avd <avd_name> -use-system-libs -gpu on
```

## Entwicklung

### Hot Reload aktivieren
- Drücke `r` in der Terminal, um den Code neu zu laden
- Drücke `R` für vollständigen Restart

### Debugging
```bash
flutter run -v  # Verbose output
flutter analyze # Code-Analyse
flutter test    # Tests ausführen
```

## Build für Release

```bash
# Android APK bauen
flutter build apk --release

# Android App Bundle (AAB) bauen
flutter build appbundle --release
```

## Mögliche Probleme & Lösungen

### "Flutter SDK not found"
- Stelle sicher, dass Flutter im PATH ist
- Überprüfe `local.properties`

### Standort wird nicht aktualisiert
- Aktiviere GPS im Emulator
- Überprüfe Berechtigungen in AndroidManifest.xml
- Stelle sicher, dass `Permission.location` gewährt wurde

### Maps werden nicht angezeigt
- Überprüfe deinen Google Maps API Key
- Stelle sicher, dass "Maps SDK for Android" aktiviert ist

### Build-Fehler
```bash
flutter clean
flutter pub get
flutter run
```

## Nächste Schritte

1. **Google Maps aktivieren:** Ersetze das Placeholder-Widget in `map_screen.dart`
2. **Datenbankintegration:** Nutze `sqflite` für persistente Speicherung
3. **mehr Sehenswürdigkeiten hinzufügen:** Bearbeite `landmark_service.dart`
4. **Benutzerauthentifizierung:** Integriere Firebase Authentication
5. **Backend-Integration:** Verbinde dich mit einem API für Live-Daten

---

**Für weitere Hilfe, siehe README.md**
