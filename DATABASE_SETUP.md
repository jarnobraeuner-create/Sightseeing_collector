# Datenbank-Setup für Multiplayer Marketplace

## Übersicht
Der Marketplace ist vorbereitet für die Anbindung an eine Echtzeit-Datenbank (Firebase/Supabase).

## Benötigte Komponenten

### 1. Firebase Setup
```bash
# Installiere Firebase Packages
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth
```

### 2. Datenbank-Struktur (Firestore)

```
users/
  {userId}/
    - username: String
    - email: String
    - coins: int
    - tokenIds: List<String>
    - createdAt: Timestamp

auctions/
  {auctionId}/
    - sellerId: String
    - sellerName: String
    - tokenId: String
    - tokenName: String
    - tokenImageUrl: String
    - minimumCoins: int
    - createdAt: Timestamp
    - expiresAt: Timestamp
    - isActive: bool
    
    bids/
      {bidId}/
        - bidderId: String
        - bidderName: String
        - coins: int
        - offeredTokenIds: List<String>
        - offeredTokenNames: List<String>
        - createdAt: Timestamp

tokens/
  {tokenId}/
    - userId: String
    - landmarkId: String
    - landmarkName: String
    - collectedAt: Timestamp
    - points: int
```

## 3. Implementierung

### User Authentication
```dart
// In lib/services/auth_service.dart (neu erstellen)
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
    notifyListeners();
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
```

### Firestore Auction Service
```dart
// In lib/services/auction_service.dart - Ersetze die lokale Version
import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<List<Auction>> get auctionsStream {
    return _firestore
        .collection('auctions')
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: DateTime.now())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Auction.fromJson(doc.data()))
            .toList());
  }
  
  Future<void> createAuction(Auction auction) async {
    await _firestore
        .collection('auctions')
        .doc(auction.id)
        .set(auction.toJson());
  }
  
  Future<void> placeBid(String auctionId, Bid bid) async {
    await _firestore
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .doc(bid.id)
        .set(bid.toJson());
  }
}
```

## 4. Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users können nur ihre eigenen Daten lesen/schreiben
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Auktionen können alle lesen, aber nur Owner erstellen
    match /auctions/{auctionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
                    && request.resource.data.sellerId == request.auth.uid;
      allow update: if request.auth != null 
                    && resource.data.sellerId == request.auth.uid;
      
      // Gebote können alle authenticated users erstellen
      match /bids/{bidId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
    
    // Tokens gehören den Usern
    match /tokens/{tokenId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null 
                   && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## 5. Migration Steps

### Schritt 1: Firebase Projekt erstellen
1. Gehe zu https://console.firebase.google.com
2. Erstelle neues Projekt
3. Aktiviere Firestore Database
4. Aktiviere Authentication (Anonymous + Email)

### Schritt 2: Flutter App konfigurieren
```bash
# Firebase CLI installieren
npm install -g firebase-tools

# In deinem Projekt
flutterfire configure
```

### Schritt 3: Code anpassen
- Ersetze `AuctionService._initializeDemoAuctions()` durch Firestore Streams
- Ändere `'current_user'` zu `FirebaseAuth.instance.currentUser!.uid`
- Nutze `StreamBuilder` statt `Consumer` für Realtime Updates

### Schritt 4: UI mit Streams verbinden
```dart
StreamBuilder<List<Auction>>(
  stream: auctionService.auctionsStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final auctions = snapshot.data!;
    return ListView.builder(...);
  },
)
```

## 6. Vorteile der vorbereiteten Struktur

✅ **toJson/fromJson** - Alle Modelle sind serialisierbar  
✅ **User Model** - Bereit für echte User-Verwaltung  
✅ **Timestamp-kompatibel** - DateTime.toIso8601String()  
✅ **Modulare Struktur** - Einfach austauschbar  
✅ **Stream-ready** - Vorbereitet für Realtime Updates  

## 7. Alternative: Supabase

Falls du Supabase statt Firebase nutzen willst:
```bash
flutter pub add supabase_flutter
```

Supabase nutzt PostgreSQL und ist einfacher für komplexe Queries.

## Nächste Schritte

1. Entscheide dich für Firebase oder Supabase
2. Erstelle das Backend-Projekt
3. Installiere die Packages
4. Ersetze die Demo-Daten durch echte Datenbank-Calls
5. Teste mit mehreren Usern

## Kosten

- **Firebase**: 50k Reads/Tag kostenlos
- **Supabase**: 500MB Datenbank kostenlos
- Beide haben großzügige Free Tiers für Indie-Entwickler
