import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction.dart';
import 'collection_service.dart';
import 'notification_service.dart';

class AuctionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  final List<Auction> _auctions = [];
  bool _isLoaded = false;
  String? _currentUserId;
  bool _streamInitialized = false;
  // landmarkId → letzter bekannter Bid-Betrag (für Bid-Erkennung)
  final Map<String, int> _lastKnownBids = {};

  List<Auction> get auctions => _auctions.toList();
  bool get isLoaded => _isLoaded;

  AuctionService() {
    _listenToAuctions();
  }

  void setCurrentUserId(String? uid) {
    _currentUserId = uid;
  }

  void _listenToAuctions() {
    _subscription = _db
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      _auctions.clear();
      for (final doc in snapshot.docs) {
        try {
          final auction = Auction.fromFirestore(doc.data(), doc.id);
          if (auction.endsAt.isBefore(now)) {
            final hasNoBids = auction.currentBid <= auction.startPrice;
            if (hasNoBids) {
              // Abgelaufen ohne Gebot: Auktion loeschen (Token bleibt beim Verkaeufer)
              _db.collection('auctions').doc(doc.id)
                  .delete()
                  .catchError((e) => debugPrint('Error deleting expired auction: $e'));
            } else {
              // Abgelaufen mit Geboten: als beendet markieren
              _db.collection('auctions').doc(doc.id)
                  .update({'status': 'ended'})
                  .catchError((e) => debugPrint('Error ending auction: $e'));
              // Verkäufer benachrichtigen wenn Auktion diesem User gehört
              if (_streamInitialized && _currentUserId != null &&
                  auction.sellerId == _currentUserId) {
                NotificationService.instance.showAuctionExpired(auction.title);
              }
            }
          } else {
            // Neues Gebot auf eigene Auktion erkennen
            if (_streamInitialized && _currentUserId != null &&
                auction.sellerId == _currentUserId) {
              final prev = _lastKnownBids[auction.id];
              if (prev != null && auction.currentBid > prev) {
                NotificationService.instance
                    .showBidReceived(auction.title, auction.currentBid);
              }
            }
            _lastKnownBids[auction.id] = auction.currentBid;
            _auctions.add(auction);
          }
        } catch (e) {
          debugPrint('Error parsing auction ${doc.id}: $e');
        }
      }
      // Im Speicher sortieren statt orderBy (kein Composite Index nötig)
      _auctions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoaded = true;
      _streamInitialized = true;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Auction stream error: $e');
      _isLoaded = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // â”€â”€â”€ Create Auction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> createAuction(
    String sellerId,
    String sellerName,
    String tokenId,
    String tokenName,
    String tokenImageUrl,
    int minimumCoins, {
    Map<String, dynamic>? tokenData,
  }) async {
    final now = DateTime.now();
    final auction = Auction(
      id: '',
      sellerId: sellerId,
      sellerName: sellerName,
      title: tokenName,
      imageUrl: tokenImageUrl,
      category: tokenId,
      tokenData: tokenData,
      startPrice: minimumCoins,
      currentBid: minimumCoins,
      status: 'active',
      createdAt: now,
      endsAt: now.add(const Duration(days: 1)),
    );
    await _db.collection('auctions').add(auction.toFirestore());
  }

  // â”€â”€â”€ Place Bid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Gebot wird in Subcollection gespeichert.
  // Hauptdokument wird nur aktualisiert wenn coins > currentBid.

  Future<void> placeBid(
    String auctionId,
    String bidderId,
    String bidderName,
    int coins,
    List<String> offeredTokenIds,
    List<String> offeredTokenNames,
  ) async {
    final bid = Bid(
      id: '',
      bidderId: bidderId,
      bidderName: bidderName,
      coins: coins,
      offeredTokenIds: offeredTokenIds,
      offeredTokenNames: offeredTokenNames,
      createdAt: DateTime.now(),
    );

    // 1. Gebot in Subcollection speichern
    await _db
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .add(bid.toFirestore());

    // 2. Hauptdokument aktualisieren wenn hÃ¶chstes Coin-Gebot
    final auction = _auctions.where((a) => a.id == auctionId).firstOrNull;
    if (auction != null && coins > auction.currentBid) {
      await _db.collection('auctions').doc(auctionId).update({
        'currentBid': coins,
        'highestBidderId': bidderId,
      });
    }
  }

  // â”€â”€â”€ Load Bids (on demand) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<List<Bid>> loadBids(String auctionId) async {
    final snapshot = await _db
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .orderBy('coins', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Bid.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Live-Stream der Gebote für eine Auktion (kein manuelles Neuladen nötig)
  Stream<List<Bid>> bidsStream(String auctionId) {
    return _db
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .orderBy('coins', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Bid.fromFirestore(doc.data(), doc.id)).toList());
  }

  // â”€â”€â”€ Accept Bid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> acceptBid(
    String auctionId,
    Bid bid,
    CollectionService collectionService,
  ) async {
    final auction = _auctions.where((a) => a.id == auctionId).firstOrNull;

    // 1. Auktion als beendet markieren + Gewinner setzen
    await _db.collection('auctions').doc(auctionId).update({
      'status': 'ended',
      'winnerId': bid.bidderId,
      'winnerCoins': bid.coins,
      'tokenClaimed': false,
    });

    // 2. Token aus Verkaeufer-Sammlung entfernen
    if (auction?.category != null) {
      collectionService.removeTokenById(auction!.category!);
    }

    // 3. Coins an Verkaeufer gutschreiben
    if (bid.coins > 0) {
      collectionService.addPoints(bid.coins);
    }
  }

  // â”€â”€â”€ Cancel Auction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> cancelAuction(String auctionId) async {
    await _db.collection('auctions').doc(auctionId).update({'status': 'cancelled'});
  }

  // â”€â”€â”€ Queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<Auction> getMyAuctions(String userId) {
    return _auctions.where((a) => a.sellerId == userId).toList();
  }

  List<Auction> getMyBids(String userId) {
    return _auctions.where((a) => a.highestBidderId == userId).toList();
  }

  Future<bool> hasUserBid(String auctionId, String userId) async {
    final snapshot = await _db
        .collection('auctions')
        .doc(auctionId)
        .collection('bids')
        .where('bidderId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
