enum TokenTier {
  bronze,
  silver,
  gold,
  platinum,
  monumente,
  weltwunder;

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
      case TokenTier.weltwunder:
        return 'Weltwunder';
    }
  }

  int get pointValue {
    switch (this) {
      case TokenTier.bronze:
        return 10;
      case TokenTier.silver:
        return 50;
      case TokenTier.gold:
        return 100;
      case TokenTier.platinum:
        return 250;
      case TokenTier.monumente:
        return 1000;
      case TokenTier.weltwunder:
        return 2000;
    }
  }
}

class Weltwunder {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  Weltwunder({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });
}

class Token {
  final String id;
  final String landmarkId;
  final String landmarkName;
  final String category;
  final DateTime collectedAt;
  final int points;
  final List<String> setIds;
  final TokenTier? tier; // nullable for legacy data
  final Weltwunder? weltwunder; // falls Weltwunder
  final String? worldWonderId;
  final int? worldWonderSerial;
  final String? worldWonderOwnerUid;
  final String? worldWonderOwnerUsername;

    bool get isWorldWonder =>
      category == 'weltwunder' || worldWonderId != null || weltwunder != null;

    String? get worldWonderBadgeLabel =>
      worldWonderSerial != null ? '#$worldWonderSerial' : null;

  Token({
    required this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.category,
    required this.collectedAt,
    required this.points,
    this.setIds = const [],
    this.tier,
    this.weltwunder,
    this.worldWonderId,
    this.worldWonderSerial,
    this.worldWonderOwnerUid,
    this.worldWonderOwnerUsername,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': landmarkId,
        'landmarkName': landmarkName,
        'category': category,
        'points': points,
        'setIds': setIds,
        'tier': tier?.name,
        'worldWonderId': worldWonderId,
        'worldWonderSerial': worldWonderSerial,
        'worldWonderOwnerUid': worldWonderOwnerUid,
        'worldWonderOwnerUsername': worldWonderOwnerUsername,
        // weltwunder: serialization nach Bedarf ergänzen
      };

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'],
        landmarkId: json['landmarkId'],
        landmarkName: json['landmarkName'],
        category: json['category'],
        collectedAt: DateTime.parse(json['collectedAt']),
        points: json['points'],
        setIds: List<String>.from(json['setIds'] ?? []),
        tier: json['tier'] != null
            ? TokenTier.values.firstWhere(
                (t) => t.name == json['tier'],
                orElse: () => TokenTier.bronze,
              )
            : (json['category'] == 'weltwunder'
                ? TokenTier.weltwunder
                : null),
        worldWonderId: json['worldWonderId'] as String?,
        worldWonderSerial: (json['worldWonderSerial'] as num?)?.toInt(),
        worldWonderOwnerUid: json['worldWonderOwnerUid'] as String?,
        worldWonderOwnerUsername: json['worldWonderOwnerUsername'] as String?,
        // weltwunder: deserialization nach Bedarf ergänzen
      );
}
