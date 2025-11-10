import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DepositService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all deposits for a specific bin
  Stream<QuerySnapshot> getDepositsForBin(String binId) {
    return _firestore
        .collection('deposits')
        .where('binId', isEqualTo: binId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all deposits for the current user
  Stream<QuerySnapshot> getUserDeposits() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore
        .collection('deposits')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get deposit statistics for a bin
  Future<Map<String, dynamic>> getBinDepositStats(String binId) async {
    final deposits = await _firestore
        .collection('deposits')
        .where('binId', isEqualTo: binId)
        .get();

    int totalItems = 0;
    double totalAmount = 0;
    Map<String, int> itemTypeCount = {};
    Map<String, double> itemTypeAmount = {};

    for (var doc in deposits.docs) {
      final data = doc.data();
      final quantity = data['quantity'] as int? ?? 0;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final itemType = data['itemType'] as String? ?? 'Unknown';

      totalItems += quantity;
      totalAmount += amount;

      itemTypeCount[itemType] = (itemTypeCount[itemType] ?? 0) + quantity;
      itemTypeAmount[itemType] = (itemTypeAmount[itemType] ?? 0.0) + amount;
    }

    return {
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'itemTypeCount': itemTypeCount,
      'itemTypeAmount': itemTypeAmount,
      'depositCount': deposits.docs.length,
    };
  }

  // Get user deposit statistics
  Future<Map<String, dynamic>> getUserDepositStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final deposits = await _firestore
        .collection('deposits')
        .where('userId', isEqualTo: user.uid)
        .get();

    int totalItems = 0;
    double totalAmount = 0;
    Map<String, int> itemTypeCount = {};
    Map<String, double> itemTypeAmount = {};
    Map<String, int> binDepositCount = {};

    for (var doc in deposits.docs) {
      final data = doc.data();
      final quantity = data['quantity'] as int? ?? 0;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final itemType = data['itemType'] as String? ?? 'Unknown';
      final binName = data['binName'] as String? ?? 'Unknown';

      totalItems += quantity;
      totalAmount += amount;

      itemTypeCount[itemType] = (itemTypeCount[itemType] ?? 0) + quantity;
      itemTypeAmount[itemType] = (itemTypeAmount[itemType] ?? 0.0) + amount;
      binDepositCount[binName] = (binDepositCount[binName] ?? 0) + 1;
    }

    return {
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'itemTypeCount': itemTypeCount,
      'itemTypeAmount': itemTypeAmount,
      'binDepositCount': binDepositCount,
      'depositCount': deposits.docs.length,
    };
  }

  // Get recent deposits (last 30 days)
  Future<List<Map<String, dynamic>>> getRecentDeposits({int days = 30}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final deposits = await _firestore
        .collection('deposits')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
        .orderBy('timestamp', descending: true)
        .get();

    return deposits.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
      };
    }).toList();
  }

  // Get top recycling items
  Future<List<Map<String, dynamic>>> getTopRecyclingItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final deposits = await _firestore
        .collection('deposits')
        .where('userId', isEqualTo: user.uid)
        .get();

    Map<String, int> itemCount = {};
    Map<String, double> itemAmount = {};

    for (var doc in deposits.docs) {
      final data = doc.data();
      final itemType = data['itemType'] as String? ?? 'Unknown';
      final quantity = data['quantity'] as int? ?? 0;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      itemCount[itemType] = (itemCount[itemType] ?? 0) + quantity;
      itemAmount[itemType] = (itemAmount[itemType] ?? 0.0) + amount;
    }

    final sortedItems = itemCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedItems.take(5).map((entry) {
      return {
        'itemType': entry.key,
        'count': entry.value,
        'amount': itemAmount[entry.key] ?? 0.0,
      };
    }).toList();
  }

  // Get environmental impact (estimated)
  Future<Map<String, dynamic>> getEnvironmentalImpact() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final deposits = await _firestore
        .collection('deposits')
        .where('userId', isEqualTo: user.uid)
        .get();

    // Rough estimates for environmental impact
    // These are approximate values and should be refined based on actual data
    double totalWeight = 0; // in kg
    double co2Saved = 0; // in kg
    double treesEquivalent = 0; // number of trees

    for (var doc in deposits.docs) {
      final data = doc.data();
      final quantity = data['quantity'] as int? ?? 0;
      final itemType = data['itemType'] as String? ?? 'Unknown';

      // Rough weight estimates per item
      double itemWeight = 0;
      switch (itemType.toLowerCase()) {
        case 'plastic bottles':
          itemWeight = 0.025; // 25g per bottle
          break;
        case 'paper':
          itemWeight = 0.005; // 5g per sheet
          break;
        case 'glass':
          itemWeight = 0.5; // 500g per bottle
          break;
        case 'aluminum':
          itemWeight = 0.015; // 15g per can
          break;
        default:
          itemWeight = 0.01; // 10g default
      }

      totalWeight += quantity * itemWeight;
    }

    // Rough CO2 savings (1kg of recycled material saves ~2kg CO2)
    co2Saved = totalWeight * 2;
    
    // Rough tree equivalent (1 tree absorbs ~22kg CO2 per year)
    treesEquivalent = co2Saved / 22;

    return {
      'totalWeight': totalWeight,
      'co2Saved': co2Saved,
      'treesEquivalent': treesEquivalent,
      'depositCount': deposits.docs.length,
    };
  }
} 