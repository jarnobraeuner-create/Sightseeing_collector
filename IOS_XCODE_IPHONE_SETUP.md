# iOS Deployment Setup (Xcode -> iPhone)

Diese Checkliste ist auf dieses Projekt abgestimmt und hilft, die App direkt auf ein echtes iPhone zu laden.

## 1) Voraussetzungen

- Mac mit aktuellem Xcode
- iPhone per Kabel verbunden
- Gleiches Apple-ID Konto in Xcode und auf dem iPhone empfohlen
- Flutter + CocoaPods auf dem Mac installiert

## 2) Flutter vorbereiten

Im Projektordner ausfuehren:

```bash
flutter clean
flutter pub get
cd ios
pod repo update
pod install
cd ..
```

## 3) Immer die Workspace-Datei oeffnen

In Xcode oeffnen:

- ios/Runner.xcworkspace

Nicht ios/Runner.xcodeproj verwenden (Pods und Build-Settings fehlen sonst oft).

## 4) Signing fuer echtes iPhone

In Xcode:

1. Target Runner waehlen
2. Tab Signing & Capabilities
3. Automatically manage signing aktivieren
4. Team auswaehlen (dein Apple Developer Team)
5. Bundle Identifier eindeutig setzen, z. B.:
   com.deinname.sightseeingcollector

Hinweis: Die Signing-Identity ist im Projekt auf Apple Development gesetzt.

## 5) Device-Start

1. Oben als Run Destination dein iPhone auswaehlen
2. Build-Konfiguration zunaechst Debug nutzen
3. Run (Play)

Beim ersten Mal auf dem iPhone bestaetigen:

- Einstellungen -> Allgemein -> VPN und Geraetemanager
- Entwickler-App vertrauen

## 6) Typische Fehler und schnelle Fixes

- No signing certificate / provisioning profile:
  Team und Bundle Identifier in Signing pruefen.
- CocoaPods/Module not found:
  ios/Runner.xcworkspace nutzen und im ios Ordner pod install erneut ausfuehren.
- Build cache Probleme:
  flutter clean, dann flutter pub get und pod install erneut.
- iOS deployment target mismatch:
  Projekt und Pods sind auf iOS 15.0 gesetzt.

## 7) Optional: Release auf Geraet testen

In Xcode Scheme Runner -> Edit Scheme -> Run -> Build Configuration auf Release setzen.

Alternativ mit Flutter (auf Mac):

```bash
flutter run --release
```
