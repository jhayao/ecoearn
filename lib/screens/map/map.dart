// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:another_flushbar/flushbar.dart';
import 'package:ecoearn/screens/home/bincard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show asin, cos, sqrt;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class MapScreen extends StatefulWidget {
  final DocumentSnapshot? bin; // Receive the selected bin

  const MapScreen({super.key, this.bin});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? mapController;
  LatLng? currentPosition;
  LatLng? destination;
  String? binLevel;
  String? binName;

  final List<Polyline> polylines = [];
  final List<Marker> markers = [];
  double? distanceInKm;

  bool isLoading = true;
  bool isRouteLoading = false;
  String? errorMessage;
  
  // Add location tracking variables
  StreamSubscription<Position>? _locationSubscription;
  bool _isTrackingLocation = false;
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        throw Exception("Please enable location services to continue");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission is required for this feature");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            "Location permissions are permanently denied. Please enable them in app settings.");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });

      // Set destination from bin data if provided
      if (widget.bin != null) {
        Get.find<NearbyBinsController>();
        final data = widget.bin!.data() as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        final level = (data['level'] as num?)?.toInt() ?? 0;
        final name = data['name'] as String? ?? 'Unknown Bin';

        setState(() {
          destination = LatLng(lat, lng);
          binLevel = '$level%'; // Store bin level as percentage
          binName = name;
        });

        _updateMarkers();
        await _drawRoute();
      
      // Start real-time location tracking
      _startLocationTracking();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      _showErrorFlushbar(e.toString());
    }
  }

  void _updateMarkers() {
    if (!mounted) return;

    setState(() {
      markers.clear();

      // User location marker with pulsing animation
      if (currentPosition != null) {
        markers.add(Marker(
          point: currentPosition!,
          width: 50,
          height: 50,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing background circle
                  Transform.scale(
                    scale: 0.8 + (0.4 * value),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3 - (0.2 * value)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Main marker
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {
                  _isPulsing = !_isPulsing;
                });
              }
            },
          ),
        ));
      }

      // Bin location marker with fill level indicator
      if (destination != null) {
        final level = int.tryParse(binLevel?.replaceAll('%', '') ?? '0') ?? 0;
        Color binColor;
        if (level >= 80) {
          binColor = Colors.red;
        } else if (level >= 50) {
          binColor = Colors.orange;
        } else {
          binColor = Colors.green;
        }

        markers.add(Marker(
          point: destination!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: binColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              // Main marker
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: binColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: binColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getFillLevelIcon(binLevel ?? '0%'),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Fill level indicator
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    binLevel ?? '0%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: binColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    });
  }

  Future<void> _drawRoute() async {
    if (currentPosition == null || destination == null || !mounted) return;

    setState(() => isRouteLoading = true);

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${currentPosition!.longitude},${currentPosition!.latitude};${destination!.longitude},${destination!.latitude}?overview=full&geometries=geojson';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        throw Exception('No route found between these points');
      }

      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      final List<LatLng> routeCoords = coords.map<LatLng>((c) {
        if (c is! List || c.length < 2) {
          throw Exception('Invalid coordinate data received');
        }
        return LatLng(c[1].toDouble(), c[0].toDouble());
      }).toList();

      if (!mounted) return;

      setState(() {
        polylines.clear();
        polylines.add(Polyline(
          points: routeCoords,
          color: const Color(0xFF34A853),
          strokeWidth: 6,
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ));
      });

      _calculateDistance();
      _updateMarkers();
      _zoomToFit();
    } catch (e) {
      debugPrint("Route fetch error: $e");
      if (mounted) {
        _showErrorFlushbar(
            'Failed to fetch route: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}');
      }
    } finally {
      if (mounted) {
        setState(() => isRouteLoading = false);
      }
    }
  }

  void _calculateDistance() {
    if (currentPosition == null || destination == null || !mounted) return;

    try {
      const p = 0.017453292519943295; // Radians per degree
      final a = 0.5 -
          cos((destination!.latitude - currentPosition!.latitude) * p) / 2 +
          cos(currentPosition!.latitude * p) *
              cos(destination!.latitude * p) *
              (1 -
                  cos((destination!.longitude - currentPosition!.longitude) *
                      p)) /
              2;

      // Calculate distance in kilometers
      final distanceInKm = 12742 * asin(sqrt(a));
      // Convert to meters
      final distanceInMeters = distanceInKm * 1000;

      setState(() {
        this.distanceInKm = distanceInKm; // Store km for internal use
      });
    } catch (e) {
      debugPrint("Distance calculation error: $e");
    }
  }

  void _zoomToFit() {
    if (currentPosition == null ||
        destination == null ||
        mapController == null ||
        !mounted) {
      return;
    }

    try {
      final bounds = _boundsFromLatLngList([currentPosition!, destination!]);
      mapController!.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(100)));
    } catch (e) {
      debugPrint("Zoom to fit error: $e");
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double minLat = list[0].latitude;
    double maxLat = list[0].latitude;
    double minLng = list[0].longitude;
    double maxLng = list[0].longitude;

    for (var point in list) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  void _startLocationTracking() {
    if (_isTrackingLocation) return;
    
    _isTrackingLocation = true;
    
    // Start listening to location updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters for more responsive updates
      ),
    ).listen(
      (Position position) {
        if (!mounted) return;
        
        final newPosition = LatLng(position.latitude, position.longitude);
        
        setState(() {
          currentPosition = newPosition;
        });
        
        // Update markers and recalculate distance in real-time
        _updateMarkers();
        _calculateDistance();
        
        // Update route every 20 meters to balance performance and accuracy
        if (_shouldUpdateRoute(newPosition)) {
          _drawRoute();
        }
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
      },
    );
  }

  LatLng? _lastRouteUpdatePosition;
  
  bool _shouldUpdateRoute(LatLng newPosition) {
    if (_lastRouteUpdatePosition == null) {
      _lastRouteUpdatePosition = newPosition;
      return true;
    }
    
    // Calculate distance from last route update
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((newPosition.latitude - _lastRouteUpdatePosition!.latitude) * p) / 2 +
        cos(_lastRouteUpdatePosition!.latitude * p) *
            cos(newPosition.latitude * p) *
            (1 - cos((newPosition.longitude - _lastRouteUpdatePosition!.longitude) * p)) / 2;
    
    final distance = 12742 * asin(sqrt(a)) * 1000; // Distance in meters
    
    if (distance > 20) { // Update route every 20 meters
      _lastRouteUpdatePosition = newPosition;
      return true;
    }
    
    return false;
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _isTrackingLocation = false;
  }

  void _showErrorFlushbar(String message) {
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(8),
      icon: const Icon(
        Icons.error,
        color: Colors.white,
      ),
    ).show(context);
  }

  IconData _getFillLevelIcon(String level) {
    final int percentage = int.tryParse(level.replaceAll('%', '')) ?? 0;
    if (percentage >= 80) {
      return Icons.inventory; // High fill icon
    } else if (percentage >= 50) {
      return Icons.inventory_2; // Medium fill icon
    } else {
      return Icons.inventory_outlined; // Low fill icon
    }
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    final Color valueColor = label == 'Distance' ? Colors.green[800]! : Colors.orange[800]!;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: valueColor.withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () {
        if (currentPosition != null && mapController != null) {
          mapController!.move(currentPosition!, 16); // Zoom in more for better detail
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.blue[100]!,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.my_location,
          size: 20,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildDistanceInfo() {
    String distanceText;
    String walkingTime = "--";
    
    if (distanceInKm == null) {
      distanceText = "--";
    } else {
      final distanceInMeters = distanceInKm! * 1000;
      if (distanceInMeters < 1000) {
        distanceText = '${distanceInMeters.toStringAsFixed(0)} m';
        // Estimate walking time (average walking speed: 5 km/h = 1.39 m/s)
        final walkingTimeMinutes = (distanceInMeters / 1.39 / 60).round();
        walkingTime = '${walkingTimeMinutes} min walk';
      } else {
        distanceText = '${distanceInKm!.toStringAsFixed(1)} km';
        // Estimate walking time for longer distances
        final walkingTimeMinutes = (distanceInKm! / 5 * 60).round();
        walkingTime = '${walkingTimeMinutes} min walk';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bin Information:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              if (_isTrackingLocation) ...[
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isPulsing ? Colors.green : Colors.green.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live Tracking',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildInfoColumn(
                          'Distance',
                          distanceText,
                          Icons.directions_walk,
                        ),
                        if (binLevel != null) ...[
                          const SizedBox(width: 24),
                          _buildInfoColumn(
                            'Fill Level',
                            binLevel!,
                            _getFillLevelIcon(binLevel!),
                          ),
                        ],
                      ],
                    ),
                    if (walkingTime != "--") ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            walkingTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildMyLocationButton(),
            ],
          ),
          if (binName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                binName!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your location...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Route to Recycling Bin',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentPosition ?? const LatLng(0, 0),
              initialZoom: 14,
              onMapReady: () {
                if (destination != null) _zoomToFit();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecoearn',
              ),
              MarkerLayer(markers: markers),
              PolylineLayer(polylines: polylines),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildDistanceInfo(),
          ),
        ],
      ),
    );
  }
}