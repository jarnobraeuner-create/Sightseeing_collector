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

  Widget _buildTokensTab() {
    return Consumer<CollectionService>(
      builder: (context, collectionService, child) {
        if (collectionService.tokens.isEmpty) {
          return Center(
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
          );
        }

        return CustomScrollView(
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
                      onTap: () {
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
        );
      },
    );
  }

  Widget _buildSetsTab() {
    return Consumer<CollectionService>(
      builder: (context, collectionService, child) {
        if (collectionService.sets.isEmpty) {
          return const Center(
            child: Text('No sets available'),
          );
        }

        return ListView.builder(
          itemCount: collectionService.sets.length,
          itemBuilder: (context, index) {
            return SetCard(set: collectionService.sets[index]);
          },
        );
      },
    );
  }
}

// ── Set Reward Card ──────────────────────────────────────────────────────────

class _SetRewardCard extends StatelessWidget {
  final CollectionSet set;
  const _SetRewardCard({required this.set});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Crown badge
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          // Wappen image
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
          // Set name
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
    );
  }
}
