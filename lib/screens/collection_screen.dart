import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import 'token_upgrade_screen.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({Key? key}) : super(key: key);

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Alle Tokens sammeln (Test)',
            onPressed: () {
              final cs = Provider.of<CollectionService>(context, listen: false);
              final ls = Provider.of<LandmarkService>(context, listen: false);
              cs.collectAllTokensForTesting(ls.landmarks);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔬 Alle Tokens gesammelt!'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Reset Collection (Test)',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Collection?'),
                  content: const Text('Alle gesammelten Tokens werden gelöscht. Dies kann nicht rückgängig gemacht werden.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<CollectionService>(context, listen: false).resetCollection();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Collection zurückgesetzt'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tokens'),
            Tab(text: 'Sets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTokensTab(),
          _buildSetsTab(),
        ],
      ),
    );
  }

  void _showTokenDetail(BuildContext context, Token token) {
    final landmarkService = Provider.of<LandmarkService>(context, listen: false);
    final landmark = landmarkService.getLandmarkById(token.landmarkId);
    final imageUrl = landmarkService.getImageUrlForTier(token.landmarkId, token.tier);

    Color tierColor;
    switch (token.tier) {
      case TokenTier.bronze: tierColor = Colors.orange[700]!; break;
      case TokenTier.silver: tierColor = Colors.grey[400]!; break;
      case TokenTier.gold:   tierColor = Colors.amber[500]!; break;
      case TokenTier.platinum: tierColor = Colors.cyan[300]!; break;
    }

    String tierEmoji;
    switch (token.tier) {
      case TokenTier.bronze: tierEmoji = '🥉'; break;
      case TokenTier.silver: tierEmoji = '🥈'; break;
      case TokenTier.gold:   tierEmoji = '🥇'; break;
      case TokenTier.platinum: tierEmoji = '💎'; break;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tierColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: tierColor.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Big token image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imageUrl,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    color: Colors.grey[800],
                    child: const Icon(Icons.image_not_supported,
                        size: 80, color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                token.landmarkName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tierColor),
                    ),
                    child: Text(
                      '$tierEmoji ${token.tier.displayName}  ·  ${token.points} 🪙',
                      style: TextStyle(
                          color: tierColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (landmark != null) ...[
                const SizedBox(height: 8),
                Text(
                  landmark.description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Schließen',
                          style: TextStyle(color: Colors.grey[500])),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upgrade, size: 16),
                      label: const Text('Upgraden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tierColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TokenUpgradeScreen(initialToken: token),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokensTab() {
    return Consumer2<CollectionService, AuthService>(
      builder: (context, collectionService, auth, child) {
        Future<void> onRefresh() async {
          final uid = auth.firebaseUser?.uid;
          if (uid != null) await collectionService.reloadFromFirestore(uid);
        }

        if (collectionService.tokens.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: Colors.amber,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.collections,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tokens collected yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Visit landmarks to start collecting!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: Colors.amber,
          child: CustomScrollView(
          slivers: [
            // ── Completed set reward badges (first row) ──────────────────
            () {
              final completedWithReward = collectionService.sets
                  .where((s) => s.completed && s.rewardImageUrl != null)
                  .toList();
              if (completedWithReward.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _SetRewardCard(set: completedWithReward[i]),
                    childCount: completedWithReward.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              );
            }(),
            // ── Regular tokens ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, index) {
                    final token = collectionService.tokens[index];
                    return TokenCard(
                      token: token,
                      onTap: () => _showTokenDetail(context, token),
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TokenUpgradeScreen(initialToken: token),
                          ),
                        );
                      },
                    );
                  },
                  childCount: collectionService.tokens.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildSetsTab() {
    return Consumer2<CollectionService, AuthService>(
      builder: (context, collectionService, auth, child) {
        Future<void> onRefresh() async {
          final uid = auth.firebaseUser?.uid;
          if (uid != null) await collectionService.reloadFromFirestore(uid);
        }

        if (collectionService.sets.isEmpty) {
          return const Center(
            child: Text('No sets available'),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: Colors.amber,
          child: ListView.builder(
            itemCount: collectionService.sets.length,
            itemBuilder: (context, index) {
              return SetCard(set: collectionService.sets[index]);
            },
          ),
        );
      },
    );
  }
}

// ── Set Reward Card ──────────────────────────────────────────────────────────

class _SetRewardCard extends StatelessWidget {
  final CollectionSet set;
  const _SetRewardCard({required this.set});

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber[400]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  set.rewardImageUrl!,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 240,
                    color: Colors.grey[800],
                    child: const Icon(Icons.emoji_events,
                        size: 80, color: Colors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                set.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[400]!),
                ),
                child: Text(
                  '🎉 Set abgeschlossen  ·  +${set.bonusPoints} 🪙',
                  style: TextStyle(
                      color: Colors.amber[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                set.description,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Schließen',
                    style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber[900]!, Colors.amber[700]!],
          ),
          border: Border.all(color: Colors.amber[400]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👑', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  set.rewardImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                set.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '🎉 Set abgeschlossen',
              style: TextStyle(color: Colors.amber, fontSize: 10),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
