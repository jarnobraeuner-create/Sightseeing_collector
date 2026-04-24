import '../models/index.dart';
import 'collection_service.dart';
import 'landmark_service.dart';

class MonumentTaskStatus {
  final String id;
  final String title;
  final String detail;
  final String progressLabel;
  final int progress;
  final int required;

  const MonumentTaskStatus({
    required this.id,
    required this.title,
    required this.detail,
    required this.progressLabel,
    required this.progress,
    required this.required,
  });

  bool get completed => progress >= required;
}

class MonumentUnlockStatus {
  final bool setCompleted;
  final int setRequiredCount;
  final int setCollectedCount;
  final List<MonumentTaskStatus> tasks;

  const MonumentUnlockStatus({
    required this.setCompleted,
    required this.setRequiredCount,
    required this.setCollectedCount,
    required this.tasks,
  });

  int get completedTaskCount => tasks.where((t) => t.completed).length;
  int get taskCount => tasks.length;
  bool get challengeUnlocked => setCompleted;
  bool get unlocked => challengeUnlocked && completedTaskCount >= taskCount;
  int get remainingTaskCount => (taskCount - completedTaskCount).clamp(0, taskCount);
  double get setProgress =>
      setRequiredCount == 0 ? 0 : (setCollectedCount / setRequiredCount);
  double get taskProgress => taskCount == 0 ? 0 : (completedTaskCount / taskCount);
}

class MonumentUnlockService {
  static const String hamburgSetId = 'set_hamburg';
  // Diese Hamburg-Tokens sollen nicht in Schritt 1 der Monumente-Challenge zählen.
  static const Set<String> _excludedHamburgChallengeIds = {
    '69',
    '70',
    '71',
    '72',
    '73',
    '74',
    '75',
  };

  static const List<String> _museumsForElbphiTask = [
    '31', // Museum für Kunst und Gewerbe
    '30', // Kunsthalle
    '51', // BallinStadt
    '73', // Museum der Arbeit
    '74', // Museum für Hamburgische Geschichte
    '75', // Völkerkundemuseum
    '32', // Maritimes Museum
  ];

  static const List<String> _hafencityForSpeicherstadtTask = [
    '18', // HCU
    '19', // Marco Polo Tower
    '21', // Westfield
    '32', // Maritimes Museum
    '29', // Miniatur Wunderland
    '2',  // Elbphilharmonie
  ];

  static int _tierRank(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return 0;
      case TokenTier.silver:
        return 1;
      case TokenTier.gold:
        return 2;
      case TokenTier.platinum:
        return 3;
      case TokenTier.monumente:
        return 4;
    }
  }

  static bool _hasTierOrHigher(
    CollectionService collectionService,
    String landmarkId,
    TokenTier minTier,
  ) {
    final minRank = _tierRank(minTier);
    return collectionService.tokens.any(
      (t) => t.landmarkId == landmarkId && _tierRank(t.tier) >= minRank,
    );
  }

  static int _countTierOrHigherInIds(
    CollectionService collectionService,
    List<String> ids,
    TokenTier minTier,
  ) {
    return ids
        .where((id) => _hasTierOrHigher(collectionService, id, minTier))
        .length;
  }

  static MonumentUnlockStatus getHamburgMonumentStatus(
    CollectionService collectionService,
    LandmarkService landmarkService,
  ) {
    final hamburgSet = collectionService.getSetById(hamburgSetId);
    final challengeRequiredIds = (hamburgSet?.requiredTokenIds ?? const <String>[])
        .where((id) => !_excludedHamburgChallengeIds.contains(id))
        .toSet();
    final collectedChallengeIds = (hamburgSet?.collectedTokenIds ?? const <String>[])
        .where(challengeRequiredIds.contains)
        .toSet();

    final setRequiredCount = challengeRequiredIds.length;
    final setCollectedCount = collectedChallengeIds.length;
    final setCompleted =
        setRequiredCount > 0 && setCollectedCount >= setRequiredCount;

    final churchIds = landmarkService.landmarks
        .where((l) => l.isChurch)
        .map((l) => l.id)
        .toSet();

    final churchTokenCount = collectionService.tokens
        .where((t) => churchIds.contains(t.landmarkId))
        .length;
    final stPetriGold = _hasTierOrHigher(collectionService, '41', TokenTier.gold);
    final stNikolaiGold =
        _hasTierOrHigher(collectionService, '28', TokenTier.gold);
    final michelDone = churchTokenCount >= 5 && stPetriGold && stNikolaiGold;

    final museumsSilverCount = _countTierOrHigherInIds(
      collectionService,
      _museumsForElbphiTask,
      TokenTier.silver,
    );

    final hafencitySilverCount = _countTierOrHigherInIds(
      collectionService,
      _hafencityForSpeicherstadtTask,
      TokenTier.silver,
    );

    final taskStatuses = [
      MonumentTaskStatus(
        id: 'task_michel',
        title: 'Michel-Aufgabe',
        detail:
            '5 Kirchen sammeln und St. Petri + St. Nikolai mindestens auf Gold.',
        progressLabel:
            'Kirchen: $churchTokenCount/5 · Petri Gold: ${stPetriGold ? 'ja' : 'nein'} · Nikolai Gold: ${stNikolaiGold ? 'ja' : 'nein'}',
        progress: michelDone ? 1 : 0,
        required: 1,
      ),
      MonumentTaskStatus(
        id: 'task_elbphi',
        title: 'Elbphilharmonie-Aufgabe',
        detail:
            'Alle Museums-Tokens auf mindestens Silber (MKG, Kunsthalle, BallinStadt, Museum der Arbeit, Museum für Hamburgische Geschichte, Völkerkundemuseum, Maritimes Museum).',
        progressLabel:
            'Museen auf Silber+: $museumsSilverCount/${_museumsForElbphiTask.length}',
        progress: museumsSilverCount,
        required: _museumsForElbphiTask.length,
      ),
      MonumentTaskStatus(
        id: 'task_speicherstadt',
        title: 'Speicherstadt-Aufgabe',
        detail:
            'Hafencity-Tokens auf mindestens Silber: HCU, Marco Polo Tower, Westfield, Maritimes Museum, Miniatur Wunderland, Elbphilharmonie.',
        progressLabel:
            'Hafencity auf Silber+: $hafencitySilverCount/${_hafencityForSpeicherstadtTask.length}',
        progress: hafencitySilverCount,
        required: _hafencityForSpeicherstadtTask.length,
      ),
    ];

    return MonumentUnlockStatus(
      setCompleted: setCompleted,
      setRequiredCount: setRequiredCount,
      setCollectedCount: setCollectedCount,
      tasks: taskStatuses,
    );
  }
}
