import 'dart:convert';
import 'package:ecoearn/screens/home/bincard_controller.dart';
import 'package:ecoearn/screens/map/map.dart';
import 'package:ecoearn/screens/map/view_all.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyBinsSection extends StatefulWidget {
  const NearbyBinsSection({super.key});

  @override
  State<NearbyBinsSection> createState() => _NearbyBinsSectionState();
}

class _NearbyBinsSectionState extends State<NearbyBinsSection> {
  late NearbyBinsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NearbyBinsController());
    // Start listening to real-time updates
    controller.startListeningToBins();
  }

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      try {
        // Loading state
        if (controller.isLoading.value) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Empty state
        if (controller.bins.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(child: Text('No nearby bins found.')),
            ),
          );
        }

        // Main content with bins
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              try {
                // Header section (Nearby Bin and View all)
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nearby Bin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const ViewMoreBinsScreen());
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 15),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 1, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                // Bin cards
                final binIndex = index - 1; // Adjust for the header
                if (binIndex <
                    (controller.bins.length > 6 ? 6 : controller.bins.length)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildBinCard(controller.bins[binIndex], controller),
                  );
                }

                // Footer spacing
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(height: 20),
                );
              } catch (e, stackTrace) {
                debugPrint('Error in SliverList delegate: $e');
                debugPrint('Stack trace: $stackTrace');
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Text(
                    'Error loading bin list.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
            },
            childCount:
                (controller.bins.length > 6 ? 6 : controller.bins.length) +
                    2, // +2 for header and footer
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('Error in NearbyBinsSection Obx: $e');
        debugPrint('Stack trace: $stackTrace');
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Error loading nearby bins section.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      }
    });
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
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading bin image: $error');
          return const Icon(
            Icons.delete,
            size: 20,
            color: Colors.black54,
          );
        },
      );
    } catch (e) {
      debugPrint('Error processing bin image: $e');
      return const Icon(
        Icons.delete,
        size: 20,
        color: Colors.black54,
      );
    }
  }

  Widget _buildBinCard(DocumentSnapshot bin, NearbyBinsController controller) {
    try {
      final data = bin.data() as Map<String, dynamic>;
      final name = data['name'] as String? ?? 'Unknown Bin';
      final level = (data['level'] as num?)?.toInt() ?? 0;
      final status = data['status'] as String? ?? 'unknown';
      final distance = controller.calculateDistance(bin);
      final imageBase64 = data['image'] as String?;

      // Determine bin color based on level and status
      Color binColor;
      if (status.toLowerCase() == 'inactive') {
        binColor = Colors.grey;
      } else if (level >= 80) {
        binColor = Colors.red;
      } else if (level >= 50) {
        binColor = Colors.orange;
      } else {
        binColor = Colors.green;
      }

      String formatDistance(double distance) {
        if (distance == double.infinity) return 'Distance unavailable';
        if (distance < 1.0) {
          return '${(distance * 1000).round()} m';
        } else {
          return '${distance.toStringAsFixed(1)} km';
        }
      }

      return GestureDetector(
        onTap: () {
          Get.to(() => MapScreen(bin: bin));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: binColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: imageBase64 != null && imageBase64.isNotEmpty
                          ? _buildBinImage(imageBase64)
                          : const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.black54,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      formatDistance(distance),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Level: $level%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == 'inactive' 
                                ? Colors.grey.withOpacity(0.2)
                                : binColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: status.toLowerCase() == 'inactive' 
                                  ? Colors.grey[600]
                                  : binColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Image(
                image: AssetImage('assets/images/Group 36712.png'),
                height: 50,
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _buildBinCard: $e');
      debugPrint('Stack trace: $stackTrace');
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Text(
          'Error loading this bin.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }
}
