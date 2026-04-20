import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction.dart';

class AuctionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  final List<Auction> _auctions = [];
  bool _isLoaded = false;

  List<Auction> get auctions => _auctions.toList();
  bool get isLoaded => _isLoaded;

  AuctionService() {
    _listenToAuctions();
  }

  void _listenToAuctions() {
    _subscription = _db
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final now = DateTime.now();
      _auctions.clear();
      for (final doc in snapshot.docs) {
        try {
          final auction = Auction.fromFirestore(doc.data(), doc.id);
          if (auction.endsAt.isBefore(now)) {
            // Abgelaufene Auktionen automatisch beenden
            _db.collection('auctions').doc(doc.id)
                .update({'status': 'ended'})
                .catchError((e) => debugPrint('Error ending auction: $e'));
          } else {
            _auctions.add(auction);
          }
        } catch (e) {
          debugPrint('Error parsing auction ${doc.id}: $e');
        }
      }
      _isLoaded = true;
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
    int minimumCoins,
  ) async {
    final now = DateTime.now();
    final auction = Auction(
      id: '',
      sellerId: sellerId,
      sellerName: sellerName,
      title: tokenName,
      imageUrl: tokenImageUrl,
      category: tokenId,
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

  // â”€â”€â”€ Accept Bid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> acceptBid(String auctionId, String bidId) async {
    await _db.collection('auctions').doc(auctionId).update({'status': 'ended'});
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
}
