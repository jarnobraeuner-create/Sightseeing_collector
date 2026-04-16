import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/landmark_service.dart';

class SetCard extends StatelessWidget {
  final CollectionSet set;

  const SetCard({
    Key? key,
    required this.set,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    set.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (set.completed)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              set.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: set.completionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      set.completed ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${set.completionPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${set.collectedTokenIds.length}/${set.requiredTokenIds.length} tokens',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Chip(
                  label: Text(
                    '${set.bonusPoints} bonus pts',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.amber[100],
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (!set.completed) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fehlende Tokens:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              _buildMissingTokens(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMissingTokens(BuildContext context) {
    final landmarkService = Provider.of<LandmarkService>(context, listen: false);
    
    // Finde fehlende Token IDs
    final missingTokenIds = set.requiredTokenIds
        .where((id) => !set.collectedTokenIds.contains(id))
        .toList();
    
    if (missingTokenIds.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Hole Landmark-Namen
    final missingLandmarks = missingTokenIds
        .map((id) {
          try {
            return landmarkService.landmarks.firstWhere((l) => l.id == id);
          } catch (e) {
            return null;
          }
        })
        .where((l) => l != null)
        .toList();
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: missingLandmarks.map((landmark) {
        return Chip(
          avatar: Icon(
            Icons.location_on,
            size: 16,
            color: Colors.red[700],
          ),
          label: Text(
            landmark!.name,
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: Colors.grey[200],
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
