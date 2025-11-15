import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getRecyclingStats(String userId) {
    return _firestore
        .collection('recycling_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Map<String, dynamic>> getProfileStats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }
} 