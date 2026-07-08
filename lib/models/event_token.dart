import 'package:cloud_firestore/cloud_firestore.dart';

class EventToken {
  final String id;
  final String eventId;
  final String eventName;
  final String eventDescription;
  final DateTime startDate;
  final DateTime endDate;
  final String landmarkId;
  final String landmarkName;
  final String tokenImageUrl;
  final String markerImageUrl;
  final String eventStatus;
  final double latitude;
  final double longitude;
  final int points;
  final int rewardCoins;
  final int rewardLootboxes;

  const EventToken({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDescription,
    required this.startDate,
    required this.endDate,
    required this.landmarkId,
    required this.landmarkName,
    required this.tokenImageUrl,
    required this.markerImageUrl,
    this.eventStatus = 'active',
    required this.latitude,
    required this.longitude,
    required this.points,
    required this.rewardCoins,
    required this.rewardLootboxes,
  });

  bool get isActive {
    if (eventStatus == 'active') return true;
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'eventDescription': eventDescription,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'landmarkId': landmarkId,
      'landmarkName': landmarkName,
      'tokenImageUrl': tokenImageUrl,
      'markerImageUrl': markerImageUrl,
      'eventStatus': eventStatus,
      'latitude': latitude,
      'longitude': longitude,
      'points': points,
      'rewardCoins': rewardCoins,
      'rewardLootboxes': rewardLootboxes,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory EventToken.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return EventToken(
      id: id ?? (json['id'] as String? ?? ''),
      eventId: json['eventId'] as String? ?? '',
      eventName: json['eventName'] as String? ?? '',
      eventDescription: json['eventDescription'] as String? ?? '',
      startDate: toDate(json['startDate']),
      endDate: toDate(json['endDate']),
      landmarkId: json['landmarkId'] as String? ?? '',
      landmarkName: json['landmarkName'] as String? ?? '',
      tokenImageUrl: json['tokenImageUrl'] as String? ?? '',
      markerImageUrl: json['markerImageUrl'] as String? ?? 'assets/images/map_pin_gold.png',
      eventStatus: json['eventStatus'] as String? ?? 'active',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      rewardLootboxes: (json['rewardLootboxes'] as num?)?.toInt() ?? 0,
    );
  }

  factory EventToken.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EventToken.fromJson(data, id: doc.id);
  }
}
