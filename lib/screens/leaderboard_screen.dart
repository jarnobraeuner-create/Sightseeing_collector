import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../services/collection_service.dart';
import 'friends_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<LeaderboardEntry> _global = [];
  List<LeaderboardEntry> _friends = [];
  bool _loadingGlobal = true;
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Publish own stats first so we appear on the leaderboard, then load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishAndLoad();
    });
  }

  Future<void> _publishAndLoad() async {
    final collection = context.read<CollectionService>();

    // Wait for collection to finish loading so leaderboardScore is accurate.
    if (!collection.isLoaded) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return false;
        return !context.read<CollectionService>().isLoaded;
      });
      if (!mounted) return;
    }

    final friendService = context.read<FriendService>();
    final stats = collection.getStatistics();

    // Build own entry to always inject into global leaderboard
    final myUid = friendService.myUid;
    final myUsername = friendService.myUsername;
    final ownEntry = (myUid != null)
        ? LeaderboardEntry(
            uid: myUid,
            username: myUsername ?? myUid,
            totalPoints: stats['leaderboardScore'] ?? 0,
            totalTokens: stats['totalTokens'] ?? 0,
            isFriend: false,
            isMe: true,
          )
        : null;

    // Publish in background — don't block the UI
    friendService.publishMyStats(
      totalPoints: stats['totalPoints'] ?? 0,
      totalTokens: stats['totalTokens'] ?? 0,
      visitedLandmarks: stats['visitedLandmarks'] ?? 0,
      leaderboardScore: stats['leaderboardScore'] ?? 0,
    );
    _loadGlobal(ownEntry: ownEntry);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadGlobal({LeaderboardEntry? ownEntry}) async {
    setState(() => _loadingGlobal = true);
    final data = await context.read<FriendService>().loadLeaderboard(friendsOnly: false, ownEntry: ownEntry);
    if (mounted) setState(() { _global = data; _loadingGlobal = false; });
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    final data = await context.read<FriendService>().loadLeaderboard(friendsOnly: true);
    if (mounted) setState(() { _friends = data; _loadingFriends = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151A26),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Rangliste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Alle Spieler'),
            Tab(text: 'Freunde'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _publishAndLoad(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LeaderboardList(
            entries: _global,
            loading: _loadingGlobal,
            emptyMessage: 'Noch keine Spieler-Daten verfügbar.\nSpiele und sammle Tokens um zu erscheinen!',
          ),
          _LeaderboardList(
            entries: _friends,
            loading: _loadingFriends,
            emptyMessage: 'Noch keine Freunde.\nFüge Freunde hinzu um sie hier zu sehen!',
            onAddFriends: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FriendsScreen())),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool loading;
  final String emptyMessage;
  final VoidCallback? onAddFriends;

  const _LeaderboardList({
    required this.entries,
    required this.loading,
    required this.emptyMessage,
    this.onAddFriends,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }
    if (entries.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 52),
          const SizedBox(height: 16),
          Text(emptyMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          if (onAddFriends != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddFriends,
              icon: const Icon(Icons.person_add),
              label: const Text('Freunde hinzufügen'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.black),
            ),
          ],
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        final rank = i + 1;
        return _LeaderboardTile(entry: e, rank: rank, onTap: e.isMe
            ? null
            : () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => FriendProfileScreen(uid: e.uid, username: e.username))));
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final VoidCallback? onTap;

  const _LeaderboardTile({required this.entry, required this.rank, this.onTap});

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white24;
  }

  String _rankEmoji() {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = entry.isMe;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.amber.withValues(alpha: 0.12)
              : const Color(0xFF151A26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted
                ? Colors.amber.withValues(alpha: 0.5)
                : entry.isFriend
                    ? Colors.deepPurple.withValues(alpha: 0.5)
                    : Colors.white12,
            width: isHighlighted || entry.isFriend ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: rank <= 3
                  ? Text(_rankEmoji(), style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)
                  : Text(
                      '#$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _rankColor(), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
            const SizedBox(width: 10),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isHighlighted
                  ? Colors.amber[700]
                  : entry.isFriend
                      ? Colors.deepPurple[700]
                      : Colors.grey[700],
              child: Text(
                entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            // Name + tokens
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        color: isHighlighted ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (entry.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(6)),
                        child: const Text('Du', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (entry.isFriend && !entry.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.deepPurple[700], borderRadius: BorderRadius.circular(6)),
                        child: const Text('Freund', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.totalTokens} Tokens',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            // Points
            Text(
              '${entry.totalPoints}',
              style: TextStyle(
                color: isHighlighted ? Colors.amber : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'Pkt',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
