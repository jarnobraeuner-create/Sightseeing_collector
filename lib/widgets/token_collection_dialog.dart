import 'package:flutter/material.dart';
import '../models/index.dart';
import '../widgets/animated_token_card.dart';

class TokenCollectionDialog extends StatefulWidget {
  final String landmarkName;
  final String landmarkCategory;
  final TokenTier? collectedTier;
  final int points;

  const TokenCollectionDialog({
    Key? key,
    required this.landmarkName,
    required this.landmarkCategory,
    required this.collectedTier,
    required this.points,
  }) : super(key: key);

  @override
  State<TokenCollectionDialog> createState() => _TokenCollectionDialogState();
}

class _TokenCollectionDialogState extends State<TokenCollectionDialog>
    with SingleTickerProviderStateMixin {
  bool _isAnimating = false;
  late AnimationController _dismissController;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Starte Animation nach Dialog-Aufbau
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isAnimating = true);
      }
    });
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _dismissController.forward();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    Text(
                      'Token Collected!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.amber[200],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.landmarkName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Animated Token Card - Lootbox Reveal Effect
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AnimatedTokenCard(
                    revealedTier: _isAnimating ? widget.collectedTier : null,
                    isAnimating: _isAnimating,
                    onAnimationComplete: () {
                      // Animation fertig - warte kurz bevor Schließen angeboten wird
                      if (mounted) {
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) setState(() => _isAnimating = false);
                        });
                      }
                    },
                  ),
                ),
              ),

              // Footer mit Punkten und Close Button
              if (!_isAnimating)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Bonus Info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.2),
                              Colors.orange.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.points} Punkte',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.amber[200],
                                    fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _closeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[600],
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            'Weiter sammeln!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(height: 48), // Placeholder während Animation
                ),
            ],
          ),
        ),
      ),
    );
  }
}
