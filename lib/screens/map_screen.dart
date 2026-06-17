import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/event_dialog.dart';
import '../widgets/map_mode_toggle_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _hasCenteredOnUser = false;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  final Map<String, BitmapDescriptor> _markerIconsGray = {};
  bool _isUpdatingMarkers = false;

  // Zoom-based clustering
  double _currentZoom = 13.0;
  final Map<String, BitmapDescriptor> _clusterIconCache = {};

  @override
  void initState() {
    super.initState();
    _loadAllMarkerIcons();
    // LocationService im Hintergrund initialisieren ohne Rendering zu blockieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LocationService>(context, listen: false)
            .ensureInitialized();
      }
    });
  }

  Future<void> _loadAllMarkerIcons() async {
    await Future.wait([
      _loadMarkerIcon('gold', 'assets/images/map_pin_gold.png'),
    ]);
    if (mounted) {
      _markerIcons['event'] = await _createEventMarkerIcon(grayscale: false);
      _markerIconsGray['event'] = await _createEventMarkerIcon(grayscale: true);
    }
    if (mounted) {
      _updateMarkers();
    }
  }

  Future<BitmapDescriptor> _createEventMarkerIcon({required bool grayscale}) async {
    final ByteData assetData = await rootBundle.load('assets/images/map_pin_gold.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      assetData.buffer.asUint8List(),
      targetWidth: 200,
      targetHeight: 200,
    );
    ui.Image pinImage = (await codec.getNextFrame()).image;
    if (grayscale) pinImage = await _convertToGrayscale(pinImage);
    const int size = 260;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
        recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    canvas.drawImageRect(
      pinImage,
      Rect.fromLTWH(0, 0, pinImage.width.toDouble(), pinImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint(),
    );
    if (!grayscale) {
      final badgeCenter = Offset(size * 0.76, size * 0.22);
      canvas.drawCircle(badgeCenter, 38, Paint()..color = const Color(0xFFFFD700));
      canvas.drawCircle(
          badgeCenter,
          38,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0);
      final starPainter = TextPainter(
        text: const TextSpan(text: '⭐', style: TextStyle(fontSize: 30)),
        textDirection: TextDirection.ltr,
      )..layout();
      starPainter.paint(
          canvas,
          Offset(badgeCenter.dx - starPainter.width / 2,
              badgeCenter.dy - starPainter.height / 2));
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(pixels);
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
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final position = locationService.currentPosition;
      if (position != null) {
        _hasCenteredOnUser = true;
        controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    }
    _updateMarkers();
  }

  String _mapStyleJson(bool isDayMode) {
    if (isDayMode) {
      return '''[
  {"elementType":"geometry","stylers":[{"color":"#ebe3cd"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#523735"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f5f1e6"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#c9b2a6"}]},
  {"featureType":"administrative.land_parcel","elementType":"geometry.stroke","stylers":[{"color":"#dcd2be"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#ae9e90"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#93817c"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#a5b076"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#447530"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f1e6"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#fdfcf8"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f8c967"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#e9bc62"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#e98d58"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry.stroke","stylers":[{"color":"#db8555"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#806b63"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"transit.line","elementType":"labels.text.fill","stylers":[{"color":"#8f7d77"}]},
  {"featureType":"transit.line","elementType":"labels.text.stroke","stylers":[{"color":"#ebe3cd"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#dfd2ae"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#b9d3c2"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#92998d"}]}
]''';
    } else {
      return '''[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]''';
    }
  }

  /// Filtert Landmarks nach aktuellem Modus (Tag/Nacht)
  List<Landmark> _filterLandmarksByMode(List<Landmark> landmarks) {
    final mapModeService =
        Provider.of<MapModeService>(context, listen: false);
    return landmarks
        .where((lm) => lm.mode == (mapModeService.isDayMode ? 'day' : 'night'))
        .toList();
  }

  void _updateMarkers() {
    if (!mounted || _isUpdatingMarkers) return;
    _isUpdatingMarkers = true;
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) {
        _isUpdatingMarkers = false;
        return;
      }
      final landmarkService =
          Provider.of<LandmarkService>(context, listen: false);
      final collectionService =
          Provider.of<CollectionService>(context, listen: false);
      final Set<Marker> newMarkers;
      if (_currentZoom >= 10.0) {
        newMarkers =
            _buildIndividualMarkers(landmarkService, collectionService);
      } else {
        newMarkers =
            await _buildClusteredMarkers(landmarkService, collectionService);
      }
      if (mounted) setState(() => _markers = newMarkers);
      _isUpdatingMarkers = false;
    });
  }

  Marker _buildSingleMarker(Landmark landmark, CollectionService cs) {
    final isCollected = cs.getToken(landmark.id) != null;
    if (landmark.category == 'weltwunder') {
      // Spezielles Icon für Weltwunder
      final markerIcon = isCollected
          ? (_markerIconsGray['weltwunder'] ?? BitmapDescriptor.defaultMarker)
          : (_markerIcons['weltwunder'] ?? BitmapDescriptor.defaultMarker);
      return Marker(
        markerId: MarkerId(landmark.id),
        position: LatLng(landmark.latitude, landmark.longitude),
        icon: markerIcon,
        alpha: isCollected ? 0.7 : 1.0,
        onTap: () => _showLandmarkDetails(landmark, null),
        infoWindow: InfoWindow.noText,
      );
    }
    final hasActiveEvent = landmark.eventIds.isNotEmpty &&
        EventService.allEvents
            .any((e) => e.isActive && landmark.eventIds.contains(e.id));
    final pinKey = hasActiveEvent ? 'event' : 'gold';
    final markerIcon = isCollected
        ? (_markerIconsGray[pinKey] ?? BitmapDescriptor.defaultMarker)
        : (_markerIcons[pinKey] ?? BitmapDescriptor.defaultMarker);
    return Marker(
      markerId: MarkerId(landmark.id),
      position: LatLng(landmark.latitude, landmark.longitude),
      icon: markerIcon,
      alpha: isCollected ? 0.7 : 1.0,
      onTap: () => _showLandmarkDetails(landmark, null),
      infoWindow: InfoWindow.noText,
    );
  }

  Set<Marker> _buildIndividualMarkers(
          LandmarkService ls, CollectionService cs) {
    final filtered = _filterLandmarksByMode(ls.landmarks);
    return filtered.map((lm) => _buildSingleMarker(lm, cs)).toSet();
  }

  Future<Set<Marker>> _buildClusteredMarkers(
      LandmarkService ls, CollectionService cs) async {
    final filtered = _filterLandmarksByMode(ls.landmarks);
    final clusters = _computeSetClusters(filtered);
    final markers = <Marker>{};
    for (final cluster in clusters) {
      if (cluster.landmarks.length == 1) {
        markers.add(_buildSingleMarker(cluster.landmarks[0], cs));
      } else {
        // Determine dominant tier for pin color
        final pinType = _dominantPinType(cluster.landmarks);
        final cacheKey =
            '${cluster.landmarks.length}_${cluster.setId}_$pinType';
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
  static const _citySets = {'set_hamburg', 'set_leipzig'};

  List<_Cluster> _computeSetClusters(List<Landmark> landmarks) {
    final Map<String, _Cluster> bySet = {};
    for (final lm in landmarks) {
      final setId =
          lm.relatedSetIds.isNotEmpty ? lm.relatedSetIds.first : 'misc';
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
      final avgLat =
          c.landmarks.map((l) => l.latitude).reduce((a, b) => a + b) /
              c.landmarks.length;
      final avgLng =
          c.landmarks.map((l) => l.longitude).reduce((a, b) => a + b) /
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
      case 'set_hamburg':
        return 'Hamburg';
      case 'set_leipzig':
        return 'Leipzig';
      case 'set_monuments':
        return 'Denkmäler';
      default:
        return setId;
    }
  }

  String _dominantPinType(List<Landmark> landmarks) {
    return 'gold';
  }

  Future<BitmapDescriptor> _createClusterIcon(
      int count, String label, String pinType) async {
    // Load the real map pin asset
    final assetPath = {
          'gold': 'assets/images/map_pin_gold.png',
          'silver': 'assets/images/Map_pin_silber.png',
          'platin': 'assets/images/Platin_mappin_platin.png',
          'bronze': 'assets/images/Map_Pin_Bronze.png',
        }[pinType] ??
        'assets/images/Map_Pin_Bronze.png';

    final ByteData assetData = await rootBundle.load(assetPath);
    final ui.Codec pinCodec = await ui.instantiateImageCodec(
        assetData.buffer.asUint8List(),
        targetWidth: 260,
        targetHeight: 260);
    final ui.Image pinImage = (await pinCodec.getNextFrame()).image;

    const int size = 340;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
        recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

    // Draw the map pin centered
    final pinSrc = Rect.fromLTWH(
        0, 0, pinImage.width.toDouble(), pinImage.height.toDouble());
    final pinDst = Rect.fromLTWH((size - 240) / 2, (size - 240) / 2, 240, 240);
    canvas.drawImageRect(pinImage, pinSrc, pinDst, Paint());

    // Badge circle in top-right corner
    final badgeCenter = Offset(size * 0.72, size * 0.28);
    canvas.drawCircle(
        badgeCenter, 42, Paint()..color = const Color(0xDD212121));
    canvas.drawCircle(
      badgeCenter,
      42,
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
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
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
        canvas, Offset((size - labelPainter.width) / 2, size * 0.80));

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
              final locationService =
                  Provider.of<LocationService>(context, listen: false);
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
      body: Stack(
        children: [
          Consumer2<LocationService, MapModeService>(
            builder: (context, locationService, mapModeService, child) {
              final position = locationService.currentPosition;
              final hasLocation = position != null;

              // Einmalig zur Nutzerposition springen wenn Karte bereit
              if (hasLocation &&
                  !_hasCenteredOnUser &&
                  _mapController != null) {
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
                      Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                    },
                    onMapCreated: _onMapCreated,
                    onCameraMove: (pos) {
                      if ((pos.zoom - _currentZoom).abs() >= 0.4) {
                        _currentZoom = pos.zoom;
                        _clusterIconCache
                            .clear(); // force re-render at new size
                        _updateMarkers();
                      }
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(53.5500, 10.0000), // Hamburg Fallback
                      zoom: 13.0,
                    ),
                    style: _mapStyleJson(mapModeService.isDayMode),
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
          // ── Event-Icon oben links (außerhalb des GoogleMap-Stacks) ───
          Positioned(
            top: 12 + MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 12,
            child: const _EventMapButton(),
          ),
          // ── Map Mode Toggle Button oben rechts ───
          Positioned(
            top: 12 + MediaQuery.of(context).padding.top + kToolbarHeight,
            right: 12,
            child: MapModeToggleButton(
              onModeChanged: () {
                // Landmarks neu filtern und anzeigen
                _updateMarkers();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLandmarkDetails(Landmark landmark, TokenTier? pinTier) {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final collectionService =
        Provider.of<CollectionService>(context, listen: false);
    final landmarkService =
        Provider.of<LandmarkService>(context, listen: false);
    final cooldownService =
        Provider.of<CooldownService>(context, listen: false);
    final position = locationService.currentPosition;

    final distance = position != null
        ? landmark.getDistance(position.latitude, position.longitude)
        : null;

    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
  final TokenTier? pinTier;

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

class _LandmarkBottomSheetState extends State<_LandmarkBottomSheet>
    with SingleTickerProviderStateMixin {
  late Duration? _remaining;
  bool _canCollect = false;

  // Church two-phase collect
  bool _mainCollected = false; // main token was collected
  bool _churchBonusCollected = false; // default church token was collected too
  bool _eventTokenCollected = false; // event token was collected

  // Fly-away animation
  late final AnimationController _flyCtrl;
  late final Animation<Offset> _flyOffset;
  late final Animation<double> _flyOpacity;

  @override
  void initState() {
    super.initState();
    _refreshCooldown();
    _startTimer();

    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flyOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.5))
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
    _flyOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _flyCtrl.dispose();
    super.dispose();
  }

  void _refreshCooldown() {
    final tier = widget.pinTier;
    final id = widget.landmark.id;
    _canCollect =
        widget.cooldownService.canCollect(id, tier ?? TokenTier.bronze);
    _remaining =
        widget.cooldownService.remainingCooldown(id, tier ?? TokenTier.bronze);
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
    // Dev-Mode: Standortbeschränkung aufheben
    if (Provider.of<DevModeService>(context, listen: false).enabled)
      return true;
    final d = widget.distance;
    if (d == null) return false; // kein GPS = nicht sammelbar
    return d <= widget.landmark.checkInRadiusKm;
  }

  Color get _tierColor {
    switch (widget.pinTier) {
      case TokenTier.bronze:
        return Colors.brown[400]!;
      case TokenTier.silver:
        return Colors.grey[400]!;
      case TokenTier.gold:
        return Colors.amber[500]!;
      case TokenTier.platinum:
        return Colors.cyan[300]!;
      case TokenTier.monumente:
        return Colors.deepPurpleAccent;
      default:
        return Colors.amber[500]!; // Random/unknown tier – gold color
    }
  }

  String get _cooldownLabel {
    final tier = widget.pinTier;
    if (tier == TokenTier.platinum) return 'Einmalig – nicht mehr sammelbar';
    if (tier == TokenTier.monumente)
      return 'Monumente-Tokens sind derzeit nicht verfügbar';
    if (_remaining == null) return '';
    return 'Cooldown: ${CooldownService.formatDuration(_remaining!)}';
  }

  /// Gibt das aktive Event zurück, das für diesen Standort gilt und noch nicht besucht wurde.
  GameEvent? _activeEventForToken() {
    final eventService = Provider.of<EventService>(context, listen: false);
    for (final event in EventService.allEvents) {
      if (!event.isActive) continue;
      if (!event.landmarkIds.contains(widget.landmark.id)) continue;
      if (eventService.hasLandmarkBeenVisited(event.id, widget.landmark.id)) {
        continue;
      }
      return event;
    }
    return null;
  }

  void _collectEventToken(BuildContext ctx) {
    final event = _activeEventForToken()!;
    final landmark = widget.landmark;
    Provider.of<EventService>(ctx, listen: false)
        .recordEventLandmarkCollected(event.id, landmark.id);
    widget.collectionService.collectEventToken(
      landmarkId: landmark.id,
      landmarkName: landmark.name,
      eventId: event.id,
      eventTitle: event.title,
      tokenImageUrl: event.tokenImageUrl,
      latitude: landmark.latitude,
      longitude: landmark.longitude,
      points: event.rewardCoins ~/ event.requiredCount,
    );
    widget.onCollected();
    _flyCtrl.forward().then((_) {
      if (mounted) {
        setState(() {
          _eventTokenCollected = true;
          _flyCtrl.reset();
        });
        if (!widget.landmark.isChurch) {
          Future.microtask(() {
            if (mounted) Navigator.pop(ctx);
          });
        }
      }
    });
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('⭐ Event-Token gesammelt! (${event.title})'),
        backgroundColor: Colors.amber[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TokenTier _rollCollectTier() {
    final roll = Random().nextDouble() * 100;
    if (roll < 0.5) return TokenTier.platinum;  // 0.5%
    if (roll < 3.5) return TokenTier.gold;      // 3%
    if (roll < 18.5) return TokenTier.silver;   // 15%
    return TokenTier.bronze;                     // 81.5%
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
    if (landmark.category == 'weltwunder') {
      widget.collectionService.collectTokenAllowDuplicate(
        landmark.id,
        landmark.name,
        landmark.category,
        landmark.pointsReward,
        landmark.relatedSetIds,
        tier: null,
        landmark: landmark,
      );
      widget.cooldownService.recordCollection(landmark.id);
      widget.onCollected();
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content:
              Text('Weltwunder gesammelt! +${landmark.pointsReward} Coins'),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final rolledTier = _rollCollectTier();
    final awardedCoins = rolledTier.pointValue;
    widget.collectionService.collectTokenAllowDuplicate(
      landmark.id,
      landmark.name,
      landmark.category,
      landmark.pointsReward,
      landmark.relatedSetIds,
      tier: rolledTier,
    );
    widget.cooldownService.recordCollection(landmark.id);
    widget.onCollected();

    if (landmark.isChurch) {
      // Fly-away animation, then show church bonus token
      _flyCtrl.forward().then((_) {
        if (mounted) {
          setState(() {
            _mainCollected = true;
            _flyCtrl.reset();
          });
        }
      });
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Token gesammelt! +$awardedCoins Coins (${rolledTier.displayName})',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final hasEventToken = _activeEventForToken() != null;
      if (hasEventToken) {
        _flyCtrl.forward().then((_) {
          if (mounted) {
            setState(() {
              _mainCollected = true;
              _flyCtrl.reset();
            });
          }
        });
      } else {
        Navigator.pop(ctx);
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Token gesammelt! +$awardedCoins Coins (${rolledTier.displayName})',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _collectChurchBonus(BuildContext ctx) {
    final landmark = widget.landmark;
    final churchId = '${landmark.id}_church';

    // Church bonus: Bronze-Wert, darf bei späteren Besuchen erneut gesammelt werden
    widget.collectionService.collectTokenAllowDuplicate(
      churchId,
      '${landmark.name} – Kirchensegen',
      landmark.category,
      50,
      landmark.relatedSetIds,
      tier: TokenTier.bronze,
    );
    widget.onCollected();

    // Event-Service benachrichtigen
    Provider.of<EventService>(ctx, listen: false)
        .recordChurchCollected(landmark.id);

    _flyCtrl.forward().then((_) {
      if (mounted) {
        setState(() {
          _churchBonusCollected = true;
          _flyCtrl.reset();
        });
      }
    });
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Kirchensegen erhalten! +10 Coins ⛪'),
        backgroundColor: Colors.teal,
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
    final isEverCollected =
        widget.cooldownService.wasEverCollected(landmark.id);
    final isFirstCollection = !isEverCollected;
    final tier = widget.pinTier;
    final isPlatinum = (tier ?? TokenTier.bronze) == TokenTier.platinum;
    final isMonumente = (tier ?? TokenTier.bronze) == TokenTier.monumente;
    final activeEvent = _activeEventForToken();
    final isEventPhase = _mainCollected && activeEvent != null && !_eventTokenCollected;
    final isChurchPhase = _mainCollected && !isEventPhase && widget.landmark.isChurch;

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
          // Token Image (with fly-away animation)
          Center(
            child: SlideTransition(
              position: _flyOffset,
              child: FadeTransition(
                opacity: _flyOpacity,
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
                    child: _mainCollected
                        // Phase 2: show church default token
                        ? Image.asset(
                            'assets/images/Kirche_default_token.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.church,
                                  size: 60, color: Colors.white54),
                            ),
                          )
                        // Phase 1: show specific landmark token
                        : (landmark.imageUrl.isNotEmpty
                            ? Image.asset(
                                widget.landmarkService.getImageUrlForTier(
                                    landmark.id, tier ?? TokenTier.bronze),
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
                              )),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEventPhase
                      ? '${landmark.name} ⭐'
                      : isChurchPhase
                          ? '⛪ Kirchensegen'
                          : landmark.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              // Tier badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _tierColor, width: 1),
                ),
                child: Text(
                  isEventPhase
                      ? '⭐ Event'
                      : isChurchPhase
                          ? 'Bonus'
                          : (landmark.category == 'weltwunder'
                              ? 'Weltwunder'
                              : '?'),
                  style: TextStyle(
                      color: _tierColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEventPhase
                ? 'Du hast diesen Standort besucht! Sammle jetzt den Event-Token. (${activeEvent.title})'
                : isChurchPhase
                    ? 'Du hast die Kirche besucht! Sammle jetzt den Kirchensegen als Bonus-Token (+50 Coins).'
                    : landmark.description,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  Icon((isPlatinum || isMonumente) ? Icons.lock : Icons.timer,
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
          if (_mainCollected) ...[
            if (isEventPhase) ...[
              // ── Event Token Phase ──
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: Text('Event-Token: ${activeEvent.title}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                        ),
                        onPressed: () => _collectEventToken(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Überspringen',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else if (isChurchPhase) ...[
              // ── Church Bonus Phase ──
              if (_churchBonusCollected) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.tealAccent, size: 26),
                      SizedBox(height: 4),
                      Text('Kirchensegen gesammelt! ⛪',
                          style: TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Schließen',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.church),
                          label: const Text('Kirchensegen +50 🪙'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 6,
                          ),
                          onPressed: () => _collectChurchBonus(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Überspringen',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // All done (non-church, event token just collected or no event)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Schließen',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ] else if (!_isNearby) ...[
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
                      label: Text(
                          isFirstCollection ? 'Sammeln' : 'Erneut sammeln'),
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
                child: Text(
                  isMonumente
                      ? 'Derzeit nicht verfügbar'
                      : (isPlatinum
                          ? 'Einmalig gesammelt ✓'
                          : 'Cooldown aktiv…'),
                ),
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

// ── Event-Map-Button ──────────────────────────────────────────────────────────

class _EventMapButton extends StatefulWidget {
  const _EventMapButton();

  @override
  State<_EventMapButton> createState() => _EventMapButtonState();
}

class _EventMapButtonState extends State<_EventMapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventService>(
      builder: (context, eventService, _) {
        final hasPending = eventService.pendingReward() != null;
        final activeEvents = EventService.allEvents
            .where((e) => e.isActive)
            .toList();
        final firstEvent = activeEvents.isNotEmpty ? activeEvents.first : null;
        final count =
            firstEvent != null ? eventService.collectedCount(firstEvent.id) : 0;
        final required = firstEvent?.requiredCount ?? 1;
        final progress = (count / required).clamp(0.0, 1.0);

        final glowColor = hasPending ? Colors.amber : const Color(0xFF9B59B6);

        return AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final glow = hasPending
                ? 0.5 + _pulse.value * 0.5
                : 0.25 + _pulse.value * 0.2;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showDialog<void>(
                context: context,
                useRootNavigator: true,
                builder: (_) => const EventDialog(),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: glow * 0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: hasPending
                            ? [const Color(0xFF3D2000), const Color(0xFF1A1A2E)]
                            : [
                                const Color(0xFF2D0A4E),
                                const Color(0xFF1A1A2E)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular progress ring around icon
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.5,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  hasPending
                                      ? Colors.amber
                                      : const Color(0xFF9B59B6),
                                ),
                              ),
                              Text(
                                hasPending ? '🎁' : '🏆',
                                style: const TextStyle(fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasPending ? 'Belohnung!' : 'Events',
                              style: TextStyle(
                                color: hasPending ? Colors.amber : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              '$count / $required',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        if (hasPending) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.amber
                                  .withValues(alpha: 0.5 + _pulse.value * 0.5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber
                                      .withValues(alpha: _pulse.value * 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
