import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/night_token.dart';

class NightTokenRepository {
  NightTokenRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _nightTokensRef =>
      _db.collection('night_tokens');

  CollectionReference<Map<String, dynamic>> get _nightLocationsRef =>
      _db.collection('night_locations');

  CollectionReference<Map<String, dynamic>> get _nightProgressRef =>
      _db.collection('night_progress');

  CollectionReference<Map<String, dynamic>> get _nightRewardsRef =>
      _db.collection('night_rewards');

  CollectionReference<Map<String, dynamic>> get _nightStatsRef =>
      _db.collection('night_stats');

  CollectionReference<Map<String, dynamic>> _userNightTokensRef(String uid) {
    return _db.collection('users').doc(uid).collection('night_tokens');
  }

  Stream<List<NightToken>> streamNightTokens({int limit = 200}) {
    return _nightTokensRef
        .where('status', isEqualTo: 'active')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(NightToken.fromFirestore).toList());
  }

  Stream<Set<String>> streamCollectedNightTokenIds(String uid) {
    return _userNightTokensRef(uid).snapshots().map(
          (snap) => snap.docs.map((doc) => doc.id).toSet(),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNightLocations() {
    return _nightLocationsRef.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchNightProgress(String uid) {
    return _nightProgressRef.doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchNightStats(String uid) {
    return _nightStatsRef.doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> readNightProgress(String uid) async {
    final doc = await _nightProgressRef.doc(uid).get();
    return doc.data();
  }

  Future<void> writeNightProgress(String uid, Map<String, dynamic> data) async {
    await _nightProgressRef.doc(uid).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> readNightStats(String uid) async {
    final doc = await _nightStatsRef.doc(uid).get();
    return doc.data();
  }

  Future<void> writeNightStats(String uid, Map<String, dynamic> data) async {
    await _nightStatsRef.doc(uid).set(
      {...data, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> upsertNightTokenDefinition(NightToken token) async {
    await _nightTokensRef.doc(token.id).set(token.toJson(), SetOptions(merge: true));
  }

  Future<void> upsertNightLocation(Map<String, dynamic> location, String id) async {
    await _nightLocationsRef.doc(id).set(
      {...location, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> upsertNightReward(String id, Map<String, dynamic> reward) async {
    await _nightRewardsRef.doc(id).set(
      {...reward, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> markNightFeatureState(String uid, Map<String, dynamic> state) async {
    await _nightStatsRef.doc(uid).set(
      {...state, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}