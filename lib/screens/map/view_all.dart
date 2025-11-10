import 'dart:convert';
import 'package:ecoearn/screens/home/bincard_controller.dart';
import 'package:ecoearn/screens/map/map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewMoreBinsScreen extends StatefulWidget {
  const ViewMoreBinsScreen({super.key});

  @override
  State<ViewMoreBinsScreen> createState() => _ViewMoreBinsScreenState();
}

class _ViewMoreBinsScreenState extends State<ViewMoreBinsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NearbyBinsController _binsController = Get.find<NearbyBinsController>();
  List<DocumentSnapshot> filteredBins = [];

  @override
  void initState() {
    super.initState();
    filteredBins = List.from(_binsController.bins);
    _searchController.addListener(_onSearchChanged);

    _binsController.bins.listen((bins) {
      if (mounted) {
        setState(() {
          filteredBins = List.from(bins);
          _onSearchChanged();
        });
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredBins = _binsController.bins.where((bin) {
        final data = bin.data() as Map<String, dynamic>;
        final name = (data['name'] as String? ?? 'Unknown Bin').toLowerCase();
        final address = (data['address'] as String? ?? '').toLowerCase();
        return name.contains(query) || address.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              if (_binsController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (filteredBins.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No bins available'
                            : 'No bins found for "${_searchController.text}"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _binsController.refreshBins,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBins.length,
                  itemBuilder: (context, index) {
                    return _buildBinCard(filteredBins[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF34A853), Color(0xFF144221)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    const Text(
                      'Nearby Recycling Bins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search bins...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinImage(String imageData) {
    try {
      // Check if it's a data URL format
      String base64String;
      if (imageData.startsWith('data:')) {
        // Extract base64 part from data URL
        final commaIndex = imageData.indexOf(',');
        if (commaIndex != -1) {
          base64String = imageData.substring(commaIndex + 1);
        } else {
          throw Exception('Invalid data URL format');
        }
      } else {
        // Assume it's already base64
        base64String = imageData;
      }
      
      return Image.memory(
        base64Decode(base64String),
        height: 60,
        width: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_not_supported,
              size: 40, color: Colors.grey);
        },
      );
    } catch (e) {
      debugPrint('Error processing bin image: $e');
      return const Icon(Icons.image_not_supported,
          size: 40, color: Colors.grey);
    }
  }

  Widget _buildBinCard(DocumentSnapshot bin) {
    try {
      final data = bin.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? 'Unknown Bin';
      final level = (data['level'] as num?)?.toInt() ?? 0;
      final imageBase64 = data['image'] as String?;
      final distance = _binsController.calculateDistance(bin);

      final latLng = _binsController.getBinLatLng(bin);
      final lat = latLng.latitude.toStringAsFixed(4);
      final lng = latLng.longitude.toStringAsFixed(4);

      final binStatus = data['status'] as String? ?? 'unknown';
      final status = binStatus.toLowerCase() == 'inactive' 
          ? 'Inactive' 
          : level >= 80 
              ? 'Full' 
              : 'Open';
      final statusColor = binStatus.toLowerCase() == 'inactive'
          ? Colors.grey
          : level >= 80
              ? Colors.red
              : level >= 50
                  ? Colors.orange
                  : Colors.green;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Get.to(() => MapScreen(bin: bin));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: imageBase64 != null && imageBase64.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildBinImage(imageBase64),
                        )
                      : const Icon(Icons.recycling,
                          size: 40, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: $lat, Lng: $lng',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            distance == double.infinity
                                ? 'Distance unavailable'
                                : distance >= 1
                                    ? '${distance.toStringAsFixed(1)} km'
                                    : '${(distance * 1000).toStringAsFixed(0)} m',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$level% full',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building bin card: $e');
      return const ListTile(
        title: Text('Error loading bin'),
        leading: Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
