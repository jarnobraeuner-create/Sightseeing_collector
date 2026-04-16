class Auction {
  final String id;
  final String sellerId;
  final String sellerName;
  final String tokenId;
  final String tokenName;
  final String tokenImageUrl;
  final int minimumCoins;
  final DateTime createdAt;
  final DateTime expiresAt;
  List<Bid> bids;
  bool isActive;

  Auction({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.tokenId,
    required this.tokenName,
    required this.tokenImageUrl,
    required this.minimumCoins,
    required this.createdAt,
    required this.expiresAt,
    this.bids = const [],
    this.isActive = true,
  });

  Bid? get highestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.totalValue > b.totalValue ? a : b);
  }
}

class Bid {
  final String id;
  final String bidderId;
  final String bidderName;
  final int coins;
  final List<String> offeredTokenIds;
  final List<String> offeredTokenNames;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.coins,
    required this.offeredTokenIds,
    required this.offeredTokenNames,
    required this.createdAt,
  });

  int get totalValue {
    // Jeder Token ist etwa 100 Punkte wert + coins
    return (offeredTokenIds.length * 100) + coins;
  }

  String get description {
    if (offeredTokenIds.isEmpty && coins > 0) {
      return '$coins Coins';
    } else if (offeredTokenIds.isNotEmpty && coins == 0) {
      return '${offeredTokenIds.length} Token${offeredTokenIds.length > 1 ? 's' : ''}';
    } else {
      return '${offeredTokenIds.length} Token${offeredTokenIds.length > 1 ? 's' : ''} + $coins Coins';
    }
  }
}
