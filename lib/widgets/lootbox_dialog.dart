import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';
import '../services/landmark_service.dart';
import '../services/lootbox_service.dart';
import 'app_lottie.dart';

class LootboxDialog extends StatefulWidget {
  final TokenTier? forcedTier;
  final String? forcedLandmarkId;
  final bool displayOnlyReward;
  final String? customTitle;

  const LootboxDialog({
    Key? key,
    this.forcedTier,
    this.forcedLandmarkId,
    this.displayOnlyReward = false,
    this.customTitle,
  }) : super(key: key);

  @override
  State<LootboxDialog> createState() => _LootboxDialogState();
}

class _LootboxDialogState extends State<LootboxDialog>
    with TickerProviderStateMixin {
  static const int _requiredMonumentTaps = 4;

  late AnimationController _shakeController;
  late AnimationController _revealController;
  late AnimationController _shinyController;
  late AnimationController _tapPulseController;
  late AnimationController _openingTokenController;
  late Animation<double> _shakeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shinyAnim;
  late Animation<double> _tapPulseAnim;
  late Animation<double> _openingTokenLiftAnim;
  late Animation<double> _openingTokenGlowAnim;

  bool _opened = false;
  bool _isOpening = false;
  int _monumentTapCount = 0;
  double _shakeStrength = 0.3;
  TokenTier? _wonTier;
  Landmark? _wonLandmark;

  bool get _isForcedRewardMode =>
      widget.forcedTier != null && widget.forcedLandmarkId != null;
  Landmark? _pendingMonumentLandmark;

  Landmark _pickMonumentLandmark(List<Landmark> all) {
    final monumentCandidates = all
        .where((l) => const {'1', '2', '4'}.contains(l.id))
        .toList();
    final random = Random();
    final source = monumentCandidates.isNotEmpty ? monumentCandidates : all;
    return source[random.nextInt(source.length)];
  }

  @override
  void initState() {
    super.initState();

    _shinyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shinyAnim = Tween<double>(begin: 0, end: 1).animate(_shinyController);
    _tapPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
    );
    _tapPulseAnim = CurvedAnimation(
      parent: _tapPulseController,
      curve: Curves.easeOut,
    );
    _openingTokenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _openingTokenLiftAnim = CurvedAnimation(
      parent: _openingTokenController,
      curve: Curves.easeInOutCubic,
    );
    _openingTokenGlowAnim = CurvedAnimation(
      parent: _openingTokenController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
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
    _tapPulseController.dispose();
    _openingTokenController.dispose();
    super.dispose();
  }

  Future<void> _openBox() async {
    if (_opened || _isOpening) return;
    final lootboxService = context.read<LootboxService>();
    final canOpen = _isForcedRewardMode || lootboxService.canOpenAny;
    if (!canOpen) return;

    await _runShakeSequence(const [
      Duration(milliseconds: 600),
      Duration(milliseconds: 600),
    ]);

    // Open lootbox / resolve forced reward
    final landmarkService = context.read<LandmarkService>();
    final all = landmarkService.landmarks;
    late final TokenTier tier;
    late final Landmark landmark;
    if (_isForcedRewardMode) {
      tier = widget.forcedTier!;
      final forcedId = widget.forcedLandmarkId!;
      final fallback = all.isNotEmpty ? all.first : null;
      final found = all.where((l) => l.id == forcedId);
      landmark = found.isNotEmpty ? found.first : (fallback ?? all.first);
    } else {
      tier = await lootboxService.openLootbox();
      final random = Random();
      landmark = all[random.nextInt(all.length)];
    }

    // Do NOT add token yet — wait for user choice (keep vs. quick-sell)
    if (!mounted) return;
    setState(() {
      _opened = true;
      _isOpening = false;
      _wonTier = tier;
      _wonLandmark = landmark;
    });

    await _revealController.forward();
  }

  Future<void> _runShakeSequence(List<Duration> durations) async {
    for (final duration in durations) {
      _shakeController.duration = duration;
      await _shakeController.forward(from: 0);
      _shakeController.reset();
    }
  }

  Future<void> _keepToken() async {
    if (widget.displayOnlyReward) {
      Navigator.pop(context);
      return;
    }

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

    if (tier == TokenTier.monumente && context.mounted) {
      await _showCollectionAddedAnimation();
    }
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showCollectionAddedAnimation() async {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.tealAccent, width: 2),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLottie(
                type: AppLottieType.monumentCollect,
                size: 140,
              ),
              SizedBox(height: 10),
              Text(
                'Monumente-Token zur Sammlung hinzugefügt!',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickSell() {
    if (widget.displayOnlyReward) {
      Navigator.pop(context);
      return;
    }

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
      case TokenTier.monumente:
        return Colors.deepPurpleAccent;
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
      case TokenTier.monumente:
        return '🏛️';
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
    const isMonument = false;
    final tapsRemaining = (_requiredMonumentTaps - _monumentTapCount).clamp(0, _requiredMonumentTaps);
    final chestGlowColor = isMonument ? Colors.deepPurpleAccent : Colors.amber;
    final chestScale = isMonument ? 1 + (_monumentTapCount * 0.04) : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.customTitle ?? '🎁 Tägliche Lootbox',
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isMonument
              ? (_isOpening
                  ? 'Die Box bricht auf... gleich erscheint dein Monumente-Token.'
                  : tapsRemaining > 0
                      ? 'Gib der Box $tapsRemaining weitere ${tapsRemaining == 1 ? 'Energie-Ladung' : 'Energie-Ladungen'}.'
                      : 'Die Box ist geladen. Noch ein Moment Spannung...')
              : 'Tippe auf die Box zum Öffnen!',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: Listenable.merge([_shinyController, _tapPulseController]),
          builder: (_, __) {
            final tapPulse = isMonument ? _tapPulseAnim.value : 0.0;
            final pulseScaleStrength = isMonument
                ? (0.06 + (_monumentTapCount * 0.02)).clamp(0.06, 0.16)
                : 0.0;
            final sparkleCenter = isMonument ? 110.0 : 80.0;
            return SizedBox(
              width: isMonument ? 220 : 160,
              height: isMonument ? 220 : 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sparkle stars around the box
                  ..._buildOrbitSparkles(
                    _shinyAnim.value,
                    color: isMonument ? Colors.deepPurpleAccent : Colors.amber[300],
                    center: sparkleCenter,
                  ),
                  if (isMonument) ..._buildTapRipples(tapPulse, Colors.deepPurpleAccent),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _shakeController,
                      _tapPulseController,
                    ]),
                    builder: (_, child) {
                      final reactiveTapPulse =
                          isMonument ? _tapPulseAnim.value : 0.0;
                      final offset =
                          sin(_shakeAnim.value * pi * 8) * 5 * _shakeStrength;
                      final tilt =
                          sin(_shakeAnim.value * pi * 6) * 0.012 * _shakeStrength;
                      return Transform.rotate(
                        angle: tilt,
                        child: Transform.translate(
                          offset: Offset(offset, 0),
                          child: Transform.scale(
                            scale: 1 + (reactiveTapPulse * pulseScaleStrength),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: _isOpening ? null : _openBox,
                      child: Transform.scale(
                        scale: chestScale,
                        child: Container(
                          width: isMonument ? 132 : 120,
                          height: isMonument ? 132 : 120,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: isMonument
                                  ? [
                                      Color.lerp(
                                            Colors.purpleAccent[100],
                                            Colors.white,
                                            tapPulse,
                                          ) ??
                                          Colors.purpleAccent,
                                      Color.lerp(
                                            Colors.deepPurple[700],
                                            Colors.indigo[900],
                                            tapPulse * 0.5,
                                          ) ??
                                          Colors.deepPurple,
                                    ]
                                  : [Colors.amber[400]!, Colors.orange[800]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: isMonument
                                ? Border.all(
                                    color: Colors.white.withValues(
                                      alpha: 0.4 + (tapPulse * 0.35),
                                    ),
                                    width: 2 + tapPulse,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: chestGlowColor.withValues(
                                  alpha: isMonument
                                      ? ((0.35 + (_monumentTapCount * 0.1)) +
                                              (tapPulse * 0.35))
                                          .clamp(0.35, 0.95)
                                      : 0.5,
                                ),
                                blurRadius: isMonument
                                    ? 28 +
                                        (_monumentTapCount * 8) +
                                        (tapPulse * 26)
                                    : 20,
                                spreadRadius: isMonument
                                    ? 6 +
                                        _monumentTapCount.toDouble() +
                                        (tapPulse * 7)
                                    : 4,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isMonument)
                                Container(
                                  width: 96 + (tapPulse * 28),
                                  height: 96 + (tapPulse * 28),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(
                                          alpha: 0.14 +
                                              (tapPulse * 0.2),
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              if (isMonument)
                                Text(
                                  _isOpening ? '' : '🏛️',
                                  style: TextStyle(
                                    fontSize: 66 + (tapPulse * 4),
                                  ),
                                )
                              else
                                const Text(
                                  '🎁',
                                  style: TextStyle(fontSize: 64),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isMonument && _isOpening)
                    _buildOpeningTokenSequence(),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
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
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _shinyAnim,
            builder: (_, __) {
              final pulse = 1 + sin(_shinyAnim.value * 2 * pi) * 0.05;
              return ScaleTransition(
                scale: _scaleAnim,
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _shinyAnim.value * 2 * pi,
                        child: Stack(
                          alignment: Alignment.center,
                          children: _buildRevealRays(color),
                        ),
                      ),
                      ..._buildRevealSparkles(_shinyAnim.value, color),
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withValues(alpha: 0.38),
                              color.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.42),
                              blurRadius: 45,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 172,
                          height: 172,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.75),
                                blurRadius: 35,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                  label: Text(
                    widget.displayOnlyReward ? 'Weiter' : 'Behalten',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
              if (!widget.displayOnlyReward) ...[
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningTokenSequence() {
    final landmarkService = context.read<LandmarkService>();
    final previewLandmarkId = _pendingMonumentLandmark?.id ?? '2';
    final tokenImagePath = landmarkService.getImageUrlForTier(
      previewLandmarkId,
      TokenTier.monumente,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_openingTokenController, _shinyController]),
        builder: (_, __) {
          final lift = _openingTokenLiftAnim.value;
          final glow = _openingTokenGlowAnim.value;
          final angle = lift * pi * 6;
          final orbitRadius = (1 - lift) * 44;
          final riseY = (1 - lift) * 62;
          final orbitX = cos(angle) * orbitRadius;
          final orbitY = sin(angle) * orbitRadius * 0.58;
          final tokenSize = 18 + (lift * 92) + (glow * 10);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (0.15 + (glow * 0.85)).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: _shinyAnim.value * 2 * pi,
                  child: Stack(
                    alignment: Alignment.center,
                    children: _buildRevealRays(Colors.deepPurpleAccent),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(orbitX, riseY + orbitY),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08 + (glow * 0.2)),
                        Colors.deepPurpleAccent.withValues(alpha: 0.1 + (glow * 0.32)),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.2 + (glow * 0.62)),
                        blurRadius: 28 + (glow * 34),
                        spreadRadius: 2 + (glow * 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: tokenSize,
                    height: tokenSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15 + (glow * 0.35)),
                          blurRadius: 20 + (glow * 18),
                          spreadRadius: 1 + (glow * 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        tokenImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOrbitSparkles(double t, {Color? color, double center = 80.0}) {
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
      final cx = center + distance * cos(angle);
      final cy = center + distance * sin(angle);
      return Positioned(
        left: cx - size / 2,
        top: cy - size / 2,
        child: Opacity(
          opacity: opacity,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: size,
              color: color ?? Colors.amber[300],
              shadows: [
                Shadow(
                  color: (color ?? Colors.amber).withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTapRipples(double pulse, Color color) {
    if (pulse <= 0) return const [];

    final rippleConfigs = [
      (84.0, 0.22),
      (112.0, 0.14),
    ];

    return rippleConfigs.map((config) {
      final baseSize = config.$1;
      final alpha = config.$2;
      final size = baseSize + (pulse * 64);
      return IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: (1 - pulse) * alpha),
              width: 2 + ((1 - pulse) * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: (1 - pulse) * 0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildRevealRays(Color color) {
    return List<Widget>.generate(10, (index) {
      final angle = (index / 10) * 2 * pi;
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: 10,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.34),
                color.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildRevealSparkles(double t, Color color) {
    const sparkleData = [
      [0.0, 82.0, 16.0, 0.0],
      [0.18, 95.0, 11.0, 0.25],
      [0.34, 88.0, 13.0, 0.55],
      [0.52, 98.0, 10.0, 0.8],
      [0.73, 84.0, 12.0, 0.4],
      [0.9, 92.0, 14.0, 0.65],
    ];

    return sparkleData.map((data) {
      final angle = (data[0] + t) * 2 * pi;
      final distance = data[1];
      final size = data[2];
      final phase = (t + data[3]) % 1.0;
      final opacity = (0.35 + sin(phase * 2 * pi) * 0.35).clamp(0.15, 0.8);
      final centerX = 115 + distance * cos(angle);
      final centerY = 115 + distance * sin(angle);

      return Positioned(
        left: centerX - size / 2,
        top: centerY - size / 2,
        child: Opacity(
          opacity: opacity,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: size,
              color: color.withValues(alpha: 0.95),
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

}
