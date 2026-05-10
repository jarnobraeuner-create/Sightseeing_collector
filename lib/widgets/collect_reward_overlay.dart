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

  static Future<bool> show(
    BuildContext context, {
    required String landmarkName,
    required String imageAssetPath,
    required TokenTier tier,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierLabel: 'collect_reward',
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, __) {
        return PopScope(
          canPop: false,
          child: Material(
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
          ),
        );
      },
    ).then((value) => value ?? false);
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
  late final Animation<Offset> _tokenLift;
  late final Animation<double> _buttonFade;

  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _suspenseFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _glowPulse = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.84)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 58,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 1.0, curve: Curves.linear),
      ),
    );

    _tokenScale = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.76, end: 0.9)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 24,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.9, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 26,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.9, curve: Curves.linear),
      ),
    );

    _tokenLift = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
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
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _suspenseFade.value,
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glow.withValues(alpha: 0.64 * _glowPulse.value),
                      glow.withValues(alpha: 0.2 * _glowPulse.value),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.62, 1.0],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: math.max(0, _suspenseFade.value - 0.15),
                      child: Text(
                        'Belohnung erhalten',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Transform.translate(
                      offset: Offset(0, _tokenLift.value.dy * 130),
                      child: Transform.scale(
                        scale: _tokenScale.value,
                        child: Container(
                          width: 292,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glow.withValues(alpha: 0.6 * _glowPulse.value),
                                blurRadius: 54,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
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
                                        size: 72,
                                        color: glow,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                widget.tier.displayName,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.85,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.landmarkName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _buttonFade.value,
                      child: SizedBox(
                        width: 252,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF29C76F), Color(0xFF1B974F)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glow.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isConfirming
                                ? null
                                : () {
                                    setState(() => _isConfirming = true);
                                    Navigator.of(context).pop(true);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            child: const Text('hinzufügen'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
