import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/collection_service.dart';
import '../services/landmark_service.dart';

class SetsScreen extends StatelessWidget {
  const SetsScreen({Key? key}) : super(key: key);

  // Set-Token-Bild je Set-ID
  String _setImage(String setId) {
    switch (setId) {
      case 'set_hamburg':
        return 'assets/images/Hamburg_Wappen_small.png';
      case 'set_monuments':
        return 'assets/images/Token_Elbphilhamonie_silber.png';
      case 'set_dissen':
        return 'assets/images/Dissen_Wappen_small.png';
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
      case 'set_dissen':
        return '🌿';
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

          if (sets.isEmpty) {
            return const Center(
              child: Text('Keine Sets verfügbar',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: set.requiredTokenIds.map((landmarkId) {
                final collected =
                    set.collectedTokenIds.contains(landmarkId);
                final landmark =
                    landmarkService.getLandmarkById(landmarkId);
                final name = landmark?.name ?? landmarkId;

                return _TokenChip(
                  collected: collected,
                  landmark: landmark,
                  name: name,
                );
              }).toList(),
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

// ── Individual token chip with tap-popup for locked tokens ──────────────────

class _TokenChip extends StatefulWidget {
  final bool collected;
  final Landmark? landmark;
  final String name;

  const _TokenChip({
    required this.collected,
    required this.landmark,
    required this.name,
  });

  @override
  State<_TokenChip> createState() => _TokenChipState();
}

class _TokenChipState extends State<_TokenChip> {
  OverlayEntry? _overlay;
  final GlobalKey _key = GlobalKey();

  void _showPopup() {
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

    return GestureDetector(
      onTap: !collected ? _showPopup : null,
      child: Container(
        key: _key,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: collected ? Colors.green[400]! : Colors.grey[700]!,
            width: 2,
          ),
          color: collected ? Colors.green[900] : Colors.grey[800],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (collected && landmark != null)
                Image.asset(
                  landmark.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.black),
                )
              else
                Container(color: Colors.black),
              if (!collected)
                const Center(
                  child:
                      Icon(Icons.lock, color: Colors.white38, size: 16),
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
                    child: const Icon(Icons.check,
                        size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
