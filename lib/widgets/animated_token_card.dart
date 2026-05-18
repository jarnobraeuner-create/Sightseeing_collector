import 'package:flutter/material.dart';

import '../models/index.dart';

class AnimatedTokenCard extends StatefulWidget {
  final TokenTier? revealedTier;
  final bool isAnimating;
  final VoidCallback? onAnimationComplete;

  const AnimatedTokenCard({
    Key? key,
    this.revealedTier,
    required this.isAnimating,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<AnimatedTokenCard> createState() => _AnimatedTokenCardState();
}

class _AnimatedTokenCardState extends State<AnimatedTokenCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Rotation: 3x komplett drehen (für Spannung)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Scale: Pulse-Effekt während Rotation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 0.97),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.12),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Reveal: Card "öffnet sich" zu 50% der Animation
    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedTokenCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    await _controller.forward();

    // Animation komplett
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTierColor(TokenTier? tier) {
    switch (tier) {
      case TokenTier.bronze:
        return const Color(0xFFCD7F32);
      case TokenTier.silver:
        return const Color(0xFFC0C0C0);
      case TokenTier.gold:
        return const Color(0xFFFFD700);
      case TokenTier.platinum:
        return const Color(0xFFE5E4E2);
      case TokenTier.monumente:
        return Colors.deepPurple;
      case TokenTier.weltwunder:
        return const Color(0xFF00E5FF);
      default:
        return Colors.grey;
    }
  }

  String _getTierName(TokenTier? tier) {
    return tier?.displayName ?? 'Token';
  }

  int _getTierPoints(TokenTier? tier) {
    switch (tier) {
      case TokenTier.bronze:
        return 10;
      case TokenTier.silver:
        return 25;
      case TokenTier.gold:
        return 50;
      case TokenTier.platinum:
        return 100;
      case TokenTier.monumente:
        return 0;
      case TokenTier.weltwunder:
        return 500;
      default:
        return 0;
    }
  }

  String _getTokenEmoji(TokenTier? tier) {
    switch (tier) {
      case TokenTier.bronze:
        return '🥉';
      case TokenTier.silver:
        return '🥈';
      case TokenTier.gold:
        return '🥇';
      case TokenTier.platinum:
        return '👑';
      case TokenTier.monumente:
        return '🏛️';
      case TokenTier.weltwunder:
        return '🌍';
      default:
        return '💎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Token Card
          AnimatedBuilder(
            animation: Listenable.merge([
              _rotationAnimation,
              _scaleAnimation,
              _revealAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Mystery Token (Default)
                      Opacity(
                        opacity: 1.0 - _revealAnimation.value,
                        child: _buildMysteryToken(),
                      ),

                      // Revealed Token
                      Opacity(
                        opacity: _revealAnimation.value,
                        child: _buildRevealedToken(),
                      ),
                    ],
                  ),
                ),
              );
              },
            ),

          // Info Text (nach Animation)
          if (!widget.isAnimating) ...[
            const SizedBox(height: 24),
            Text(
              _getTierName(widget.revealedTier),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _getTierColor(widget.revealedTier),
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_getTierPoints(widget.revealedTier)} Punkte',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.amber[200],
                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMysteryToken() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[600]!,
            Colors.grey[400]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Innerer Ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          // Mystery Icon
          Text(
            '?',
            style: TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedToken() {
    final color = _getTierColor(widget.revealedTier);

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Innerer Ring
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
          // Tier Emoji
          Text(
            _getTokenEmoji(widget.revealedTier),
            style: const TextStyle(fontSize: 60),
          ),
        ],
      ),
    );
  }
}
