import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/index.dart';

class CollectRewardOverlay extends StatefulWidget {
  final String landmarkName;
  final String imageAssetPath;
  final TokenTier tier;

  const CollectRewardOverlay({
    Key? key,
    required this.landmarkName,
    required this.imageAssetPath,
    required this.tier,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String landmarkName,
    required String imageAssetPath,
    required TokenTier tier,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierLabel: 'collect_reward',
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Center(
              child: CollectRewardOverlay(
                landmarkName: landmarkName,
                imageAssetPath: imageAssetPath,
                tier: tier,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CollectRewardOverlay> createState() => _CollectRewardOverlayState();
}

class _CollectRewardOverlayState extends State<CollectRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _suspenseFade;
  late final Animation<double> _glowPulse;
  late final Animation<double> _tokenScale;
  late final Animation<double> _tokenFade;
  late final Animation<Offset> _tokenLift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _suspenseFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _glowPulse = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.72)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.95, curve: Curves.linear),
      ),
    );

    _tokenScale = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.82, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.9, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.9, curve: Curves.linear),
      ),
    );

    _tokenFade = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 75,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 1.0, curve: Curves.linear),
      ),
    );

    _tokenLift = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = _glowForTier(widget.tier);
    final textColor = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.12),
      glow,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _tokenFade.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _suspenseFade.value,
                child: Container(
                  width: 330,
                  height: 330,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glow.withValues(alpha: 0.58 * _glowPulse.value),
                        glow.withValues(alpha: 0.16 * _glowPulse.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.62, 1.0],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, _tokenLift.value.dy * 120),
                child: Transform.scale(
                  scale: _tokenScale.value,
                  child: Container(
                    width: 212,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.17),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.55 * _glowPulse.value),
                          blurRadius: 42,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset(
                              widget.imageAssetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[850],
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 60,
                                  color: glow,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.tier.displayName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.landmarkName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                child: Opacity(
                  opacity: math.max(0, _suspenseFade.value - 0.2),
                  child: Text(
                    'Belohnung erhalten',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _glowForTier(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return const Color(0xFFCD7F32);
      case TokenTier.silver:
        return const Color(0xFFC0C7D1);
      case TokenTier.gold:
        return const Color(0xFFFFC94D);
      case TokenTier.platinum:
        return const Color(0xFF86E8FF);
      case TokenTier.monumente:
        return const Color(0xFF6E65FF);
      case TokenTier.weltwunder:
        return const Color(0xFF43F4D1);
    }
  }
}
