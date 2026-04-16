class User {
  final String id;
  final String username;
  final String email;
  final int coins;
  final List<String> tokenIds;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.coins,
    required this.tokenIds,
    required this.createdAt,
  });

  // Für Firebase/Datenbank
  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'coins': coins,
        'tokenIds': tokenIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        coins: json['coins'] as int,
        tokenIds: List<String>.from(json['tokenIds'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  User copyWith({
    String? id,
    String? username,
    String? email,
    int? coins,
    List<String>? tokenIds,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      coins: coins ?? this.coins,
      tokenIds: tokenIds ?? this.tokenIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
