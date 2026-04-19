import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import '../services/auction_service.dart';
import '../services/landmark_service.dart';
import '../models/auction.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(
          _currentPage == 0 ? 'Shop' : 'Auktionshaus',
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
                _PageDot(active: _currentPage == 0, label: 'Shop'),
                const SizedBox(width: 16),
                _PageDot(active: _currentPage == 1, label: 'Auktionen'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildShop(),
                _buildAuctionsPage(),
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
              Tab(text: 'Marktplatz'),
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
                  'Extra Münzen Paket',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  '500 Coins für 375 Coins',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bald verfügbar!')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Kaufen', style: TextStyle(fontWeight: FontWeight.bold)),
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
          _ShopItem(
            icon: '🎰',
            title: 'Extra Lootbox',
            subtitle: 'Eine zusätzliche Lootbox öffnen',
            price: 200,
            onBuy: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bald verfügbar!')),
            ),
          ),
          const SizedBox(height: 10),
          _ShopItem(
            icon: '⚡',
            title: 'Cooldown Skip',
            subtitle: 'Einen Cooldown sofort aufheben',
            price: 150,
            onBuy: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bald verfügbar!')),
            ),
          ),
          const SizedBox(height: 10),
          _ShopItem(
            icon: '🗺️',
            title: 'Radar-Boost',
            subtitle: 'Zeige alle Tokens in 500m Radius',
            price: 100,
            onBuy: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bald verfügbar!')),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '👆 Nach links wischen für Auktionen',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swipe_left, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text('Auktionshaus', style: TextStyle(color: Colors.grey[400])),
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
    return Consumer<AuctionService>(
      builder: (context, auctionService, child) {
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
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            final timeLeft = auction.expiresAt.difference(DateTime.now());
            final highestBid = auction.highestBid;
            
            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _showBidDialog(auction),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Token Bild
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          auction.tokenImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auction.tokenName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
                            if (highestBid != null)
                              Text(
                                'Höchstes Gebot: ${highestBid.description}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                'Mindestgebot: ${auction.minimumCoins} Coins',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                          ],
                        ),
                      ),
                      // Anzahl Gebote
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${auction.bids.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
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
    final collectionService = Provider.of<CollectionService>(context, listen: false);
    final myTokens = collectionService.tokens;
    final myCoins = collectionService.totalPoints;
    
    int coinBid = auction.highestBid?.coins ?? auction.minimumCoins;
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
                      child: Image.asset(
                        auction.tokenImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.tokenName,
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
                      
                      auctionService.placeBid(
                        auction.id,
                        'current_user',
                        'Du',
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
                        landmark.imageUrl,
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
                            'Wert: ~100 Coins',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAuctionDialog(token, landmark),
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

  void _showCreateAuctionDialog(token, landmark) {
    int minimumCoins = 50;
    
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
                      landmark.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      landmark.name,
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
              Slider(
                value: minimumCoins.toDouble(),
                min: 0,
                max: 200,
                divisions: 20,
                activeColor: Colors.amber[700],
                onChanged: (value) {
                  setDialogState(() {
                    minimumCoins = value.toInt();
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
                final auctionService = Provider.of<AuctionService>(context, listen: false);
                auctionService.createAuction(
                  'current_user',
                  'Du',
                  token.id,
                  landmark.name,
                  landmark.imageUrl,
                  minimumCoins,
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
    );
  }

  Widget _buildMyAuctions() {
    return Consumer<AuctionService>(
      builder: (context, auctionService, child) {
        final myAuctions = auctionService.getMyAuctions('current_user');
        
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
            final timeLeft = auction.expiresAt.difference(DateTime.now());
            final highestBid = auction.highestBid;
            
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
                          child: Image.asset(
                            auction.tokenImageUrl,
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
                                auction.tokenName,
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
                    Text(
                      'Gebote (${auction.bids.length}):',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (auction.bids.isEmpty)
                      Text(
                        'Noch keine Gebote',
                        style: TextStyle(color: Colors.grey[500]),
                      )
                    else
                      ...auction.bids.map((bid) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bid.bidderName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        bid.description,
                                        style: const TextStyle(color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                                if (bid == highestBid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[700],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Höchstes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.grey[900],
                                        title: const Text(
                                          'Gebot annehmen?',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: Text(
                                          'Möchtest du das Gebot von ${bid.bidderName} annehmen?\n\nGebot: ${bid.description}',
                                          style: const TextStyle(color: Colors.white70),
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
                                              auctionService.acceptBid(auction.id, bid.id);
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Gebot angenommen!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[700],
                                            ),
                                            child: const Text('Annehmen'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: Colors.green[400],
                                  ),
                                ),
                              ],
                            ),
                          )),
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
  final VoidCallback onBuy;

  const _ShopItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[700]!),
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
              backgroundColor: Colors.amber[700],
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
