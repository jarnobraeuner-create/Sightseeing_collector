import 'dart:math' as math;
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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Consumer<EventService>(
        builder: (context, eventService, _) {
          final events = EventService.allEvents;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E0A35), Color(0xFF0D0D1F)],
              ),
              border: Border.all(
                color: const Color(0xFF5E2A8E).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogHeader(onClose: () => Navigator.pop(context)),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 500),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _EventCard(event: events[i], eventService: eventService),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A1A7E),
            const Color(0xFF2A0E5E),
            const Color(0xFF1A1A3E).withValues(alpha: 0.8),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0x445E2A8E), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aktive Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Sammle Tokens & verdiene Belohnungen',
                style: TextStyle(
                  color: Colors.purple[200],
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event Card ────────────────────────────────────────────────────────────────

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

    final remaining = event.endDate.difference(DateTime.now());
    final daysLeft = remaining.inDays;
    final hoursLeft = remaining.inHours % 24;

    final Color accentColor;
    final Color cardTop;
    final String statusLabel;
    final Color statusColor;

    if (claimed) {
      accentColor = Colors.green;
      cardTop = const Color(0xFF0A2010);
      statusLabel = '✅ Abgeholt';
      statusColor = Colors.green;
    } else if (expired) {
      accentColor = Colors.grey;
      cardTop = const Color(0xFF151515);
      statusLabel = 'Abgelaufen';
      statusColor = Colors.grey;
    } else if (completed) {
      accentColor = Colors.amber;
      cardTop = const Color(0xFF2A1800);
      statusLabel = '🎁 Bereit!';
      statusColor = Colors.amber;
    } else {
      accentColor = const Color(0xFF9B59B6);
      cardTop = const Color(0xFF1A0A30);
      statusLabel = 'Aktiv';
      statusColor = const Color(0xFF9B59B6);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardTop, const Color(0xFF111128)],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: completed && !claimed ? 0.8 : 0.35),
          width: completed && !claimed ? 1.5 : 1.0,
        ),
        boxShadow: completed && !claimed
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text('⛪', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.06),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // Progress label + bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fortschritt',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '$count / $required',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: completed
                                    ? [Colors.amber[300]!, Colors.orange[600]!]
                                    : [
                                        const Color(0xFF9B59B6),
                                        const Color(0xFF6C3483),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Timer + reward pill
                Row(
                  children: [
                    Icon(
                      expired
                          ? Icons.timer_off_outlined
                          : Icons.timer_outlined,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      expired
                          ? 'Abgelaufen'
                          : (daysLeft > 0
                              ? 'Noch $daysLeft Tag${daysLeft == 1 ? '' : 'e'} $hoursLeft h'
                              : 'Endet heute in ${remaining.inHours} h'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.2),
                            Colors.orange.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆 ', style: TextStyle(fontSize: 11)),
                          Text(
                            '${event.rewardLootboxes}× Lootbox  +  ${event.rewardCoins} 🪙',
                            style: TextStyle(
                              color: Colors.amber[300],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (completed && !claimed && !expired) ...[
                  const SizedBox(height: 12),
                  _ClaimButton(onClaim: () => _claimReward(context)),
                ],
              ],
            ),
          ),
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
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belohnung erhalten',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Event abgeschlossen! +${event.rewardCoins} Coins und ${event.rewardLootboxes} Lootboxen erhalten.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      );
    }
  }
}

// ── Claim Button (shimmer animation) ─────────────────────────────────────────

class _ClaimButton extends StatefulWidget {
  final VoidCallback onClaim;
  const _ClaimButton({required this.onClaim});

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return GestureDetector(
          onTap: widget.onClaim,
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFFE67E00),
                  Color(0xFFFFD700),
                  Color(0xFFE67E00),
                ],
                stops: [
                  0.0,
                  (_shimmer.value * 1.4 - 0.2).clamp(0.0, 1.0),
                  1.0,
                ],
                transform: GradientRotation(_shimmer.value * math.pi * 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Belohnung abholen!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
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
}
