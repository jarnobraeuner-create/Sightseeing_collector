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
  bool _isOrbiting = false;
  OverlayEntry? _orbitOverlay;

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

  // ─── Fly animation ────────────────────────────────────────────────────────

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
              tooltip: 'Auswahl zur�cksetzen',
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

  // ─── Header: main slot + sacrifice bar ───────────────────────────────────

  Widget _buildHeader(LandmarkService landmarkService) {
    final token = _selectedTokenToUpgrade;
    final tierColor =
        token != null ? _getTierColor(token.tier) : Colors.grey[600]!;

    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // ── Main slot ──────────────────────────────────────────────────
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

          // ── Sacrifice bar ───────────────────────────────────────────────
          if (token != null) ...[
            const SizedBox(height: 14),
            const Text('Tausch-Tokens (5 benötigt)',
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

  // ─── Token list ────────────────────────────────────────────────────────────

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
                ? 'Keine upgradef�higen Tokens vorhanden.'
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
        ? 'W�hle einen Token zum Verbessern:'
        : 'W�hle noch $remaining ${_getTierEmoji(_selectedTokenToUpgrade!.tier)} Token(s) zum Eintauschen:';

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

              // Stable key on the thumbnail � used as fly animation source
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

  // ─── Upgrade button ────────────────────────────────────────────────────────

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
            onPressed: _isOrbiting ? null : () => _startOrbitAndUpgrade(
              collectionService, landmarkService,
            ),
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

  // ─── Orbital upgrade animation ────────────────────────────────────────────

  Future<void> _startOrbitAndUpgrade(
    CollectionService collectionService,
    LandmarkService landmarkService,
  ) async {
    if (_isOrbiting || _selectedTokenToUpgrade == null) return;
    setState(() => _isOrbiting = true);

    final mainBox = _mainSlotKey.currentContext?.findRenderObject() as RenderBox?;
    if (mainBox == null) {
      _doUpgrade(collectionService, landmarkService);
      return;
    }

    final mainPos = mainBox.localToGlobal(Offset.zero);
    final mainSize = mainBox.size;
    final mainCenter = Offset(
      mainPos.dx + mainSize.width / 2,
      mainPos.dy + mainSize.height / 2,
    );

    // Gather sacrifice token images
    final sacrificeImages = _selectedTokensToTrade.map((t) {
      return landmarkService.getImageUrlForTier(t.landmarkId, t.tier);
    }).toList();
    final toTier = _getNextTier(_selectedTokenToUpgrade!.tier);
    final mainColor = _getTierColor(_selectedTokenToUpgrade!.tier);

    final orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600), // 2 full orbits
    );
    final collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final orbitAnim = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: orbitController, curve: Curves.easeInOut),
    );
    final collapseAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: collapseController, curve: Curves.easeIn),
    );
    final flashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: flashController, curve: Curves.easeOut),
    );

    const orbitRadius = 70.0;
    const tokenSize = 46.0;
    final count = sacrificeImages.length;
    final toColor = _getTierColor(toTier);

    _orbitOverlay = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: Listenable.merge([orbitAnim, collapseAnim, flashAnim]),
        builder: (_, __) {
          final phase = collapseController.isAnimating || collapseController.isCompleted;
          final radius = orbitRadius * (phase ? collapseAnim.value : 1.0);
          final opacity = phase ? collapseAnim.value : 1.0;
          return Stack(
            children: [
              // Flash effect on main slot
              if (flashController.isAnimating || flashController.isCompleted)
                Positioned(
                  left: mainCenter.dx - 80,
                  top: mainCenter.dy - 80,
                  child: Opacity(
                    opacity: (1.0 - flashAnim.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            toColor.withValues(alpha: 0.9),
                            toColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Orbiting tokens
              ...List.generate(count, (i) {
                final angle = orbitAnim.value + (2 * pi * i / count);
                final x = mainCenter.dx + radius * cos(angle) - tokenSize / 2;
                final y = mainCenter.dy + radius * sin(angle) - tokenSize / 2;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Container(
                      width: tokenSize,
                      height: tokenSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: mainColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(sacrificeImages[i], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    Overlay.of(context).insert(_orbitOverlay!);

    // 2 full orbits
    await orbitController.forward();
    // Collapse into main token
    await collapseController.forward();
    // Flash
    flashController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    _orbitOverlay?.remove();
    _orbitOverlay = null;
    orbitController.dispose();
    collapseController.dispose();

    await Future.delayed(const Duration(milliseconds: 300));
    flashController.dispose();

    if (mounted) _doUpgrade(collectionService, landmarkService);
  }

  void _doUpgrade(
    CollectionService collectionService,
    LandmarkService landmarkService,
  ) {
    final toTier = _getNextTier(_selectedTokenToUpgrade!.tier);
    final landmark = landmarkService.landmarks
        .firstWhere((l) => l.id == _selectedTokenToUpgrade!.landmarkId);
    final newImagePath =
        landmarkService.getImageUrlForTier(_selectedTokenToUpgrade!.landmarkId, toTier);

    collectionService.upgradeSpecificTokens(
      _selectedTokenToUpgrade!.id,
      _selectedTokensToTrade.map((t) => t.id).toList(),
      toTier,
    );

    if (mounted) {
      setState(() {
        _isOrbiting = false;
        _selectedTokenToUpgrade = null;
        _selectedTokensToTrade.clear();
      });
      _showUpgradeResult(landmark, toTier, newImagePath);
    }
  }

  void _showUpgradeResult(Landmark landmark, TokenTier tier, String imagePath) {
    final tierColor = _getTierColor(tier);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _UpgradeResultDialog(
        landmark: landmark,
        tier: tier,
        imagePath: imagePath,
        tierColor: tierColor,
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

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
        return '??';
      case TokenTier.silver:
        return '??';
      case TokenTier.gold:
        return '??';
      case TokenTier.platinum:
        return '??';
    }
  }
}

// ── Upgrade Result Dialog ─────────────────────────────────────────────────

class _UpgradeResultDialog extends StatefulWidget {
  final Landmark landmark;
  final TokenTier tier;
  final String imagePath;
  final Color tierColor;

  const _UpgradeResultDialog({
    required this.landmark,
    required this.tier,
    required this.imagePath,
    required this.tierColor,
  });

  @override
  State<_UpgradeResultDialog> createState() => _UpgradeResultDialogState();
}

class _UpgradeResultDialogState extends State<_UpgradeResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _raysController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _raysAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _raysAnim = Tween<double>(begin: 0, end: 1).animate(_raysController);

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _raysController.dispose();
    super.dispose();
  }

  String _tierLabel(TokenTier t) {
    switch (t) {
      case TokenTier.bronze: return '🥉 Bronze';
      case TokenTier.silver: return '🥈 Silber';
      case TokenTier.gold: return '🥇 Gold';
      case TokenTier.platinum: return '💎 Platin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.tierColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Upgrade erfolgreich! 🎉',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Token image with glow + rays
              AnimatedBuilder(
                animation: Listenable.merge([_glowAnim, _raysAnim]),
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating rays
                      Transform.rotate(
                        angle: _raysAnim.value * 2 * pi,
                        child: CustomPaint(
                          size: const Size(220, 220),
                          painter: _RaysPainter(
                            color: color.withValues(alpha: 0.18),
                            rayCount: 12,
                          ),
                        ),
                      ),
                      // Glow circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: _glowAnim.value * 0.7),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                      // Token image
                      child!,
                    ],
                  );
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(widget.imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Landmark name
              Text(
                widget.landmark.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  _tierLabel(widget.tier),
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Super! ✨',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  final int rayCount;

  _RaysPainter({required this.color, required this.rayCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    const innerR = 55.0;
    const halfAngle = 0.12;

    for (int i = 0; i < rayCount; i++) {
      final baseAngle = (2 * pi / rayCount) * i;
      final path = Path()
        ..moveTo(
          center.dx + innerR * cos(baseAngle - halfAngle),
          center.dy + innerR * sin(baseAngle - halfAngle),
        )
        ..lineTo(
          center.dx + innerR * cos(baseAngle + halfAngle),
          center.dy + innerR * sin(baseAngle + halfAngle),
        )
        ..lineTo(
          center.dx + outerR * cos(baseAngle),
          center.dy + outerR * sin(baseAngle),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
