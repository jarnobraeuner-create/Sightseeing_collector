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

class _CollectionScreenState extends State<CollectionScreen> {
  List<_TokenCategory> _buildCategories(List<Token> tokens) {
    return [
      _TokenCategory(
        key: 'set_tokens',
        label: 'Set Tokens',
        icon: Icons.collections_bookmark,
        color: Colors.lightBlueAccent,
        predicate: (t) => t.setIds.isNotEmpty,
      ),
      _TokenCategory(
        key: 'monumente',
        label: 'Monumente',
        icon: Icons.account_balance,
        color: Colors.deepPurpleAccent,
        predicate: (t) => t.tier == TokenTier.monumente,
      ),
      _TokenCategory(
        key: 'platin',
        label: 'Platin',
        icon: Icons.diamond,
        color: Colors.cyanAccent,
        predicate: (t) => t.tier == TokenTier.platinum,
      ),
      _TokenCategory(
        key: 'gold',
        label: 'Gold',
        icon: Icons.emoji_events,
        color: Colors.amberAccent,
        predicate: (t) => t.tier == TokenTier.gold,
      ),
      _TokenCategory(
        key: 'silber',
        label: 'Silber',
        icon: Icons.workspace_premium,
        color: Colors.white70,
        predicate: (t) => t.tier == TokenTier.silver,
      ),
      _TokenCategory(
        key: 'bronze',
        label: 'Bronze',
        icon: Icons.military_tech,
        color: Colors.orangeAccent,
        predicate: (t) => t.tier == TokenTier.bronze,
      ),
    ];
  }

  void _openSetWappenPage(BuildContext context, CollectionService collectionService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SetWappenPage(sets: collectionService.sets),
      ),
    );
  }

  void _openCategory(BuildContext context, _TokenCategory category, List<Token> allTokens) {
    final filtered = allTokens.where(category.predicate).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CollectionCategoryPage(
          title: category.label,
          color: category.color,
          tokens: filtered,
          onTokenTap: (token) => _showTokenDetail(context, token),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDevMode = context.watch<DevModeService>().enabled;
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Collection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isDevMode)
            IconButton(
              icon: const Icon(Icons.science, color: Colors.white70),
              tooltip: 'Alle Tokens sammeln (Test)',
              onPressed: () {
                final cs = Provider.of<CollectionService>(context, listen: false);
                final ls = Provider.of<LandmarkService>(context, listen: false);
                cs.collectAllTokensForTesting(ls.landmarks);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔬 Alle Token-Tiers pro Landmark gesammelt!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
            ),
          if (isDevMode)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.white70),
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
      ),
      body: _buildTokensTab(),
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
      case TokenTier.monumente: tierColor = Colors.deepPurpleAccent; break;
    }

    String tierEmoji;
    switch (token.tier) {
      case TokenTier.bronze: tierEmoji = '🥉'; break;
      case TokenTier.silver: tierEmoji = '🥈'; break;
      case TokenTier.gold:   tierEmoji = '🥇'; break;
      case TokenTier.platinum: tierEmoji = '💎'; break;
      case TokenTier.monumente: tierEmoji = '🏛️'; break;
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

        final visibleTokens = collectionService.tokens
            .where((t) => !t.landmarkId.endsWith('_church'))
            .toList();
        final categories = _buildCategories(visibleTokens);

        if (visibleTokens.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: Colors.amber,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLottie(
                          type: AppLottieType.empty,
                          size: 130,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Noch keine Tokens gesammelt',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Besuche Orte auf der Karte und starte deine Sammlung.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                          textAlign: TextAlign.center,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _CollectionOverview(
                  totalTokens: visibleTokens.length,
                  totalCoins: collectionService.totalPoints,
                  completedSets: collectionService.getCompletedSets().length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((category) {
                    final count = category.key == 'set_tokens'
                        ? collectionService.sets.length
                        : visibleTokens.where(category.predicate).length;
                    return _CategoryTile(
                      title: category.label,
                      count: count,
                      icon: category.icon,
                      color: category.color,
                      onTap: category.key == 'set_tokens'
                          ? () => _openSetWappenPage(context, collectionService)
                          : () => _openCategory(context, category, visibleTokens),
                    );
                  }).toList(),
                ),
              ),
            ),
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
                    final token = visibleTokens[index];
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
                  childCount: visibleTokens.length,
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

}

class _TokenCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final bool Function(Token token) predicate;

  const _TokenCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.predicate,
  });
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 44) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151A26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.65), width: 1.3),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _CollectionCategoryPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<Token> tokens;
  final ValueChanged<Token> onTokenTap;

  const _CollectionCategoryPage({
    required this.title,
    required this.color,
    required this.tokens,
    required this.onTokenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: tokens.isEmpty
          ? Center(
              child: Text(
                'Keine Tokens in dieser Kategorie',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: tokens.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final token = tokens[index];
                  return TokenCard(
                    token: token,
                    onTap: () => onTokenTap(token),
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TokenUpgradeScreen(initialToken: token),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _CollectionOverview extends StatelessWidget {
  final int totalTokens;
  final int totalCoins;
  final int completedSets;

  const _CollectionOverview({
    required this.totalTokens,
    required this.totalCoins,
    required this.completedSets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2132), Color(0xFF151A26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewItem(
              label: 'Tokens',
              value: '$totalTokens',
              color: Colors.lightBlueAccent,
            ),
          ),
          Expanded(
            child: _OverviewItem(
              label: 'Coins',
              value: '$totalCoins',
              color: Colors.amberAccent,
            ),
          ),
          Expanded(
            child: _OverviewItem(
              label: 'Sets',
              value: '$completedSets',
              color: Colors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
      ],
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

// ── Set Wappen Page ───────────────────────────────────────────────────────────

class _SetWappenPage extends StatelessWidget {
  final List<CollectionSet> sets;
  const _SetWappenPage({required this.sets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        title: const Text('Set Tokens', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: sets.isEmpty
          ? Center(
              child: Text(
                'Keine Sets verfügbar',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: sets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final set = sets[index];
                  return _WappenCard(set: set);
                },
              ),
            ),
    );
  }
}

class _WappenCard extends StatelessWidget {
  final CollectionSet set;
  const _WappenCard({required this.set});

  @override
  Widget build(BuildContext context) {
    final completed = set.completed;
    final progress = set.collectedTokenIds.length;
    final total = set.requiredTokenIds.length;
    final rewardUrl = set.rewardImageUrl;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: completed
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[900]!, Colors.amber[700]!],
              )
            : const LinearGradient(
                colors: [Color(0xFF1A2132), Color(0xFF151A26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: completed ? Colors.amber[400]! : Colors.white24,
          width: completed ? 2 : 1,
        ),
        boxShadow: completed
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (completed) const Text('👑', style: TextStyle(fontSize: 18)),
            if (completed) const SizedBox(height: 4),
            Expanded(
              child: rewardUrl != null
                  ? ColorFiltered(
                      colorFilter: completed
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      0.5, 0,
                            ]),
                      child: Image.asset(
                        rewardUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.emoji_events,
                          size: 60,
                          color: completed ? Colors.amber : Colors.white24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.emoji_events,
                      size: 60,
                      color: completed ? Colors.amber : Colors.white24,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              set.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: completed ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            if (completed)
              const Text(
                '🎉 Set abgeschlossen',
                style: TextStyle(color: Colors.amber, fontSize: 10),
              )
            else
              Text(
                '$progress / $total',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
