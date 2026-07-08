import 'package:cloud_firestore/cloud_firestore.dart';

class NightToken {
  final String id;
  final String locationId;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String tokenImageUrl;
  final String markerImageUrl;
  final String status;
  final DateTime updatedAt;

  const NightToken({
    required this.id,
    required this.locationId,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.tokenImageUrl,
    required this.markerImageUrl,
    this.status = 'coming_soon',
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'tokenImageUrl': tokenImageUrl,
      'markerImageUrl': markerImageUrl,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory NightToken.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return NightToken(
      id: id ?? (json['id'] as String? ?? ''),
      locationId: json['locationId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'night',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      tokenImageUrl: json['tokenImageUrl'] as String? ?? '',
      markerImageUrl: json['markerImageUrl'] as String? ?? 'assets/images/map_pin_gold.png',
      status: json['status'] as String? ?? 'coming_soon',
      updatedAt: toDate(json['updatedAt']),
    );
  }

  factory NightToken.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return NightToken.fromJson(doc.data() ?? {}, id: doc.id);
  }
}