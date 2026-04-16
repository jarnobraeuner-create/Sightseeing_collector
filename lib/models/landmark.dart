import 'dart:math';

class Quest {
  final String id;
  final String title;
  final String taskType; // 'photo', 'checkin', 'puzzle'
  final bool completed;

  Quest({
    required this.id,
    required this.title,
    required this.taskType,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'taskType': taskType,
        'completed': completed,
      };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'],
        title: json['title'],
        taskType: json['taskType'],
        completed: json['completed'] ?? false,
      );
}

class Landmark {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category; // 'sightseeing' or 'travel'
  final String difficulty; // 'easy', 'medium', 'hard'
  final int pointsReward;
  final String imageUrl;
  final List<Quest> quests;
  final List<String> relatedSetIds;

  Landmark({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.difficulty,
    required this.pointsReward,
    required this.imageUrl,
    this.quests = const [],
    this.relatedSetIds = const [],
  });

  // Calculate distance to user using Haversine formula
  double getDistance(double userLat, double userLon) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(userLat - latitude);
    double dLon = _toRadians(userLon - longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(userLat)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance; // in km
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'difficulty': difficulty,
        'pointsReward': pointsReward,
        'imageUrl': imageUrl,
        'quests': quests.map((q) => q.toJson()).toList(),
        'relatedSetIds': relatedSetIds,
      };

  factory Landmark.fromJson(Map<String, dynamic> json) => Landmark(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        category: json['category'],
        difficulty: json['difficulty'],
        pointsReward: json['pointsReward'],
        imageUrl: json['imageUrl'],
        quests: (json['quests'] as List?)
                ?.map((q) => Quest.fromJson(q))
                .toList() ??
            [],
        relatedSetIds: List<String>.from(json['relatedSetIds'] ?? []),
      );
}
