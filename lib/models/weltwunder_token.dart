import 'package:cloud_firestore/cloud_firestore.dart';

class WorldWonderToken {
  final String tokenId;
  final String wonderId;
  final int serial;
  final String landmarkId;
  final String landmarkName;
  final String title;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final int points;
  final String ownerUid;
  final String ownerUsername;
  final DateTime claimedAt;
  final String status;

  const WorldWonderToken({
    required this.tokenId,
    required this.wonderId,
    required this.serial,
    required this.landmarkId,
    required this.landmarkName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.points,
    required this.ownerUid,
    required this.ownerUsername,
    required this.claimedAt,
    required this.status,
  });

  String get displayNumber => '#$serial';

  Map<String, dynamic> toFirestore() => {
        'tokenId': tokenId,
        'wonderId': wonderId,
        'serial': serial,
        'landmarkId': landmarkId,
        'landmarkName': landmarkName,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'points': points,
        'ownerUid': ownerUid,
        'ownerUsername': ownerUsername,
        'claimedAt': Timestamp.fromDate(claimedAt),
        'status': status,
      };

  factory WorldWonderToken.fromFirestore(Map<String, dynamic> data, String id) {
    return WorldWonderToken(
      tokenId: data['tokenId'] as String? ?? id,
      wonderId: data['wonderId'] as String? ?? '',
      serial: (data['serial'] as num?)?.toInt() ?? 0,
      landmarkId: data['landmarkId'] as String? ?? '',
      landmarkName: data['landmarkName'] as String? ?? '',
      title: data['title'] as String? ?? data['landmarkName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerUsername: data['ownerUsername'] as String? ?? '',
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'owned',
    );
  }
}