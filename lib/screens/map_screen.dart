import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/lootbox_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  bool _hasCenteredOnUser = false;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  final Map<String, BitmapDescriptor> _markerIconsGray = {};
  bool _isUpdatingMarkers = false;

  @override
  void initState() {
    super.initState();
    _loadAllMarkerIcons();
    // Verzögerte Initialisierung
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final locationService = Provider.of<LocationService>(context, listen: false);
        locationService.ensureInitialized();
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  Future<void> _loadAllMarkerIcons() async {
    await Future.wait([
      _loadMarkerIcon('bronze', 'assets/images/Map_Pin_Bronze.png'),
      _loadMarkerIcon('silver', 'assets/images/Map_pin_silber.png'),
      _loadMarkerIcon('gold', 'assets/images/map_pin_gold.png'),
      _loadMarkerIcon('platin', 'assets/images/Platin_mappin_platin.png'),
    ]);
    
    if (mounted) {
      _updateMarkers();
    }
  }

  Future<void> _loadMarkerIcon(String tierKey, String imagePath) async {
    try {
      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200,
        targetHeight: 200,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (resizedData != null) {
        final BitmapDescriptor icon = BitmapDescriptor.fromBytes(
          resizedData.buffer.asUint8List(),
        );
        
        final ui.Image grayImage = await _convertToGrayscale(frameInfo.image);
        final ByteData? grayData = await grayImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        
        if (mounted) {
          setState(() {
            _markerIcons[tierKey] = icon;
            if (grayData != null) {
              _markerIconsGray[tierKey] = BitmapDescriptor.fromBytes(
                grayData.buffer.asUint8List(),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des $tierKey Marker Icons: $e');
    }
  }

  Future<ui.Image> _convertToGrayscale(ui.Image image) async {
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return image;
    
    final Uint8List pixels = data.buffer.asUint8List();
    
    // Konvertiere zu Graustufen
    for (int i = 0; i < pixels.length; i += 4) {
      final int r = pixels[i];
      final int g = pixels[i + 1];
      final int b = pixels[i + 2];
      
      // Graustufen-Formel: 0.299*R + 0.587*G + 0.114*B
      final int gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
      
      pixels[i] = gray;
      pixels[i + 1] = gray;
      pixels[i + 2] = gray;
      // Alpha-Kanal (i+3) bleibt unverändert
    }
    
    // Erstelle neues Bild aus modifizierten Pixeln
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    
    return frameInfo.image;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Einmalig auf Nutzerposition zentrieren wenn GPS bereits verfügbar
    if (!_hasCenteredOnUser) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;
      if (position != null) {
        _hasCenteredOnUser = true;
        controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    }
    _mapController?.setMapStyle('''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1b1b1b"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#373737"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [{"color": "#4e4e4e"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d3d3d"}]
  }
]
    ''');
    _updateMarkers();
  }

  void _updateMarkers() {
    if (!mounted || _isUpdatingMarkers) return;
    
    _isUpdatingMarkers = true;
    
    // Debounce: Warte kurz bevor Update
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        _isUpdatingMarkers = false;
        return;
      }
      
      final landmarkService = Provider.of<LandmarkService>(context, listen: false);
      final collectionService = Provider.of<CollectionService>(context, listen: false);
      
      final newMarkers = landmarkService.landmarks.map((landmark) {
        final token = collectionService.getToken(landmark.id);
        final isCollected = token != null;
        
        // Pin-Typ basierend auf defaultTier des Landmarks
        String pinType;
        switch (landmark.defaultTier) {
          case TokenTier.silver:
            pinType = 'silver';
            break;
          case TokenTier.gold:
            pinType = 'gold';
            break;
          case TokenTier.platinum:
            pinType = 'platin';
            break;
          default:
            pinType = 'bronze';
        }
        
        // Wähle das passende Icon
        BitmapDescriptor markerIcon;
        if (isCollected) {
          // Gesammelt: Verwende Graustufen-Version
          markerIcon = _markerIconsGray[pinType] ?? BitmapDescriptor.defaultMarker;
        } else {
          // Nicht gesammelt: Verwende farbige Version
          markerIcon = _markerIcons[pinType] ?? BitmapDescriptor.defaultMarker;
        }
        
        return Marker(
          markerId: MarkerId(landmark.id),
          position: LatLng(landmark.latitude, landmark.longitude),
          icon: markerIcon,
          alpha: isCollected ? 0.7 : 1.0,
          onTap: () => _showLandmarkDetails(landmark),
          infoWindow: InfoWindow(
            title: landmark.name,
            snippet: isCollected ? 'Gesammelt ✓' : '${landmark.pointsReward} Punkte',
          ),
        );
      }).toSet();
      
      if (mounted) {
        setState(() {
          _markers = newMarkers;
        });
      }
      
      _isUpdatingMarkers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Karte'),
        leading: Consumer<LootboxService>(
          builder: (context, lootboxService, _) {
            final canOpen = lootboxService.canOpen;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Text(
                    '🎁',
                    style: TextStyle(
                      fontSize: 26,
                      color: canOpen ? null : Colors.grey,
                    ),
                  ),
                  tooltip: canOpen ? 'Lootbox öffnen!' : 'Morgen wieder verfügbar',
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const LootboxDialog(),
                    );
                  },
                ),
                if (canOpen)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              final locationService = Provider.of<LocationService>(context, listen: false);
              locationService.refreshLocation();
              final position = locationService.currentPosition;
              if (position != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(position.latitude, position.longitude),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateMarkers,
          ),
        ],
      ),
      body: !_isMapReady
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Consumer<LocationService>(
              builder: (context, locationService, child) {
                final position = locationService.currentPosition;
                final hasLocation = position != null;

                // Einmalig zur Nutzerposition springen wenn Karte bereit
                if (hasLocation && !_hasCenteredOnUser && _mapController != null) {
                  _hasCenteredOnUser = true;
                  Future.microtask(() {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(position.latitude, position.longitude),
                      ),
                    );
                  });
                }

                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(53.5500, 10.0000), // Hamburg Fallback
                        zoom: 13.0,
                      ),
                      markers: _markers,
                      myLocationEnabled: locationService.isLocationAccessGranted,
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                    // Overlay-Spinner solange kein Standort bekannt
                    if (!hasLocation)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.amber,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Standort wird ermittelt …',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  void _showLandmarkDetails(Landmark landmark) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final collectionService = Provider.of<CollectionService>(context, listen: false);
    final landmarkService = Provider.of<LandmarkService>(context, listen: false);
    final cooldownService = Provider.of<CooldownService>(context, listen: false);
    final position = locationService.currentPosition;

    final distance = position != null
        ? landmark.getDistance(position.latitude, position.longitude)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LandmarkBottomSheet(
        landmark: landmark,
        distance: distance,
        collectionService: collectionService,
        landmarkService: landmarkService,
        cooldownService: cooldownService,
        onCollected: _updateMarkers,
      ),
    );
  }
}

// ── Landmark Detail Bottom Sheet ────────────────────────────────────────────

class _LandmarkBottomSheet extends StatefulWidget {
  final Landmark landmark;
  final double? distance;
  final CollectionService collectionService;
  final LandmarkService landmarkService;
  final CooldownService cooldownService;
  final VoidCallback onCollected;

  const _LandmarkBottomSheet({
    required this.landmark,
    required this.distance,
    required this.collectionService,
    required this.landmarkService,
    required this.cooldownService,
    required this.onCollected,
  });

  @override
  State<_LandmarkBottomSheet> createState() => _LandmarkBottomSheetState();
}

class _LandmarkBottomSheetState extends State<_LandmarkBottomSheet> {
  late Duration? _remaining;
  bool _canCollect = false;

  @override
  void initState() {
    super.initState();
    _refreshCooldown();
    // Refresh countdown every second if in cooldown
    _startTimer();
  }

  void _refreshCooldown() {
    final tier = widget.landmark.defaultTier;
    final id = widget.landmark.id;
    _canCollect = widget.cooldownService.canCollect(id, tier);
    _remaining = widget.cooldownService.remainingCooldown(id, tier);
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(_refreshCooldown);
      return _remaining != null && _remaining!.inSeconds > 0;
    });
  }

  // Distanz in km; <= 0.1 km = innerhalb 100 Meter
  bool get _isNearby {
    final d = widget.distance;
    if (d == null) return false; // kein GPS = nicht sammelbar
    return d <= 0.25;
  }

  Color get _tierColor {
    switch (widget.landmark.defaultTier) {
      case TokenTier.bronze: return Colors.brown[400]!;
      case TokenTier.silver: return Colors.grey[400]!;
      case TokenTier.gold: return Colors.amber[500]!;
      case TokenTier.platinum: return Colors.cyan[300]!;
    }
  }

  String get _cooldownLabel {
    final tier = widget.landmark.defaultTier;
    if (tier == TokenTier.platinum) return 'Einmalig – nicht mehr sammelbar';
    if (_remaining == null) return '';
    return 'Cooldown: ${CooldownService.formatDuration(_remaining!)}';
  }

  void _collect(BuildContext ctx) {
    final landmark = widget.landmark;
    widget.collectionService.collectTokenAllowDuplicate(
      landmark.id,
      landmark.name,
      landmark.category,
      landmark.pointsReward,
      landmark.relatedSetIds,
      tier: landmark.defaultTier,
    );
    widget.cooldownService.recordCollection(landmark.id);
    widget.onCollected();
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          'Token gesammelt! +${landmark.pointsReward} Punkte (${landmark.defaultTier.displayName})',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _quickSell(BuildContext ctx) {
    final landmark = widget.landmark;
    final coins = landmark.pointsReward * 2;
    widget.collectionService.addPoints(coins);
    widget.cooldownService.recordCollection(landmark.id);
    widget.onCollected();
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Quick-Sell! +$coins Münzen 🪙 (kein Token)'),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landmark = widget.landmark;
    final isEverCollected = widget.cooldownService.wasEverCollected(landmark.id);
    final isFirstCollection = !isEverCollected;
    final tier = landmark.defaultTier;
    final isPlatinum = tier == TokenTier.platinum;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[900]!, Colors.grey[850]!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Token Image
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _tierColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: landmark.imageUrl.isNotEmpty
                    ? Image.asset(
                        widget.landmarkService
                            .getImageUrlForTier(landmark.id, tier),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.image_not_supported,
                              size: 60, color: Colors.white54),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.location_on,
                            size: 60, color: Colors.amber),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  landmark.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _tierColor, width: 1),
                ),
                child: Text(
                  tier.displayName,
                  style: TextStyle(color: _tierColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            landmark.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          // Distance + points row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  widget.distance != null
                      ? '${(widget.distance! * 1000).toStringAsFixed(0)} m entfernt'
                      : 'Entfernung unbekannt',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.amber[700]!, Colors.amber[500]!]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${landmark.pointsReward} 🪙',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Cooldown banner
          if (!_canCollect) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.red[900]!.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[700]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(isPlatinum ? Icons.lock : Icons.timer,
                      color: Colors.red[300], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _cooldownLabel,
                    style: TextStyle(color: Colors.red[200], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Buttons
          if (!_isNearby) ...[                
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_off, color: Colors.grey, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    widget.distance != null
                        ? 'Zu weit entfernt (${(widget.distance! * 1000).toStringAsFixed(0)} m) – komm näher!'
                        : 'Standort nicht verfügbar',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (_canCollect) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(isFirstCollection ? 'Sammeln' : 'Erneut sammeln'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      onPressed: () => _collect(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sell_outlined),
                      label: Text('+${landmark.pointsReward * 2} 🪙'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      onPressed: () => _quickSell(context),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: null,
                child: Text(isPlatinum ? 'Einmalig gesammelt ✓' : 'Cooldown aktiv…'),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
