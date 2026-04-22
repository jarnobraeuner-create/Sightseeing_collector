import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import '../services/auction_service.dart';
import '../services/landmark_service.dart';
import '../services/auth_service.dart';
import '../services/lootbox_service.dart';
import '../services/cooldown_service.dart';
import '../services/dev_mode_service.dart';
import '../models/index.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({Key? key}) : super(key: key);

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (!auth.isLoggedIn) {
      return _AuthRequiredPage();
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          _currentPage == 0 ? 'Marktplatz' : 'Shop',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CollectionService>(
            builder: (context, collectionService, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '${collectionService.totalPoints} Coins',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageDot(active: _currentPage == 0, label: 'Marktplatz'),
                const SizedBox(width: 16),
                _PageDot(active: _currentPage == 1, label: 'Shop'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildAuctionsPage(),
                _buildShop(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionsPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber,
            tabs: const [
              Tab(text: 'Auktionen'),
              Tab(text: 'Bieten'),
              Tab(text: 'Eigene'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMarketplace(),
              _buildCreateAuction(),
              _buildMyAuctions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tagesangebot
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[900]!, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const Text(
                      'Tagesangebot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '–25%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '10x Lootbox Paket',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  '10 Lootboxen für 15.000 Coins (statt 16.000)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Consumer2<CollectionService, LootboxService>(
                  builder: (context, collection, lootbox, _) => ElevatedButton(
                    onPressed: () async {
                      final devMode = Provider.of<DevModeService>(context, listen: false).enabled;
                      if (!devMode && collection.totalPoints < 15000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Zu wenig Coins! Du brauchst 15.000 🪙')),
                        );
                        return;
                      }
                      if (!devMode) collection.spendPoints(15000);
                      await lootbox.addExtraLootboxes(10);
                      if (context.mounted) {
                        await _showLootboxReceivedPopup(
                          title: 'Lootboxen erhalten',
                          message: 'Du hast 10 Extra-Lootboxen bekommen.',
                          accent: Colors.orange,
                          emoji: '🎰',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('15.000 🪙 kaufen', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shop-Items
          const Text(
            'Verfügbare Items',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Consumer2<CollectionService, LootboxService>(
            builder: (context, collection, lootbox, _) => _ShopItem(
              icon: '🎰',
              title: 'Extra Lootbox',
              subtitle: 'Eine zusätzliche Lootbox kaufen',
              price: 2000,
              canAfford: collection.totalPoints >= 2000 || Provider.of<DevModeService>(context, listen: false).enabled,
              onBuy: () async {
                final devMode = Provider.of<DevModeService>(context, listen: false).enabled;
                if (!devMode && collection.totalPoints < 2000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zu wenig Coins!')),
                  );
                  return;
                }
                if (!devMode) collection.spendPoints(2000);
                await lootbox.addExtraLootboxes(1);
                if (context.mounted) {
                  await _showLootboxReceivedPopup(
                    title: 'Lootbox erhalten',
                    message: 'Du hast 1 Extra-Lootbox bekommen.',
                    accent: Colors.orange,
                    emoji: '🎰',
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          Consumer2<CollectionService, LootboxService>(
            builder: (context, collection, lootbox, _) => _ShopItem(
              icon: '🏛️',
              title: 'Monumente-Lootbox',
              subtitle: 'Exklusiv: enthält nur Monumente-Token',
              price: 6000,
              canAfford: collection.totalPoints >= 6000 || Provider.of<DevModeService>(context, listen: false).enabled,
              onBuy: () async {
                final devMode = Provider.of<DevModeService>(context, listen: false).enabled;
                if (!devMode && collection.totalPoints < 6000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zu wenig Coins!')),
                  );
                  return;
                }
                if (!devMode) collection.spendPoints(6000);
                await lootbox.addMonumentLootboxes(1);
                if (context.mounted) {
                  await _showLootboxReceivedPopup(
                    title: 'Monumente-Lootbox erhalten',
                    message: 'Du hast 1 Monumente-Lootbox bekommen.',
                    accent: Colors.deepPurpleAccent,
                    emoji: '🏛️',
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          Consumer2<CollectionService, CooldownService>(
            builder: (context, collection, cooldown, _) => _ShopItem(
              icon: '⚡',
              title: 'Cooldown Skip',
              subtitle: 'Alle Sammel-Cooldowns sofort zurücksetzen',
              price: 1500,
              canAfford: collection.totalPoints >= 1500 || Provider.of<DevModeService>(context, listen: false).enabled,
              onBuy: () async {
                final devMode = Provider.of<DevModeService>(context, listen: false).enabled;
                if (!devMode && collection.totalPoints < 1500) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zu wenig Coins!')),
                  );
                  return;
                }
                if (!devMode) collection.spendPoints(1500);
                await cooldown.resetAllCooldowns();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ Cooldowns zurückgesetzt!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '👆 Nach links wischen für Shop',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swipe_left, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text('Shop', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMarketplace() {
    return Consumer2<AuctionService, AuthService>(
      builder: (context, auctionService, auth, child) {
        final myUid = auth.firebaseUser?.uid ?? '';
        final auctions = auctionService.auctions;

        if (auctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Keine Auktionen verfügbar',
                  style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            final isOwn = auction.sellerId == myUid;
            final timeLeft = auction.endsAt.difference(DateTime.now());
            final hasBids = auction.currentBid > auction.startPrice;

            return Card(
              color: isOwn ? Colors.grey[800] : Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: isOwn ? null : () => _showBidDialog(auction),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Token Bild
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: auction.imageUrl != null
                            ? Image.asset(
                                auction.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80, height: 80,
                                  color: Colors.grey[700],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 80, height: 80,
                                color: Colors.grey[700],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    auction.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (isOwn)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Deine',
                                      style: TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verkäufer: ${auction.sellerName}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasBids
                                  ? 'Höchstes Gebot: ${auction.currentBid} Coins'
                                  : 'Mindestgebot: ${auction.startPrice} Coins',
                              style: TextStyle(
                                color: hasBids ? Colors.amber : Colors.grey[400],
                                fontWeight: hasBids ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bieten-Icon oder Eigene-Indikator
                      if (!isOwn)
                        Icon(Icons.gavel, color: Colors.amber[600])
                      else
                        Icon(Icons.visibility, color: Colors.blue[400]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBidDialog(Auction auction) {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auction.sellerId == auth.firebaseUser?.uid) return; // Eigene Auktionen nicht bietbar

    final collectionService = Provider.of<CollectionService>(context, listen: false);
    final myTokens = collectionService.tokens;
    final myCoins = collectionService.totalPoints;
    
    int coinBid = auction.currentBid + 1;
    List<String> selectedTokenIds = [];
    final TextEditingController coinController = TextEditingController(text: coinBid.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasEnoughCoins = coinBid <= myCoins;
          
          return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Gebot abgeben',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token Info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: auction.imageUrl != null
                          ? Image.asset(
                              auction.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60, height: 60,
                                color: Colors.grey[700],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 60, height: 60,
                              color: Colors.grey[700],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'von ${auction.sellerName}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Verfügbare Coins Anzeige
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.amber[700], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Verfügbar: $myCoins Coins',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Coins TextField
                Text(
                  'Coins bieten:',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: coinController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(
                      Icons.monetization_on,
                      color: Colors.amber[700],
                    ),
                    errorText: !hasEnoughCoins && coinBid > 0
                        ? 'Nicht genug Coins!'
                        : null,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      coinBid = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Token Auswahl
                Text(
                  'Token zum Tausch (optional):',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (myTokens.isEmpty)
                  Text(
                    'Du hast keine Tokens zum Tauschen',
                    style: TextStyle(color: Colors.grey[500]),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: myTokens.map((token) {
                      final isSelected = selectedTokenIds.contains(token.id);
                      return FilterChip(
                        label: Text(token.landmarkName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTokenIds.add(token.id);
                            } else {
                              selectedTokenIds.remove(token.id);
                            }
                          });
                        },
                        selectedColor: Colors.amber[700],
                        checkmarkColor: Colors.black,
                        backgroundColor: Colors.grey[800],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                
                // Gesamtwert
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dein Gebot:',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      if (selectedTokenIds.isEmpty && coinBid > 0)
                        Text(
                          '$coinBid Coins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (selectedTokenIds.isNotEmpty && coinBid == 0)
                        Text(
                          '${selectedTokenIds.length} Token${selectedTokenIds.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (selectedTokenIds.isNotEmpty && coinBid > 0)
                        Text(
                          '${selectedTokenIds.length} Token${selectedTokenIds.length > 1 ? 's' : ''} + $coinBid Coins',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          'Mindestens Coins oder Token angeben',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: ((coinBid > 0 || selectedTokenIds.isNotEmpty) && hasEnoughCoins)
                  ? () {
                      final auctionService = Provider.of<AuctionService>(context, listen: false);
                      final selectedTokenNames = myTokens
                          .where((t) => selectedTokenIds.contains(t.id))
                          .map((t) => t.landmarkName)
                          .toList();
                      
                      final auth = Provider.of<AuthService>(context, listen: false);
                      auctionService.placeBid(
                        auction.id,
                        auth.firebaseUser!.uid,
                        auth.appUser?.username ?? 'Unbekannt',
                        coinBid,
                        selectedTokenIds,
                        selectedTokenNames,
                      );
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gebot erfolgreich abgegeben!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
              ),
              child: const Text('Bieten'),
            ),
          ],
        );
        },
      ),
    );
  }

  Widget _buildCreateAuction() {
    return Consumer3<CollectionService, AuctionService, LandmarkService>(
      builder: (context, collectionService, auctionService, landmarkService, child) {
        final myTokens = collectionService.tokens;
        
        if (myTokens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Du hast keine Tokens zum Versteigern',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myTokens.length,
          itemBuilder: (context, index) {
            final token = myTokens[index];
            final landmark = landmarkService.landmarks.firstWhere((l) => l.id == token.landmarkId);
            final tokenImageUrl = landmarkService.getImageUrlForTier(landmark.id, token.tier);
            
            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        tokenImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            landmark.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${token.tier.displayName} · Wert: ~${token.points} Coins',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAuctionDialog(token, landmark, tokenImageUrl),
                      icon: const Icon(Icons.sell, size: 18),
                      label: const Text('Versteigern'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateAuctionDialog(Token token, Landmark landmark, String tokenImageUrl) {
    int minimumCoins = 50;
    final minimumCoinsController = TextEditingController(text: minimumCoins.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Auktion erstellen',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                        tokenImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${landmark.name} · ${token.tier.displayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Mindestgebot: $minimumCoins Coins',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minimumCoinsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Startpreis in Coins',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  hintText: 'Beliebigen Betrag eingeben',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber[700]!),
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    minimumCoins = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Die Auktion läuft 24 Stunden',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final parsedMinimumCoins = int.tryParse(minimumCoinsController.text);
                if (parsedMinimumCoins == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte einen gültigen Startpreis eingeben.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final auctionService = Provider.of<AuctionService>(context, listen: false);
                final auth = Provider.of<AuthService>(context, listen: false);
                auctionService.createAuction(
                  auth.firebaseUser!.uid,
                  auth.appUser?.username ?? 'Unbekannt',
                  token.id,
                  '${landmark.name} · ${token.tier.displayName}',
                  tokenImageUrl,
                  parsedMinimumCoins,
                  tokenData: token.toJson(),
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Auktion erfolgreich erstellt!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
              ),
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    ).then((_) => minimumCoinsController.dispose());
  }

  Future<void> _showLootboxReceivedPopup({
    required String title,
    required String message,
    required Color accent,
    required String emoji,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyAuctions() {
    return Consumer<AuctionService>(
      builder: (context, auctionService, child) {
        final auth = Provider.of<AuthService>(context, listen: false);
        final myAuctions = auctionService.getMyAuctions(auth.firebaseUser?.uid ?? '');
        
        if (myAuctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Du hast keine aktiven Auktionen',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myAuctions.length,
          itemBuilder: (context, index) {
            final auction = myAuctions[index];
            final timeLeft = auction.endsAt.difference(DateTime.now());

            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: auction.imageUrl != null
                              ? Image.asset(
                                  auction.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80, height: 80,
                                    color: Colors.grey[700],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 80, height: 80,
                                  color: Colors.grey[700],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auction.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m',
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.grey[900],
                                title: const Text(
                                  'Auktion beenden?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Möchtest du diese Auktion wirklich beenden?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Abbrechen',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      auctionService.cancelAuction(auction.id);
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                    ),
                                    child: const Text('Beenden'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    // Gebote live aus Subcollection
                    StreamBuilder<List<Bid>>(
                      stream: auctionService.bidsStream(auction.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        final bids = snapshot.data ?? [];
                        final highestBid = bids.isEmpty
                            ? null
                            : bids.reduce((a, b) => a.coins > b.coins ? a : b);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gebote (${bids.length}):',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (bids.isEmpty)
                              Text('Noch keine Gebote',
                                  style: TextStyle(color: Colors.grey[500]))
                            else
                              ...bids.map((bid) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(bid.bidderName,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                          Text(bid.description,
                                              style: const TextStyle(color: Colors.amber)),
                                        ],
                                      ),
                                    ),
                                    if (bid.id == highestBid?.id)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[700],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Höchstes',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.grey[900],
                                          title: const Text('Gebot annehmen?',
                                              style: TextStyle(color: Colors.white)),
                                          content: Text(
                                            'Gebot von ${bid.bidderName} annehmen?\n\n${bid.description}',
                                            style:
                                                const TextStyle(color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: Text('Abbrechen',
                                                  style: TextStyle(
                                                      color: Colors.grey[400]))),
                                            ElevatedButton(
                                              onPressed: () {
                                                final collectionService = Provider.of<CollectionService>(context, listen: false);
                                                auctionService.acceptBid(
                                                    auction.id, bid, collectionService);
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Gebot angenommen!'),
                                                  backgroundColor: Colors.green,
                                                ));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green[700]),
                                              child: const Text('Annehmen'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      icon: Icon(Icons.check_circle,
                                          color: Colors.green[400]),
                                    ),
                                  ],
                                ),
                              )),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────────

class _PageDot extends StatelessWidget {
  final bool active;
  final String label;

  const _PageDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.amber : Colors.grey[600],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.amber : Colors.grey[600],
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ShopItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final int price;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ShopItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onBuy,
    this.canAfford = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: canAfford ? Colors.grey[700]! : Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? Colors.amber[700] : Colors.grey[700],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              '$price 🪙',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthRequiredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text('Marktplatz', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 72, color: Colors.grey[600]),
              const SizedBox(height: 20),
              const Text(
                'Anmeldung erforderlich',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Melde dich an, um den Marktplatz und das Auktionshaus zu nutzen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
