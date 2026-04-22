enum TokenTier {
  bronze,
  silver,
  gold,
  platinum,
  monumente;

  String get displayName {
    switch (this) {
      case TokenTier.bronze:
        return 'Bronze';
      case TokenTier.silver:
        return 'Silber';
      case TokenTier.gold:
        return 'Gold';
      case TokenTier.platinum:
        return 'Platin';
      case TokenTier.monumente:
        return 'Monumente';
    }
  }

  int get pointValue {
    switch (this) {
      case TokenTier.bronze:
        return 10;
      case TokenTier.silver:
        return 50;
      case TokenTier.gold:
        return 200;
      case TokenTier.platinum:
        return 1000;
      case TokenTier.monumente:
        return 5000;
    }
  }
}

class Token {
  final String id;
  final String landmarkId;
  final String landmarkName;
  final String category;
  final DateTime collectedAt;
  final int points;
  final List<String> setIds;
  final TokenTier tier;

  Token({
    required this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.category,
    required this.collectedAt,
    required this.points,
    this.setIds = const [],
    this.tier = TokenTier.bronze,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': landmarkId,
        'landmarkName': landmarkName,
        'category': category,
        'collectedAt': collectedAt.toIso8601String(),
        'points': points,
        'setIds': setIds,
        'tier': tier.name,
      };

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'],
        landmarkId: json['landmarkId'],
        landmarkName: json['landmarkName'],
        category: json['category'],
        collectedAt: DateTime.parse(json['collectedAt']),
        points: json['points'],
        setIds: List<String>.from(json['setIds'] ?? []),
        tier: TokenTier.values.firstWhere(
          (t) => t.name == (json['tier'] ?? 'bronze'),
          orElse: () => TokenTier.bronze,
        ),
      );
}
