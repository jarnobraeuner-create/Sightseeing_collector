import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/collection_service.dart';
import '../services/landmark_service.dart';

class TokenUpgradeScreen extends StatefulWidget {
  final Token? initialToken;

  const TokenUpgradeScreen({Key? key, this.initialToken}) : super(key: key);

  @override
  State<TokenUpgradeScreen> createState() => _TokenUpgradeScreenState();
}

class _TokenUpgradeScreenState extends State<TokenUpgradeScreen>
    with TickerProviderStateMixin {
  Token? _selectedTokenToUpgrade;
  final List<Token> _selectedTokensToTrade = [];
  bool _isAnimating = false;

  // Keys for animation targets
  final GlobalKey _mainSlotKey = GlobalKey();
  final List<GlobalKey> _sacrificeSlotKeys =
      List.generate(5, (_) => GlobalKey());

  // Stable keys for each token chip (by token id)
  final Map<String, GlobalKey> _chipKeys = {};

  GlobalKey _chipKey(String tokenId) =>
      _chipKeys.putIfAbsent(tokenId, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedTokenToUpgrade = widget.initialToken);
      });
    }
  }

  // â”€â”€â”€ Fly animation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _flyToken({
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required String imagePath,
    required Color borderColor,
    required VoidCallback onComplete,
  }) {
    final sourceBox =
        sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null || targetBox == null) {
      onComplete();
      return;
    }

    final sourcePos = sourceBox.localToGlobal(Offset.zero);
    final sourceSize = sourceBox.size;
    final targetPos = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;

    const flySize = 58.0;
    final startCenter = Offset(
      sourcePos.dx + sourceSize.width / 2,
      sourcePos.dy + sourceSize.height / 2,
    );
    final endCenter = Offset(
      targetPos.dx + targetSize.width / 2,
      targetPos.dy + targetSize.height / 2,
    );

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curved =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: curved,
        builder: (_, __) {
          final t = curved.value;
          final cx = startCenter.dx + (endCenter.dx - startCenter.dx) * t;
          final cy = startCenter.dy + (endCenter.dy - startCenter.dy) * t;
          // Arc: rise 90px at the midpoint
          final arcOffset = -90.0 * sin(pi * t);
          return Positioned(
            left: cx - flySize / 2,
            top: cy + arcOffset - flySize / 2,
            width: flySize,
            height: flySize,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.55),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(imagePath, fit: BoxFit.cover),
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(entry);
    setState(() => _isAnimating = true);

    controller.forward().then((_) {
      entry.remove();
      controller.dispose();
      if (mounted) setState(() => _isAnimating = false);
      onComplete();
    });
  }

  void _onChipTapped({
    required Token token,
    required String imagePath,
    required Color tierColor,
  }) {
    if (_isAnimating) return;
    final chipKey = _chipKey(token.id);

    if (_selectedTokenToUpgrade == null) {
      // First tap â†’ fly to main slot
      _flyToken(
        sourceKey: chipKey,
        targetKey: _mainSlotKey,
        imagePath: imagePath,
        borderColor: tierColor,
        onComplete: () {
          if (mounted) setState(() => _selectedTokenToUpgrade = token);
        },
      );
    } else if (_selectedTokensToTrade.length < 5) {
      // Subsequent taps â†’ fly to next sacrifice slot
      final slotIdx = _selectedTokensToTrade.length;
      _flyToken(
        sourceKey: chipKey,
        targetKey: _sacrificeSlotKeys[slotIdx],
        imagePath: imagePath,
        borderColor: tierColor,
        onComplete: () {
          if (mounted) setState(() => _selectedTokensToTrade.add(token));
        },
      );
    }
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Token Upgrades',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            tooltip: 'Alle Tokens sammeln (Test)',
            onPressed: () {
              final cs = context.read<CollectionService>();
              final ls = context.read<LandmarkService>();
              cs.collectAllTokensForTesting(ls.landmarks);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('6x Bronze-Token pro Landmark gesammelt!'),
                backgroundColor: Colors.blue,
              ));
            },
          ),
          if (_selectedTokenToUpgrade != null ||
              _selectedTokensToTrade.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Auswahl zurücksetzen',
              onPressed: () => setState(() {
                _selectedTokenToUpgrade = null;
                _selectedTokensToTrade.clear();
              }),
            ),
        ],
      ),
      body: Consumer2<CollectionService, LandmarkService>(
        builder: (context, collectionService, landmarkService, child) {
          return Column(
            children: [
              _buildHeader(landmarkService),
              const Divider(color: Colors.grey, height: 1),
              Expanded(
                  child: _buildList(collectionService, landmarkService)),
              if (_selectedTokenToUpgrade != null &&
                  _selectedTokensToTrade.length == 5)
                _buildUpgradeButton(collectionService, landmarkService),
            ],
          );
        },
      ),
    );
  }

  // â”€â”€â”€ Header: main slot + sacrifice bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeader(LandmarkService landmarkService) {
    final token = _selectedTokenToUpgrade;
    final tierColor =
        token != null ? _getTierColor(token.tier) : Colors.grey[600]!;

    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // â”€â”€ Main slot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          const Text('Token zum Verbessern',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            key: _mainSlotKey,
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: token != null
                  ? tierColor.withValues(alpha: 0.1)
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: token != null ? tierColor : Colors.grey[700]!,
                width: 2.5,
              ),
              boxShadow: token != null
                  ? [
                      BoxShadow(
                          color: tierColor.withValues(alpha: 0.4),
                          blurRadius: 16)
                    ]
                  : null,
            ),
            child: token != null
                ? GestureDetector(
                    onTap: () => setState(() {
                      _selectedTokenToUpgrade = null;
                      _selectedTokensToTrade.clear();
                    }),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            landmarkService.getImageUrlForTier(
                                token.landmarkId, token.tier),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 3,
                          right: 3,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                color: Colors.red[700],
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Icon(Icons.add_circle_outline,
                        size: 40, color: Colors.grey),
                  ),
          ),
          if (token != null) ...[
            const SizedBox(height: 8),
            Text(
              landmarkService.landmarks
                  .firstWhere((l) => l.id == token.landmarkId)
                  .name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tierBadge(token.tier),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                      color: Colors.green, size: 20),
                ),
                _tierBadge(_getNextTier(token.tier)),
              ],
            ),
          ],

          // â”€â”€ Sacrifice bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (token != null) ...[
            const SizedBox(height: 14),
            const Text('Tausch-Tokens (5 benÃ¶tigt)',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _selectedTokensToTrade.length;
                final sacrifice =
                    filled ? _selectedTokensToTrade[i] : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: filled
                        ? () => setState(
                            () => _selectedTokensToTrade.removeAt(i))
                        : null,
                    child: AnimatedContainer(
                      key: _sacrificeSlotKeys[i],
                      duration: const Duration(milliseconds: 250),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: filled
                            ? tierColor.withValues(alpha: 0.1)
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: filled ? tierColor : Colors.grey[700]!,
                          width: filled ? 2.0 : 1.5,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                    color: tierColor.withValues(alpha: 0.3),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: filled
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    landmarkService.getImageUrlForTier(
                                        sacrifice!.landmarkId,
                                        sacrifice.tier),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                        color: Colors.red[700],
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16),
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedTokensToTrade.length}/5',
              style: TextStyle(
                color: _selectedTokensToTrade.length == 5
                    ? Colors.green[400]
                    : Colors.orange[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tierBadge(TokenTier tier) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _getTierColor(tier).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getTierColor(tier)),
        ),
        child: Text(
          '${_getTierEmoji(tier)} ${tier.displayName}',
          style: TextStyle(
            color: _getTierColor(tier),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  // â”€â”€â”€ Token list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildList(
      CollectionService collectionService, LandmarkService landmarkService) {
    final tokens = collectionService.tokens;

    if (tokens.isEmpty) {
      return const Center(
          child: Text('Keine Tokens gesammelt',
              style: TextStyle(color: Colors.grey, fontSize: 18)));
    }

    final alreadySelectedIds = <String>{
      if (_selectedTokenToUpgrade != null) _selectedTokenToUpgrade!.id,
      ..._selectedTokensToTrade.map((t) => t.id),
    };

    final List<Token> eligible;
    if (_selectedTokenToUpgrade == null) {
      eligible = tokens.where((t) => t.tier != TokenTier.platinum).toList();
    } else {
      // Opfertokens: gleiche Stufe, beliebiges Landmark
      eligible = tokens
          .where((t) =>
              t.tier == _selectedTokenToUpgrade!.tier &&
              !alreadySelectedIds.contains(t.id))
          .toList();
    }

    if (eligible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _selectedTokenToUpgrade == null
                ? 'Keine upgradefähigen Tokens vorhanden.'
                : 'Keine weiteren ${_selectedTokenToUpgrade!.tier.displayName}-Tokens vorhanden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ),
      );
    }

    final Map<String, List<Token>> grouped = {};
    for (final t in eligible) {
      final key = '${t.landmarkId}_${t.tier.name}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    final remaining = 5 - _selectedTokensToTrade.length;
    final hint = _selectedTokenToUpgrade == null
        ? 'Wähle einen Token zum Verbessern:'
        : 'Wähle noch $remaining ${_getTierEmoji(_selectedTokenToUpgrade!.tier)} Token(s) zum Eintauschen:';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(hint,
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            itemCount: grouped.length,
            itemBuilder: (context, idx) {
              final key = grouped.keys.elementAt(idx);
              final group = grouped[key]!;
              final first = group.first;
              final landmark = landmarkService.landmarks
                  .firstWhere((l) => l.id == first.landmarkId);
              final imagePath = landmarkService.getImageUrlForTier(
                  first.landmarkId, first.tier);
              final tierColor = _getTierColor(first.tier);

              // Stable key on the thumbnail — used as fly animation source
              final groupKey =
                  _chipKey('g_${first.landmarkId}_${first.tier.name}');

              // How many from this group are queued as sacrifices
              final selectedFromGroup = _selectedTokensToTrade
                  .where((t) =>
                      t.landmarkId == first.landmarkId &&
                      t.tier == first.tier)
                  .length;

              final canTapCard =
                  !_isAnimating && group.isNotEmpty;

              return GestureDetector(
                onTap: canTapCard
                    ? () {
                        final tokenToUse = group.first;
                        if (_selectedTokenToUpgrade == null) {
                          _flyToken(
                            sourceKey: groupKey,
                            targetKey: _mainSlotKey,
                            imagePath: imagePath,
                            borderColor: tierColor,
                            onComplete: () {
                              if (mounted)
                                setState(() =>
                                    _selectedTokenToUpgrade = tokenToUse);
                            },
                          );
                        } else if (_selectedTokensToTrade.length < 5) {
                          final slotIdx = _selectedTokensToTrade.length;
                          _flyToken(
                            sourceKey: groupKey,
                            targetKey: _sacrificeSlotKeys[slotIdx],
                            imagePath: imagePath,
                            borderColor: tierColor,
                            onComplete: () {
                              if (mounted)
                                setState(() =>
                                    _selectedTokensToTrade.add(tokenToUse));
                            },
                          );
                        }
                      }
                    : null,
                child: Card(
                  color: canTapCard ? Colors.grey[850] : Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Thumbnail (fly animation source)
                        Container(
                          key: groupKey,
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: canTapCard
                                    ? tierColor
                                    : Colors.grey[700]!,
                                width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child:
                                Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + tier badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(landmark.name,
                                  style: TextStyle(
                                      color: canTapCard
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              _tierBadge(first.tier),
                            ],
                          ),
                        ),
                        // Count + selected indicator
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${group.length}x',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            if (selectedFromGroup > 0)
                              Text('$selectedFromGroup ausgew.',
                                  style: TextStyle(
                                      color: tierColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€ Upgrade button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildUpgradeButton(
      CollectionService collectionService, LandmarkService landmarkService) {
    final toTier = _getNextTier(_selectedTokenToUpgrade!.tier);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              collectionService.upgradeSpecificTokens(
                _selectedTokenToUpgrade!.id,
                _selectedTokensToTrade.map((t) => t.id).toList(),
                toTier,
              );
              final landmark = landmarkService.landmarks.firstWhere(
                  (l) => l.id == _selectedTokenToUpgrade!.landmarkId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    '${landmark.name} ${toTier.displayName} erstellt! ðŸŽ‰'),
                backgroundColor: Colors.green,
              ));
              setState(() {
                _selectedTokenToUpgrade = null;
                _selectedTokensToTrade.clear();
              });
            },
            icon: const Icon(Icons.upgrade),
            label: Text(
              'Zu ${toTier.displayName} upgraden',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Color _getTierColor(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return Colors.orange[700]!;
      case TokenTier.silver:
        return Colors.grey[400]!;
      case TokenTier.gold:
        return Colors.amber[600]!;
      case TokenTier.platinum:
        return Colors.cyan[400]!;
    }
  }

  TokenTier _getNextTier(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return TokenTier.silver;
      case TokenTier.silver:
        return TokenTier.gold;
      case TokenTier.gold:
        return TokenTier.platinum;
      case TokenTier.platinum:
        return TokenTier.platinum;
    }
  }

  String _getTierEmoji(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return '🥉';
      case TokenTier.silver:
        return '🥈';
      case TokenTier.gold:
        return '🥇';
      case TokenTier.platinum:
        return '💎';
    }
  }
}
