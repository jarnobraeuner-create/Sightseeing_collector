import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/index.dart';
import '../services/index.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  final Map<String, BitmapDescriptor> _markerIcons = {}; // Bronze, Silver, Gold, Platinum
  final Map<String, BitmapDescriptor> _markerIconsGray = {}; // Graustufen-Versionen
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
    // Dark Mode Style anwenden
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
        
        // Michel (id='4') bekommt silbernen Pin, Chilehaus (id='5') gold, Laeiszhalle (id='3') platin, alle anderen bronze
        String pinType = 'bronze';
        if (landmark.id == '4') {
          pinType = 'silver';
        } else if (landmark.id == '5') {
          pinType = 'gold';
        } else if (landmark.id == '3') {
          pinType = 'platin';
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
                
                if (position == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Standort wird ermittelt...'),
                      ],
                    ),
                  );
                }

                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(position.latitude, position.longitude),
                    zoom: 13.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                );
              },
            ),
    );
  }

  void _showLandmarkDetails(Landmark landmark) {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final collectionService = Provider.of<CollectionService>(context, listen: false);
    final position = locationService.currentPosition;
    
    final distance = position != null
        ? landmark.getDistance(position.latitude, position.longitude)
        : null;
    // TESTMODUS: Distanz-Check deaktiviert - alle Tokens sammelbar
    final token = collectionService.getToken(landmark.id);
    final isCollected = token != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
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
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: landmark.imageUrl.isNotEmpty
                      ? Image.asset(
                          landmark.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Colors.white54,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.location_on,
                            size: 60,
                            color: Colors.amber,
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
                    landmark.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
                if (isCollected)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              landmark.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[300],
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    distance != null
                        ? '${(distance * 1000).toStringAsFixed(0)} m entfernt'
                        : 'Entfernung unbekannt',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[700]!, Colors.amber[500]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${landmark.pointsReward} Punkte',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCollected ? Colors.grey[700] : Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                onPressed: isCollected
                    ? null
                    : () {
                        collectionService.collectToken(
                          landmark.id,
                          landmark.name,
                          landmark.category,
                          landmark.pointsReward,
                          landmark.relatedSetIds,
                          tier: landmark.defaultTier,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Token gesammelt! +${landmark.pointsReward} Punkte (${landmark.defaultTier.displayName})',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        _updateMarkers(); // Update marker color
                      },
                child: Text(
                  isCollected ? 'Bereits gesammelt ✓' : 'Token sammeln',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
