import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/collection_service.dart';
import '../services/landmark_service.dart';

class TokenUpgradeScreen extends StatefulWidget {
  const TokenUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<TokenUpgradeScreen> createState() => _TokenUpgradeScreenState();
}

class _TokenUpgradeScreenState extends State<TokenUpgradeScreen> {
  Token? _selectedTokenToUpgrade;
  final List<Token> _selectedTokensToTrade = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Token Upgrades',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_selectedTokenToUpgrade != null || _selectedTokensToTrade.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Auswahl zurücksetzen',
              onPressed: () {
                setState(() {
                  _selectedTokenToUpgrade = null;
                  _selectedTokensToTrade.clear();
                });
              },
            ),
        ],
      ),
      body: Consumer2<CollectionService, LandmarkService>(
        builder: (context, collectionService, landmarkService, child) {
          return Column(
            children: [
              // Oben: Ausgewählter Token zum Verbessern
              _buildUpgradePreview(landmarkService),
              
              const Divider(color: Colors.grey, height: 1),
              
              // Unten: Token-Auswahl
              Expanded(
                child: _buildTokenSelection(collectionService, landmarkService),
              ),
              
              // Upgrade Button
              if (_selectedTokenToUpgrade != null && _selectedTokensToTrade.length == 5)
                _buildUpgradeButton(collectionService, landmarkService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpgradePreview(LandmarkService landmarkService) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey[850],
      child: Column(
        children: [
          const Text(
            'Token zum Verbessern',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTokenToUpgrade != null)
            _buildSelectedTokenDisplay(landmarkService)
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _selectedTokenToUpgrade != null
                ? 'Wähle 5 ${_selectedTokenToUpgrade!.tier.displayName} Tokens zum Eintauschen'
                : 'Wähle einen Token zum Verbessern',
            style: TextStyle(
              color: _selectedTokenToUpgrade != null ? Colors.green[300] : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedTokensToTrade.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selectedTokensToTrade.length}/5 Tokens ausgewählt',
                style: TextStyle(
                  color: Colors.orange[300],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedTokenDisplay(LandmarkService landmarkService) {
    final token = _selectedTokenToUpgrade!;
    final landmark = landmarkService.landmarks.firstWhere(
      (l) => l.id == token.landmarkId,
    );

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTierColor(token.tier),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getTierColor(token.tier).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              landmarkService.getImageUrlForTier(token.landmarkId, token.tier),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          landmark.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getTierColor(token.tier).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getTierColor(token.tier)),
          ),
          child: Text(
            token.tier.displayName,
            style: TextStyle(
              color: _getTierColor(token.tier),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Icon(Icons.arrow_downward, color: Colors.green, size: 32),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getTierColor(_getNextTier(token.tier)).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getTierColor(_getNextTier(token.tier))),
          ),
          child: Text(
            _getNextTier(token.tier).displayName,
            style: TextStyle(
              color: _getTierColor(_getNextTier(token.tier)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenSelection(
    CollectionService collectionService,
    LandmarkService landmarkService,
  ) {
    final tokens = collectionService.tokens;

    if (tokens.isEmpty) {
      return const Center(
        child: Text(
          'Keine Tokens gesammelt',
          style: TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }

    // Gruppiere Tokens nach Landmark und Tier
    final Map<String, List<Token>> groupedTokens = {};
    for (final token in tokens) {
      final key = '${token.landmarkId}_${token.tier.name}';
      groupedTokens.putIfAbsent(key, () => []);
      groupedTokens[key]!.add(token);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTokens.length,
      itemBuilder: (context, index) {
        final key = groupedTokens.keys.elementAt(index);
        final tokenList = groupedTokens[key]!;
        final firstToken = tokenList.first;
        final landmark = landmarkService.landmarks.firstWhere(
          (l) => l.id == firstToken.landmarkId,
        );

        // Filtere basierend auf Auswahlmodus
        if (_selectedTokenToUpgrade != null) {
          // Zeige nur Tokens mit gleichem Landmark und Tier
          if (firstToken.landmarkId != _selectedTokenToUpgrade!.landmarkId ||
              firstToken.tier != _selectedTokenToUpgrade!.tier) {
            return const SizedBox.shrink();
          }
        }

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getTierColor(firstToken.tier),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          landmarkService.getImageUrlForTier(firstToken.landmarkId, firstToken.tier),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            landmark.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(firstToken.tier).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              firstToken.tier.displayName,
                              style: TextStyle(
                                color: _getTierColor(firstToken.tier),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${tokenList.length}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tokenList.map((token) {
                    final isSelected = _selectedTokenToUpgrade?.id == token.id ||
                        _selectedTokensToTrade.any((t) => t.id == token.id);
                    final canSelect = _selectedTokenToUpgrade == null ||
                        (_selectedTokensToTrade.length < 5 &&
                            token.id != _selectedTokenToUpgrade!.id);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTokenToUpgrade?.id == token.id) {
                            // Deselektiere Haupttoken
                            _selectedTokenToUpgrade = null;
                            _selectedTokensToTrade.clear();
                          } else if (_selectedTokensToTrade.any((t) => t.id == token.id)) {
                            // Deselektiere Trade-Token
                            _selectedTokensToTrade.removeWhere((t) => t.id == token.id);
                          } else if (_selectedTokenToUpgrade == null) {
                            // Wähle als Haupttoken
                            _selectedTokenToUpgrade = token;
                          } else if (canSelect) {
                            // Füge zu Trade-Tokens hinzu
                            _selectedTokensToTrade.add(token);
                          }
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getTierColor(token.tier).withOpacity(0.3)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _getTierColor(token.tier)
                                : Colors.grey[700]!,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (isSelected)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _getTierColor(token.tier),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Center(
                              child: Text(
                                _getTierEmoji(token.tier),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpgradeButton(
    CollectionService collectionService,
    LandmarkService landmarkService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final fromTier = _selectedTokenToUpgrade!.tier;
              final toTier = _getNextTier(fromTier);
              
              collectionService.upgradeTokens(
                _selectedTokenToUpgrade!.landmarkId,
                fromTier,
                toTier,
              );
              
              final landmark = landmarkService.landmarks.firstWhere(
                (l) => l.id == _selectedTokenToUpgrade!.landmarkId,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${landmark.name} ${toTier.displayName} Token erstellt! 🎉',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              setState(() {
                _selectedTokenToUpgrade = null;
                _selectedTokensToTrade.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Token Upgraden',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

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

  TokenTier _getNextTier(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:
        return TokenTier.silver;
      case TokenTier.silver:
        return TokenTier.gold;
      case TokenTier.gold:
        return TokenTier.platinum;
      case TokenTier.platinum:
        return TokenTier.platinum; // Max tier
    }
  }
}
