import 'package:cloud_firestore/cloud_firestore.dart';

class Auction {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? category; // tokenId (UUID der Token-Instanz)
  final int startPrice;
  int currentBid;
  String? highestBidderId;
  String status; // 'active' | 'ended' | 'cancelled'
  final DateTime createdAt;
  final DateTime endsAt;

  // Gebot-Annahme Felder
  final String? winnerId;
  final Map<String, dynamic>? tokenData;
  final bool tokenClaimed;
  final int winnerCoins;

  List<Bid> bids;

  Auction({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    this.description,
    this.imageUrl,
    this.category,
    required this.startPrice,
    required this.currentBid,
    this.highestBidderId,
    required this.status,
    required this.createdAt,
    required this.endsAt,
    this.winnerId,
    this.tokenData,
    this.tokenClaimed = false,
    this.winnerCoins = 0,
    this.bids = const [],
  });

  bool get isActive => status == 'active' && endsAt.isAfter(DateTime.now());

  Bid? get highestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.coins > b.coins ? a : b);
  }

  Map<String, dynamic> toFirestore() => {
    'sellerId': sellerId,
    'sellerName': sellerName,
    'title': title,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (category != null) 'category': category,
    if (tokenData != null) 'tokenData': tokenData,
    'startPrice': startPrice,
    'currentBid': currentBid,
    'highestBidderId': null,
    'status': status,
    'tokenClaimed': false,
    'winnerCoins': 0,
    'createdAt': Timestamp.fromDate(createdAt),
    'endsAt': Timestamp.fromDate(endsAt),
  };

  factory Auction.fromFirestore(Map<String, dynamic> data, String id) {
    return Auction(
      id: id,
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? 'Unbekannt',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] as String?,
      tokenData: data['tokenData'] != null
          ? Map<String, dynamic>.from(data['tokenData'] as Map)
          : null,
      startPrice: (data['startPrice'] as num?)?.toInt() ?? 0,
      currentBid: (data['currentBid'] as num?)?.toInt() ?? 0,
      highestBidderId: data['highestBidderId'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      endsAt: (data['endsAt'] as Timestamp).toDate(),
      winnerId: data['winnerId'] as String?,
      tokenClaimed: data['tokenClaimed'] as bool? ?? false,
      winnerCoins: (data['winnerCoins'] as num?)?.toInt() ?? 0,
    );
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

  const Bid({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.coins,
    required this.offeredTokenIds,
    required this.offeredTokenNames,
    required this.createdAt,
  });

  int get totalValue => (offeredTokenIds.length * 100) + coins;

  String get description {
    if (offeredTokenIds.isEmpty) return '$coins Coins';
    if (coins == 0) {
      return '${offeredTokenIds.length} Token${offeredTokenIds.length > 1 ? "s" : ""}';
    }
    return '${offeredTokenIds.length} Token${offeredTokenIds.length > 1 ? "s" : ""} + $coins Coins';
  }

  Map<String, dynamic> toFirestore() => {
    'bidderId': bidderId,
    'bidderName': bidderName,
    'coins': coins,
    'offeredTokenIds': offeredTokenIds,
    'offeredTokenNames': offeredTokenNames,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Bid.fromFirestore(Map<String, dynamic> data, String id) => Bid(
    id: id,
    bidderId: data['bidderId'] as String? ?? '',
    bidderName: data['bidderName'] as String? ?? 'Unbekannt',
    coins: (data['coins'] as num?)?.toInt() ?? 0,
    offeredTokenIds: List<String>.from(data['offeredTokenIds'] as List? ?? []),
    offeredTokenNames: List<String>.from(data['offeredTokenNames'] as List? ?? []),
    createdAt: (data['createdAt'] as Timestamp).toDate(),
  );
}