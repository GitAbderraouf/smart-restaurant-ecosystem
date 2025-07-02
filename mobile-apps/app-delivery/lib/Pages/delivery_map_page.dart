import 'dart:async';
import 'dart:convert'; // For jsonDecode
import 'dart:typed_data'; // For PointAnnotation image
import 'dart:ui' as ui; // Added for image decoding
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PointAnnotation image
// import 'package:mapbox_gl/mapbox_gl.dart' as mapbox_gl; // Removed old import
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb; // Added prefix for mapbox
import 'package:hungerz_delivery/Pages/new_delivery_tasks_page.dart'; // For DeliveryTask model
import 'package:geolocator/geolocator.dart' as geo; // Added prefix
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
// import 'package:share_plus/share_plus.dart'; // REMOVE THIS LINE

// Firebase imports
// import 'package:firebase_core/firebase_core.dart'; // Already initialized in main
import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // Will use Mapbox Directions
// import 'package:hungerz_delivery/map_utils.dart'; // For Google API key, no longer needed here

// Enum for Mapbox travel modes - can be expanded
enum MapboxTravelMode { driving, cycling, walking }

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String? maneuverType;
  final String? maneuverModifier;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuverType,
    this.maneuverModifier,
  });
}

class RouteInfo {
  final MapboxTravelMode mode;
  // final List<mapbox_gl.LatLng> points; // Old: mapbox_gl.LatLng
  final List<List<double>> points; // New: GeoJSON coordinate pairs [lng, lat]
  final String? durationText;
  final String? distanceText;
  final double? totalDurationSeconds; // Added for arrival time calculation
  final List<RouteStep> steps; // Added to store maneuver steps

  RouteInfo(this.mode, this.points, this.durationText, this.distanceText, this.totalDurationSeconds, this.steps);
}

class DeliveryMapPage extends StatefulWidget {
  final DeliveryTask task;
  const DeliveryMapPage({Key? key, required this.task}) : super(key: key);

  static const String routeName = '/delivery_map';

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> with SingleTickerProviderStateMixin {
  mb.MapboxMap? _mapboxMapController; // New controller type
  // String _mapboxAccessToken = "YOUR_PK_TOKEN"; // Removed, token is set globally in main.dart
  String _styleUri = mb.MapboxStyles.MAPBOX_STREETS; // Using official Style enum

  StreamSubscription<geo.Position>? _positionStreamSubscription; // Used geo.Position
  
  // For locations, we'll often use Point.fromJson({'type': 'Point', 'coordinates': [longitude, latitude]})
  // Or store LatLng-like objects and convert them. For now, let's keep track of raw lat/lng.
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _animatedPickupLatitude;
  double? _animatedPickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;

  // Annotation managers for markers
  mb.PointAnnotationManager? _pickupPointAnnotationManager;
  mb.PointAnnotation? _pickupAnnotation;
  mb.PointAnnotationManager? _destinationPointAnnotationManager;
  mb.PointAnnotation? _destinationAnnotation;

  // For polylines (routes)
  static const String ROUTE_SOURCE_ID = "route-source";
  static const String ROUTE_LAYER_ID = "route-layer";

  List<RouteInfo> _routeOptions = [];
  RouteInfo? _selectedRoute;

  AnimationController? _symbolAnimationController; 
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;

  bool _isRequestingPermission = false;
  bool _mapReady = false; 
  bool _isJourneyStarted = false; // Added to track journey state
  String? _currentManeuverInstruction;
  RouteStep? _nextManeuverStep; // New: Store the full next step for icon logic
  DateTime? _estimatedArrivalTime; // For displaying ETA
  bool _isSoundEnabled = true; // For sound toggle
  double? _currentSpeedKmh; // For speedometer
  double? _currentBearing; // For camera bearing in navigation
  String? _currentStreetName; // For displaying current street
  DateTime? _lastReverseGeocodeTime; // For throttling street name updates
  bool _isReverseGeocoding = false; // To prevent concurrent reverse geocoding calls
  static const double OFF_ROUTE_THRESHOLD_METERS = 75.0; // 75 meters off-route threshold
  bool _isRecalculatingRoute = false; // To prevent concurrent recalculations

  // Image data for custom markers
  Uint8List? _pickupIconBytes;
  int? _pickupIconWidth;
  int? _pickupIconHeight;
  Uint8List? _destinationIconBytes;
  int? _destinationIconWidth;
  int? _destinationIconHeight;
  static const String PICKUP_ICON_IMAGE_ID = "pickup-icon";
  static const String DESTINATION_ICON_IMAGE_ID = "destination-icon";


  @override
  void initState() {
    super.initState();
    if (widget.task.customerLocation != null) {
      _destinationLatitude = widget.task.customerLocation!.latitude;
      _destinationLongitude = widget.task.customerLocation!.longitude;
    }
    
    _loadMarkerImages(); // Load custom marker images
    _initializeLocationTracking(); 

    _symbolAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700), 
      vsync: this,
    );

    _symbolAnimationController!.addListener(() {
      if (_latAnimation != null && _lngAnimation != null && mounted && _mapReady) {
        _animatedPickupLatitude = _latAnimation!.value;
        _animatedPickupLongitude = _lngAnimation!.value;
        _updateOrAddPickupAnnotation(); 
      }
    });
  }

  Future<void> _loadMarkerImages() async {
    try {
      final ByteData pickupByteData = await rootBundle.load('images/deliveryman.png');
      _pickupIconBytes = pickupByteData.buffer.asUint8List();
      final ui.Codec pickupCodec = await ui.instantiateImageCodec(_pickupIconBytes!);
      final ui.FrameInfo pickupFrameInfo = await pickupCodec.getNextFrame();
      _pickupIconWidth = pickupFrameInfo.image.width;
      _pickupIconHeight = pickupFrameInfo.image.height;

      final ByteData destinationByteData = await rootBundle.load('images/map_pin.png');
      _destinationIconBytes = destinationByteData.buffer.asUint8List();
      final ui.Codec destinationCodec = await ui.instantiateImageCodec(_destinationIconBytes!);
      final ui.FrameInfo destinationFrameInfo = await destinationCodec.getNextFrame();
      _destinationIconWidth = destinationFrameInfo.image.width;
      _destinationIconHeight = destinationFrameInfo.image.height;

      // If map is already created and style loaded, add images
      if (_mapboxMapController != null && _mapReady) {
        await _addImagesToMapStyle();
      }
    } catch (e) {
      print("Error loading marker images: $e");
    }
  }

  Future<void> _addImagesToMapStyle() async {
    if (_mapboxMapController == null) return;
    if (_pickupIconBytes != null && _pickupIconWidth != null && _pickupIconHeight != null) {
      // Corrected MbxImage constructor
      await _mapboxMapController!.style.addStyleImage(PICKUP_ICON_IMAGE_ID, 1.0, mb.MbxImage(width: _pickupIconWidth!, height: _pickupIconHeight!, data: _pickupIconBytes!), false, [], [], null);
    }
    if (_destinationIconBytes != null && _destinationIconWidth != null && _destinationIconHeight != null) {
      // Corrected MbxImage constructor
      await _mapboxMapController!.style.addStyleImage(DESTINATION_ICON_IMAGE_ID, 1.0, mb.MbxImage(width: _destinationIconWidth!, height: _destinationIconHeight!, data: _destinationIconBytes!), false, [], [], null);
    }
  }


  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _symbolAnimationController?.dispose(); 
    // _mapboxMapController?.dispose(); // MapWidget handles its own controller lifecycle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine initial camera target
    mb.Point? initialCenterPoint;
    double initialZoom = 2.0;

    if (_pickupLatitude != null && _pickupLongitude != null) {
      initialCenterPoint = mb.Point(coordinates: mb.Position(_pickupLongitude!, _pickupLatitude!));
      initialZoom = 14.0;
    } else if (_destinationLatitude != null && _destinationLongitude != null) {
      initialCenterPoint = mb.Point(coordinates: mb.Position(_destinationLongitude!, _destinationLatitude!));
      initialZoom = 14.0;
    } else {
      initialCenterPoint = mb.Point(coordinates: mb.Position(0,0)); // Default to (0,0)
    }

    return Scaffold(
      // Conditionally hide AppBar if journey has started
      appBar: _isJourneyStarted 
        ? null 
        : AppBar(
            title: Text(
               _selectedRoute?.durationText != null 
                    ? "Order #${widget.task.orderNumber} (ETA: ${_selectedRoute!.durationText})" 
                  : "Order #${widget.task.orderNumber} (ETA: Fetching...)"
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location),
                tooltip: "Recenter Map",
                onPressed: _isJourneyStarted ? _moveCameraToNavigationPerspective : _moveCameraToFitRoute,
              ),
            ],
          ),
      body: Stack( 
        children: [
          mb.MapWidget(
            key: ValueKey("deliveryMap"),
            styleUri: _styleUri,
            cameraOptions: mb.CameraOptions(
              center: initialCenterPoint,
              zoom: initialZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded, 
          ),
          if (_isJourneyStarted && _selectedRoute != null) _buildManeuverPanel(),
          if (_isJourneyStarted && _selectedRoute != null) _buildNavigationInfoPanel(),
          if (_isJourneyStarted) _buildMapControlsOverlay(), // Add map controls
          if (!_isJourneyStarted && _selectedRoute != null) _buildRoutePreviewPanel(),
        ],
      ),
      floatingActionButton: (_selectedRoute == null && !_isJourneyStarted && _pickupLatitude != null && _pickupLongitude != null && _destinationLatitude != null && _destinationLongitude != null) 
        ? FloatingActionButton.extended(
            onPressed: () {
                if (_selectedRoute == null) {
                  _fetchAllRoutesAndDrawSelected();
                } else {
                  _fetchAllRoutesAndDrawSelected(); 
                }
            },
            label: Text(_selectedRoute == null ? 'Show Route' : 'Recalculate'),
            icon: Icon(_selectedRoute == null ? Icons.directions_rounded : Icons.refresh_rounded ),
            backgroundColor: Theme.of(context).primaryColor,
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRoutePreviewPanel() {
    if (_selectedRoute == null) return SizedBox.shrink();

    String etaString = _selectedRoute!.durationText ?? "-- min";
    String distanceString = _selectedRoute!.distanceText ?? "-- km";

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Card(
        margin: EdgeInsets.all(12.0),
        elevation: 8.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$etaString (${distanceString})",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
              ),
              SizedBox(height: 4),
              Text(
                "Fastest route, considering current traffic.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow_rounded),
                    label: Text("Start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _startJourneyWithMapbox,
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.add_road_rounded),
                    label: Text("Steps"),
                    onPressed: () { 
                      if (_selectedRoute != null && _selectedRoute!.steps.isNotEmpty) {
                        _showRouteStepsDialog(_selectedRoute!.steps);
                      } else {
                        _showCustomSnackBar(context, 'No steps available for this route.', isError: true);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8), // Add some spacing
              // Optional: Display alternative routes if available directly in preview
              if (_routeOptions.length > 1)
                TextButton.icon(
                  icon: Icon(Icons.alt_route_rounded, color: Theme.of(context).primaryColor),
                  label: Text("Show ${(_routeOptions.length -1)} other route(s)", style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: _showAlternativeRoutesDialog, 
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManeuverPanel() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Card(
        elevation: 4.0,
        color: Theme.of(context).primaryColor.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.navigation_rounded, color: Colors.white, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentManeuverInstruction ?? "Proceed to destination",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  // Placeholder for voice command button from image
                  Icon(Icons.mic, color: Colors.white.withOpacity(0.7), size: 28),
                ],
              ),
              if (_nextManeuverStep != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 42), // Align with text above
                  child: Row(
                    children: [
                      Text("Then", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(_getManeuverIcon(_nextManeuverStep?.maneuverType, _nextManeuverStep?.maneuverModifier), color: Colors.white.withOpacity(0.8), size: 22), 
                      // Consider Text(_nextManeuverStep!.instruction, style: ...) if you want to show text too
                    ],
                  ),
                ),
              // Display current street name if available
              if (_currentStreetName != null && _currentStreetName!.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0), // Adjust padding as needed
                  child: Row(
                    children: [
                      Icon(Icons.signpost_outlined, color: Colors.white.withOpacity(0.7), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentStreetName!,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        ),
      ),
    );
  }

  IconData _getManeuverIcon(String? type, String? modifier) {
    // Default icon
    IconData icon = Icons.arrow_forward_rounded;

    if (type == null) return icon;

    switch (type.toLowerCase()) {
      case 'turn':
      case 'fork':
      case 'off ramp':
      case 'on ramp': // Consider ramp icons if available/distinct
        switch (modifier?.toLowerCase()) {
          case 'uturn':
            icon = Icons.u_turn_left_rounded;
            break;
          case 'sharp right':
            icon = Icons.turn_sharp_right_rounded;
            break;
          case 'right':
            icon = Icons.turn_right_rounded;
            break;
          case 'slight right':
            icon = Icons.turn_slight_right_rounded;
            break;
          case 'sharp left':
            icon = Icons.turn_sharp_left_rounded;
            break;
          case 'left':
            icon = Icons.turn_left_rounded;
            break;
          case 'slight left':
            icon = Icons.turn_slight_left_rounded;
            break;
        }
        break;
      case 'roundabout':
      case 'rotary':
        // For roundabouts, the exit number is often in the instruction. 
        // Modifier might say "left", "right", "straight" relative to entry.
        // A generic roundabout icon is often sufficient here.
        icon = Icons.roundabout_right_rounded; // Or a more generic one like Icons.settings_ethernet for a circle
        // Could potentially use modifier to pick Icons.roundabout_left vs Icons.roundabout_right
        if (modifier?.toLowerCase().contains('left') ?? false) {
            icon = Icons.roundabout_left_rounded;
        }
        break;
      case 'merge':
        icon = Icons.merge_type_rounded;
        break;
      case 'arrive':
        icon = Icons.flag_rounded;
        break;
      case 'depart':
        icon = Icons.navigation_rounded; // Or a starting flag
        break;
      // Add more cases as needed: continue, new name, etc.
      case 'continue': 
        if (modifier?.toLowerCase().contains('straight') ?? false) {
            icon = Icons.straight_rounded;
        } else if (modifier?.toLowerCase().contains('right') ?? false) {
            icon = Icons.arrow_forward; // Or a slight right arrow if available
        } else if (modifier?.toLowerCase().contains('left') ?? false) {
             icon = Icons.arrow_forward; // Or a slight left arrow if available
        }
        break;
      default:
        icon = Icons.arrow_forward_rounded; // Default for unhandled types
    }
    return icon;
  }

  Widget _buildNavigationInfoPanel() {
    String etaString = _selectedRoute?.durationText ?? "-- min";
    String distanceString = _selectedRoute?.distanceText ?? "-- km";
    String arrivalTimeString = _estimatedArrivalTime != null 
      ? "${_estimatedArrivalTime!.hour.toString().padLeft(2, '0')}:${_estimatedArrivalTime!.minute.toString().padLeft(2, '0')}" 
      : "--:--";

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 10, // Consider safe area
      left: 10,
      right: 10,
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:12.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, size: 28, color: Colors.redAccent),
                padding: EdgeInsets.all(4.0),
                constraints: BoxConstraints(),
                tooltip: "End Navigation",
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _isJourneyStarted = false;
                      _currentManeuverInstruction = null;
                      _estimatedArrivalTime = null;
                      _nextManeuverStep = null; // Clear next step object
                      // Revert camera to overview
                       _mapboxMapController?.flyTo(
                        mb.CameraOptions(pitch: 0.0, zoom: 14.0), // Reset pitch and zoom
                        mb.MapAnimationOptions(duration: 800)
                      );
                      _moveCameraToFitRoute(); // Fit route after ending navigation
                    });
                    _positionStreamSubscription?.pause(); 
                    _showCustomSnackBar(context, 'Navigation ended.', iconData: Icons.stop_circle_outlined);
                  }
                },
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      etaString,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2),
                    Text(
                      "$distanceString • Arrival: $arrivalTimeString",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Placeholder for a potential right-side button like re-center or options
              SizedBox(width: 40), // To balance the X button on the left
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlsOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 120, // Adjust as needed below maneuver panel
      right: 10,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'recenter_map_fab', // Unique heroTag
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.my_location, color: Theme.of(context).primaryColorDark),
            onPressed: _moveCameraToNavigationPerspective,
            tooltip: 'Recenter View',
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'sound_toggle_fab', // Unique heroTag
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(_isSoundEnabled ? Icons.volume_up : Icons.volume_off, color: Theme.of(context).primaryColorDark),
            onPressed: () {
              setState(() {
                _isSoundEnabled = !_isSoundEnabled;
              });
              _showCustomSnackBar(context, _isSoundEnabled ? 'Sound On' : 'Sound Off', iconData: _isSoundEnabled ? Icons.volume_up : Icons.volume_off);
            },
            tooltip: _isSoundEnabled ? 'Mute Sound' : 'Unmute Sound',
          ),
          SizedBox(height: 20),
          // Speedometer
          Card(
            elevation: 2,
            color: Colors.black.withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                _currentSpeedKmh != null ? "${_currentSpeedKmh!.toStringAsFixed(0)} km/h" : "-- km/h",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Placeholder Report Button
          FloatingActionButton(
            heroTag: 'report_fab', // Unique heroTag
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
            onPressed: () {
                 _showCustomSnackBar(context, 'Report feature not implemented yet.', iconData: Icons.report_problem_outlined);
            },
            tooltip: 'Report an Issue',
          ),
           SizedBox(height: 8),
          // Placeholder Alternative Routes Button
          FloatingActionButton(
            heroTag: 'alt_routes_fab', // Unique heroTag
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.alt_route_rounded, color: Theme.of(context).primaryColorDark),
            onPressed: () {
                _showAlternativeRoutesDialog(); // Call new method
            },
            tooltip: 'Alternative Routes',
          ),
        ],
      ),
    );
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) async {
    _mapboxMapController = mapboxMap;
    // Create annotation managers
    _pickupPointAnnotationManager = await _mapboxMapController?.annotations.createPointAnnotationManager();
    _destinationPointAnnotationManager = await _mapboxMapController?.annotations.createPointAnnotationManager();
    
    // If images are already loaded, add them to the style
    if (_pickupIconBytes != null || _destinationIconBytes != null) {
        // It's safer to add images onStyleLoaded, but if the map is created after images are loaded.
        // However, onStyleLoaded is the more robust place.
    }
     print("[DeliveryMapPage] Map created.");
  }

  void _onStyleLoaded(mb.StyleLoadedEventData eventData) async {
    setState(() {
      _mapReady = true;
    });
    print("[DeliveryMapPage] Map style loaded.");
    await _addImagesToMapStyle(); // Add custom marker images to the map style

    // Now it's safe to add annotations and layers
    if (_destinationLatitude != null && _destinationLongitude != null) {
      _addOrUpdateDestinationAnnotation(); 
    }
    if (_animatedPickupLatitude != null && _animatedPickupLongitude != null) {
      _updateOrAddPickupAnnotation(); 
    }
    if (_selectedRoute != null) {
      _updateMapRouteLine(); 
    }
  }
  
  // Placeholder for new "Start Journey" button logic
  void _startJourneyWithMapbox() {
    if (_pickupLatitude == null || _pickupLongitude == null || _destinationLatitude == null || _destinationLongitude == null) {
      if (mounted) {
        _showCustomSnackBar(context, 'Pickup or destination location is not available to start journey.', isError: true);
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isJourneyStarted = true;
      });
      _fetchAllRoutesAndDrawSelected(); 
      _startLiveLocationUpdates(); // Start continuous tracking
      _moveCameraToFitRoute();
      _showCustomSnackBar(context, 'Journey started! Live tracking active...', isSuccess: true, iconData: Icons.navigation_rounded);
    }
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    if (_isRequestingPermission) {
      return await Permission.locationWhenInUse.status;
    }
    _isRequestingPermission = true;
    PermissionStatus status;
    try {
      status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }
      if (status.isPermanentlyDenied && mounted) {
        _showCustomSnackBar(context, 'Location permission is permanently denied. Please enable it in app settings.', 
                              isError: true, 
                              duration: Duration(seconds: 6), 
                            );
      }
    } finally {
      _isRequestingPermission = false;
    }
    return status;
  }

  // Refactored for PointAnnotations
  Future<void> _updateOrAddPickupAnnotation() async {
    if (!_mapReady || _mapboxMapController == null || _pickupPointAnnotationManager == null || _animatedPickupLatitude == null || _animatedPickupLongitude == null || !mounted) return;
    if (_pickupIconBytes == null) return; // Wait for image

    final point = mb.Point(coordinates: mb.Position(_animatedPickupLongitude!, _animatedPickupLatitude!));
    final options = mb.PointAnnotationOptions(
      geometry: point, // Use Point directly
      iconImage: PICKUP_ICON_IMAGE_ID, // Corrected to iconImage and using ID string
      iconSize: 0.4, // Further reduced size from 0.7
    );

    if (_pickupAnnotation == null) {
      _pickupAnnotation = await _pickupPointAnnotationManager!.create(options);
    } else {
      _pickupAnnotation!.geometry = point;
      await _pickupPointAnnotationManager!.update(_pickupAnnotation!);
    }
  }
  
  Future<void> _addOrUpdateDestinationAnnotation() async {
    if (!_mapReady || _mapboxMapController == null || _destinationPointAnnotationManager == null || _destinationLatitude == null || _destinationLongitude == null || !mounted) return;
    if (_destinationIconBytes == null) return; // Wait for image

    final point = mb.Point(coordinates: mb.Position(_destinationLongitude!, _destinationLatitude!));
    final options = mb.PointAnnotationOptions(
      geometry: point, // Use Point directly
      iconImage: DESTINATION_ICON_IMAGE_ID, // Corrected to iconImage and using ID string
      iconSize: 0.4, // Further reduced size from 0.7
      textField: "Deliver to: ${widget.task.customerName}",
      textOffset: [0.0, 2.0], 
    );

     if (_destinationAnnotation == null) {
      _destinationAnnotation = await _destinationPointAnnotationManager!.create(options);
    } else {
      _destinationAnnotation!.geometry = point;
      await _destinationPointAnnotationManager!.update(_destinationAnnotation!);
    }
  }

  Future<void> _moveCameraToLocation(double latitude, double longitude, {double zoom = 16.0}) async {
    if (!_mapReady || _mapboxMapController == null) return;
    _mapboxMapController!.flyTo( // Changed from camera.easeTo to flyTo
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(longitude, latitude)), // Used geo.Position
        zoom: zoom,
      ),
      mb.MapAnimationOptions(duration: 1000) 
    );
  }

Future<void> _initializeLocationTracking() async {
    PermissionStatus permissionStatus = await _requestLocationPermission();
    if (!permissionStatus.isGranted && mounted) {
        _showCustomSnackBar(context, 'Location permission not granted. Please enable it to start tracking.', isError: true);
      return;
    }
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled(); // Used geo.Geolocator
    if (!serviceEnabled && mounted) {
      _showCustomSnackBar(context, 'Location services are disabled. Please enable them for live tracking.', isError: true);
      return;
    }

    try {
      geo.Position initialPosition = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
      if (mounted) {
        _pickupLatitude = initialPosition.latitude;
        _pickupLongitude = initialPosition.longitude;
        _animatedPickupLatitude = _pickupLatitude;
        _animatedPickupLongitude = _pickupLongitude;
        
        if(_mapReady) { 
          _updateOrAddPickupAnnotation();
          if (_destinationLatitude != null) {
            _addOrUpdateDestinationAnnotation();
            // If we have both pickup and destination, fetch initial route
            if (_pickupLatitude != null && _pickupLongitude != null) {
                _fetchAllRoutesAndDrawSelected(); 
            }
          }
        }
        
        if (_pickupLatitude != null) _moveCameraToLocation(_pickupLatitude!, _pickupLongitude!); 
      }
    } catch (e) {
      print("[DeliveryMapPage] Error getting initial position: $e.");
      if (mounted) {
        _showCustomSnackBar(context, "Error getting initial location: $e", isError: true);
      }
    }
    // Continuous location updates will be started by _startLiveLocationUpdates()
  }

  // Method to start live location updates
  Future<void> _startLiveLocationUpdates() async {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel(); // Cancel any existing subscription
    }
    final geo.LocationSettings locationSettings = geo.LocationSettings(accuracy: geo.LocationAccuracy.high, distanceFilter: 10);
    _positionStreamSubscription = geo.Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (geo.Position position) {
        if (mounted && _isJourneyStarted) { // Only process if journey has started
          final newLat = position.latitude;
          final newLng = position.longitude;
          double? newBearing = position.heading;

          // Update speed
          if (position.speed != null) {
            setState(() {
              _currentSpeedKmh = position.speed * 3.6; // m/s to km/h
            });
          }
          // Update bearing
          if (newBearing != null && (position.speedAccuracy ?? 0) > 0 && position.speed > 0.5) { // Speed in m/s
            if (_currentBearing == null || (newBearing - _currentBearing!).abs() > 5.0) {
                 setState(() {
                    _currentBearing = newBearing;
                 });
            }
          } 
          // Update current street name by reverse geocoding (throttled)
          final now = DateTime.now();
          if (!_isReverseGeocoding && 
              (_lastReverseGeocodeTime == null || 
               now.difference(_lastReverseGeocodeTime!) > const Duration(seconds: 5))) {
            _isReverseGeocoding = true; // Set flag before async call
            _lastReverseGeocodeTime = now;
            _updateCurrentStreetName(newLat, newLng).then((_) {
              _isReverseGeocoding = false; // Reset flag after async call completes
            });
          }

          // Off-route detection
          if (_isJourneyStarted && _selectedRoute != null && !_isRecalculatingRoute) {
            double minDistanceToRoute = double.infinity;
            if (_selectedRoute!.points.isNotEmpty) {
              for (var routePointCoords in _selectedRoute!.points) {
                final distance = geo.Geolocator.distanceBetween(
                  newLat, newLng, 
                  routePointCoords[1], routePointCoords[0] // Lat, Lng for route point
                );
                if (distance < minDistanceToRoute) {
                  minDistanceToRoute = distance;
                }
              }

              if (minDistanceToRoute > OFF_ROUTE_THRESHOLD_METERS) {
                _isRecalculatingRoute = true;
                _showCustomSnackBar(context, "You appear to be off-route. Recalculating...", iconData: Icons.sync_problem_rounded);
                _fetchAllRoutesAndDrawSelected().then((_) {
                   // Add a small delay before allowing another recalculation to avoid rapid fire
                  Future.delayed(const Duration(seconds: 5), () {
                     _isRecalculatingRoute = false;
                  });
                }).catchError((_){
                    _isRecalculatingRoute = false; // Ensure it's reset on error too
                });
              }
            }
          }

          if (_animatedPickupLatitude != null && _animatedPickupLongitude != null) {
            if ((newLat - _animatedPickupLatitude!).abs() > 0.000001 ||
                (newLng - _animatedPickupLongitude!).abs() > 0.000001) {

              _latAnimation = Tween<double>(
                begin: _animatedPickupLatitude!, 
                end: newLat,
              ).animate(_symbolAnimationController!);
              _lngAnimation = Tween<double>(
                begin: _animatedPickupLongitude!, 
                end: newLng,
              ).animate(_symbolAnimationController!);

              _symbolAnimationController!.reset();
              _symbolAnimationController!.forward();
            } else { 
                 _animatedPickupLatitude = newLat;
                 _animatedPickupLongitude = newLng;
                 if(_mapReady) _updateOrAddPickupAnnotation(); 
            }
          } else {
            _animatedPickupLatitude = newLat;
            _animatedPickupLongitude = newLng;
            if(_mapReady) _updateOrAddPickupAnnotation();
          }
          _pickupLatitude = newLat; 
          _pickupLongitude = newLng;
          _sendLocationUpdate(_pickupLatitude!, _pickupLongitude!); 

          // Re-calculate and draw route if selected, as driver is moving
          if (_selectedRoute != null) {
            _fetchAllRoutesAndDrawSelected(); 
          }
        }
      },
      onError: (error) { print("[DeliveryMapPage] Error in location stream: $error"); },
      cancelOnError: false,
    );
  }

  void _sendLocationUpdate(double latitude, double longitude) {
    if (widget.task.orderId.isNotEmpty) { 
      DatabaseReference ref = FirebaseDatabase.instance.ref("live_driver_locations/${widget.task.orderId}");
      ref.set({
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": DateTime.now().millisecondsSinceEpoch, 
      }).catchError((error) {
        print("[DeliveryMapPage] Error sending location to Firebase: $error");
      });
    }
  }

  Future<List<RouteInfo>?> _fetchRouteDetailsForMode(MapboxTravelMode mode, double pLat, double pLng, double dLat, double dLng) async {
    String modeString;
    switch (mode) {
      case MapboxTravelMode.driving:
        modeString = "driving-traffic"; 
        break;
      case MapboxTravelMode.cycling:
        modeString = "cycling";
        break;
      case MapboxTravelMode.walking:
        modeString = "walking";
        break;
    }
    
    String tempAccessToken = "pk.eyJ1IjoiZHVrZXBhbiIsImEiOiJjbWI3NzdkM2YwMWxyMmtyMWl3a3BoaHMxIn0.m2NX96ioOrsJnz6YNpNd5w";


    String url = "https://api.mapbox.com/directions/v5/mapbox/$modeString/"
        "$pLng,$pLat;$dLng,$dLat"
        "?alternatives=true&geometries=geojson&overview=full&steps=true"
        "&access_token=$tempAccessToken"; 

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          List<RouteInfo> foundRoutes = [];
          for (var routeData in data['routes']) {
            final geometry = routeData['geometry']['coordinates'] as List<dynamic>;
            final points = geometry.map((coord) => [coord[0] as double, coord[1] as double]).toList();

            final num? durationNum = routeData['duration'] as num?;
            final double? durationInSeconds = durationNum?.toDouble();
            final num? distanceNum = routeData['distance'] as num?;
            final double? distanceInMeters = distanceNum?.toDouble();
            
            String? durationText;
            if (durationInSeconds != null) {
               int minutes = (durationInSeconds / 60).round();
               durationText = "$minutes min";
            }

            String? distanceText;
             if (distanceInMeters != null) {
              double km = distanceInMeters / 1000.0;
              distanceText = "${km.toStringAsFixed(1)} km";
            }

            List<RouteStep> steps = [];
            if (routeData['legs'] != null && routeData['legs'].isNotEmpty) {
              final leg = routeData['legs'][0];
              if (leg['steps'] != null) {
                steps = (leg['steps'] as List<dynamic>).map((stepData) {
                  final num? stepDistNum = stepData['distance'] as num?;
                  final double stepDist = stepDistNum?.toDouble() ?? 0.0;
                  final num? stepDurNum = stepData['duration'] as num?;
                  final double stepDur = stepDurNum?.toDouble() ?? 0.0;
                  final String? type = stepData['maneuver']?['type'] as String?;
                  final String? modifier = stepData['maneuver']?['modifier'] as String?;
                  return RouteStep(
                    instruction: stepData['maneuver']?['instruction'] ?? 'N/A',
                    distance: stepDist,
                    duration: stepDur,
                    maneuverType: type,
                    maneuverModifier: modifier,
                  );
                }).toList();
              }
            }
            foundRoutes.add(RouteInfo(mode, points, durationText, distanceText, durationInSeconds, steps));
          }
          return foundRoutes.isNotEmpty ? foundRoutes : null;
        } else {
          print("[DeliveryMapPage] Mapbox Directions API Error for $modeString: No routes found or error in response - ${data['code']} - ${data['message']}");
        }
      } else {
        print("[DeliveryMapPage] HTTP Error fetching Mapbox directions: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("[DeliveryMapPage] Exception fetching Mapbox directions: $e");
    }
    return null;
  }

  Future<void> _fetchAllRoutesAndDrawSelected() async {
    if (_pickupLatitude == null || _pickupLongitude == null || _destinationLatitude == null || _destinationLongitude == null || !mounted) return;

    List<RouteInfo>? drivingRoutes = await _fetchRouteDetailsForMode(MapboxTravelMode.driving, _pickupLatitude!, _pickupLongitude!, _destinationLatitude!, _destinationLongitude!);

    if (mounted) {
      setState(() {
        _routeOptions = drivingRoutes ?? [];
        if (_routeOptions.isNotEmpty) {
          _selectedRoute = _routeOptions.first;
          if (_selectedRoute != null) {
            if (_selectedRoute!.steps.isNotEmpty) {
              _currentManeuverInstruction = _selectedRoute!.steps.first.instruction;
              if (_selectedRoute!.steps.length > 1) {
                _nextManeuverStep = _selectedRoute!.steps[1];
              } else {
                _nextManeuverStep = null;
              }
            } else {
              _currentManeuverInstruction = "Proceed to destination";
              _nextManeuverStep = null;
            }
            if (_selectedRoute!.totalDurationSeconds != null) {
              _estimatedArrivalTime = DateTime.now().add(Duration(seconds: _selectedRoute!.totalDurationSeconds!.round()));
            }
          } else {
            _currentManeuverInstruction = null;
            _estimatedArrivalTime = null;
            _nextManeuverStep = null;
          }
        } else {
          _selectedRoute = null;
          _currentManeuverInstruction = null;
          _estimatedArrivalTime = null;
          _nextManeuverStep = null;
        }
        _updateMapRouteLine();
      });
      if (_selectedRoute != null) {
         if (_isJourneyStarted) _moveCameraToNavigationPerspective();
         else _moveCameraToFitRoute(); 
      } else {
        if(mounted) {
            _showCustomSnackBar(context, 'Could not fetch any routes.', isError: true);
        }
      }
    }
  }
  
  Future<void> _updateMapRouteLine() async {
    if (!_mapReady || _mapboxMapController == null || !mounted) return;

    try {
      // Remove existing route source and layer if they exist
      if (await _mapboxMapController!.style.styleLayerExists(ROUTE_LAYER_ID)) {
         await _mapboxMapController!.style.removeStyleLayer(ROUTE_LAYER_ID); // Remove layer first
        await _mapboxMapController!.style.removeStyleSource(ROUTE_SOURCE_ID);
      }
      // It's good practice to also check if layer exists before removing,
      // though removing source should ideally remove dependent layers or error if they exist.
      // else if (await _mapboxMapController!.style.styleLayerExists(ROUTE_LAYER_ID)) {
      // await _mapboxMapController!.style.removeStyleLayer(ROUTE_LAYER_ID);
      // }


      if (_selectedRoute != null && _selectedRoute!.points.isNotEmpty) {
        final geoJsonSource = mb.GeoJsonSource(
          id: ROUTE_SOURCE_ID,
          data: json.encode({
            'type': 'Feature',
            'properties': {},
            'geometry': {
              'type': 'LineString',
              'coordinates': _selectedRoute!.points, 
            }
          }),
        );
        await _mapboxMapController!.style.addSource(geoJsonSource);

        final lineLayer = mb.LineLayer(
          id: ROUTE_LAYER_ID,
          sourceId: ROUTE_SOURCE_ID,
          lineJoin: mb.LineJoin.ROUND,
          lineCap: mb.LineCap.ROUND,
          lineColor: Colors.green.value,
          lineWidth: 7.0,
          lineOpacity: 0.8,
        );
        await _mapboxMapController!.style.addLayer(lineLayer);
      }
    } catch (e) {
      print("Error updating map route line: $e");
    }
  }

  void _moveCameraToFitRoute() async {
    if (!_mapReady || _mapboxMapController == null || !mounted) return;

    double? pLat = _animatedPickupLatitude;
    double? pLng = _animatedPickupLongitude;
    double? dLat = _destinationLatitude;
    double? dLng = _destinationLongitude;

    if (_selectedRoute != null && _selectedRoute!.points.isNotEmpty) {
        List<List<double>> routePoints = _selectedRoute!.points; 
        if (routePoints.length == 1) {
            _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(routePoints.first[0], routePoints.first[1])), zoom: 15), mb.MapAnimationOptions(duration: 1000));
      return;
    }
    
        double minLat = routePoints.first[1];
        double maxLat = routePoints.first[1];
        double minLng = routePoints.first[0];
        double maxLng = routePoints.first[0];

        for (var pointPair in routePoints) { 
            if (pointPair[1] < minLat) minLat = pointPair[1];
            if (pointPair[1] > maxLat) maxLat = pointPair[1];
            if (pointPair[0] < minLng) minLng = pointPair[0];
            if (pointPair[0] > maxLng) maxLng = pointPair[0];
        }
        try {
            final cameraOptions = await _mapboxMapController!.cameraForCoordinates(
                [
                  mb.Point(coordinates: mb.Position(minLng, minLat)),
                  mb.Point(coordinates: mb.Position(maxLng, maxLat)),
                ],
                mb.MbxEdgeInsets(top: 40, left: 40, bottom: 150, right: 40),
                null, 
                null  
            );
            _mapboxMapController!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1000));

        } catch (e) {
             print("Error animating camera to bounds: $e");
             if (dLat != null && dLng != null) _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(dLng, dLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
             else if (pLat != null && pLng != null) _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(pLng, pLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
        }

    } else if (pLat != null && pLng != null && dLat != null && dLng != null) {
      try {
        final cameraOptions = await _mapboxMapController!.cameraForCoordinates(
            [
              mb.Point(coordinates: mb.Position(pLng < dLng ? pLng : dLng, pLat < dLat ? pLat : dLat)),
              mb.Point(coordinates: mb.Position(pLng > dLng ? pLng : dLng, pLat > dLat ? pLat : dLat)),
            ],
            mb.MbxEdgeInsets(top: 40, left: 40, bottom: 150, right: 40),
            null, null
        );
         _mapboxMapController!.flyTo(cameraOptions, mb.MapAnimationOptions(duration: 1000));
      } catch (e) {
        print("Error animating camera to p/d bounds: $e");
         if (dLat != null && dLng != null) _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(dLng, dLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
         else if (pLat != null && pLng != null) _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(pLng, pLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
      }
    } else if (dLat != null && dLng != null) {
      _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(dLng, dLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
    } else if (pLat != null && pLng != null) {
      _mapboxMapController!.flyTo(mb.CameraOptions(center: mb.Point(coordinates: mb.Position(pLng, pLat)), zoom: 14), mb.MapAnimationOptions(duration: 1000));
    }
  }

  void _moveCameraToNavigationPerspective() async {
    if (!_mapReady || _mapboxMapController == null || _animatedPickupLatitude == null || _animatedPickupLongitude == null) return;
    // Get current camera bearing if available, otherwise default to 0
    // This requires getting camera state, which can be asynchronous.
    // For simplicity, we might need to store bearing or set it based on location updates.
    // For now, let's just set a fixed pitch.
    _mapboxMapController!.flyTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(_animatedPickupLongitude!, _animatedPickupLatitude!)),
        zoom: 17.0, // Zoom in closer for navigation
        pitch: 60.0, // Tilt the camera
        bearing: _currentBearing ?? 0.0, // Set bearing based on movement direction
      ),
      mb.MapAnimationOptions(duration: 1200)
    );
  }

  void _showAlternativeRoutesDialog() {
    if (_routeOptions.length <= 1) {
      _showCustomSnackBar(context, 'No alternative routes available.', iconData: Icons.alt_route_outlined);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a Route'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // Rounded corners for dialog
          contentPadding: EdgeInsets.symmetric(vertical: 16.0), // Adjust padding
          content: SingleChildScrollView(
            child: ListBody(
              children: _routeOptions.asMap().entries.map((entry) {
                int idx = entry.key;
                RouteInfo route = entry.value;
                bool isSelected = route == _selectedRoute;
                return Card(
                  elevation: isSelected ? 4.0 : 2.0,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  color: isSelected ? Theme.of(context).primaryColorLight.withOpacity(0.4) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
                        child: Text("${idx + 1}", style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                    ),
                    title: Text(
                      '${route.durationText ?? "N/A"} (${route.distanceText ?? "N/A"})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: isSelected 
                        ? Text('Currently Selected', style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).primaryColorDark))
                        : Text('Tap to select', style: TextStyle(fontSize: 12)), 
                    onTap: () {
                      Navigator.of(context).pop(); // Close dialog
                      _selectNewRoute(route);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _selectNewRoute(RouteInfo newRoute) {
    if (mounted && newRoute != _selectedRoute) {
      setState(() {
        _selectedRoute = newRoute;
        if (_selectedRoute!.steps.isNotEmpty) {
          _currentManeuverInstruction = _selectedRoute!.steps.first.instruction;
          if (_selectedRoute!.steps.length > 1) {
            _nextManeuverStep = _selectedRoute!.steps[1];
          } else {
            _nextManeuverStep = null;
          }
        } else {
          _currentManeuverInstruction = "Proceed to destination";
          _nextManeuverStep = null;
        }
        if (_selectedRoute!.totalDurationSeconds != null) {
          _estimatedArrivalTime = DateTime.now().add(Duration(seconds: _selectedRoute!.totalDurationSeconds!.round()));
        }
        _updateMapRouteLine(); // Redraw route on map
      });
      // Optionally, re-adjust camera, though _updateMapRouteLine might trigger it or it might be fine
      if (_isJourneyStarted) {
        _moveCameraToNavigationPerspective(); 
      } else {
        _moveCameraToFitRoute();
      }
       _showCustomSnackBar(context, 'Switched to new route.', isSuccess: true, iconData: Icons.alt_route_rounded);
    }
  }

  // Helper method for showing customized SnackBars
  void _showCustomSnackBar(
    BuildContext context, 
    String message, 
    { bool isError = false, 
      bool isSuccess = false, 
      Duration duration = const Duration(seconds: 4), 
      IconData? iconData } // Optional icon
  ) {
    if (!mounted) return; // Ensure the widget is still in the tree

    Color backgroundColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[800]! 
        : Colors.black87;
    Color textColor = Colors.white;
    IconData? leadingIcon = iconData;

    if (isError) {
      backgroundColor = Colors.redAccent[700]!;
      leadingIcon = iconData ?? Icons.error_outline_rounded;
    } else if (isSuccess) {
      backgroundColor = Colors.green[700]!;
      leadingIcon = iconData ?? Icons.check_circle_outline_rounded;
    } else {
      // Default info style, could add a specific icon if desired
      leadingIcon = iconData ?? Icons.info_outline_rounded;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide any existing snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (leadingIcon != null) Icon(leadingIcon, color: textColor, size: 20),
            if (leadingIcon != null) SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: textColor, fontSize: 15))),
          ],
        ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating, // Makes it float above content
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Margin for floating
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
          elevation: 6.0,
      ),
    );
  }

  // Restore _showRouteStepsDialog
  void _showRouteStepsDialog(List<RouteStep> steps) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Route Steps'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // Rounded corners
          contentPadding: EdgeInsets.zero, // Let ListView handle padding
          content: Container(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: steps.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (BuildContext context, int index) {
                final step = steps[index];
                String distanceStr;
                if (step.distance >= 1000) {
                  distanceStr = "${(step.distance / 1000).toStringAsFixed(1)} km";
                } else {
                  distanceStr = "${step.distance.toStringAsFixed(0)} m";
                }
                String durationStr = "${(step.duration / 60).toStringAsFixed(0)} min";

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: Text("${index + 1}", style: TextStyle(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(step.instruction, style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text("$distanceStr, approx. $durationStr", style: TextStyle(color: Colors.grey[600])),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCurrentStreetName(double lat, double lng) async {
    // Use your Mapbox Access Token
    String accessToken = "pk.eyJ1IjoiZHVrZXBhbiIsImEiOiJjbWI3NzdkM2YwMWxyMmtyMWl3a3BoaHMxIn0.m2NX96ioOrsJnz6YNpNd5w"; 
    String url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?types=address,street&access_token=$accessToken";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          // Prioritize 'address' type feature text, then 'street' from place_name, then first feature text
          String? streetName;
          for (var feature in data['features']) {
            if (feature['place_type'] != null && (feature['place_type'] as List).contains('address')) {
              streetName = feature['text'] as String?;
              break;
            }
          }
          if (streetName == null) {
            for (var feature in data['features']) {
                if (feature['place_type'] != null && (feature['place_type'] as List).contains('street')) {
                    // Street names are often part of place_name for street features
                    // e.g., "Rue Mohamed Slimani, Algiers"
                    // We only want "Rue Mohamed Slimani"
                    String? placeName = feature['place_name'] as String?;
                    if (placeName != null) {
                        streetName = placeName.split(',').first.trim();
                        break;
                    }
                }
            }
          }
          if (streetName == null) {
            streetName = data['features'][0]['text'] as String?;
          }

          if (mounted && streetName != null && streetName != _currentStreetName) {
            setState(() {
              _currentStreetName = streetName;
            });
          }
        } else {
          print("[DeliveryMapPage] Reverse geocoding found no features.");
        }
      } else {
        print("[DeliveryMapPage] Reverse geocoding error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("[DeliveryMapPage] Exception during reverse geocoding: $e");
    }
  }
}

// Helper to load assets as Uint8List for Mapbox custom images (if needed)
// Added for MbxImage
// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle;
// Future<Uint8List> _loadAssetAsBytes(String assetPath) async {
//   final ByteData byteData = await rootBundle.load(assetPath);
//   return byteData.buffer.asUint8List();
// }

// Note: Removed _updateDestinationMarker as its logic is now in _addOrUpdateDestinationAnnotation and called from _onStyleLoaded or _initializeLocationTracking.
// Note: Removed _fetchRouteDetails as its combined logic is in _fetchAllRoutesAndDrawSelected