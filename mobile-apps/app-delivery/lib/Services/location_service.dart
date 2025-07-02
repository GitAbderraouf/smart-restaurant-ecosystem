import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class LocationService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('locations');

  // Request location permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return false;
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

  // Send location to Firebase
  Future<void> sendLocationToFirebase(String userId, Position position) async {
    try {
      await _dbRef.child(userId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': ServerValue.timestamp, // For server-side timestamp
      });
    } catch (e) {
      print("Error sending location to Firebase: $e");
    }
  }

  // Stream location updates from Firebase for a specific user
  Stream<DatabaseEvent>? getLocationStream(String userId) {
    try {
      return _dbRef.child(userId).onValue;
    } catch (e) {
      print("Error getting location stream from Firebase: $e");
      return null;
    }
  }
} 