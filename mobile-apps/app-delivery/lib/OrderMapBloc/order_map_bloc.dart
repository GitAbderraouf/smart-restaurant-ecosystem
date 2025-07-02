import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../map_utils.dart';
import 'order_map_state.dart';
import 'package:flutter/material.dart';

class OrderMapBloc extends Cubit<OrderMapState> {
  OrderMapBloc() : super(OrderMapState({}, {}));

  Future<BitmapDescriptor> _getRiderIcon() async {
    try {
      // Assuming the image is at assets/images/rider_pointer.png
      // And that your pubspec.yaml is configured to include this asset.
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
        'images/deliveryman.png',
      );
    } catch (e) {
      print("Error loading rider icon: $e. Using default marker.");
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied, we cannot request permissions.');
        return null;
      }
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Error getting current location: $e");
      return null;
    }
  }

  void loadMap() async {
    Position? currentLocation = await _getCurrentLocation();
    Set<Polyline> polylines = {}; // Initialize as empty
    Set<Marker> markersSet = {};    // Initialize as empty
    BitmapDescriptor riderIcon = await _getRiderIcon(); // Ensure custom icon is loaded

    if (currentLocation != null) {
      LatLng currentLatLng = LatLng(currentLocation.latitude, currentLocation.longitude);

      markersSet.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentLatLng,
          icon: riderIcon, // Use the loaded custom riderIcon
          infoWindow: const InfoWindow(title: 'My Current Location'),
        ),
      );
      // Polylines and destination markers should be handled based on specific tasks,
      // not shown by default when just displaying current location.
    } else {
      // Current location is not available.
      print("Failed to get current location. Map will not show a current location marker or will be empty.");
      // markersSet will remain empty, and so will polylines.
      // This avoids showing a misleading marker in San Francisco.
    }
    
    emit(OrderMapState(polylines, markersSet));
  }

  Future<Polyline?> _getPolyLine(LatLng origin, LatLng destination) async {
    PolylineId id = PolylineId('poly');
    List<LatLng> polylineCoordinates = await _getPolylineCoordinates(origin, destination);
    
    if (polylineCoordinates.isNotEmpty) {
      return Polyline(
      width: 3,
      polylineId: id,
        points: polylineCoordinates,
    );
    }
    return null;
  }

  Future<List<LatLng>> _getPolylineCoordinates(
    LatLng pickupLatLng, LatLng dropLatLng) async {
  final polylinePoints = PolylinePoints();
  final polylineCoordinates = <LatLng>[];

  try {
    final request = PolylineRequest(
      origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
      destination: PointLatLng(dropLatLng.latitude, dropLatLng.longitude),
      mode: TravelMode.driving, // or .walking, .bicycling, .transit
      avoidHighways: false,
      avoidTolls: false,
      optimizeWaypoints: true,
    );

    final result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
      googleApiKey: apiKey,
    );

    if (result.points.isEmpty) {
      print('No polyline points returned');
      return polylineCoordinates;
    }

    if (result.errorMessage?.isNotEmpty ?? false) {
      print('Polyline error: ${result.errorMessage}');
      return polylineCoordinates;
    }

    polylineCoordinates.addAll(
      result.points.map((point) => LatLng(point.latitude, point.longitude)),
    );

    print('Polyline coordinates: ${polylineCoordinates.length} points');
    return polylineCoordinates;
  } catch (e) {
    print('Failed to get polyline: $e');
    return polylineCoordinates;
  }
}

  List<Marker> markers = [
    Marker(
      markerId: MarkerId('mark1'),
      position: LatLng(37.42796133580664, -122.085749655962),
      icon: markerss.first,
    ),
    // Marker(
    //   markerId: MarkerId('mark2'),
    //   position: LatLng(37.42496133180663, -122.081743655960),
    //   icon: markerss[1],
    // ),
    // Marker(
    //   markerId: MarkerId('mark3'),
    //   position: LatLng(37.42196183580660, -122.089743655967),
    //   icon: markerss[2],
    // )
  ];
}
