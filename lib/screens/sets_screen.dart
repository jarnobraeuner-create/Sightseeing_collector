import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/collection_service.dart';
import '../services/dev_mode_service.dart';
import '../services/landmark_service.dart';
import '../services/location_service.dart';
import '../services/monument_unlock_service.dart';
import '../widgets/app_lottie.dart';

class SetsScreen extends StatelessWidget {
  const SetsScreen({Key? key}) : super(key: key);

  // Set-Token-Bild je Set-ID
  String _setImage(String setId) {
    switch (setId) {
      case 'set_hamburg':
        return 'assets/images/Hamburg_Wappen_small.png';
      case 'set_monuments':
        return 'assets/images/Token_Elbphilhamonie_silber.png';
      case 'set_leipzig':
        return 'assets/images/Leipzig_Wappen_Set_token.png';
      case 'set_weltwunder':
        return 'assets/images/Collosseum_Weltwunder_token.png';
      default:
        return 'assets/images/Token_gold_speicherstadt.png';
    }
  }

  String _setEmoji(String setId) {
    switch (setId) {
      case 'set_hamburg':
        return '🏙️';
      case 'set_monuments':
        return '🏛️';
      case 'set_leipzig':
        return '🏙️';
      case 'set_weltwunder':
        return '🌍';
      default:
        return '🎖️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Sets', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<CollectionService, LandmarkService>(
        builder: (context, collectionService, landmarkService, _) {
          // Ensure sets are loaded
          final sets = collectionService.sets;
          final monumentStatus = MonumentUnlockService.getHamburgMonumentStatus(
            collectionService,
            landmarkService,
          );

          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  AppLottie(type: AppLottieType.empty, size: 120),
                  SizedBox(height: 12),
                  Text(
                    'Keine Sets verfügbar',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MonumentUnlockCard(status: monumentStatus);
              }

              final setIndex = index - 1;
              final set = sets[setIndex];
              return _SetCard(
                set: set,
                landmarkService: landmarkService,
                setImage: _setImage(set.id),
                setEmoji: _setEmoji(set.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _MonumentUnlockCard extends StatelessWidget {
  final MonumentUnlockStatus status;

  const _MonumentUnlockCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final unlocked = status.unlocked;
    final accent = unlocked ? Colors.tealAccent : Colors.deepPurpleAccent;
    final Widget statusBadge;

    if (unlocked) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.tealAccent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Freigeschaltet',
          style: TextStyle(
            color: Colors.tealAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (!status.challengeUnlocked) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Set nicht fertig',
          style: TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${status.remainingTaskCount} Aufgaben offen',
          style: const TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFF1E1730),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accent.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Monumente-Challenge: Hamburg',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                statusBadge,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? 'Monumente sind jetzt freigeschaltet.'
                  : !status.challengeUnlocked
                      ? 'Schritt 1: Hamburg-Challenge-Tokens vollständig abschließen.'
                      : 'Schritt 2: 3 Monument-Aufgaben lösen.',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.challengeUnlocked
                    ? status.taskProgress
                    : status.setProgress,
                minHeight: 8,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status.challengeUnlocked
                  ? '${status.completedTaskCount} / ${status.taskCount} Monument-Aufgaben gelöst'
                  : '${status.setCollectedCount} / ${status.setRequiredCount} Hamburg-Challenge-Tokens gesammelt',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            if (status.challengeUnlocked) ...[
              const SizedBox(height: 10),
              ...status.tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          task.completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 15,
                          color: task.completed
                              ? Colors.tealAccent
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${task.title}: ${task.progressLabel}',
                            style: TextStyle(
                              color: task.completed
                                  ? Colors.tealAccent
                                  : Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              ...status.tasks
                  .where((task) => task.detail.isNotEmpty)
                  .map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          task.detail,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final CollectionSet set;
  final LandmarkService landmarkService;
  final String setImage;
  final String setEmoji;

  const _SetCard({
    required this.set,
    required this.landmarkService,
    required this.setImage,
    required this.setEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final progress = set.collectedTokenIds.length;
    final total = set.requiredTokenIds.length;
    final pct = total > 0 ? progress / total : 0.0;
    final isComplete = set.completed;
    final slotPalette = _SetSlotPalette.forSetId(set.id);

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: isComplete
                  ? Colors.amber[800]!.withValues(alpha: 0.25)
                  : Colors.grey[800],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Set token image / placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isComplete
                          ? Colors.amber[400]!
                          : Colors.grey[600]!,
                      width: 2,
                    ),
                    boxShadow: isComplete
                        ? [
                            BoxShadow(
                              color:
                                  Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(setImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                                  child: Text(setEmoji,
                                      style:
                                          const TextStyle(fontSize: 36)),
                                )),
                      ),
                      if (!isComplete)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock,
                                color: Colors.white54, size: 28),
                          ),
                        ),
                      if (isComplete)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$setEmoji ${set.name}',
                        style: TextStyle(
                          color:
                              isComplete ? Colors.amber[300] : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        set.description,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey[700],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete
                                ? Colors.amber[400]!
                                : Colors.blue[400]!,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$progress / $total Tokens',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                          if (isComplete)
                            Text('✅ Abgeschlossen!',
                                style: TextStyle(
                                    color: Colors.amber[300],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))
                          else
                            Text(
                              '+${set.bonusPoints} Bonus-Punkte',
                              style: TextStyle(
                                  color: Colors.green[400], fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Token grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _PagedTokenGrid(
              requiredTokenIds: set.requiredTokenIds,
              collectedTokenIds: set.collectedTokenIds,
              landmarkService: landmarkService,
              slotPalette: slotPalette,
            ),
          ),

          // Completion reward banner
          if (isComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber[800]!.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Text(
                    '🎉 Set-Belohnung freigeschaltet!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.amber[300],
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  if (set.rewardImageUrl != null) ...[
                    const SizedBox(height: 8),
                    Image.asset(
                      set.rewardImageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PagedTokenGrid extends StatefulWidget {
  final List<String> requiredTokenIds;
  final List<String> collectedTokenIds;
  final LandmarkService landmarkService;
  final _SetSlotPalette slotPalette;

  const _PagedTokenGrid({
    required this.requiredTokenIds,
    required this.collectedTokenIds,
    required this.landmarkService,
    required this.slotPalette,
  });

  @override
  State<_PagedTokenGrid> createState() => _PagedTokenGridState();
}

class _PagedTokenGridState extends State<_PagedTokenGrid> {
  static const int _tokensPerPage = 18;
  int _currentPage = 0;

  List<List<String>> _buildPages() {
    final pages = <List<String>>[];
    for (var i = 0; i < widget.requiredTokenIds.length; i += _tokensPerPage) {
      final end = (i + _tokensPerPage) > widget.requiredTokenIds.length
          ? widget.requiredTokenIds.length
          : i + _tokensPerPage;
      pages.add(widget.requiredTokenIds.sublist(i, end));
    }
    if (pages.isEmpty) return const [[]];
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            itemCount: pages.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final pageIds = pages[index];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pageIds.map((landmarkId) {
                  final collected =
                      widget.collectedTokenIds.contains(landmarkId);
                  final landmark =
                      widget.landmarkService.getLandmarkById(landmarkId);
                  final name = landmark?.name ?? landmarkId;

                  return _TokenChip(
                    collected: collected,
                    landmark: landmark,
                    name: name,
                    slotPalette: widget.slotPalette,
                  );
                }).toList(),
              );
            },
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seite ${_currentPage + 1}/${pages.length}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Text(
                'Nach links/rechts wischen',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Individual token chip with tap-popup for locked tokens ──────────────────

class _TokenChip extends StatefulWidget {
  final bool collected;
  final Landmark? landmark;
  final String name;
  final _SetSlotPalette slotPalette;

  const _TokenChip({
    required this.collected,
    required this.landmark,
    required this.name,
    required this.slotPalette,
  });

  @override
  State<_TokenChip> createState() => _TokenChipState();
}

class _TokenChipState extends State<_TokenChip> {
  OverlayEntry? _overlay;
  final GlobalKey _key = GlobalKey();

  bool _isReachable(Landmark landmark) {
    final devMode = Provider.of<DevModeService>(context, listen: false).enabled;
    if (devMode) return true;
    final position = Provider.of<LocationService>(context, listen: false).currentPosition;
    if (position == null) return false;
    final distance = landmark.getDistance(position.latitude, position.longitude);
    return distance <= landmark.checkInRadiusKm;
  }

  Widget _grayDefaultToken() {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.asset(
        'assets/images/default_token.jpeg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[700]),
      ),
    );
  }


  void _showPopup() {
    if (widget.collected && widget.landmark != null) {
      // Großes Pop-up für gesammelte Tokens: immer höchstes Tier anzeigen
      final collectionService = Provider.of<CollectionService>(context, listen: false);
      final tokens = collectionService.tokens.where((t) => t.landmarkId == widget.landmark!.id).toList();
      if (tokens.isEmpty) return;
      tokens.sort((a, b) {
        if (a.tier == null && b.tier != null) return 1;
        if (a.tier != null && b.tier == null) return -1;
        if (a.tier == null && b.tier == null) return 0;
        return b.tier!.index.compareTo(a.tier!.index);
      });
      final token = tokens.first;
      final landmarkService = Provider.of<LandmarkService>(context, listen: false);
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Damit das Pop-up selbst nicht schließt
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.asset(
                            token.tier != null
                                ? landmarkService.getImageUrlForTier(token.landmarkId, token.tier!)
                                : 'assets/images/default_token.jpeg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          token.landmarkName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          token.tier?.displayName ?? 'Weltwunder',
                          style: TextStyle(color: Colors.amber, fontSize: 14),
                        ),
                        Text(
                          '${token.points} Punkte',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kategorie: ${token.category}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Kleines Overlay für fehlende Tokens
      _removePopup();
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final pos = box.localToGlobal(Offset.zero);
      final size = box.size;

      _overlay = OverlayEntry(
        builder: (_) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removePopup,
          child: Stack(
            children: [
              Positioned(
                left: pos.dx + size.width / 2 - 70,
                top: pos.dy + size.height + 6,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[600]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      Overlay.of(context).insert(_overlay!);
      // Auto-dismiss after 2 seconds
      Future.delayed(const Duration(seconds: 2), _removePopup);
    }
  }

  void _removePopup() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collected = widget.collected;
    final landmark = widget.landmark;
    final reachable = landmark != null ? _isReachable(landmark) : false;
    final slotPalette = widget.slotPalette;

    return GestureDetector(
      onTap: _showPopup,
      child: Container(
        key: _key,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              slotPalette.velvetLight,
              slotPalette.velvetBase,
              slotPalette.velvetDark,
            ],
            stops: const [0.0, 0.52, 1.0],
          ),
          border: Border.all(
            color: collected
                ? slotPalette.borderCollected
                : slotPalette.borderDefault,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: slotPalette.shadowOuter,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: slotPalette.shadowInnerGlow,
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (collected && landmark != null)
                Builder(
                  builder: (context) {
                    final collectionService = Provider.of<CollectionService>(context, listen: false);
                    final tokens = collectionService.tokens.where((t) => t.landmarkId == landmark.id).toList();
                    if (tokens.isEmpty) {
                      return Container(color: Colors.black);
                    }
                    tokens.sort((a, b) {
                      if (a.tier == null && b.tier != null) return 1;
                      if (a.tier != null && b.tier == null) return -1;
                      if (a.tier == null && b.tier == null) return 0;
                      return b.tier!.index.compareTo(a.tier!.index);
                    });
                    final token = tokens.first;
                    final landmarkService = Provider.of<LandmarkService>(context, listen: false);
                    return Image.asset(
                      token.tier != null
                          ? landmarkService.getImageUrlForTier(token.landmarkId, token.tier!)
                          : 'assets/images/default_token.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: slotPalette.placeholderFill,
                      ),
                    );
                  },
                )
              else if (!collected && landmark != null && !reachable)
                _grayDefaultToken()
              else
                Container(color: slotPalette.placeholderFill),
              if (!collected)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              if (!collected)
                const Center(
                  child: Icon(Icons.lock, color: Colors.white38, size: 16),
                ),
              if (collected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetSlotPalette {
  final Color velvetLight;
  final Color velvetBase;
  final Color velvetDark;
  final Color borderDefault;
  final Color borderCollected;
  final Color shadowOuter;
  final Color shadowInnerGlow;
  final Color placeholderFill;

  const _SetSlotPalette({
    required this.velvetLight,
    required this.velvetBase,
    required this.velvetDark,
    required this.borderDefault,
    required this.borderCollected,
    required this.shadowOuter,
    required this.shadowInnerGlow,
    required this.placeholderFill,
  });

  factory _SetSlotPalette.forSetId(String setId) {
    switch (setId) {
      case 'set_hamburg':
        return const _SetSlotPalette(
          velvetLight: Color(0xFF6E3A44),
          velvetBase: Color(0xFF5A2E37),
          velvetDark: Color(0xFF44232B),
          borderDefault: Color(0xFFD8AEB8),
          borderCollected: Color(0xFFEBC0C9),
          shadowOuter: Color(0x5528141A),
          shadowInnerGlow: Color(0x33E9CCD2),
          placeholderFill: Color(0xFF2F1C22),
        );
      case 'set_leipzig':
        return const _SetSlotPalette(
          velvetLight: Color(0xFF3C5E4A),
          velvetBase: Color(0xFF324F3E),
          velvetDark: Color(0xFF263C2F),
          borderDefault: Color(0xFFB8D7C3),
          borderCollected: Color(0xFFD0E9D8),
          shadowOuter: Color(0x5520362A),
          shadowInnerGlow: Color(0x33CFE9D6),
          placeholderFill: Color(0xFF1F2D25),
        );
      case 'set_weltwunder':
        return const _SetSlotPalette(
          velvetLight: Color(0xFF35666B),
          velvetBase: Color(0xFF2C565A),
          velvetDark: Color(0xFF204045),
          borderDefault: Color(0xFFAED7D9),
          borderCollected: Color(0xFFC6E9EB),
          shadowOuter: Color(0x55192E31),
          shadowInnerGlow: Color(0x33CDEEF0),
          placeholderFill: Color(0xFF1B2F33),
        );
      default:
        return const _SetSlotPalette(
          velvetLight: Color(0xFF4D5362),
          velvetBase: Color(0xFF3E4350),
          velvetDark: Color(0xFF2E323C),
          borderDefault: Color(0xFFBFC7D5),
          borderCollected: Color(0xFFD7DEEA),
          shadowOuter: Color(0x5521242B),
          shadowInnerGlow: Color(0x33D8E0F0),
          placeholderFill: Color(0xFF232730),
        );
    }
  }
}
