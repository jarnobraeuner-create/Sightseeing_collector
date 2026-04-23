import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class TokenCard extends StatelessWidget {
  final Token token;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TokenCard({
    Key? key,
    required this.token,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkService>(
      builder: (context, landmarkService, child) {
        final landmark = landmarkService.getLandmarkById(token.landmarkId);
        
        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Card(
          elevation: 2,
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: landmark != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          child: Image.asset(
                            landmarkService.getImageUrlForTier(token.landmarkId, token.tier),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.emoji_events,
                                size: 48,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 48,
                            color: Colors.amber[700],
                          ),
                        ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token.landmarkName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              token.tier.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: _getTierColor(token.tier),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${token.points} pts',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          token.category == 'sightseeing'
                              ? Icons.camera_alt
                              : Icons.flight,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
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
      case TokenTier.monumente:
        return Colors.deepPurpleAccent;
    }
  }
}
