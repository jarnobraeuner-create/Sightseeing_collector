import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';

class LandmarkCard extends StatefulWidget {
  final Landmark landmark;
  final VoidCallback onTap;

  const LandmarkCard({
    Key? key,
    required this.landmark,
    required this.onTap,
  }) : super(key: key);

  @override
  State<LandmarkCard> createState() => _LandmarkCardState();
}

class _LandmarkCardState extends State<LandmarkCard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache image für bessere Performance
    if (widget.landmark.imageUrl.isNotEmpty) {
      precacheImage(AssetImage(widget.landmark.imageUrl), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final collectionService = Provider.of<CollectionService>(context);
    
    final distance = locationService.currentPosition != null
        ? widget.landmark.getDistance(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          )
        : null;

    final isCollected = collectionService.hasCollectedToken(widget.landmark.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Landmark Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.landmark.imageUrl.isNotEmpty
                      ? Image.asset(
                          widget.landmark.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.location_on, size: 40);
                          },
                        )
                      : const Icon(Icons.location_on, size: 40),
                ),
              ),
              const SizedBox(width: 12),
              // Landmark Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.landmark.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (isCollected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.landmark.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance != null
                              ? '${(distance * 1000).toStringAsFixed(0)} m'
                              : 'Entfernung unbekannt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            '${widget.landmark.pointsReward} pts',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.amber[100],
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
