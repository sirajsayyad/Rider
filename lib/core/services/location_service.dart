import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../config/app_config.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  
  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });
  
  @override
  String toString() => 'LocationData($latitude, $longitude, $address)';
}

/// Location Service for GPS and geocoding
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationData>.broadcast();
  
  Stream<LocationData> get locationStream => _locationController.stream;
  
  /// Check and request location permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
  
  /// Get current location with address
  Future<LocationData?> getCurrentLocationWithAddress() async {
    try {
      final location = await getCurrentLocation();
      if (location == null) return null;
      
      return await getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      debugPrint('Error getting location with address: $e');
      return null;
    }
  }
  
  /// Reverse geocode - get address from coordinates
  Future<LocationData> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = [
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
        ].where((part) => part != null && part.isNotEmpty).toList();
        
        return LocationData(
          latitude: lat,
          longitude: lng,
          address: addressParts.join(', '),
          city: place.locality,
          state: place.administrativeArea,
          country: place.country,
          postalCode: place.postalCode,
        );
      }
      
      return LocationData(latitude: lat, longitude: lng);
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
      return LocationData(latitude: lat, longitude: lng);
    }
  }
  
  /// Forward geocode - get coordinates from address
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error in forward geocoding: $e');
      return null;
    }
  }
  
  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    ) / 1000; // Convert to kilometers
  }
  
  /// Start location tracking
  void startTracking({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen((position) {
      _locationController.add(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });
  }
  
  /// Stop location tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
  
  /// Get default location (used when GPS is unavailable)
  LocationData getDefaultLocation() {
    return LocationData(
      latitude: AppConfig.defaultLatitude,
      longitude: AppConfig.defaultLongitude,
      address: 'Default Location',
    );
  }
  
  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Current location provider
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocationWithAddress();
});

/// Location stream provider
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  locationService.startTracking();
  return locationService.locationStream;
});
