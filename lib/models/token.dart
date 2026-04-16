class Token {
  final String id;
  final String landmarkId;
  final String landmarkName;
  final String category;
  final DateTime collectedAt;
  final int points;
  final List<String> setIds;

  Token({
    required this.id,
    required this.landmarkId,
    required this.landmarkName,
    required this.category,
    required this.collectedAt,
    required this.points,
    this.setIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'landmarkId': landmarkId,
        'landmarkName': landmarkName,
        'category': category,
        'collectedAt': collectedAt.toIso8601String(),
        'points': points,
        'setIds': setIds,
      };

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'],
        landmarkId: json['landmarkId'],
        landmarkName: json['landmarkName'],
        category: json['category'],
        collectedAt: DateTime.parse(json['collectedAt']),
        points: json['points'],
        setIds: List<String>.from(json['setIds'] ?? []),
      );
}
