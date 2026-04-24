import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import 'notification_service.dart';
import 'landmark_service.dart';

class CollectionService extends ChangeNotifier {
    // Anzahl der Lootboxen (Dummy-Implementierung, bitte ggf. anpassen)
    int get lootboxCount => 0; // TODO: Hier die echte Anzahl der Lootboxen aus dem User-Objekt oder Firestore zurückgeben
  static const String _monumentRewardClaimedKey = 'monument_reward_claimed';
  bool _monumentRewardAvailable = false;

  bool get monumentRewardAvailable => _monumentRewardAvailable;

  Future<void> setMonumentRewardAvailable(bool value) async {
    _monumentRewardAvailable = value;
    notifyListeners();
    if (!value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_monumentRewardClaimedKey, true);
    }
  }

  Future<bool> isMonumentRewardClaimed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_monumentRewardClaimedKey) ?? false;
  }
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Set<String> _removedLandmarkIds = {
    '7', '8', '9', '10', '11', '12',
    '22', '23',
  };

  String? _userId;
  final List<Token> _tokens = [];
  final List<CollectionSet> _sets = [];
  int _totalPoints = 0;
  bool _isLoaded = false;
  CollectionSet? _lastCompletedSet;

  List<Token> get tokens => _tokens;
  List<CollectionSet> get sets => _sets;
  int get totalPoints => _totalPoints;
  bool get isLoaded => _isLoaded;
  /// Enthält das zuletzt abgeschlossene Set (null wenn keines). 
  /// Nach Anzeige via [clearLastCompletedSet] zurücksetzen.
  CollectionSet? get lastCompletedSet => _lastCompletedSet;

  void clearLastCompletedSet() {
    _lastCompletedSet = null;
  }

  CollectionService() {
    _initializeSets();
    _initMonumentRewardFlag();
  }

  Future<void> _initMonumentRewardFlag() async {
    final claimed = await isMonumentRewardClaimed();
    if (claimed) {
      _monumentRewardAvailable = false;
      notifyListeners();
    }
  }

  // â”€â”€â”€ User Management (called by ProxyProvider) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void setUserId(String? uid) {
    if (_userId == uid) return;
    _userId = uid;
    if (uid != null) {
      _loadFromFirestore(uid);
    } else {
      _clearLocalData();
    }
  }

  Future<void> _loadFromFirestore(String uid) async {
    return reloadFromFirestore(uid);
  }

  /// Öffentlich aufrufbar für Pull-to-Refresh
  Future<void> reloadFromFirestore(String uid) async {
    _isLoaded = false;
    notifyListeners();
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _totalPoints = (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
      }

      final tokensSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .get();

      _tokens.clear();
      for (final doc in tokensSnap.docs) {
        try {
          final token = Token.fromJson(doc.data());
          if (_removedLandmarkIds.contains(token.landmarkId)) {
            // Legacy cleanup: removed landmarks must not remain in collection.
            await doc.reference.delete();
            continue;
          }
          _tokens.add(token);
        } catch (e) {
          debugPrint('Error parsing token ${doc.id}: $e');
        }
      }

      _rebuildSetsState();
      _isLoaded = true;
      notifyListeners();

      // Gewonnene Auktionen einloesen (Token empfangen + Coins abziehen)
      await claimWonAuctions(uid);
    } catch (e) {
      debugPrint('Error loading collection from Firestore: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Prueft ob der User Auktionen gewonnen hat und empfaengt die Token automatisch.
  Future<void> claimWonAuctions(String uid) async {
    try {
      final snap = await _db
          .collection('auctions')
          .where('winnerId', isEqualTo: uid)
          .where('status', isEqualTo: 'ended')
          .where('tokenClaimed', isEqualTo: false)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final tokenJson = data['tokenData'] != null
            ? Map<String, dynamic>.from(data['tokenData'] as Map)
            : null;
        if (tokenJson == null) continue;

        final coins = (data['winnerCoins'] as num?)?.toInt() ?? 0;

        // Token in eigene Sammlung aufnehmen
        final token = Token.fromJson(tokenJson);
        addToken(token);

        // Benachrichtigung: Gebot angenommen
        NotificationService.instance.showBidAccepted(token.landmarkName);

        // Coins abziehen
        if (coins > 0) spendPoints(coins);

        // Als eingeloest markieren
        await _db
            .collection('auctions')
            .doc(doc.id)
            .update({'tokenClaimed': true})
            .catchError((e) => debugPrint('Error marking claimed: $e'));
      }
    } catch (e) {
      debugPrint('Error claiming won auctions: $e');
    }
  }

  void _clearLocalData() {
    _tokens.clear();
    _totalPoints = 0;
    _isLoaded = false;
    _initializeSets();
    notifyListeners();
  }

  // â”€â”€â”€ Sets Initialization â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _initializeSets() {
    _sets.clear();
    _sets.addAll([
      CollectionSet(
        id: 'set_hamburg',
        name: 'Hamburg',
        description: 'Sammle alle klassischen Sehensw\u00fcrdigkeiten in Hamburg',
        requiredTokenIds: [
          '1',
          '2',
          '3',
          '4',
          '5',
          '6',
          '13',
          '14',
          '15',
          '16',
          '17',
          '18',
          '19',
          '20',
          '21',
          '24',
          '25',
          '26',
          '27',
          '28',
          '29',
          '30',
          '31',
          '32',
          '33',
          '34',
          '35',
          '36',
          '37',
          '38',
          '39',
          '40',
          '41',
          '42',
          '43',
          '44',
          '45',
          '46',
          '47',
          '48',
          '49',
          '50',
          '51',
          '69',
          '70',
          '71',
          '72',
          '73',
          '74',
          '75',
        ],
        bonusPoints: 800,
        rewardImageUrl: 'assets/images/Hamburg_Wappen_small.png',
      ),
      CollectionSet(
        id: 'set_leipzig',
        name: 'Leipzig',
        description: 'Entdecke alle Sehenswürdigkeiten in Leipzig',
        requiredTokenIds: ['52', '53', '54', '55', '56', '57', '58', '59', '60', '61', '62', '63', '64', '65', '66', '67', '68'],
        bonusPoints: 700,
        rewardImageUrl: 'assets/images/Leipzig_Wappen_Set_token.png',
      ),
    ]);
  }

  void _rebuildSetsState() {
    _initializeSets();
    for (final token in _tokens) {
      _updateSets(token.landmarkId, token.setIds);
    }
  }

  // â”€â”€â”€ Token Collection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void collectToken(
    String landmarkId,
    String landmarkName,
    String category,
    int points,
    List<String> setIds, {
    TokenTier tier = TokenTier.bronze,
  }) {
    if (hasCollectedToken(landmarkId)) {
      debugPrint('Token already collected for landmark: $landmarkId');
      return;
    }

    final token = Token(
      id: const Uuid().v4(),
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      category: category,
      collectedAt: DateTime.now(),
      points: tier.pointValue,
      setIds: setIds,
      tier: tier,
    );

    _tokens.add(token);
    _totalPoints += token.points;
    _updateSets(landmarkId, setIds);
    notifyListeners();
    _persistToken(token);
    _persistCoins();
  }

  /// Like collectToken but skips the already-collected check (used for lootbox)
  void collectTokenAllowDuplicate(
    String landmarkId,
    String landmarkName,
    String category,
    int points,
    List<String> setIds, {
    TokenTier tier = TokenTier.bronze,
  }) {
    final token = Token(
      id: const Uuid().v4(),
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      category: category,
      collectedAt: DateTime.now(),
      points: tier.pointValue,
      setIds: setIds,
      tier: tier,
    );
    _tokens.add(token);
    _totalPoints += token.points;
    _updateSets(landmarkId, setIds);
    notifyListeners();
    _persistToken(token);
    _persistCoins();
  }

  /// Adds an externally created token (e.g. received from a trade)
  void addToken(Token token) {
    if (_removedLandmarkIds.contains(token.landmarkId)) {
      debugPrint('Skipped token for removed landmark: ${token.landmarkId}');
      return;
    }
    _tokens.add(token);
    _totalPoints += token.points;
    _updateSets(token.landmarkId, token.setIds);
    notifyListeners();
    _persistToken(token);
    _persistCoins();
  }

  /// Removes a token by ID (e.g. sold or traded away)
  void removeTokenById(String tokenId) {
    final idx = _tokens.indexWhere((t) => t.id == tokenId);
    if (idx == -1) return;
    final token = _tokens[idx];
    _tokens.removeAt(idx);
    _totalPoints -= token.points;
    if (_totalPoints < 0) _totalPoints = 0;
    notifyListeners();
    _deleteTokenFromFirestore(tokenId);
    _persistCoins();
  }

  void _updateSets(String landmarkId, List<String> setIds) {
    for (var setId in setIds) {
      final setIndex = _sets.indexWhere((s) => s.id == setId);
      if (setIndex == -1) continue;

      final set = _sets[setIndex];
      if (!set.requiredTokenIds.contains(landmarkId)) continue;
      if (set.collectedTokenIds.contains(landmarkId)) continue;

      final updatedCollectedTokens =
          List<String>.from(set.collectedTokenIds)..add(landmarkId);
      final isComplete =
          updatedCollectedTokens.length == set.requiredTokenIds.length;

      _sets[setIndex] = set.copyWith(
        collectedTokenIds: updatedCollectedTokens,
        completed: isComplete,
      );

      if (isComplete && !set.completed) {
        _totalPoints += set.bonusPoints;
        _lastCompletedSet = _sets[setIndex];
        debugPrint('Set completed: ${set.name}. Bonus: ${set.bonusPoints}');
        NotificationService.instance.showSetCompleted(set.name, set.bonusPoints);
      }
    }
  }

  // â”€â”€â”€ Coins / Points â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void addPoints(int points) {
    _totalPoints += points;
    notifyListeners();
    _persistCoins();
  }

  void spendPoints(int points) {
    _totalPoints -= points;
    if (_totalPoints < 0) _totalPoints = 0;
    notifyListeners();
    _persistCoins();
  }

  // â”€â”€â”€ Queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool hasCollectedToken(String landmarkId) {
    return _tokens.any((token) => token.landmarkId == landmarkId);
  }

  Token? getToken(String landmarkId) {
    try {
      return _tokens.firstWhere((t) => t.landmarkId == landmarkId);
    } catch (e) {
      return null;
    }
  }

  List<Token> getTokensByCategory(String category) {
    return _tokens.where((t) => t.category == category).toList();
  }

  CollectionSet? getSetById(String setId) {
    try {
      return _sets.firstWhere((s) => s.id == setId);
    } catch (e) {
      return null;
    }
  }

  int getSetCompletionPercentage(String setId) {
    final set = getSetById(setId);
    return set?.completionPercentage.round() ?? 0;
  }

  List<CollectionSet> getCompletedSets() {
    return _sets.where((s) => s.completed).toList();
  }

  Map<String, int> getStatistics() {
    return {
      'totalTokens': _tokens.length,
      'totalPoints': _totalPoints,
      'completedSets': getCompletedSets().length,
      'totalSets': _sets.length,
      'sightseeingTokens': getTokensByCategory('sightseeing').length,
      'travelTokens': getTokensByCategory('travel').length,
    };
  }

  // â”€â”€â”€ Token Upgrade System â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  bool canUpgradeToken(String landmarkId, TokenTier fromTier) {
    final count = _tokens
        .where((t) => t.landmarkId == landmarkId && t.tier == fromTier)
        .length;
    return count >= 5;
  }

  void upgradeTokens(String landmarkId, TokenTier fromTier, TokenTier toTier) {
    final tokensToUpgrade = _tokens
        .where((t) => t.landmarkId == landmarkId && t.tier == fromTier)
        .take(5)
        .toList();

    if (tokensToUpgrade.length < 5) {
      debugPrint('Not enough tokens to upgrade');
      return;
    }

    for (var token in tokensToUpgrade) {
      _tokens.remove(token);
      _totalPoints -= token.points;
      _deleteTokenFromFirestore(token.id);
    }

    final firstToken = tokensToUpgrade.first;
    final newToken = Token(
      id: const Uuid().v4(),
      landmarkId: landmarkId,
      landmarkName: firstToken.landmarkName,
      category: firstToken.category,
      collectedAt: DateTime.now(),
      points: toTier.pointValue,
      setIds: firstToken.setIds,
      tier: toTier,
    );

    _tokens.add(newToken);
    _totalPoints += newToken.points;
    notifyListeners();
    _persistToken(newToken);
    _persistCoins();
  }

  void upgradeSpecificTokens(
    String mainTokenId,
    List<String> sacrificeTokenIds,
    TokenTier toTier,
  ) {
    final mainToken = _tokens.firstWhere((t) => t.id == mainTokenId);

    _tokens.removeWhere((t) => t.id == mainTokenId);
    _totalPoints -= mainToken.points;
    _deleteTokenFromFirestore(mainTokenId);

    for (final id in sacrificeTokenIds) {
      final sacrifice =
          _tokens.firstWhere((t) => t.id == id, orElse: () => mainToken);
      _tokens.removeWhere((t) => t.id == id);
      _totalPoints -= sacrifice.points;
      _deleteTokenFromFirestore(id);
    }

    final newToken = Token(
      id: const Uuid().v4(),
      landmarkId: mainToken.landmarkId,
      landmarkName: mainToken.landmarkName,
      category: mainToken.category,
      collectedAt: DateTime.now(),
      points: toTier.pointValue,
      setIds: mainToken.setIds,
      tier: toTier,
    );

    _tokens.add(newToken);
    _totalPoints += newToken.points;
    notifyListeners();
    _persistToken(newToken);
    _persistCoins();
  }

  int getTokenCountByTier(String landmarkId, TokenTier tier) {
    return _tokens
        .where((t) => t.landmarkId == landmarkId && t.tier == tier)
        .length;
  }

  // Alle Tokens für Testzwecke sammeln (alle Tiers pro Landmark)
  void collectAllTokensForTesting(List<Landmark> landmarks) {
    for (final landmark in landmarks) {
      for (final tier in TokenTier.values) {
        // Monument-Tokens nur für Monument-fähige Landmarks
        if (tier == TokenTier.monumente &&
            !LandmarkService.monumentLandmarkIds.contains(landmark.id)) {
          continue;
        }
        final token = Token(
          id: const Uuid().v4(),
          landmarkId: landmark.id,
          landmarkName: landmark.name,
          category: landmark.category,
          collectedAt: DateTime.now(),
          points: tier.pointValue,
          setIds: landmark.relatedSetIds,
          tier: tier,
        );
        _tokens.add(token);
        _totalPoints += token.points;
      }
    }
    for (int i = 0; i < _sets.length; i++) {
      final set = _sets[i];
      if (!set.completed) {
        _sets[i] = set.copyWith(
          collectedTokenIds: List<String>.from(set.requiredTokenIds),
          completed: true,
        );
        _totalPoints += set.bonusPoints;
      }
    }
    notifyListeners();
    for (final token in _tokens) {
      _persistToken(token);
    }
    _persistCoins();
  }

  // Reset collection for testing
  void resetCollection() {
    final tokenIds = _tokens.map((t) => t.id).toList();
    _tokens.clear();
    _totalPoints = 0;
    _initializeSets();
    notifyListeners();
    if (_userId != null) {
      for (final id in tokenIds) {
        _deleteTokenFromFirestore(id);
      }
      _persistCoins();
    }
  }

  // â”€â”€â”€ Firestore Persistence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _persistToken(Token token) {
    if (_userId == null) return;
    _db
        .collection('users')
        .doc(_userId)
        .collection('tokens')
        .doc(token.id)
        .set(token.toJson())
        .catchError((e) => debugPrint('Error saving token: $e'));
  }

  void _deleteTokenFromFirestore(String tokenId) {
    if (_userId == null) return;
    _db
        .collection('users')
        .doc(_userId)
        .collection('tokens')
        .doc(tokenId)
        .delete()
        .catchError((e) => debugPrint('Error deleting token: $e'));
  }

  void _persistCoins() {
    if (_userId == null) return;
    _db
        .collection('users')
        .doc(_userId)
        .set({'coins': _totalPoints}, SetOptions(merge: true))
        .catchError((e) => debugPrint('Error saving coins: $e'));
  }
}
