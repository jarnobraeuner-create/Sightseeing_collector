import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/landmark.dart';
import '../models/weltwunder_token.dart';

class WeltwunderService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static bool isWeltwunderLandmark(Landmark landmark) {
    return landmark.category == 'weltwunder';
  }

  DocumentReference<Map<String, dynamic>> _wonderRef(String wonderId) {
    return _db.collection('weltwunder').doc(wonderId);
  }

  DocumentReference<Map<String, dynamic>> _instanceRef(
    String wonderId,
    int serial,
  ) {
    return _wonderRef(wonderId).collection('tokens').doc(serial.toString());
  }

  DocumentReference<Map<String, dynamic>> _userMirrorRef(
    String ownerUid,
    String tokenId,
  ) {
    return _db.collection('users').doc(ownerUid).collection('weltwunder').doc(tokenId);
  }

  static WorldWonderToken fromLandmarkAndOwner({
    required Landmark landmark,
    required int serial,
    required String ownerUid,
    required String ownerUsername,
    required DateTime claimedAt,
  }) {
    return WorldWonderToken(
      tokenId: '${landmark.id}_$serial',
      wonderId: landmark.id,
      serial: serial,
      landmarkId: landmark.id,
      landmarkName: landmark.name,
      title: landmark.name,
      description: landmark.description,
      imageUrl: landmark.imageUrl,
      latitude: landmark.latitude,
      longitude: landmark.longitude,
      points: landmark.pointsReward,
      ownerUid: ownerUid,
      ownerUsername: ownerUsername,
      claimedAt: claimedAt,
      status: 'owned',
    );
  }

  Future<WorldWonderToken?> claimWorldWonderToken({
    required Landmark landmark,
    required String ownerUid,
    required String ownerUsername,
  }) async {
    if (!isWeltwunderLandmark(landmark)) return null;

    final ownedSnap = await _db
        .collection('users')
        .doc(ownerUid)
        .collection('weltwunder')
        .where('wonderId', isEqualTo: landmark.id)
        .limit(1)
        .get();
    if (ownedSnap.docs.isNotEmpty) {
      return null;
    }

    return _db.runTransaction((tx) async {
      final wonderRef = _wonderRef(landmark.id);
      final wonderSnap = await tx.get(wonderRef);
      final wonderData = wonderSnap.data() ?? <String, dynamic>{};
      final nextSerial = (wonderData['nextSerial'] as num?)?.toInt() ?? 1;
      final instanceRef = _instanceRef(landmark.id, nextSerial);
      final instanceSnap = await tx.get(instanceRef);
      if (instanceSnap.exists) {
        throw StateError('Weltwunder-Token #$nextSerial für ${landmark.id} ist bereits vergeben.');
      }

      final token = fromLandmarkAndOwner(
        landmark: landmark,
        serial: nextSerial,
        ownerUid: ownerUid,
        ownerUsername: ownerUsername,
        claimedAt: DateTime.now(),
      );

      tx.set(
        wonderRef,
        {
          'wonderId': landmark.id,
          'title': landmark.name,
          'description': landmark.description,
          'imageUrl': landmark.imageUrl,
          'latitude': landmark.latitude,
          'longitude': landmark.longitude,
          'nextSerial': nextSerial + 1,
          'totalClaimed': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(instanceRef, token.toFirestore());
      tx.set(_userMirrorRef(ownerUid, token.tokenId), token.toFirestore());
      return token;
    });
  }

  Future<List<WorldWonderToken>> loadOwnedTokens(String ownerUid) async {
    final snap = await _db
        .collection('users')
        .doc(ownerUid)
        .collection('weltwunder')
        .orderBy('claimedAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => WorldWonderToken.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> releaseToken(WorldWonderToken token) async {
    final batch = _db.batch();
    batch.set(
      _instanceRef(token.wonderId, token.serial),
      {
        ...token.toFirestore(),
        'status': 'released',
        'ownerUid': null,
        'ownerUsername': null,
        'releasedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.delete(_userMirrorRef(token.ownerUid, token.tokenId));
    await batch.commit();
  }

  Future<int> getNextSerial(String wonderId) async {
    final snap = await _wonderRef(wonderId).get();
    return (snap.data()?['nextSerial'] as num?)?.toInt() ?? 1;
  }
}
