import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class CollectionService extends ChangeNotifier {
  final List<Token> _tokens = [];
  final List<CollectionSet> _sets = [];
  int _totalPoints = 0;
  bool _isInitialized = false;

  List<Token> get tokens => _tokens;
  List<CollectionSet> get sets {
    _ensureInitialized();
    return _sets;
  }
  int get totalPoints => _totalPoints;

  CollectionService() {
    // Nicht automatisch initialisieren
    debugPrint('CollectionService created (lazy loading)');
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeSets();
    }
  }

  void _initializeSets() {
    _sets.addAll([
      CollectionSet(
        id: 'set_hamburg',
        name: 'Hamburg Klassiker',
        description: 'Sammle alle klassischen Sehenswürdigkeiten in Hamburg',
        requiredTokenIds: ['1', '2', '3', '4', '5', '6', '13', '14', '15', '16'], // 10 Hamburg Landmarks
        bonusPoints: 800,
      ),
      CollectionSet(
        id: 'set_monuments',
        name: 'Hamburgs Denkmäler',
        description: 'Besuche die berühmtesten Denkmäler Hamburgs',
        requiredTokenIds: ['1', '2'], // Speicherstadt, Elbphilharmonie
        bonusPoints: 250,
      ),
      CollectionSet(
        id: 'set_dissen',
        name: 'Dissen Klassiker',
        description: 'Entdecke alle Sehenswürdigkeiten in Dissen',
        requiredTokenIds: ['7', '8', '9', '10', '11', '12'], // 6 Dissen Landmarks
        bonusPoints: 500,
      ),
    ]);
  }

  void collectToken(
    String landmarkId,
    String landmarkName,
    String category,
    int points,
    List<String> setIds, {
    TokenTier tier = TokenTier.bronze,
  }) {
    // Check if token already collected
    if (hasCollectedToken(landmarkId)) {
      debugPrint('Token already collected for landmark: $landmarkId');
      return;
    }

    // Create new token
    final token = Token(
      id: const Uuid().v4(),
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      category: category,
      collectedAt: DateTime.now(),
      points: points,
      setIds: setIds,
      tier: tier,
    );

    _tokens.add(token);
    _totalPoints += points;

    // Update related sets
    _updateSets(landmarkId, setIds);

    notifyListeners();
  }

  void _updateSets(String landmarkId, List<String> setIds) {
    for (var setId in setIds) {
      final setIndex = _sets.indexWhere((s) => s.id == setId);
      if (setIndex == -1) continue;

      final set = _sets[setIndex];
      
      // Check if this landmark is required for this set
      if (!set.requiredTokenIds.contains(landmarkId)) continue;

      // Add to collected tokens if not already there
      if (!set.collectedTokenIds.contains(landmarkId)) {
        final updatedCollectedTokens = List<String>.from(set.collectedTokenIds)
          ..add(landmarkId);

        // Check if set is now complete
        final isComplete = updatedCollectedTokens.length == set.requiredTokenIds.length;

        _sets[setIndex] = set.copyWith(
          collectedTokenIds: updatedCollectedTokens,
          completed: isComplete,
        );

        // Award bonus points if complete
        if (isComplete && !set.completed) {
          _totalPoints += set.bonusPoints;
          debugPrint('Set completed: ${set.name}. Bonus points: ${set.bonusPoints}');
        }
      }
    }
  }

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

  // Token Upgrade System
  bool canUpgradeToken(String landmarkId, TokenTier fromTier) {
    final tokensOfLandmark = _tokens.where(
      (t) => t.landmarkId == landmarkId && t.tier == fromTier,
    );
    return tokensOfLandmark.length >= 5;
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

    // Entferne die 5 Token
    for (var token in tokensToUpgrade) {
      _tokens.remove(token);
      _totalPoints -= token.points;
    }

    // Erstelle neuen höherwertigen Token
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
  }

  void upgradeSpecificTokens(
    String mainTokenId,
    List<String> sacrificeTokenIds,
    TokenTier toTier,
  ) {
    final mainToken = _tokens.firstWhere((t) => t.id == mainTokenId);

    // Entferne Haupttoken
    _tokens.removeWhere((t) => t.id == mainTokenId);
    _totalPoints -= mainToken.points;

    // Entferne Opfertokens
    for (final id in sacrificeTokenIds) {
      final sacrifice = _tokens.firstWhere((t) => t.id == id, orElse: () => mainToken);
      _tokens.removeWhere((t) => t.id == id);
      _totalPoints -= sacrifice.points;
    }

    // Erstelle upgegradeten Token
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
  }

  int getTokenCountByTier(String landmarkId, TokenTier tier) {
    return _tokens
        .where((t) => t.landmarkId == landmarkId && t.tier == tier)
        .length;
  }

  // Reset collection for testing
  void resetCollection() {
    _tokens.clear();
    _totalPoints = 0;
    for (var i = 0; i < _sets.length; i++) {
      _sets[i] = _sets[i].copyWith(
        collectedTokenIds: [],
        completed: false,
      );
    }
    notifyListeners();
  }
}
