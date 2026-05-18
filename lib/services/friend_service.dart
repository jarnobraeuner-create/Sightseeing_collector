import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUid: d['fromUid'] as String,
      fromUsername: d['fromUsername'] as String? ?? '',
      toUid: d['toUid'] as String,
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
  final int totalPoints;
  final int totalTokens;
  final int visitedLandmarks;

  const FriendProfile({
    required this.uid,
    required this.username,
    required this.totalPoints,
    required this.totalTokens,
    required this.visitedLandmarks,
  });
}

class LeaderboardEntry {
  final String uid;
  final String username;
  final int totalPoints;
  final int totalTokens;
  final bool isFriend;
  final bool isMe;

  const LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.totalPoints,
    required this.totalTokens,
    required this.isFriend,
    required this.isMe,
  });
}

/// Manages friend requests, friendships and leaderboard data via Firestore.
///
/// Firestore layout:
///   friend_requests/{requestId}  – FriendRequest doc
///   users/{uid}/stats            – public stats: totalPoints, totalTokens, visitedLandmarks, username
class FriendService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _myUid;
  String? _myUsername;

  String? get myUid => _myUid;
  String? get myUsername => _myUsername;

  // Incoming pending requests
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> get incomingRequests => _incomingRequests;

  // UIDs of accepted friends
  Set<String> _friendUids = {};
  Set<String> get friendUids => _friendUids;

  int get incomingCount => _incomingRequests.length;

  void setUser(String? uid, String? username) {
    // If only the username changed (uid same), just update it — no listener restart needed.
    if (_myUid == uid) {
      if (_myUsername != username && username != null) {
        _myUsername = username;
        notifyListeners();
      }
      return;
    }
    _myUid = uid;
    _myUsername = username;
    _incomingRequests = [];
    _friendUids = {};
    if (uid != null) {
      _startListening();
    }
    notifyListeners();
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _startListening() {
    // Incoming pending requests
    _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      _incomingRequests = snap.docs.map(FriendRequest.fromFirestore).toList();
      notifyListeners();
    });

    // My friendships (both directions)
    _db
        .collection('friend_requests')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snap) {
      final uids = <String>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        final from = d['fromUid'] as String;
        final to = d['toUid'] as String;
        if (from == _myUid) uids.add(to);
        if (to == _myUid) uids.add(from);
      }
      _friendUids = uids;
      notifyListeners();
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Search for a user by username (case-insensitive prefix).
  Future<List<AppUserSummary>> searchUsers(String query) async {
    if (_myUid == null || query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();

    // Primary search: usernameLower prefix query
    final snap = await _db
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: lower)
        .where('usernameLower', isLessThanOrEqualTo: '$lower\uf8ff')
        .limit(20)
        .get();

    final results = <String, AppUserSummary>{};
    for (final d in snap.docs) {
      if (d.id == _myUid) continue;
      results[d.id] = AppUserSummary(
        uid: d.id,
        username: d.data()['username'] as String? ?? d.id,
      );
    }

    // Fallback: also search by exact username (case-sensitive) for accounts
    // that may not have usernameLower written yet
    if (results.isEmpty) {
      final snap2 = await _db
          .collection('users')
          .where('username', isEqualTo: query.trim())
          .limit(10)
          .get();
      for (final d in snap2.docs) {
        if (d.id == _myUid) continue;
        results[d.id] = AppUserSummary(
          uid: d.id,
          username: d.data()['username'] as String? ?? d.id,
        );
      }
    }

    return results.values.toList();
  }

  /// Load all registered players (for browsing).
  Future<List<AppUserSummary>> loadAllPlayers() async {
    // Always do a plain collection fetch (no ordering) to avoid missing index issues
    try {
      final snap = await _db.collection('users').limit(100).get();
      debugPrint('=== loadAllPlayers: ${snap.docs.length} docs found ===');
      for (final d in snap.docs) {
        final data = d.data();
        debugPrint('  uid=${d.id} username=${data['username']} usernameLower=${data['usernameLower']} email=${data['email']}');
      }
      final players = snap.docs
          .where((d) => d.id != _myUid)
          .map((d) => AppUserSummary(
                uid: d.id,
                username: d.data()['username'] as String? ?? d.id,
              ))
          .toList();
      players.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return players;
    } catch (e) {
      debugPrint('loadAllPlayers error: $e');
      return [];
    }
  }

  /// Send a friend request. Returns error string or null on success.
  Future<String?> sendRequest(String toUid, String toUsername) async {
    if (_myUid == null) return 'Nicht angemeldet';
    if (toUid == _myUid) return 'Du kannst dir selbst keine Anfrage schicken';
    if (_friendUids.contains(toUid)) return 'Ihr seid bereits befreundet';

    // Check if already a pending request in either direction
    final existing = await _db
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in existing.docs) {
      final d = doc.data();
      final from = d['fromUid'] as String;
      final to = d['toUid'] as String;
      if ((from == _myUid && to == toUid) || (from == toUid && to == _myUid)) {
        return 'Anfrage bereits vorhanden';
      }
    }

    await _db.collection('friend_requests').add({
      'fromUid': _myUid,
      'fromUsername': _myUsername ?? '',
      'toUid': toUid,
      'toUsername': toUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return null;
  }

  Future<void> acceptRequest(String requestId) async {
    await _db.collection('friend_requests').doc(requestId).update({
      'status': 'accepted',
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _db.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Future<void> removeFriend(String friendUid) async {
    final snap = await _db
        .collection('friend_requests')
        .where('status', isEqualTo: 'accepted')
        .get();
    for (final doc in snap.docs) {
      final d = doc.data();
      final from = d['fromUid'] as String;
      final to = d['toUid'] as String;
      if ((from == _myUid && to == friendUid) ||
          (from == friendUid && to == _myUid)) {
        await doc.reference.delete();
      }
    }
  }

  // ── Profile & Stats ────────────────────────────────────────────────────────

  Future<FriendProfile?> loadFriendProfile(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      final d = userDoc.data()!;
      final statsDoc = await _db.collection('users').doc(uid).collection('stats').doc('summary').get();
      int points = 0, tokens = 0, visited = 0;
      if (statsDoc.exists) {
        final sd = statsDoc.data()!;
        points = sd['totalPoints'] as int? ?? 0;
        tokens = sd['totalTokens'] as int? ?? 0;
        visited = sd['visitedLandmarks'] as int? ?? 0;
      }
      return FriendProfile(
        uid: uid,
        username: d['username'] as String? ?? uid,
        totalPoints: points,
        totalTokens: tokens,
        visitedLandmarks: visited,
      );
    } catch (e) {
      debugPrint('loadFriendProfile error: $e');
      return null;
    }
  }

  /// Publishes local stats to Firestore so others can see them.
  /// Writes public_stats/{uid} first (main leaderboard source),
  /// then attempts users/{uid}/stats/summary (may fail if rules are old).
  Future<void> publishMyStats({
    required int totalPoints,
    required int totalTokens,
    required int visitedLandmarks,
    required int leaderboardScore,
  }) async {
    if (_myUid == null) return;
    final statsData = {
      'totalPoints': totalPoints,
      'totalTokens': totalTokens,
      'visitedLandmarks': visitedLandmarks,
      'leaderboardScore': leaderboardScore,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Write public_stats independently — this is the primary leaderboard source
    try {
      await _db.collection('public_stats').doc(_myUid).set(
        {
          ...statsData,
          'uid': _myUid,
          'username': _myUsername ?? '',
        },
        SetOptions(merge: true),
      );
      debugPrint('publishMyStats: public_stats OK uid=$_myUid score=$leaderboardScore');
    } catch (e) {
      debugPrint('publishMyStats: public_stats FAILED: $e');
    }

    // Write stats subcollection separately — failure here doesn't block the above
    try {
      await _db
          .collection('users')
          .doc(_myUid)
          .collection('stats')
          .doc('summary')
          .set(statsData, SetOptions(merge: true));
      debugPrint('publishMyStats: stats/summary OK');
    } catch (e) {
      debugPrint('publishMyStats: stats/summary FAILED (rules not yet deployed?): $e');
    }
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> loadLeaderboard({
    bool friendsOnly = false,
    LeaderboardEntry? ownEntry,
  }) async {
    try {
      // Each entry: { data map, uid }
      final entries = <LeaderboardEntry>[];

      if (friendsOnly) {
        if (_friendUids.isEmpty) return [];
        for (final uid in _friendUids) {
          final doc = await _db
              .collection('users')
              .doc(uid)
              .collection('stats')
              .doc('summary')
              .get();
          final userDoc = await _db.collection('users').doc(uid).get();
          final username = (userDoc.data()?['username'] as String?) ?? uid;
          if (!doc.exists) {
            entries.add(LeaderboardEntry(
              uid: uid,
              username: username,
              totalPoints: 0,
              totalTokens: 0,
              isFriend: true,
              isMe: uid == _myUid,
            ));
            continue;
          }
          final d = doc.data()!;
          entries.add(LeaderboardEntry(
            uid: uid,
            username: d['username'] as String? ?? username,
            totalPoints: (d['leaderboardScore'] as num?)?.toInt() ?? (d['totalPoints'] as num?)?.toInt() ?? 0,
            totalTokens: (d['totalTokens'] as num?)?.toInt() ?? 0,
            isFriend: true,
            isMe: uid == _myUid,
          ));
        }
      } else {
        // Fetch all users + public_stats in parallel, merge them
        final results = await Future.wait([
          _db.collection('users').get(const GetOptions(source: Source.server)),
          _db.collection('public_stats').get(const GetOptions(source: Source.server)),
        ]);
        final usersSnap = results[0];
        final statsSnap = results[1];
        debugPrint('loadLeaderboard: ${usersSnap.docs.length} users, ${statsSnap.docs.length} public_stats docs');
        for (final d in usersSnap.docs) {
          debugPrint('  user: ${d.id} => username=${d.data()["username"]}');
        }

        // Build map uid -> public_stats data
        final statsMap = <String, Map<String, dynamic>>{};
        for (final doc in statsSnap.docs) {
          statsMap[doc.id] = doc.data();
        }

        for (final userDoc in usersSnap.docs) {
          final uid = userDoc.id;
          final username = (userDoc.data()['username'] as String?) ?? uid;
          final stats = statsMap[uid];
          entries.add(LeaderboardEntry(
            uid: uid,
            username: stats?['username'] as String? ?? username,
            totalPoints: (stats?['leaderboardScore'] as num?)?.toInt() ??
                (stats?['totalPoints'] as num?)?.toInt() ?? 0,
            totalTokens: (stats?['totalTokens'] as num?)?.toInt() ?? 0,
            isFriend: _friendUids.contains(uid),
            isMe: uid == _myUid,
          ));
        }
      }

      // Always include own entry (even if publishMyStats hasn't run yet)
      if (ownEntry != null && !entries.any((e) => e.uid == ownEntry.uid)) {
        entries.add(ownEntry);
      }

      entries.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      debugPrint('loadLeaderboard: ${entries.length} entries, friendsOnly=$friendsOnly');
      return entries;
    } catch (e) {
      debugPrint('loadLeaderboard error: $e');
      // Still return own entry on error
      if (ownEntry != null) return [ownEntry];
      return [];
    }
  }
}

/// Lightweight user summary for search results.
class AppUserSummary {
  final String uid;
  final String username;
  const AppUserSummary({required this.uid, required this.username});
}
