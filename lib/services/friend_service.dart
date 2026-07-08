import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final String toUsername;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.toUsername,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FriendRequest(
      id: doc.id,
      fromUid: d['fromUid'] as String? ?? '',
      fromUsername: d['fromUsername'] as String? ?? '',
      toUid: d['toUid'] as String? ?? '',
      toUsername: d['toUsername'] as String? ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (s) => s.name == (d['status'] as String? ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FriendProfile {
  final String uid;
  final String username;
  final String? photoUrl;
  final int totalPoints;
  final int totalTokens;
  final int worldWonderTokens;
  final int level;
  final int visitedLandmarks;
  final List<FavoriteTokenPreview> favoriteTokens;

  const FriendProfile({
    required this.uid,
    required this.username,
    this.photoUrl,
    required this.totalPoints,
    required this.totalTokens,
    this.worldWonderTokens = 0,
    this.level = 1,
    required this.visitedLandmarks,
    this.favoriteTokens = const [],
  });
}

class FavoriteTokenPreview {
  final String tokenId;
  final String landmarkName;
  final String imageUrl;
  final String? tier;
  final int points;

  const FavoriteTokenPreview({
    required this.tokenId,
    required this.landmarkName,
    required this.imageUrl,
    this.tier,
    required this.points,
  });

  factory FavoriteTokenPreview.fromMap(Map<String, dynamic> data) {
    return FavoriteTokenPreview(
      tokenId: data['tokenId'] as String? ?? '',
      landmarkName: data['landmarkName'] as String? ?? 'Token',
      imageUrl: data['imageUrl'] as String? ?? '',
      tier: data['tier'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardEntry {
  final String uid;
  final String username;
  final String? photoUrl;
  final int totalPoints;
  final int totalTokens;
  final int worldWonderTokens;
  final int level;
  final bool isFriend;
  final bool isMe;

  const LeaderboardEntry({
    required this.uid,
    required this.username,
    this.photoUrl,
    required this.totalPoints,
    required this.totalTokens,
    this.worldWonderTokens = 0,
    this.level = 1,
    required this.isFriend,
    required this.isMe,
  });
}

class AppUserSummary {
  final String uid;
  final String username;
  final String? photoUrl;

  const AppUserSummary({
    required this.uid,
    required this.username,
    this.photoUrl,
  });
}

class FriendService extends ChangeNotifier {
  FriendService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String? _myUid;
  String? _myUsername;
  String? _myPhotoUrl;
  Map<String, int>? _lastPublishedStats;

  String? get myUid => _myUid;
  String? get myUsername => _myUsername;

  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> get incomingRequests => _incomingRequests;

  List<FriendRequest> _outgoingRequests = [];
  List<FriendRequest> get outgoingRequests => _outgoingRequests;

  Set<String> _friendUids = {};
  Set<String> get friendUids => _friendUids;

  final Set<String> _contactFriendUids = {};
  final Set<String> _acceptedSentFriendUids = {};
  final Set<String> _acceptedReceivedFriendUids = {};

  int get incomingCount => _incomingRequests.length;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outgoingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _acceptedAsSenderSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _acceptedAsReceiverSub;

  final StreamController<Set<String>> _friendUidsController =
      StreamController<Set<String>>.broadcast();

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _db.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _leaderboardRef =>
      _db.collection('leaderboard_stats');

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _db.collection('friends').doc(uid).collection('contacts');

  void setUser(String? uid, String? username) {
    if (_myUid == uid && _myUsername == username) return;

    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _friendsSub?.cancel();
    _acceptedAsSenderSub?.cancel();
    _acceptedAsReceiverSub?.cancel();

    _myUid = uid;
    _myUsername = username;
    _incomingRequests = [];
    _outgoingRequests = [];
    _friendUids = {};
    _contactFriendUids.clear();
    _acceptedSentFriendUids.clear();
    _acceptedReceivedFriendUids.clear();

    if (uid != null) {
      _startListening(uid);
      _loadMyPhoto();
    }

    notifyListeners();
  }

  Future<void> _loadMyPhoto() async {
    if (_myUid == null) return;
    final userDoc = await _db.collection('users').doc(_myUid).get();
    _myPhotoUrl = userDoc.data()?['photoUrl'] as String?;
  }

  void _startListening(String uid) {
    _incomingSub = _requestsRef
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _incomingRequests = snap.docs.map(FriendRequest.fromFirestore).toList();
      notifyListeners();
    });

    _outgoingSub = _requestsRef
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _outgoingRequests = snap.docs.map(FriendRequest.fromFirestore).toList();
      notifyListeners();
    });

    _friendsSub = _friendsRef(uid).snapshots().listen((snap) {
      _contactFriendUids
        ..clear()
        ..addAll(snap.docs.map((d) => d.id));
      _emitFriendUids();
    });

    _acceptedAsSenderSub = _requestsRef
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snap) {
      _acceptedSentFriendUids
        ..clear()
        ..addAll(
          snap.docs
              .map((doc) => (doc.data()['toUid'] as String? ?? ''))
              .where((value) => value.isNotEmpty),
        );
      _emitFriendUids();
    });

    _acceptedAsReceiverSub = _requestsRef
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snap) {
      _acceptedReceivedFriendUids
        ..clear()
        ..addAll(
          snap.docs
              .map((doc) => (doc.data()['fromUid'] as String? ?? ''))
              .where((value) => value.isNotEmpty),
        );
      _emitFriendUids();
    });
  }

  void _emitFriendUids() {
    _friendUids = {
      ..._contactFriendUids,
      ..._acceptedSentFriendUids,
      ..._acceptedReceivedFriendUids,
    };
    if (!_friendUidsController.isClosed) {
      _friendUidsController.add(Set<String>.unmodifiable(_friendUids));
    }
    notifyListeners();
  }

  Stream<Set<String>> friendUidsStream() {
    final current = Set<String>.unmodifiable(_friendUids);
    return Stream<Set<String>>.multi((controller) {
      controller.add(current);
      final sub = _friendUidsController.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  void syncLiveStatsFromCollection(Map<String, int> stats) {
    if (_myUid == null) return;

    final normalized = <String, int>{
      'totalPoints': stats['totalPoints'] ?? 0,
      'totalTokens': stats['totalTokens'] ?? 0,
      'visitedLandmarks': stats['visitedLandmarks'] ?? 0,
      'leaderboardScore':
          stats['leaderboardScore'] ?? (stats['totalPoints'] ?? 0),
      'worldWonderTokens': stats['worldWonderTokens'] ?? 0,
      'level': stats['level'] ?? (((stats['totalPoints'] ?? 0) ~/ 100) + 1),
    };

    if (mapEquals(_lastPublishedStats, normalized)) {
      return;
    }
    _lastPublishedStats = Map<String, int>.from(normalized);

    publishMyStats(
      totalPoints: normalized['totalPoints']!,
      totalTokens: normalized['totalTokens']!,
      visitedLandmarks: normalized['visitedLandmarks']!,
      leaderboardScore: normalized['leaderboardScore']!,
      worldWonderTokens: normalized['worldWonderTokens']!,
      level: normalized['level']!,
    );
  }

  Future<List<AppUserSummary>> searchUsers(String query) async {
    if (_myUid == null || query.trim().isEmpty) return [];

    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();
    final results = <String, AppUserSummary>{};

    final directByUid = await _db.collection('users').doc(trimmed).get();
    if (directByUid.exists && directByUid.id != _myUid) {
      results[directByUid.id] = AppUserSummary(
        uid: directByUid.id,
        username: directByUid.data()?['username'] as String? ?? directByUid.id,
        photoUrl: directByUid.data()?['photoUrl'] as String?,
      );
    }

    QuerySnapshot<Map<String, dynamic>> byLower;
    try {
      byLower = await _db
          .collection('users')
          .orderBy('usernameLower')
          .where('usernameLower', isGreaterThanOrEqualTo: lower)
          .where('usernameLower', isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(20)
          .get();
    } catch (_) {
      byLower = await _db.collection('users').limit(50).get();
    }

    for (final d in byLower.docs) {
      if (d.id == _myUid) continue;
      final username = d.data()['username'] as String? ?? d.id;
      if (!username.toLowerCase().contains(lower)) continue;
      results[d.id] = AppUserSummary(
        uid: d.id,
        username: username,
        photoUrl: d.data()['photoUrl'] as String?,
      );
    }

    if (results.isEmpty) {
      final byExact = await _db
          .collection('users')
          .where('username', isEqualTo: trimmed)
          .limit(20)
          .get();
      for (final d in byExact.docs) {
        if (d.id == _myUid) continue;
        results[d.id] = AppUserSummary(
          uid: d.id,
          username: d.data()['username'] as String? ?? d.id,
          photoUrl: d.data()['photoUrl'] as String?,
        );
      }
    }

    return results.values.toList();
  }

  Future<List<AppUserSummary>> loadAllPlayers({int limit = 100}) async {
    final snap = await _db.collection('users').limit(limit).get();

    final players = snap.docs
        .where((d) => d.id != _myUid)
        .map((d) => AppUserSummary(
              uid: d.id,
              username: d.data()['username'] as String? ?? d.id,
              photoUrl: d.data()['photoUrl'] as String?,
            ))
        .toList()
      ..sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    return players;
  }

  Future<String?> sendRequest(String toUid, String toUsername) async {
    final myUid = _myUid;
    if (myUid == null) return 'Nicht angemeldet';
    if (toUid == myUid) return 'Du kannst dir selbst keine Anfrage schicken';
    if (_friendUids.contains(toUid)) return 'Ihr seid bereits befreundet';

    final outgoingExisting = await _requestsRef
        .where('fromUid', isEqualTo: myUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (outgoingExisting.docs.isNotEmpty) {
      return 'Anfrage bereits gesendet';
    }

    final incomingExisting = await _requestsRef
        .where('fromUid', isEqualTo: toUid)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (incomingExisting.docs.isNotEmpty) {
      return 'Du hast bereits eine offene Anfrage von diesem Spieler';
    }

    await _requestsRef.add({
      'fromUid': myUid,
      'fromUsername': _myUsername ?? '',
      'toUid': toUid,
      'toUsername': toUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return null;
  }

  Future<void> acceptRequest(String requestId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final requestRef = _requestsRef.doc(requestId);
    await _db.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) return;

      final data = requestSnap.data() ?? {};
      final fromUid = data['fromUid'] as String?;
      final toUid = data['toUid'] as String?;
      final fromUsername = data['fromUsername'] as String? ?? fromUid ?? '';

      if (toUid != myUid || fromUid == null || toUid == null) {
        return;
      }

      tx.update(requestRef, {'status': 'accepted'});

      final now = FieldValue.serverTimestamp();
      tx.set(
          _friendsRef(myUid).doc(fromUid),
          {
            'uid': fromUid,
            'username': fromUsername,
            'createdAt': now,
          },
          SetOptions(merge: true));
    });
  }

  Future<void> rejectRequest(String requestId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final requestRef = _requestsRef.doc(requestId);
    final snap = await requestRef.get();
    if (!snap.exists) return;
    if (snap.data()?['toUid'] != myUid) return;

    await requestRef.update({'status': 'rejected'});
  }

  Future<void> withdrawRequest(String requestId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final requestRef = _requestsRef.doc(requestId);
    final snap = await requestRef.get();
    if (!snap.exists) return;
    if (snap.data()?['fromUid'] != myUid) return;

    await requestRef.delete();
  }

  Future<void> removeFriend(String friendUid) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final batch = _db.batch();

    batch.delete(_friendsRef(myUid).doc(friendUid));

    final a = await _requestsRef
        .where('fromUid', isEqualTo: myUid)
        .where('toUid', isEqualTo: friendUid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (final doc in a.docs) {
      batch.delete(doc.reference);
    }

    final b = await _requestsRef
        .where('fromUid', isEqualTo: friendUid)
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (final doc in b.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<FriendProfile?> loadFriendProfile(String uid) async {
    DocumentSnapshot<Map<String, dynamic>>? statDoc;
    DocumentSnapshot<Map<String, dynamic>>? summaryDoc;
    DocumentSnapshot<Map<String, dynamic>>? userDoc;

    try {
      statDoc = await _leaderboardRef.doc(uid).get();
    } catch (_) {}
    try {
      summaryDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('summary')
          .get();
    } catch (_) {}
    try {
      userDoc = await _db.collection('users').doc(uid).get();
    } catch (_) {}

    final hasStat = statDoc?.exists == true;
    final hasSummary = summaryDoc?.exists == true;
    final hasUser = userDoc?.exists == true;
    if (!hasUser && !hasStat && !hasSummary) return null;

    final userData = userDoc?.data() ?? {};
    final stats = statDoc?.data() ?? {};
    final summary = summaryDoc?.data() ?? {};

    final username = stats['username'] as String? ??
        summary['username'] as String? ??
        userData['username'] as String? ??
        uid;
    final points = (stats['totalPoints'] as num?)?.toInt() ??
        (summary['totalPoints'] as num?)?.toInt() ??
        0;
    final tokens = (stats['totalTokens'] as num?)?.toInt() ??
        (summary['totalTokens'] as num?)?.toInt() ??
        0;
    final visited = (stats['visitedLandmarks'] as num?)?.toInt() ??
        (summary['visitedLandmarks'] as num?)?.toInt() ??
        0;
    final worldWonderTokens = (stats['worldWonderTokens'] as num?)?.toInt() ??
        (summary['worldWonderTokens'] as num?)?.toInt() ??
        0;
    final level = (stats['level'] as num?)?.toInt() ??
        (summary['level'] as num?)?.toInt() ??
        ((points ~/ 100) + 1);
    final rawFavorites =
        userData['favoriteTokens'] as List<dynamic>? ?? const [];
    final favoriteTokens = rawFavorites
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry('$k', v)))
        .map((entry) => FavoriteTokenPreview.fromMap(entry))
        .where((entry) => entry.tokenId.isNotEmpty)
        .take(5)
        .toList(growable: false);

    return FriendProfile(
      uid: uid,
      username: username,
      photoUrl: stats['photoUrl'] as String? ??
          summary['photoUrl'] as String? ??
          userData['photoUrl'] as String?,
      totalPoints: points,
      totalTokens: tokens,
      worldWonderTokens: worldWonderTokens,
      level: level,
      visitedLandmarks: visited,
      favoriteTokens: favoriteTokens,
    );
  }

  Future<void> publishMyStats({
    required int totalPoints,
    required int totalTokens,
    required int visitedLandmarks,
    required int leaderboardScore,
    int worldWonderTokens = 0,
    int level = 1,
  }) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final data = {
      'uid': myUid,
      'username': _myUsername ?? myUid,
      'photoUrl': _myPhotoUrl,
      'totalPoints': totalPoints,
      'totalTokens': totalTokens,
      'visitedLandmarks': visitedLandmarks,
      'leaderboardScore': leaderboardScore,
      'worldWonderTokens': worldWonderTokens,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      _leaderboardRef.doc(myUid).set(data, SetOptions(merge: true)),
      _db
          .collection('users')
          .doc(myUid)
          .collection('stats')
          .doc('summary')
          .set(data, SetOptions(merge: true)),
    ]);
  }

  LeaderboardEntry _mapEntry(
    Map<String, dynamic> data, {
    required bool isFriend,
  }) {
    final uid = data['uid'] as String? ?? '';
    final points = (data['totalPoints'] as num?)?.toInt() ??
        (data['leaderboardScore'] as num?)?.toInt() ??
        0;
    final entry = LeaderboardEntry(
      uid: uid,
      username: data['username'] as String? ?? uid,
      photoUrl: data['photoUrl'] as String?,
      totalPoints: points,
      totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
      worldWonderTokens: (data['worldWonderTokens'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? ((points ~/ 100) + 1),
      isFriend: isFriend,
      isMe: uid == _myUid,
    );

    return entry;
  }

  Stream<List<LeaderboardEntry>> streamGlobalLeaderboard({int limit = 30}) {
    return Stream<List<LeaderboardEntry>>.multi((controller) {
      Map<String, Map<String, dynamic>> usersByUid = {};
      Map<String, Map<String, dynamic>> statsByUid = {};
      Set<String> friendIds = _friendUids;

      void emitCurrent() {
        final allUids = <String>{...usersByUid.keys, ...statsByUid.keys};
        final entries = <LeaderboardEntry>[];

        for (final uid in allUids) {
          final userData = usersByUid[uid] ?? const <String, dynamic>{};
          final statData = statsByUid[uid] ?? const <String, dynamic>{};
          final merged = <String, dynamic>{
            'uid': uid,
            'username': statData['username'] ?? userData['username'] ?? uid,
            'photoUrl': statData['photoUrl'] ?? userData['photoUrl'],
            'totalPoints': statData['totalPoints'] ?? userData['coins'] ?? 0,
            'totalTokens': statData['totalTokens'] ?? 0,
            'worldWonderTokens': statData['worldWonderTokens'] ?? 0,
            'level': statData['level'] ?? 1,
          };

          entries.add(_mapEntry(merged, isFriend: friendIds.contains(uid)));
        }

        entries.sort((a, b) {
          final byPoints = b.totalPoints.compareTo(a.totalPoints);
          if (byPoints != 0) return byPoints;
          return a.username.toLowerCase().compareTo(b.username.toLowerCase());
        });
        controller.add(entries.take(limit).toList(growable: false));
      }

      final usersSub = _db.collection('users').snapshots().listen((snap) {
        usersByUid = {
          for (final doc in snap.docs) doc.id: doc.data(),
        };
        emitCurrent();
      });

      final statsSub = _leaderboardRef.snapshots().listen((snap) {
        statsByUid = {
          for (final doc in snap.docs) doc.id: doc.data(),
        };
        emitCurrent();
      });

      final friendSub = friendUidsStream().listen((ids) {
        friendIds = ids;
        emitCurrent();
      });

      controller.onCancel = () async {
        await usersSub.cancel();
        await statsSub.cancel();
        await friendSub.cancel();
      };
    });
  }

  Stream<List<LeaderboardEntry>> streamFriendsLeaderboard(
      {int limit = 30}) async* {
    final myUid = _myUid;
    if (myUid == null) {
      yield [];
      return;
    }

    yield* Stream<List<LeaderboardEntry>>.multi((controller) {
      Set<String> allowed = {myUid};
      List<LeaderboardEntry>? latestGlobalEntries;

      void emitCurrent() {
        final globalEntries = latestGlobalEntries;
        if (globalEntries == null) {
          controller.add(const <LeaderboardEntry>[]);
          return;
        }

        final entries = globalEntries
            .where((entry) => allowed.contains(entry.uid))
            .toList();
        entries.sort((a, b) {
          final byPoints = b.totalPoints.compareTo(a.totalPoints);
          if (byPoints != 0) return byPoints;
          return a.username.toLowerCase().compareTo(b.username.toLowerCase());
        });
        controller.add(entries.take(limit).toList(growable: false));
      }

      final friendSub = friendUidsStream().listen((friendIds) {
        allowed = {...friendIds, myUid};
        emitCurrent();
      });

      final globalSub = streamGlobalLeaderboard(limit: 1000).listen((entries) {
        latestGlobalEntries = entries;
        emitCurrent();
      });

      controller.onCancel = () async {
        await friendSub.cancel();
        await globalSub.cancel();
      };
    });
  }

  Future<List<LeaderboardEntry>> loadLeaderboard({
    bool friendsOnly = false,
    LeaderboardEntry? ownEntry,
    int limit = 50,
  }) async {
    final stream = friendsOnly
        ? streamFriendsLeaderboard(limit: limit)
        : streamGlobalLeaderboard(limit: limit);

    final entries = await stream.first;
    if (ownEntry != null && !entries.any((e) => e.uid == ownEntry.uid)) {
      return [...entries, ownEntry]
        ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }
    return entries;
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _friendsSub?.cancel();
    _acceptedAsSenderSub?.cancel();
    _acceptedAsReceiverSub?.cancel();
    _friendUidsController.close();
    super.dispose();
  }
}
