// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:ecoearn/screens/onboarding_screen.dart';
import 'package:ecoearn/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileService _profileService = ProfileService();

  Future<void> _redeemPoints(BuildContext context, int currentPoints) async {
    const int maxPoints = 10000;
    const int pointsPerPeso = 10;

    // Show points redemption dialog
    final redeemedPoints =
        await _showPointsRedemptionDialog(context, currentPoints, maxPoints);
    if (redeemedPoints == null) return;

    // Confirm redemption
    final confirmed =
        await _showConfirmationDialog(context, redeemedPoints, pointsPerPeso);
    if (!confirmed) return;

    // Show credit card form
    final cashOutConfirmed = await _showCreditCardBottomSheet(
        context, redeemedPoints, pointsPerPeso);
    if (!cashOutConfirmed) return;

    // Process redemption
    await _processRedemption(context, redeemedPoints, pointsPerPeso);
  }

  Future<int?> _showPointsRedemptionDialog(
      BuildContext context, int currentPoints, int maxPoints) async {
    int? pointsToRedeem;
    final pointsController = TextEditingController();
    bool isValid = false;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/Group 36706.png', height: 100),
                  const SizedBox(height: 16),
                  Text(
                    'Redeem Your Points',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter points to redeem (multiples of 10, max 10,000).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color.fromARGB(255, 95, 94, 94)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ], // Restrict to numbers
                    decoration: InputDecoration(
                      hintText: 'Points (e.g., 10, 20)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      errorText: isValid
                          ? null
                          : 'Enter valid points (multiples of 10)',
                    ),
                    onChanged: (value) {
                      final points = int.tryParse(value) ?? 0;
                      setState(() {
                        pointsToRedeem = points;
                        isValid = points > 0 &&
                            points <= currentPoints &&
                            points <= maxPoints &&
                            points % 10 == 0;
                        if (points > maxPoints) {
                          pointsController.text = maxPoints.toString();
                          pointsController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: pointsController.text.length),
                          );
                          pointsToRedeem = maxPoints;
                          isValid = true;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pointsToRedeem != null && pointsToRedeem! > 0
                        ? 'You will receive ${pointsToRedeem! ~/ 10} Pesos'
                        : '',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              actions: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCancelButton(context),
                      const SizedBox(width: 15),
                      _buildActionButton(
                        context,
                        'Redeem',
                        isValid
                            ? () => Navigator.pop(context, pointsToRedeem)
                            : () => _showErrorFlushbar(
                                context, 'Enter valid points'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, int redeemedPoints, int pointsPerPeso) async {
    return (await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Redemption'),
              content: Text(
                'Redeem $redeemedPoints points for ${redeemedPoints ~/ pointsPerPeso} Pesos?',
              ),
              actions: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCancelButton(context, result: false),
                      const SizedBox(width: 15),
                      _buildActionButton(context, 'Confirm',
                          () => Navigator.pop(context, true)),
                    ],
                  ),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  Future<bool> _showCreditCardBottomSheet(
      BuildContext context, int redeemedPoints, int pointsPerPeso) async {
    final formKey = GlobalKey<FormState>();
    String cardNumber = '';
    String expiryDate = '';
    String cardHolderName = '';
    String cvvCode = '';
    bool isCvvFocused = false;

    return (await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return CreditCardFormWithFlip(
                  formKey: formKey,
                  redeemedPoints: redeemedPoints,
                  pointsPerPeso: pointsPerPeso,
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  isCvvFocused: isCvvFocused,
                  onCreditCardModelChange: (CreditCardModel model) {
                    setState(() {
                      cardNumber = model.cardNumber;
                      expiryDate = model.expiryDate;
                      cardHolderName = model.cardHolderName;
                      cvvCode = model.cvvCode;
                      isCvvFocused = model.isCvvFocused;
                    });
                  },
                );
              },
            );
          },
        )) ??
        false;
  }

  Widget _buildCancelButton(BuildContext context, {bool result = false}) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: const Color(0xFF34A853)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context, result),
        child: const Text('Cancel'),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF34A853),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(text),
      ),
    );
  }

  Future<void> _processRedemption(
      BuildContext context, int redeemedPoints, int pointsPerPeso) async {
    // ignore: unused_local_variable
    bool isLoading = true;
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final tcToAdd = redeemedPoints ~/ pointsPerPeso;

      // Validate points
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final currentPoints = userDoc.data()?['totalPoints'] ?? 0;
      if (redeemedPoints > currentPoints) {
        throw Exception('Insufficient points');
      }

      // Update Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'totalPoints': FieldValue.increment(-redeemedPoints),
          'Pesos': FieldValue.increment(tcToAdd),
        });
      });

      // Record transaction
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(DateTime.now().millisecondsSinceEpoch.toString())
          .set({
        'userId': user.uid,
        'amount': tcToAdd,
        'type': 'withdrawal',
        'status': 'completed',
        'date': DateTime.now().toIso8601String(),
        'method': 'card',
        'details': {
          'cardNumber':
              '•••• XXXX', // Placeholder; replace with actual logic if needed
          'cardHolderName': 'REDACTED', // Avoid storing sensitive data
        },
      });

      // Deduct from admin cash balance
      await FirebaseFirestore.instance.collection('admin_transactions').add({
        'type': 'withdraw',
        'amount': tcToAdd,
        'description': 'User redemption: ${user.email} redeemed $redeemedPoints points for ₱$tcToAdd',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'pointsRedeemed': redeemedPoints,
      });

      // Add notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'type': 'redeem',
        'message':
            'Successfully redeemed $redeemedPoints points for $tcToAdd Pesos',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessFlushbar(context, 'Successfully redeemed $tcToAdd Pesos!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorFlushbar(context, _getUserFriendlyError(e.toString()));
      }
    } finally {
      isLoading = false;
    }
  }

  void _showSuccessFlushbar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Flushbar(
          message: message,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          borderRadius: BorderRadius.circular(8),
          margin: const EdgeInsets.all(8),
        ).show(context);
      }
    });
  }

  void _showErrorFlushbar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Flushbar(
          message: message,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          borderRadius: BorderRadius.circular(8),
          margin: const EdgeInsets.all(8),
        ).show(context);
      }
    });
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('Insufficient points')) {
      return 'You don\'t have enough points.';
    }
    if (error.contains('User not logged in')) {
      return 'Please log in to continue.';
    }
    if (error.contains('network')) return 'Network error. Please try again.';
    return 'An error occurred. Please try again.';
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'No',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        await _logoutUser();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OnboardingScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logoutUser() async {
    await AuthService().signOut();
    await Future.delayed(const Duration(milliseconds: 500));
    log('User logged out');
  }

  Future<void> _changeProfilePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final bytes = File(image.path).readAsBytesSync();
    String base64Image = base64Encode(bytes);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profilePicture': base64Image,
      });

      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Flushbar(
              message: 'Profile picture updated!',
              icon: const Icon(Icons.check_circle, color: Colors.white),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              borderRadius: BorderRadius.circular(8),
              margin: const EdgeInsets.all(8),
            ).show(context);
          }
        });
      }
    }
  }

  Map<String, dynamic> _aggregateRecyclingData(List<Map<String, dynamic>> list) {
    print('🔄 Aggregating ${list.length} deposit documents');
    double plasticWeightMonth = 0;
    int glassItemsMonth = 0;
    double plasticWeightTotal = 0;
    int glassItemsTotal = 0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    print('📅 Current month start: $startOfMonth');

    for (var item in list) {
      final sessionData = item['sessionData'] as Map<String, dynamic>? ?? {};
      final plasticCount = (sessionData['plasticCount'] as num?)?.toInt() ?? 0;
      final tinCount = (sessionData['tinCount'] as num?)?.toInt() ?? 0;
      final timestamp = item['timestamp'];

      print('📄 Processing document - Plastic: $plasticCount, Tin: $tinCount, Timestamp: $timestamp');

      // Check if this deposit is from this month
      bool isThisMonth = false;
      if (timestamp is Timestamp) {
        final depositDate = timestamp.toDate();
        isThisMonth = depositDate.isAfter(startOfMonth) || depositDate.isAtSameMomentAs(startOfMonth);
        print('📅 Deposit date: $depositDate, Is this month: $isThisMonth');
      }

      // Use session data counts - assuming plasticCount represents weight equivalent
      plasticWeightTotal += plasticCount.toDouble();
      glassItemsTotal += tinCount;

      if (isThisMonth) {
        plasticWeightMonth += plasticCount.toDouble();
        glassItemsMonth += tinCount;
      }
    }

    final result = {
      'plastic_weight_month': plasticWeightMonth,
      'glass_items_month': glassItemsMonth,
      'plastic_weight_total': plasticWeightTotal,
      'glass_items_total': glassItemsTotal,
    };
    print('✅ Final aggregated result: $result');
    return result;
  }

  TableRow _buildTableRow(
      String material, String month, String total, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(material),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15, top: 10),
          child: Text(
            '$month pcs',
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 10),
          child: Text(
            '$total pcs',
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('👤 Current user: ${user?.uid ?? 'null'}');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: const Icon(
              Icons.logout_outlined,
              color: Color(0xFF34A853),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _profileService.getProfileStats(),
              builder: (context, profileSnapshot) {
                print('🔄 Profile data snapshot: ${profileSnapshot.connectionState}');
                if (profileSnapshot.hasError) {
                  print('❌ Profile data error: ${profileSnapshot.error}');
                }
                if (profileSnapshot.hasData) {
                  print('✅ Profile data received: ${profileSnapshot.data}');
                }
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: user != null ? _profileService.getRecyclingStats(user.uid) : Stream.value([]),
                  builder: (context, recyclingSnapshot) {
                    print('🔄 Recycling data snapshot: ${recyclingSnapshot.connectionState}');
                    if (recyclingSnapshot.hasError) {
                      print('❌ Recycling data error: ${recyclingSnapshot.error}');
                    }
                    if (recyclingSnapshot.hasData) {
                      print('✅ Recycling data received: ${recyclingSnapshot.data?.length ?? 0} documents');
                    }
                    final profileData = profileSnapshot.data ?? {};
                    final recyclingList = recyclingSnapshot.data ?? [];
                    print('🔄 Aggregating recycling data');
                    print(recyclingSnapshot.data);
                    final recyclingData = _aggregateRecyclingData(recyclingList);

                    final totalPoints = profileData['totalPoints'] ?? 0;

                    final monthlyData = {
                      'plastic': (recyclingData['plastic_weight_month'] ?? 0.0)
                          .toInt(),
                      'glass':
                          (recyclingData['glass_items_month'] ?? 0).toInt(),
                    };

                    final totalData = {
                      'plastic': (recyclingData['plastic_weight_total'] ?? 0.0)
                          .toInt(),
                      'glass':
                          (recyclingData['glass_items_total'] ?? 0).toInt(),
                    };

                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        // Profile Image and Name
                        GestureDetector(
                          onTap: () => _changeProfilePicture(context),
                          child: Container(
                            width: double.infinity,
                            color: Colors.green[100]?.withOpacity(0.3),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        profileData['profilePicture'] != null
                                            ? MemoryImage(base64Decode(
                                                profileData['profilePicture']))
                                            : null,
                                    child: profileData['profilePicture'] == null
                                        ? const Icon(Icons.person,
                                            size: 50, color: Colors.grey)
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user?.displayName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Points Section
                        Container(
                          color: Colors.green[100]?.withOpacity(0.3),
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.height * 0.01,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.025,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Earned Total Points: ',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.018,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Text(
                                  '$totalPoints',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.height *
                                            0.02,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () =>
                                      _redeemPoints(context, totalPoints),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34A853),
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      vertical:
                                          MediaQuery.of(context).size.height *
                                              0.01,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                    'Redeem',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                              0.018,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Recycled Materials Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recycled Materials',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 160,
                                      width: double.infinity,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 120,
                                            width: 120,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                PieChart(
                                                  PieChartData(
                                                    sectionsSpace: 4,
                                                    centerSpaceRadius: 40,
                                                    sections: [
                                                      if (monthlyData[
                                                              'glass'] !=
                                                          0)
                                                        PieChartSectionData(
                                                          value: monthlyData[
                                                                  'glass']!
                                                              .toDouble(),
                                                          color: Colors
                                                              .green.shade200,
                                                          title: '',
                                                          radius: 25,
                                                        ),
                                                      if (monthlyData[
                                                              'plastic'] !=
                                                          0)
                                                        PieChartSectionData(
                                                          value: monthlyData[
                                                                  'plastic']!
                                                              .toDouble(),
                                                          color: const Color(
                                                              0xFF34A853),
                                                          title: '',
                                                          radius: 25,
                                                        ),
                                                      if (monthlyData[
                                                                  'glass'] ==
                                                              0 &&
                                                          monthlyData[
                                                                  'plastic'] ==
                                                              0)
                                                        PieChartSectionData(
                                                          value: 1,
                                                          color: Colors.grey
                                                              .withOpacity(0.2),
                                                          title: '',
                                                          radius: 25,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '${monthlyData['plastic']!.toInt() + monthlyData['glass']!} items',
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  'This month',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                    color: Colors.grey.shade300, thickness: 1),
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(1),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(1),
                                  },
                                  children: [
                                    const TableRow(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 0),
                                          child: Text(
                                            'MATERIAL',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 0),
                                          child: Text(
                                            'THIS MONTH',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(right: 15),
                                          child: Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildTableRow(
                                      'Plastic\nBottles',
                                      '${monthlyData['plastic']!.toInt()}',
                                      '${totalData['plastic']!.toInt()}',
                                      const Color(0xFF34A853),
                                    ),
                                    _buildTableRow(
                                      'Tin Cans',
                                      '${monthlyData['glass']}',
                                      '${totalData['glass']}',
                                      Colors.green.shade200,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CreditCardFormWithFlip extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final int redeemedPoints;
  final int pointsPerPeso;
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cvvCode;
  final bool isCvvFocused;
  final Function(CreditCardModel) onCreditCardModelChange;

  const CreditCardFormWithFlip({
    super.key,
    required this.formKey,
    required this.redeemedPoints,
    required this.pointsPerPeso,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.cvvCode,
    required this.isCvvFocused,
    required this.onCreditCardModelChange,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CreditCardFormWithFlipState createState() => _CreditCardFormWithFlipState();
}

class _CreditCardFormWithFlipState extends State<CreditCardFormWithFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetHeader(context),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 25),
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0 && !_showFront) {
                      _toggleCard();
                    } else if (details.primaryVelocity! < 0 && _showFront) {
                      _toggleCard();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_animation.value * 3.141592),
                        alignment: Alignment.center,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _animation.value <= 0.5
                              ? _buildCardFront(
                                  widget.cardNumber,
                                  widget.cardHolderName,
                                  widget.expiryDate,
                                  widget.isCvvFocused,
                                )
                              : Transform(
                                  transform: Matrix4.identity()
                                    ..rotateY(3.141592),
                                  alignment: Alignment.center,
                                  child: _buildCardBack(widget.cvvCode),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              CreditCardForm(
                formKey: widget.formKey,
                cardNumber: widget.cardNumber,
                expiryDate: widget.expiryDate,
                cardHolderName: widget.cardHolderName,
                cvvCode: widget.cvvCode,
                onCreditCardModelChange: (CreditCardModel data) {
                  widget.onCreditCardModelChange(data);
                  if (data.isCvvFocused != widget.isCvvFocused) {
                    _toggleCard();
                  }
                },
                inputConfiguration: InputConfiguration(
                  cardNumberDecoration: _buildInputDecoration(
                    'Card Number',
                    'XXXX XXXX XXXX XXXX',
                    icon: Icons.credit_card,
                  ),
                  expiryDateDecoration: _buildInputDecoration(
                    'Expiry Date',
                    'MM/YY',
                    icon: Icons.calendar_today,
                  ),
                  cvvCodeDecoration: _buildInputDecoration(
                    'CVV',
                    'XXX',
                    icon: Icons.lock,
                  ),
                  cardHolderDecoration: _buildInputDecoration(
                    'Card Holder Name',
                    'Full Name',
                    icon: Icons.person,
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                isHolderNameVisible: true,
                isCardNumberVisible: true,
                isExpiryDateVisible: true,
                enableCvv: true,
              ),
              _buildPaymentSummary(
                  context, widget.redeemedPoints, widget.pointsPerPeso),
              _buildBottomSheetButtons(context, widget.formKey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(
    String cardNumber,
    String cardHolderName,
    String expiryDate,
    bool isCvvFocused,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF34A853), Color(0xFF144221)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              'Visa Platinum',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset('assets/images/logo.png',
                  height: 20, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Text(
              cardNumber.isEmpty
                  ? '•••• •••• •••• ••••'
                  : cardNumber.replaceAllMapped(
                      RegExp(r'.{4}'),
                      (match) => '${match.group(0)} ',
                    ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARD HOLDER',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cardHolderName.isEmpty
                      ? 'YOUR NAME'
                      : cardHolderName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPIRES',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VISA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(String cvvCode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF144221), Color(0xFF34A853)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            height: 40,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 30,
                color: Colors.white,
              ),
              const Spacer(),
              Text(
                cvvCode.isEmpty ? '•••' : cvvCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'AUTHORIZED SIGNATURE - NOT VALID UNLESS SIGNED',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Reused UI components from ProfileScreen
  Widget _buildBottomSheetHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 30, right: 20),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Enter Card Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
      BuildContext context, int redeemedPoints, int pointsPerPeso) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Points Redeemed:'),
                Text('Peso Value:'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$redeemedPoints pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₱${redeemedPoints ~/ pointsPerPeso}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF34A853),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetButtons(
      BuildContext context, GlobalKey<FormState> formKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF34A853)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF34A853)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                } else {
                  _showErrorFlushbar(
                      context, 'Please enter valid card details');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Confirm Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorFlushbar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Flushbar(
          message: message,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          borderRadius: BorderRadius.circular(8),
          margin: const EdgeInsets.all(8),
        ).show(context);
      }
    });
  }

  InputDecoration _buildInputDecoration(String label, String hint,
      {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}
