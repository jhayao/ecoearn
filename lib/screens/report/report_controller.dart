import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ReportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String description,
    required String location,
    required String base64Image,
    required String userId,
  }) async {
    try {
      // Validate inputs
      if (description.trim().isEmpty) {
        throw Exception('Description cannot be empty');
      }
      
      if (location.trim().isEmpty) {
        throw Exception('Location cannot be empty');
      }
      
      if (base64Image.isEmpty) {
        throw Exception('Image data is missing');
      }

      // Try to get username from users collection first (more reliable)
      String userName = 'Unknown';
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['userName'] as String? ?? 'Unknown';
        } else {
          // Fallback to recycling_requests if user not found in users collection
          final querySnapshot = await _firestore
              .collection('recycling_requests')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userData = querySnapshot.docs.first.data();
            userName = userData['userName'] as String? ?? 'Unknown';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch username: $e');
        // Continue with 'Unknown' username
      }

      // Submit the report
      await _firestore.collection('reports').add({
        'description': description.trim(),
        'location': location.trim(),
        'image': base64Image,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
      });
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  String encodeImage(List<int> imageBytes) {
    try {
      if (imageBytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error encoding image: $e');
      rethrow;
    }
  }

  Image decodeImage(String base64Image) {
    return Image.memory(base64Decode(base64Image));
  }
}