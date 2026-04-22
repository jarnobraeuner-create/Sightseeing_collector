import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/daily_reward_service.dart';
import '../services/collection_service.dart';
import '../services/lootbox_service.dart';
import '../services/cooldown_service.dart';

class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({Key? key}) : super(key: key);

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  bool _claiming = false;
  bool _claimed = false;
  String? _resultMessage;
  TokenTier? _wonTier;

  Color _tierColor(TokenTier? tier) {
    if (tier == null) return Colors.amber;
    switch (tier) {
      case TokenTier.bronze:   return const Color(0xFFCD7F32);
      case TokenTier.silver:   return const Color(0xFFC0C0C0);
      case TokenTier.gold:     return const Color(0xFFFFD700);
      case TokenTier.platinum: return const Color(0xFFE5E4E2);
      case TokenTier.monumente: return const Color(0xFF6F2CFF);
    }
  }

  String _tierName(TokenTier tier) {
    switch (tier) {
      case TokenTier.bronze:   return 'Bronze';
      case TokenTier.silver:   return 'Silber';
      case TokenTier.gold:     return 'Gold';
      case TokenTier.platinum: return 'Platin';
      case TokenTier.monumente: return 'Monumente';
    }
  }

  Future<void> _claim(BuildContext context) async {
    if (_claiming || _claimed) return;
    setState(() => _claiming = true);

    final rewardService  = context.read<DailyRewardService>();
    final collection     = context.read<CollectionService>();
    final lootbox        = context.read<LootboxService>();
    final cooldown       = context.read<CooldownService>();
    final reward         = rewardService.todaysReward;

    try {
      switch (reward.type) {
        case DailyRewardType.lootbox:
          // Use openLootbox only if cooldown allows, otherwise skip cooldown tracking
          late TokenTier tier;
          if (lootbox.canOpen) {
            tier = await lootbox.openLootbox();
          } else {
            // Reward regardless of daily lootbox cooldown
            tier = _rollLootbox();
          }
          _wonTier = tier;
          _resultMessage = 'Du hast einen ${_tierName(tier)}-Token gewonnen!';
          break;

        case DailyRewardType.coins100:
          collection.addPoints(100);
          _resultMessage = '+100 Coins erhalten!';
          break;

        case DailyRewardType.coins200:
          collection.addPoints(200);
          _resultMessage = '+200 Coins erhalten!';
          break;

        case DailyRewardType.coins300:
          collection.addPoints(300);
          _resultMessage = '+300 Coins erhalten!';
          break;

        case DailyRewardType.cooldownSkip:
          await cooldown.resetAllCooldowns();
          _resultMessage = 'Alle Cooldowns wurden zurückgesetzt!';
          break;

        case DailyRewardType.lootboxSilverPlus:
          final tier = lootbox.openGuaranteedSilverLootbox();
          _wonTier = tier;
          _resultMessage = 'Du hast einen ${_tierName(tier)}-Token gewonnen!';
          break;
      }

      await rewardService.markClaimed();
      setState(() {
        _claiming = false;
        _claimed = true;
      });
    } catch (e) {
      setState(() => _claiming = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  TokenTier _rollLootbox() {
    final rand = (100 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
    if (rand < 1)  return TokenTier.platinum;
    if (rand < 11) return TokenTier.gold;
    if (rand < 31) return TokenTier.silver;
    return TokenTier.bronze;
  }

  @override
  Widget build(BuildContext context) {
    final rewardService = context.watch<DailyRewardService>();
    final currentDay = rewardService.currentDay;
    final todaysReward = rewardService.todaysReward;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              '🎉 Tägliche Belohnung',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Komm täglich für deine Belohnung!',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 7 streak-day reward cards
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
              children: [
                ...DailyRewardService.rewards.take(4).map((r) => _RewardCard(
                  reward: r,
                  isToday: r.day == currentDay,
                  isClaimed: r.day < currentDay ||
                      (r.day == currentDay && rewardService.claimedToday),
                )),
                // empty spacer for centering last 3
                const SizedBox.shrink(),
                ...DailyRewardService.rewards.skip(4).map((r) => _RewardCard(
                  reward: r,
                  isToday: r.day == currentDay,
                  isClaimed: r.day < currentDay ||
                      (r.day == currentDay && rewardService.claimedToday),
                )),
              ],
            ),

            const SizedBox(height: 16),

            // Result message after claim
            if (_claimed && _resultMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _wonTier != null
                      ? _tierColor(_wonTier!).withOpacity(0.15)
                      : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _wonTier != null ? _tierColor(_wonTier!) : Colors.amber,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _wonTier != null ? _tierColor(_wonTier!) : Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            if (!_claimed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _claiming ? null : () => _claim(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _claiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          '${todaysReward.emoji}  ${todaysReward.description} abholen',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<DailyRewardService>().dismissPopup();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Später',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Super! Schließen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final DailyReward reward;
  final bool isToday;
  final bool isClaimed;

  const _RewardCard({
    required this.reward,
    required this.isToday,
    required this.isClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isToday ? Colors.amber : Colors.white12;
    final bgColor = isToday
        ? Colors.amber.withOpacity(0.12)
        : Colors.white.withOpacity(0.04);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Stack(
        children: [
          // Claimed checkmark overlay
          if (isClaimed)
            Positioned(
              top: 2,
              right: 4,
              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reward.label,
                  style: TextStyle(
                    color: isToday ? Colors.amber : Colors.grey[500],
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reward.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  reward.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.grey[600],
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
