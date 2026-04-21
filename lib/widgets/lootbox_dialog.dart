import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';
import '../services/landmark_service.dart';
import '../services/lootbox_service.dart';

class LootboxDialog extends StatefulWidget {
  const LootboxDialog({Key? key}) : super(key: key);

  @override
  State<LootboxDialog> createState() => _LootboxDialogState();
}

class _LootboxDialogState extends State<LootboxDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _revealController;
  late AnimationController _shinyController;
  late Animation<double> _shakeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shinyAnim;

  bool _opened = false;
  TokenTier? _wonTier;
  Landmark? _wonLandmark;

  @override
  void initState() {
    super.initState();

    _shinyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shinyAnim = Tween<double>(begin: 0, end: 1).animate(_shinyController);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
        parent: _revealController, curve: Curves.elasticOut)
        as Animation<double>;
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _revealController.dispose();
    _shinyController.dispose();
    super.dispose();
  }

  Future<void> _openBox() async {
    if (_opened) return;
    final lootboxService = context.read<LootboxService>();
    if (!lootboxService.canOpenAny) return;

    // Shake animation
    await _shakeController.forward();
    _shakeController.reset();
    await _shakeController.forward();
    _shakeController.reset();

    // Open lootbox
    final tier = await lootboxService.openLootbox();

    // Pick random landmark
    final landmarkService = context.read<LandmarkService>();
    final all = landmarkService.landmarks;
    final random = Random();
    final landmark = all[random.nextInt(all.length)];

    // Do NOT add token yet — wait for user choice (keep vs. quick-sell)
    setState(() {
      _opened = true;
      _wonTier = tier;
      _wonLandmark = landmark;
    });

    await _revealController.forward();
  }

  void _keepToken() {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte melde dich an, um Tokens zu behalten. Gehe zum Profil-Tab.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final collectionService = context.read<CollectionService>();
    final landmark = _wonLandmark!;
    final tier = _wonTier!;
    collectionService.collectTokenAllowDuplicate(
      landmark.id,
      landmark.name,
      landmark.category,
      tier.pointValue,
      landmark.relatedSetIds,
      tier: tier,
    );
    Navigator.pop(context);
  }

  void _quickSell() {
    final collectionService = context.read<CollectionService>();
    final coins = _wonTier!.pointValue * 2;
    collectionService.addPoints(coins);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick-Sell! +$coins Münzen 🪙 (kein Token)'),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _tierColor(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return Colors.orange[700]!;
      case TokenTier.silver:
        return Colors.grey[300]!;
      case TokenTier.gold:
        return Colors.amber[500]!;
      case TokenTier.platinum:
        return Colors.cyan[300]!;
    }
  }

  String _tierEmoji(TokenTier tier) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[900]!, Colors.grey[850]!],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _opened
                ? _tierColor(_wonTier!).withValues(alpha: 0.8)
                : Colors.amber[700]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _opened
                  ? _tierColor(_wonTier!).withValues(alpha: 0.4)
                  : Colors.amber.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: _opened ? _buildReveal() : _buildChest(),
      ),
    );
  }

  Widget _buildChest() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🎁 Tägliche Lootbox',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tippe auf die Box zum Öffnen!',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _shinyAnim,
          builder: (_, child) {
            return SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sparkle stars around the box
                  ..._buildSparkles(_shinyAnim.value),
                  child!,
                ],
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final offset = sin(_shakeAnim.value * pi * 8) * 12;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _openBox,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.amber[400]!, Colors.orange[800]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎁', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chanceBadge('🥉 Bronze', '69%', Colors.orange[700]!),
            const SizedBox(width: 6),
            _chanceBadge('🥈 Silber', '20%', Colors.grey[400]!),
            const SizedBox(width: 6),
            _chanceBadge('🥇 Gold', '10%', Colors.amber[500]!),
            const SizedBox(width: 6),
            _chanceBadge('💎 Platin', '1%', Colors.cyan[300]!),
          ],
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Schließen',
              style: TextStyle(color: Colors.grey[500])),
        ),
      ],
    );
  }

  Widget _buildReveal() {
    final tier = _wonTier!;
    final landmark = _wonLandmark!;
    final color = _tierColor(tier);
    final landmarkService = context.read<LandmarkService>();
    final imagePath =
        landmarkService.getImageUrlForTier(landmark.id, tier);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_tierEmoji(tier)} ${tier.displayName}-Token!',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Du hast gewonnen:',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            landmark.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color),
            ),
            child: Text(
              '${_tierEmoji(tier)} ${tier.displayName} · +${tier.pointValue} Coins',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Behalten',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _keepToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.sell_outlined),
                  label: Text('+${tier.pointValue * 2} 🪙',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _quickSell,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(double t) {
    const sparkleData = [
      // [angle_fraction, distance, size, phase_offset]
      [0.0, 65.0, 10.0, 0.0],
      [0.15, 58.0, 7.0, 0.3],
      [0.28, 70.0, 9.0, 0.6],
      [0.42, 60.0, 6.0, 0.15],
      [0.57, 68.0, 10.0, 0.45],
      [0.71, 55.0, 7.0, 0.75],
      [0.85, 65.0, 8.0, 0.9],
    ];
    return sparkleData.map((d) {
      final angleFraction = d[0];
      final distance = d[1];
      final size = d[2];
      final phaseOffset = d[3];
      final angle = (angleFraction + t) * 2 * pi;
      final phase = ((t + phaseOffset) % 1.0);
      final opacity = (sin(phase * pi)).clamp(0.0, 1.0);
      final cx = 80.0 + distance * cos(angle);
      final cy = 80.0 + distance * sin(angle);
      return Positioned(
        left: cx - size / 2,
        top: cy - size / 2,
        child: Opacity(
          opacity: opacity,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: size,
              color: Colors.amber[300],
              shadows: [
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _chanceBadge(String label, String pct, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(pct,
            style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }
}
