class CollectionSet {
  final String id;
  final String name;
  final String description;
  final List<String> requiredTokenIds;
  final List<String> collectedTokenIds;
  final int bonusPoints;
  final bool completed;
  final String? rewardImageUrl;

  CollectionSet({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredTokenIds,
    this.collectedTokenIds = const [],
    required this.bonusPoints,
    this.completed = false,
    this.rewardImageUrl,
  });

  double get completionPercentage {
    if (requiredTokenIds.isEmpty) return 0;
    return (collectedTokenIds.length / requiredTokenIds.length) * 100;
  }

  CollectionSet copyWith({
    List<String>? collectedTokenIds,
    bool? completed,
  }) {
    return CollectionSet(
      id: id,
      name: name,
      description: description,
      requiredTokenIds: requiredTokenIds,
      collectedTokenIds: collectedTokenIds ?? this.collectedTokenIds,
      bonusPoints: bonusPoints,
      completed: completed ?? this.completed,
      rewardImageUrl: rewardImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requiredTokenIds': requiredTokenIds,
        'collectedTokenIds': collectedTokenIds,
        'bonusPoints': bonusPoints,
        'completed': completed,
        'rewardImageUrl': rewardImageUrl,
      };

  factory CollectionSet.fromJson(Map<String, dynamic> json) => CollectionSet(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        requiredTokenIds: List<String>.from(json['requiredTokenIds'] ?? []),
        collectedTokenIds: List<String>.from(json['collectedTokenIds'] ?? []),
        bonusPoints: json['bonusPoints'],
        completed: json['completed'] ?? false,
        rewardImageUrl: json['rewardImageUrl'],
      );
}
