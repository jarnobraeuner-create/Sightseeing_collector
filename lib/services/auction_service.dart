import 'package:flutter/foundation.dart';
import '../models/auction.dart';

class AuctionService extends ChangeNotifier {
  final List<Auction> _auctions = [];
  
  List<Auction> get auctions => _auctions.where((a) => a.isActive).toList();
  
  AuctionService() {
    _initializeDemoAuctions();
  }

  void _initializeDemoAuctions() {
    // Demo-Auktionen für Testing
    final now = DateTime.now();
    
    _auctions.addAll([
      Auction(
        id: 'auction_1',
        sellerId: 'demo_seller_1',
        sellerName: 'Max Mustermann',
        tokenId: '1',
        tokenName: 'Speicherstadt',
        tokenImageUrl: 'assets/images/Token_gold_speicherstadt.png',
        minimumCoins: 50,
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        bids: [
          Bid(
            id: 'bid_1',
            bidderId: 'bidder_1',
            bidderName: 'Anna Schmidt',
            coins: 75,
            offeredTokenIds: [],
            offeredTokenNames: [],
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Auction(
        id: 'auction_2',
        sellerId: 'demo_seller_2',
        sellerName: 'Lisa Müller',
        tokenId: '2',
        tokenName: 'Elbphilharmonie',
        tokenImageUrl: 'assets/images/Token_gold_elbphilharmonie.png',
        minimumCoins: 80,
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
        bids: [
          Bid(
            id: 'bid_2',
            bidderId: 'bidder_2',
            bidderName: 'Tom Weber',
            coins: 50,
            offeredTokenIds: ['4'],
            offeredTokenNames: ['Michel'],
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      Auction(
        id: 'auction_3',
        sellerId: 'demo_seller_3',
        sellerName: 'Peter Klein',
        tokenId: '5',
        tokenName: 'Chilehaus',
        tokenImageUrl: 'assets/images/Token_gold_chilehaus.png',
        minimumCoins: 60,
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 23)),
        bids: [],
      ),
    ]);
  }

  void createAuction(
    String sellerId,
    String sellerName,
    String tokenId,
    String tokenName,
    String tokenImageUrl,
    int minimumCoins,
  ) {
    final auction = Auction(
      id: 'auction_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      sellerName: sellerName,
      tokenId: tokenId,
      tokenName: tokenName,
      tokenImageUrl: tokenImageUrl,
      minimumCoins: minimumCoins,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
    
    _auctions.add(auction);
    notifyListeners();
  }

  void placeBid(
    String auctionId,
    String bidderId,
    String bidderName,
    int coins,
    List<String> offeredTokenIds,
    List<String> offeredTokenNames,
  ) {
    final auctionIndex = _auctions.indexWhere((a) => a.id == auctionId);
    if (auctionIndex == -1) return;

    final bid = Bid(
      id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
      bidderId: bidderId,
      bidderName: bidderName,
      coins: coins,
      offeredTokenIds: offeredTokenIds,
      offeredTokenNames: offeredTokenNames,
      createdAt: DateTime.now(),
    );

    _auctions[auctionIndex].bids.add(bid);
    notifyListeners();
  }

  void acceptBid(String auctionId, String bidId) {
    final auctionIndex = _auctions.indexWhere((a) => a.id == auctionId);
    if (auctionIndex == -1) return;

    _auctions[auctionIndex].isActive = false;
    notifyListeners();
  }

  void cancelAuction(String auctionId) {
    final auctionIndex = _auctions.indexWhere((a) => a.id == auctionId);
    if (auctionIndex == -1) return;

    _auctions[auctionIndex].isActive = false;
    notifyListeners();
  }

  List<Auction> getMyAuctions(String userId) {
    return _auctions.where((a) => a.sellerId == userId && a.isActive).toList();
  }

  List<Auction> getMyBids(String userId) {
    return _auctions.where((a) => 
      a.isActive && a.bids.any((b) => b.bidderId == userId)
    ).toList();
  }
}
