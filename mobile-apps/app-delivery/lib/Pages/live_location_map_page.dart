import 'dart:async';
import 'dart:typed_data'; // For custom marker image loading
import 'dart:ui' as ui; // Added for image decoding
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For custom marker image loading
import 'package:geolocator/geolocator.dart' as geo; // Added prefix for geolocator
// import 'package:mapbox_gl/mapbox_gl.dart'; // Old import
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb; // New import
import 'package:permission_handler/permission_handler.dart';
// flutter_polyline_points is removed, Mapbox Directions API will be used later.
// import 'package:flutter_polyline_points/flutter_polyline_points.dart'; 
import 'package:http/http.dart' as http; // For Mapbox Directions API
import 'dart:convert'; // For Mapbox Directions API


class LiveLocationMapPage extends StatefulWidget {
  const LiveLocationMapPage({Key? key}) : super(key: key);

  static const String routeName = '/live_location_map';

  @override
  State<LiveLocationMapPage> createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> with SingleTickerProviderStateMixin {
  mb.MapboxMap? _mapboxMap; // Renamed from _mapboxController and changed type
  StreamSubscription<geo.Position>? _positionStreamSubscription; // Used geo.Position

  // Storing lat/lng directly, will form mb.Position or mb.Point as needed
  double? _currentLatitude;
  double? _currentLongitude;
  double? _animatedLatitude;
  double? _animatedLongitude;

  // For PointAnnotations (formerly Symbols)
  mb.PointAnnotationManager? _pointAnnotationManager;
  mb.PointAnnotation? _currentLocationAnnotation;
  static const String CURRENT_LOCATION_ICON_ID = "current-location-icon";
  Uint8List? _currentLocationIconBytes;
  int? _currentLocationIconWidth;
  int? _currentLocationIconHeight;


  AnimationController? _markerAnimationController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;

  bool _isRequestingPermission = false;
  bool _locationPermissionGranted = false;
  bool _backgroundLocationPermissionGranted = false;
  bool _locationServicesEnabled = false;
  bool _mapReady = false;

  // Access token is set globally in main.dart via MapboxOptions.setAccessToken()
  // final String _mapboxAccessToken = 'pk.eyJ1IjoiZHVrZXBhbiIsImEiOiJjbWI3NzdkM2YwMWxyMmtyMWl3a3BoaHMxIn0.m2NX96ioOrsJnz6YNpNd5w';
  final String _mapboxStyleString = mb.MapboxStyles.MAPBOX_STREETS; // Used mb.MapboxStyles

  // Initial camera position values
  final double _initialLatitude = 37.42796133580664;
  final double _initialLongitude = -122.085749655962;
  final double _initialMapboxZoom = 14.0;

  // For Mapbox polylines (using GeoJSON layers)
  static const String ROUTE_SOURCE_ID = "live-route-source";
  static const String ROUTE_LAYER_ID = "live-route-layer";
  List<List<double>>? _routeCoordinates; // Store as list of [lng, lat] pairs


  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _markerAnimationController!.addListener(() {
      if (_latAnimation != null && _lngAnimation != null && mounted && _mapboxMap != null && _mapReady) {
        _animatedLatitude = _latAnimation!.value;
        _animatedLongitude = _lngAnimation!.value;
        if (_animatedLatitude != null && _animatedLongitude != null) {
          _updateOrAddCurrentLocationAnnotation();
        }
      }
    });
    _loadMarkerImage();
    _initializeLocationTracking();
  }

  Future<void> _loadMarkerImage() async {
    try {
      // Using a generic marker for now, same as delivery page for consistency
      final ByteData byteData = await rootBundle.load('images/map_pin.png'); 
      _currentLocationIconBytes = byteData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(_currentLocationIconBytes!);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _currentLocationIconWidth = frameInfo.image.width;
      _currentLocationIconHeight = frameInfo.image.height;

      if (_mapboxMap != null && _mapReady) {
        await _addImageToMapStyle();
      }
    } catch (e) {
      print("Error loading current location marker image: $e");
    }
  }

  Future<void> _addImageToMapStyle() async {
    if (_mapboxMap == null || _currentLocationIconBytes == null || _currentLocationIconWidth == null || _currentLocationIconHeight == null) return;
    try {
        await _mapboxMap!.style.addStyleImage(
            CURRENT_LOCATION_ICON_ID,
            1.0, // scale, not sdf. Sdf is next.
            mb.MbxImage(width: _currentLocationIconWidth!, height: _currentLocationIconHeight!, data: _currentLocationIconBytes!),
            false, // sdf
            <mb.ImageStretches>[], // stretchX - explicitly typed empty list
            <mb.ImageStretches>[], // stretchY - explicitly typed empty list
            null // content
            );
    } catch (e) {
        print("Error adding image to map style: $e");
    }
  }


  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _markerAnimationController?.dispose();
    // _mapboxMap?.dispose(); // MapWidget handles its own controller lifecycle
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;
    PermissionStatus statusWhenInUse = await Permission.locationWhenInUse.status;
    if (statusWhenInUse.isDenied) {
      statusWhenInUse = await Permission.locationWhenInUse.request();
    }
    if (mounted) setState(() => _locationPermissionGranted = statusWhenInUse.isGranted);

    if (statusWhenInUse.isGranted) {
      PermissionStatus statusAlways = await Permission.locationAlways.status;
      if (statusAlways.isDenied) statusAlways = await Permission.locationAlways.request();
      if (mounted) setState(() => _backgroundLocationPermissionGranted = statusAlways.isGranted);
      if (statusAlways.isPermanentlyDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Background location permission is permanently denied. Please enable it in app settings for full functionality.'),
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        ));
      }
    }
    if (statusWhenInUse.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location permission (when in use) is permanently denied. Please enable it in app settings.'),
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ));
    }
    _isRequestingPermission = false;
  }

  Future<void> _checkLocationServices() async {
    _locationServicesEnabled = await geo.Geolocator.isLocationServiceEnabled(); // Used geo.
    if (!_locationServicesEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable them.'))
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _initializeLocationTracking() async {
    await _requestLocationPermission();
    await _checkLocationServices();
    if (!_locationPermissionGranted || !_locationServicesEnabled) {
      if (mounted) setState(() {});
      return;
    }
    try {
      geo.Position initialPosition = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high); // Used geo.
      if (mounted) {
        _currentLatitude = initialPosition.latitude;
        _currentLongitude = initialPosition.longitude;
        _animatedLatitude = _currentLatitude;
        _animatedLongitude = _currentLongitude;
        
        if (_mapboxMap != null && _mapReady && _currentLatitude != null && _currentLongitude != null) {
          _animateCameraToPosition(_currentLatitude!, _currentLongitude!);
          _updateOrAddCurrentLocationAnnotation();
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error getting initial location: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting initial location: ${e.toString()}')));
    }

    final geo.LocationSettings locationSettings = geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 5); // Used geo.
    _positionStreamSubscription = geo.Geolocator.getPositionStream(locationSettings: locationSettings).listen((geo.Position position) { // Used geo.
      if (mounted) {
        final newLat = position.latitude;
        final newLng = position.longitude;

        if (_animatedLatitude != null && _animatedLongitude != null && _currentLatitude != null && _currentLongitude != null) {
          if ((newLat - _currentLatitude!).abs() > 0.00001 ||
              (newLng - _currentLongitude!).abs() > 0.00001) {
            _latAnimation = Tween<double>(begin: _animatedLatitude!, end: newLat).animate(_markerAnimationController!);
            _lngAnimation = Tween<double>(begin: _animatedLongitude!, end: newLng).animate(_markerAnimationController!);
            _markerAnimationController!.reset();
            _markerAnimationController!.forward();
          } else {
             // No significant movement, just update internal state
            _animatedLatitude = newLat;
            _animatedLongitude = newLng;
            // Annotation is updated via animation listener or if no animation, directly
            if (!_markerAnimationController!.isAnimating && _mapReady) {
                 _updateOrAddCurrentLocationAnnotation();
            }
          }
        } else { // First update or if previous animated positions were null
          _animatedLatitude = newLat;
          _animatedLongitude = newLng;
           if (_mapboxMap != null && _mapReady && _animatedLatitude != null && _animatedLongitude != null) {
             _updateOrAddCurrentLocationAnnotation();
            _animateCameraToPosition(newLat, newLng);
          }
        }
        _currentLatitude = newLat;
        _currentLongitude = newLng;
        if (mounted) setState(() {}); // To update any UI dependent on _currentLat/Lng if any in future
      }
    }, onError: (error) {
      print("Error in location stream: $error");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error in location stream: ${error.toString()}')));
    });
  }

  // Replaced _loadSymbolImageFromAsset and _addNetworkImageToMap, using _addImageToMapStyle
  // for local assets. Network images would be similar if needed.

  Future<void> _updateOrAddCurrentLocationAnnotation() async {
    if (_mapboxMap == null || !_mapReady || _pointAnnotationManager == null || _animatedLatitude == null || _animatedLongitude == null) return;
    if (_currentLocationIconBytes == null) {
        print("Current location icon bytes not loaded yet.");
        return;
    }

    final point = mb.Point(coordinates: mb.Position(_animatedLongitude!, _animatedLatitude!));
    final options = mb.PointAnnotationOptions(
      geometry: point,
      iconImage: CURRENT_LOCATION_ICON_ID, // Use the ID of the loaded image
      iconSize: 1.0, // Adjust as needed
    );

    if (_currentLocationAnnotation == null) {
      _currentLocationAnnotation = await _pointAnnotationManager!.create(options);
    } else {
      // Update existing annotation
      _currentLocationAnnotation!.geometry = point; // Update geometry
      await _pointAnnotationManager!.update(_currentLocationAnnotation!);
    }
  }
  
  Future<void> _getRouteAndDrawPolylinesMapbox({double? destLat, double? destLng}) async {
    if (_currentLatitude == null || _currentLongitude == null || _mapboxMap == null || !_mapReady) return;
    if (destLat == null || destLng == null) {
        print("Destination for route not provided");
        return;
    }
    
    final String? accessToken = await mb.MapboxOptions.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
        print("Mapbox Access Token is not set globally.");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mapbox Access Token not configured.')));
        return;
    }

    final String directionsUrl = 
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${_currentLongitude},${_currentLatitude};'
        '${destLng},${destLat}'
        '?alternatives=false&geometries=geojson&overview=full&steps=false'
        '&access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['routes'] != null && responseBody['routes'].isNotEmpty) {
          final List<dynamic> coordinates = responseBody['routes'][0]['geometry']['coordinates'];
          // Store coordinates for drawing
          _routeCoordinates = coordinates.map((coord) => [coord[0] as double, coord[1] as double]).toList();
          
          if (mounted) {
            setState(() {}); // Trigger rebuild to draw route or update UI
            _updateMapRouteLine(); // Call method to draw/update the layer
             _animateCameraToFitRoute(); // Adjust camera to fit route
          }

        } else {
          print('Mapbox Directions API: No routes found. ${responseBody['message']}');
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error drawing route: ${responseBody['message'] ?? "No routes found"}')));
        }
      } else {
        print('Mapbox Directions API Error: ${response.statusCode} ${response.body}');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching route from Mapbox.')));
      }
    } catch (e) {
      print('Error with Mapbox Directions API: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error fetching route.')));
    }
  }
  
  Future<void> _updateMapRouteLine() async {
    if (!_mapReady || _mapboxMap == null || !mounted) return;
    if (_routeCoordinates == null || _routeCoordinates!.isEmpty) {
        // Optionally remove existing route if coordinates are cleared
        if (await _mapboxMap!.style.styleLayerExists(ROUTE_LAYER_ID)) {
            await _mapboxMap!.style.removeStyleLayer(ROUTE_LAYER_ID);
        }
        if (await _mapboxMap!.style.styleSourceExists(ROUTE_SOURCE_ID)) {
            await _mapboxMap!.style.removeStyleSource(ROUTE_SOURCE_ID);
        }
        return;
    }

    try {
      // Remove old layer and source first if they exist
      if (await _mapboxMap!.style.styleLayerExists(ROUTE_LAYER_ID)) {
        await _mapboxMap!.style.removeStyleLayer(ROUTE_LAYER_ID);
      }
      if (await _mapboxMap!.style.styleSourceExists(ROUTE_SOURCE_ID)) {
        await _mapboxMap!.style.removeStyleSource(ROUTE_SOURCE_ID);
      }

      // Add new source
      await _mapboxMap!.style.addSource(mb.GeoJsonSource(
        id: ROUTE_SOURCE_ID,
        data: json.encode({
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': _routeCoordinates,
          }
        }),
      ));

      // Add new layer
      await _mapboxMap!.style.addLayer(mb.LineLayer(
        id: ROUTE_LAYER_ID,
        sourceId: ROUTE_SOURCE_ID,
        lineJoin: mb.LineJoin.ROUND,
        lineCap: mb.LineCap.ROUND,
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
    } catch (e) {
      print("Error updating map route line: $e");
    }
  }


  Future<void> _animateCameraToPosition(double lat, double lng, {double? zoom}) async {
    if (_mapboxMap == null || !_mapReady) return;
    _mapboxMap!.flyTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(lng, lat)),
        zoom: zoom ?? _initialMapboxZoom, // Use provided zoom or default
      ),
      mb.MapAnimationOptions(duration: 800) // milliseconds
    );
  }
  
  void _animateCameraToFitRoute() async {
    if (!_mapReady || _mapboxMap == null || !mounted || _routeCoordinates == null || _routeCoordinates!.isEmpty) return;

    if (_routeCoordinates!.length == 1) {
        _animateCameraToPosition(_routeCoordinates!.first[1], _routeCoordinates!.first[0], zoom: 15);
        return;
    }
    
    double minLat = _routeCoordinates!.first[1];
    double maxLat = _routeCoordinates!.first[1];
    double minLng = _routeCoordinates!.first[0];
    double maxLng = _routeCoordinates!.first[0];

    for (var pointPair in _routeCoordinates!) { // pointPair is [lng, lat]
        if (pointPair[1] < minLat) minLat = pointPair[1];
        if (pointPair[1] > maxLat) maxLat = pointPair[1];
        if (pointPair[0] < minLng) minLng = pointPair[0];
        if (pointPair[0] > maxLng) maxLng = pointPair[0];
    }
    try {
        final cameraOptions = await _mapboxMap!.cameraForCoordinates(
            [
              mb.Point(coordinates: mb.Position(minLng, minLat)),
              mb.Point(coordinates: mb.Position(maxLng, maxLat)),
            ],
            mb.MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), 
            null, 
            null  
        );
        _mapboxMap!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1000));
    } catch (e) {
         print("Error animating camera to route bounds: $e");
         // Fallback: center on current location or destination if route fitting fails
         if (_currentLatitude != null && _currentLongitude != null) {
           _animateCameraToPosition(_currentLatitude!, _currentLongitude!, zoom: 14);
         }
    }
}


  void _onMapCreated(mb.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Create annotation manager for current location marker
    _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    // Add tap listener for annotations if needed (example from DeliveryMapPage)
    // _pointAnnotationManager?.onPointAnnotationClickListener.add((annotation) {
    //   print("Tapped annotation: ${annotation.id}");
    //   // Handle tap, e.g. show info
    // });

    if (_mapReady && _currentLatitude != null && _currentLongitude != null) { // Ensure style is loaded before adding annotations if image relies on it
        _updateOrAddCurrentLocationAnnotation();
        _animateCameraToPosition(_currentLatitude!, _currentLongitude!);
    }
    print('LiveLocationMapPage: Map created.');
  }

  void _onStyleLoadedCallback(mb.StyleLoadedEventData eventData) async { // Matched type from MapWidget
    print('LiveLocationMapPage: Map style loaded.');
    setState(() {
      _mapReady = true;
    });
    await _addImageToMapStyle(); // Add custom marker image to the map style

    // Now it's safe to add annotations and layers
    if (_currentLatitude != null && _currentLongitude != null) {
      _updateOrAddCurrentLocationAnnotation();
    }
    if (_routeCoordinates != null && _routeCoordinates!.isNotEmpty) {
        _updateMapRouteLine();
    }
  }

  // _onSymbolTapped is replaced by PointAnnotationManager's click listener setup if needed

  @override
  Widget build(BuildContext context) {
    mb.CameraOptions initialCameraOptions;
    if (_currentLatitude != null && _currentLongitude != null) {
        initialCameraOptions = mb.CameraOptions(
            center: mb.Point(coordinates: mb.Position(_currentLongitude!, _currentLatitude!)),
            zoom: _initialMapboxZoom
        );
    } else {
        initialCameraOptions = mb.CameraOptions(
            center: mb.Point(coordinates: mb.Position(_initialLongitude, _initialLatitude)),
            zoom: _initialMapboxZoom
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Tracker'), // Simplified title
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Re-initialize Tracking",
            onPressed: () async {
              _positionStreamSubscription?.cancel();
              if (_currentLocationAnnotation != null && _pointAnnotationManager != null) {
                 await _pointAnnotationManager!.delete(_currentLocationAnnotation!); 
                 _currentLocationAnnotation = null;
              }
              _routeCoordinates = null; // Clear route
              if(mounted) {
                setState(() {});
                _updateMapRouteLine(); // Remove route layer from map
              }
              _initializeLocationTracking();
            },
          ),
          IconButton( // Temp button to test route drawing
            icon: const Icon(Icons.directions),
            tooltip: "Get Route to SF",
            onPressed: () {
                // Example: Get route to a fixed point (e.g., San Francisco downtown)
                _getRouteAndDrawPolylinesMapbox(destLat: 37.7749, destLng: -122.4194);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          mb.MapWidget(
            key: const ValueKey("liveLocationMap"), // Added ValueKey
            styleUri: _mapboxStyleString, 
            cameraOptions: initialCameraOptions, // Use CameraOptions
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoadedCallback, // Corrected listener name
            // myLocationEnabled and myLocationTrackingMode are not directly available on MapWidget
            // Location layer needs to be handled manually if custom puck is desired
            // Or use MapboxMap.location.updateSettings for built-in puck (later enhancement)
            // onTap gesture can be wrapped around MapWidget or use specific map event listeners
          ),
          if (!_locationPermissionGranted || !_locationServicesEnabled)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  !_locationServicesEnabled
                      ? 'Location services are disabled. Please enable them to track your location.'
                      : !_locationPermissionGranted
                          ? 'Location permission (when in use) denied. Please grant permission to track your location.'
                          : '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_locationPermissionGranted && !_backgroundLocationPermissionGranted && _locationServicesEnabled)
             Positioned(
              top: _locationServicesEnabled && _locationPermissionGranted ? 60 : 0, // Adjust position if needed
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange.withOpacity(0.8),
                padding: const EdgeInsets.all(12.0),
                child: const Text(
                  'Background location permission not granted. Tracking may be limited. Grant \'Allow all the time\' for full functionality.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLatitude != null && _currentLongitude != null && _mapboxMap != null && _mapReady) {
            _animateCameraToPosition(_currentLatitude!, _currentLongitude!);
          } else {
            _initializeLocationTracking(); // Re-initialize if something is not ready
          }
        },
        child: const Icon(Icons.my_location),
        tooltip: "Center on my location",
      ),
    );
  }
} 