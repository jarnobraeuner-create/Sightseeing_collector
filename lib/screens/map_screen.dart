import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import '../services/index.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// ─── Pin-Tier Randomization Constants ────────────────────────────────────────
const _kPinTiersKey = 'pin_tiers_data_v1';
const _kPinTiersTimestampKey = 'pin_tiers_timestamp_v1';
const _kPinRefreshHours = 24;

TokenTier _rollPinTier(Random rng) {
  final roll = rng.nextDouble() * 100;
  if (roll < 1.0) return TokenTier.gold;   // 1%
  if (roll < 6.0) return TokenTier.silver; // 5%
  return TokenTier.bronze;                 // 94%
}
// ─────────────────────────────────────────────────────────────────────────────

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _hasCenteredOnUser = false;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  final Map<String, BitmapDescriptor> _markerIconsGray = {};
  bool _isUpdatingMarkers = false;

  // Random pin tiers, refreshed every 24h
  Map<String, TokenTier> _pinTiers = {};

  // Zoom-based clustering
  double _currentZoom = 13.0;
  final Map<String, BitmapDescriptor> _clusterIconCache = {};

  @override
  void initState() {
    super.initState();
    _loadAllMarkerIcons();
    _loadOrRefreshPinTiers();
    // LocationService im Hintergrund initialisieren ohne Rendering zu blockieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LocationService>(context, listen: false).ensureInitialized();
      }
    });
  }

  Future<void> _loadOrRefreshPinTiers() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final savedTs = prefs.getInt(_kPinTiersTimestampKey) ?? 0;
    final ageHours = (now - savedTs) / (1000 * 60 * 60);

    if (ageHours < _kPinRefreshHours) {
      // Load saved tiers
      final raw = prefs.getString(_kPinTiersKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = <String, TokenTier>{};
        decoded.forEach((id, tierName) {
          loaded[id] = _tierFromName(tierName as String);
        });
        if (mounted) {
          setState(() => _pinTiers = loaded);
          _updateMarkers();
        }
        return;
      }
    }

    // Generate fresh random tiers
    await _generateAndSavePinTiers(prefs);
  }

  Future<void> _generateAndSavePinTiers(SharedPreferences prefs) async {
    final landmarkService = Provider.of<LandmarkService>(context, listen: false);
    final rng = Random();
    final newTiers = <String, TokenTier>{};
    for (final lm in landmarkService.landmarks) {
      newTiers[lm.id] = _rollPinTier(rng);
    }
    final encoded = jsonEncode(
      newTiers.map((id, tier) => MapEntry(id, _tierToName(tier))),
    );
    await prefs.setString(_kPinTiersKey, encoded);
    await prefs.setInt(_kPinTiersTimestampKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) {
      setState(() => _pinTiers = newTiers);
      _updateMarkers();
    }
  }

  String _tierToName(TokenTier t) {
    switch (t) {
      case TokenTier.silver: return 'silver';
      case TokenTier.gold: return 'gold';
      case TokenTier.platinum: return 'platinum';
      default: return 'bronze';
    }
  }

  TokenTier _tierFromName(String name) {
    switch (name) {
      case 'silver': return TokenTier.silver;
      case 'gold': return TokenTier.gold;
      case 'platinum': return TokenTier.platinum;
      default: return TokenTier.bronze;
    }
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
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) {
        _isUpdatingMarkers = false;
        return;
      }
      final landmarkService = Provider.of<LandmarkService>(context, listen: false);
      final collectionService = Provider.of<CollectionService>(context, listen: false);
      final Set<Marker> newMarkers;
      if (_currentZoom >= 10.0) {
        newMarkers = _buildIndividualMarkers(landmarkService, collectionService);
      } else {
        newMarkers = await _buildClusteredMarkers(landmarkService, collectionService);
      }
      if (mounted) setState(() => _markers = newMarkers);
      _isUpdatingMarkers = false;
    });
  }

  Marker _buildSingleMarker(Landmark landmark, CollectionService cs) {
    final isCollected = cs.getToken(landmark.id) != null;
    final pinTier = _pinTiers[landmark.id] ?? TokenTier.bronze;
    String pinType;
    switch (pinTier) {
      case TokenTier.silver:   pinType = 'silver'; break;
      case TokenTier.gold:     pinType = 'gold';   break;
      case TokenTier.platinum: pinType = 'platin'; break;
      default:                 pinType = 'bronze';
    }
    final markerIcon = isCollected
        ? (_markerIconsGray[pinType] ?? BitmapDescriptor.defaultMarker)
        : (_markerIcons[pinType] ?? BitmapDescriptor.defaultMarker);
    return Marker(
      markerId: MarkerId(landmark.id),
      position: LatLng(landmark.latitude, landmark.longitude),
      icon: markerIcon,
      alpha: isCollected ? 0.7 : 1.0,
      onTap: () => _showLandmarkDetails(landmark, pinTier),
      infoWindow: InfoWindow.noText,
    );
  }

  Set<Marker> _buildIndividualMarkers(LandmarkService ls, CollectionService cs) =>
      ls.landmarks.map((lm) => _buildSingleMarker(lm, cs)).toSet();

  Future<Set<Marker>> _buildClusteredMarkers(
      LandmarkService ls, CollectionService cs) async {
    final clusters = _computeSetClusters(ls.landmarks);
    final markers = <Marker>{};
    for (final cluster in clusters) {
      if (cluster.landmarks.length == 1) {
        markers.add(_buildSingleMarker(cluster.landmarks[0], cs));
      } else {
        // Determine dominant tier for pin color
        final pinType = _dominantPinType(cluster.landmarks);
        final cacheKey = '${cluster.landmarks.length}_${cluster.setId}_$pinType';
        _clusterIconCache[cacheKey] ??= await _createClusterIcon(
            cluster.landmarks.length, cluster.label, pinType);
        markers.add(Marker(
          markerId: MarkerId('cluster_${cluster.setId}'),
          position: cluster.center,
          icon: _clusterIconCache[cacheKey]!,
          onTap: () => _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.center, _currentZoom + 3.0),
          ),
          infoWindow: InfoWindow.noText,
        ));
      }
    }
    return markers;
  }

  // Group landmarks by their first relatedSetId — only city sets get clustered
  static const _citySets = {'set_hamburg', 'set_dissen', 'set_leipzig'};

  List<_Cluster> _computeSetClusters(List<Landmark> landmarks) {
    final Map<String, _Cluster> bySet = {};
    for (final lm in landmarks) {
      final setId = lm.relatedSetIds.isNotEmpty ? lm.relatedSetIds.first : 'misc';
      // Non-city sets → treat each landmark as its own "cluster" of 1
      final clusterKey = _citySets.contains(setId) ? setId : 'single_${lm.id}';
      if (bySet.containsKey(clusterKey)) {
        bySet[clusterKey]!.landmarks.add(lm);
      } else {
        bySet[clusterKey] = _Cluster(
          setId: clusterKey,
          label: _setLabel(setId),
          center: LatLng(lm.latitude, lm.longitude),
          landmarks: [lm],
        );
      }
    }
    // Recalculate center as average
    return bySet.values.map((c) {
      final avgLat = c.landmarks.map((l) => l.latitude).reduce((a, b) => a + b) /
          c.landmarks.length;
      final avgLng = c.landmarks.map((l) => l.longitude).reduce((a, b) => a + b) /
          c.landmarks.length;
      return _Cluster(
          setId: c.setId,
          label: c.label,
          center: LatLng(avgLat, avgLng),
          landmarks: c.landmarks);
    }).toList();
  }

  String _setLabel(String setId) {
    switch (setId) {
      case 'set_hamburg':  return 'Hamburg';
      case 'set_dissen':   return 'Dissen';
      case 'set_leipzig':  return 'Leipzig';
      case 'set_monuments': return 'Denkmäler';
      default: return setId;
    }
  }

  String _dominantPinType(List<Landmark> landmarks) {
    // Pick highest tier present in the cluster
    int gold = 0, silver = 0;
    for (final lm in landmarks) {
      final t = _pinTiers[lm.id];
      if (t == TokenTier.gold || t == TokenTier.platinum) gold++;
      else if (t == TokenTier.silver) silver++;
    }
    if (gold > 0) return 'gold';
    if (silver > 0) return 'silver';
    return 'bronze';
  }

  Future<BitmapDescriptor> _createClusterIcon(
      int count, String label, String pinType) async {
    // Load the real map pin asset
    final assetPath = {
      'gold':   'assets/images/map_pin_gold.png',
      'silver': 'assets/images/Map_pin_silber.png',
      'platin': 'assets/images/Platin_mappin_platin.png',
      'bronze': 'assets/images/Map_Pin_Bronze.png',
    }[pinType] ?? 'assets/images/Map_Pin_Bronze.png';

    final ByteData assetData = await rootBundle.load(assetPath);
    final ui.Codec pinCodec = await ui.instantiateImageCodec(
        assetData.buffer.asUint8List(), targetWidth: 260, targetHeight: 260);
    final ui.Image pinImage = (await pinCodec.getNextFrame()).image;

    const int size = 340;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
        recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // Draw the map pin centered
    final pinSrc =
        Rect.fromLTWH(0, 0, pinImage.width.toDouble(), pinImage.height.toDouble());
    final pinDst = Rect.fromLTWH(
        (size - 240) / 2, (size - 240) / 2, 240, 240);
    canvas.drawImageRect(pinImage, pinSrc, pinDst, Paint());

    // Badge circle in top-right corner
    final badgeCenter = Offset(size * 0.72, size * 0.28);
    canvas.drawCircle(badgeCenter, 42,
        Paint()..color = const Color(0xDD212121));
    canvas.drawCircle(
      badgeCenter, 42,
      Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Count number in badge
    final countPainter = TextPainter(
      text: TextSpan(
          text: '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    countPainter.paint(
        canvas,
        Offset(badgeCenter.dx - countPainter.width / 2,
            badgeCenter.dy - countPainter.height / 2));

    // City label below pin
    final labelPainter = TextPainter(
      text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);
    labelPainter.paint(
        canvas,
        Offset((size - labelPainter.width) / 2, size * 0.80));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: null,
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
      body: Consumer<LocationService>(
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
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                      onMapCreated: _onMapCreated,
                      onCameraMove: (pos) {
                        if ((pos.zoom - _currentZoom).abs() >= 0.4) {
                          _currentZoom = pos.zoom;
                          _clusterIconCache.clear(); // force re-render at new size
                          _updateMarkers();
                        }
                      },
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

  void _showLandmarkDetails(Landmark landmark, TokenTier pinTier) {
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
        pinTier: pinTier,
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
  final TokenTier pinTier;

  const _LandmarkBottomSheet({
    required this.landmark,
    required this.distance,
    required this.collectionService,
    required this.landmarkService,
    required this.cooldownService,
    required this.onCollected,
    required this.pinTier,
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
    final tier = widget.pinTier;
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

  // Distanz in km; <= checkInRadiusKm = innerhalb Sammelbereich
  bool get _isNearby {
    final d = widget.distance;
    if (d == null) return false; // kein GPS = nicht sammelbar
    return d <= widget.landmark.checkInRadiusKm;
  }

  Color get _tierColor {
    switch (widget.pinTier) {
      case TokenTier.bronze: return Colors.brown[400]!;
      case TokenTier.silver: return Colors.grey[400]!;
      case TokenTier.gold: return Colors.amber[500]!;
      case TokenTier.platinum: return Colors.cyan[300]!;
    }
  }

  String get _cooldownLabel {
    final tier = widget.pinTier;
    if (tier == TokenTier.platinum) return 'Einmalig – nicht mehr sammelbar';
    if (_remaining == null) return '';
    return 'Cooldown: ${CooldownService.formatDuration(_remaining!)}';
  }

  void _collect(BuildContext ctx) {
    final authService = Provider.of<AuthService>(ctx, listen: false);
    if (!authService.isLoggedIn) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte melde dich an, um Tokens zu sammeln. Gehe zum Profil-Tab.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final landmark = widget.landmark;
    widget.collectionService.collectTokenAllowDuplicate(
      landmark.id,
      landmark.name,
      landmark.category,
      landmark.pointsReward,
      landmark.relatedSetIds,
      tier: widget.pinTier,
    );
    widget.cooldownService.recordCollection(landmark.id);
    widget.onCollected();
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          'Token gesammelt! +${landmark.pointsReward} Coins (${widget.pinTier.displayName})',
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
    final tier = widget.pinTier;
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

// ── Cluster helper ───────────────────────────────────────────────────────────

class _Cluster {
  final String setId;
  final String label;
  LatLng center;
  List<Landmark> landmarks;

  _Cluster({
    required this.setId,
    required this.label,
    required this.center,
    required this.landmarks,
  });
}
