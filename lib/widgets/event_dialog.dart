import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/event_service.dart';
import '../services/collection_service.dart';
import '../services/lootbox_service.dart';

/// Zeigt alle aktiven Events als Popup-Dialog.
class EventDialog extends StatelessWidget {
  const EventDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Consumer<EventService>(
        builder: (context, eventService, _) {
          final events = EventService.allEvents;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A1A6E), Color(0xFF2A1A5E)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Aktive Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Event list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _EventCard(event: events[i], eventService: eventService),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final GameEvent event;
  final EventService eventService;

  const _EventCard({required this.event, required this.eventService});

  @override
  Widget build(BuildContext context) {
    final count = eventService.collectedCount(event.id);
    final required = event.requiredCount;
    final claimed = eventService.rewardClaimed(event.id);
    final expired = event.isExpired;
    final completed = count >= required;
    final progress = (count / required).clamp(0.0, 1.0);

    // Days remaining
    final remaining = event.endDate.difference(DateTime.now());
    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours % 24;

    Color cardBorderColor;
    if (expired || claimed) {
      cardBorderColor = Colors.grey[700]!;
    } else if (completed) {
      cardBorderColor = Colors.amber;
    } else {
      cardBorderColor = Colors.purple[400]!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252545),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: completed && !claimed
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Text('⛪', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (claimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text('✅ Abgeholt',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                )
              else if (expired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Text('Abgelaufen',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[400]!),
                  ),
                  child: const Text('Aktiv',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            event.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completed ? Colors.amber : Colors.purple[400]!,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$count / $required',
                style: TextStyle(
                  color: completed ? Colors.amber : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time remaining + reward
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                expired
                    ? 'Abgelaufen'
                    : (daysLeft > 0
                        ? 'Noch $daysLeft Tag${daysLeft == 1 ? '' : 'e'} $hoursLeft h'
                        : 'Endet heute in ${remaining.inHours} h'),
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              const Spacer(),
              const Text('🏆 ', style: TextStyle(fontSize: 12)),
              Text(
                '${event.rewardLootboxes}× Lootbox + ${event.rewardCoins} 🪙',
                style: TextStyle(color: Colors.amber[300], fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Claim button
          if (completed && !claimed && !expired) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Belohnung abholen!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                ),
                onPressed: () => _claimReward(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _claimReward(BuildContext context) async {
    final eventSvc = Provider.of<EventService>(context, listen: false);
    final collection = Provider.of<CollectionService>(context, listen: false);
    final lootbox = Provider.of<LootboxService>(context, listen: false);

    await eventSvc.claimReward(event.id);
    collection.addPoints(event.rewardCoins);
    await lootbox.addExtraLootboxes(event.rewardLootboxes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Event abgeschlossen! +${event.rewardCoins} Coins + ${event.rewardLootboxes} Lootboxen!',
          ),
          backgroundColor: Colors.amber[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
