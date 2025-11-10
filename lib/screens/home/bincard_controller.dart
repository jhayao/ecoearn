import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class NearbyBinsController extends GetxController {
  final RxList<DocumentSnapshot> bins = <DocumentSnapshot>[].obs;
  final RxBool isLoading = true.obs;
  Position? _userPosition;

  @override
  void onInit() {
    super.onInit();
    fetchNearbyBins();
  }

  Future<void> fetchNearbyBins() async {
    try {
      isLoading.value = true;

      // Get user's current location
      await _getUserLocation();

      // Fetch bins from Firestore with proper error handling
      final snapshot = await FirebaseFirestore.instance
          .collection('bins')
          .get(); // Fetch all bins regardless of status
      
      // Filter out invalid bins and validate data structure
      final validBins = snapshot.docs.where((doc) {
        try {
          final data = doc.data();
          // Check if required fields exist and are valid
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          final name = data['name'] as String?;
          final level = (data['level'] as num?)?.toInt();
          
          return lat != null && 
                 lng != null && 
                 name != null && 
                 name.isNotEmpty &&
                 level != null &&
                 lat >= -90 && lat <= 90 && // Valid latitude range
                 lng >= -180 && lng <= 180; // Valid longitude range
        } catch (e) {
          if (kDebugMode) {
            print('Invalid bin data for document ${doc.id}: $e');
          }
          return false;
        }
      }).toList();

      bins.value = validBins;

      if (kDebugMode) {
        print('Fetched ${validBins.length} valid bins out of ${snapshot.docs.length} total');
      }

      // Sort bins by distance
      sortBinsByDistance();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching nearby bins: $e');
      }
      // Set empty list on error
      bins.value = [];
    } finally {
      isLoading.value = false;
    }
  }
  

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user location: $e');
      }

      _userPosition = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }

  void sortBinsByDistance() {
    bins.sort((a, b) => calculateDistance(a).compareTo(calculateDistance(b)));
  }

  double calculateDistance(DocumentSnapshot bin) {
    final data = bin.data() as Map<String, dynamic>;
    final binLat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    final binLng = (data['lng'] as num?)?.toDouble() ?? 0.0;

    if (_userPosition == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          binLat,
          binLng,
        ) /
        1000;
  }

  LatLng getBinLatLng(DocumentSnapshot bin) {
    final data = bin.data() as Map<String, dynamic>;
    final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
    return LatLng(lat, lng);
  }

  Future<void> refreshBins() async {
    await fetchNearbyBins();
  }

  // Add method to listen to real-time bin updates
  void startListeningToBins() {
    FirebaseFirestore.instance
        .collection('bins')
        .snapshots()
        .listen((snapshot) {
      try {
        // Filter out invalid bins and validate data structure
        final validBins = snapshot.docs.where((doc) {
          try {
            final data = doc.data();
            // Check if required fields exist and are valid
            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            final name = data['name'] as String?;
            final level = (data['level'] as num?)?.toInt();
            
            return lat != null && 
                   lng != null && 
                   name != null && 
                   name.isNotEmpty &&
                   level != null &&
                   lat >= -90 && lat <= 90 && // Valid latitude range
                   lng >= -180 && lng <= 180; // Valid longitude range
          } catch (e) {
            if (kDebugMode) {
              print('Invalid bin data for document ${doc.id}: $e');
            }
            return false;
          }
        }).toList();

        bins.value = validBins;
        sortBinsByDistance();
        
        if (kDebugMode) {
          print('Real-time update: ${validBins.length} valid bins');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error in real-time bin update: $e');
        }
      }
    });
  }
}