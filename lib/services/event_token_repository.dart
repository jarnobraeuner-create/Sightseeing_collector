import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_token.dart';

class EventTokenRepository {
  EventTokenRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _eventTokensRef =>
      _db.collection('event_tokens');

  CollectionReference<Map<String, dynamic>> _userEventTokensRef(String uid) {
    return _db.collection('users').doc(uid).collection('event_tokens');
  }

  Stream<List<EventToken>> streamActiveEventTokens({
    required String activeEventId,
    int limit = 200,
  }) {
    return _eventTokensRef
      .where('eventStatus', isEqualTo: 'active')
      .where('eventId', isEqualTo: activeEventId)
      .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(EventToken.fromFirestore).toList());
  }

  Stream<Set<String>> streamCollectedEventTokenIds(String uid) {
    return _userEventTokensRef(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Future<void> upsertEventTokenDefinition(EventToken token) async {
    await _eventTokensRef.doc(token.id).set(token.toJson(), SetOptions(merge: true));
  }

  Future<void> collectEventToken({
    required String uid,
    required String username,
    required EventToken token,
  }) async {
    final userDocRef = _userEventTokensRef(uid).doc(token.id);
    await _db.runTransaction((tx) async {
      final existing = await tx.get(userDocRef);
      if (existing.exists) {
        return;
      }

      tx.set(userDocRef, {
        ...token.toJson(),
        'id': token.id,
        'uid': uid,
        'username': username,
        'collectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
