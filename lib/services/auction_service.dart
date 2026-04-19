import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction.dart';

class AuctionService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  final List<Auction> _auctions = [];
  bool _isLoaded = false;

  List<Auction> get auctions => _auctions.where((a) => a.isActive).toList();
  bool get isLoaded => _isLoaded;

  AuctionService() {
    _listenToAuctions();
  }

  void _listenToAuctions() {
    _subscription = _db
        .collection('auctions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _auctions.clear();
      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        try {
          final auction = Auction.fromJson(doc.data());
          // Automatisch abgelaufene Auktionen deaktivieren
          if (auction.isActive && auction.expiresAt.isBefore(now)) {
            _db.collection('auctions').doc(doc.id).update({'isActive': false});
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

  // ─── Create Auction ───────────────────────────────────────────────────────

  Future<void> createAuction(
    String sellerId,
    String sellerName,
    String tokenId,
    String tokenName,
    String tokenImageUrl,
    int minimumCoins,
  ) async {
    final id = 'auction_${DateTime.now().millisecondsSinceEpoch}';
    final auction = Auction(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      tokenId: tokenId,
      tokenName: tokenName,
      tokenImageUrl: tokenImageUrl,
      minimumCoins: minimumCoins,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );

    await _db.collection('auctions').doc(id).set(auction.toJson());
    // Stream update wird den UI refresh triggern
  }

  // ─── Place Bid ────────────────────────────────────────────────────────────

  Future<void> placeBid(
    String auctionId,
    String bidderId,
    String bidderName,
    int coins,
    List<String> offeredTokenIds,
    List<String> offeredTokenNames,
  ) async {
    final bid = Bid(
      id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
      bidderId: bidderId,
      bidderName: bidderName,
      coins: coins,
      offeredTokenIds: offeredTokenIds,
      offeredTokenNames: offeredTokenNames,
      createdAt: DateTime.now(),
    );

    await _db.collection('auctions').doc(auctionId).update({
      'bids': FieldValue.arrayUnion([bid.toJson()]),
    });
  }

  // ─── Accept Bid ───────────────────────────────────────────────────────────

  Future<void> acceptBid(String auctionId, String bidId) async {
    await _db
        .collection('auctions')
        .doc(auctionId)
        .update({'isActive': false, 'acceptedBidId': bidId});
  }

  // ─── Cancel Auction ───────────────────────────────────────────────────────

  Future<void> cancelAuction(String auctionId) async {
    await _db
        .collection('auctions')
        .doc(auctionId)
        .update({'isActive': false});
  }

  // ─── Queries ─────────────────────────────────────────────────────────────

  List<Auction> getMyAuctions(String userId) {
    return _auctions.where((a) => a.sellerId == userId && a.isActive).toList();
  }

  List<Auction> getMyBids(String userId) {
    return _auctions
        .where((a) => a.isActive && a.bids.any((b) => b.bidderId == userId))
        .toList();
  }
}
