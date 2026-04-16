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

  // Für Firebase/Datenbank
  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'tokenId': tokenId,
        'tokenName': tokenName,
        'tokenImageUrl': tokenImageUrl,
        'minimumCoins': minimumCoins,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'bids': bids.map((b) => b.toJson()).toList(),
        'isActive': isActive,
      };

  factory Auction.fromJson(Map<String, dynamic> json) => Auction(
        id: json['id'] as String,
        sellerId: json['sellerId'] as String,
        sellerName: json['sellerName'] as String,
        tokenId: json['tokenId'] as String,
        tokenName: json['tokenName'] as String,
        tokenImageUrl: json['tokenImageUrl'] as String,
        minimumCoins: json['minimumCoins'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        bids: (json['bids'] as List).map((b) => Bid.fromJson(b)).toList(),
        isActive: json['isActive'] as bool,
      );
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

  // Für Firebase/Datenbank
  Map<String, dynamic> toJson() => {
        'id': id,
        'bidderId': bidderId,
        'bidderName': bidderName,
        'coins': coins,
        'offeredTokenIds': offeredTokenIds,
        'offeredTokenNames': offeredTokenNames,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        id: json['id'] as String,
        bidderId: json['bidderId'] as String,
        bidderName: json['bidderName'] as String,
        coins: json['coins'] as int,
        offeredTokenIds: List<String>.from(json['offeredTokenIds'] as List),
        offeredTokenNames: List<String>.from(json['offeredTokenNames'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
