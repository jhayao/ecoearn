// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:ecoearn/screens/home/bincard.dart';
import 'package:ecoearn/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/waste_service.dart';
import '../../screens/notifications/notifications_screen.dart';

class CustomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height);
    var secondEndPoint = Offset(size.width, size.height - 80);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WasteService _wasteService = WasteService();
  Timer? _timer;
  int _currentInfoIndex = 0;
  bool _hasUnreadNotifications = false;

  final List<Map<String, String>> _infoItems = [
    {
      'image': 'assets/images/image.png',
      'text': 'REDUCE\nMinimize your waste',
    },
    {
      'image': 'assets/images/image 2.png',
      'text': 'REUSE\nGive items a second life',
    },
    {
      'image': 'assets/images/image 1.png',
      'text': 'RECYCLE\nTransform waste to new',
    },
  ];

  @override
  void initState() {
    super.initState();
    _wasteService.initializeUserStats();
    _startAutoChange();
    _checkNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoChange() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentInfoIndex = (_currentInfoIndex + 1) % _infoItems.length;
      });
    });
  }

  void _checkNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  Widget _buildInfoSection() {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(top: size.height * 0.025),
      child: Center(
        child: Column(
          children: [
            Container(
              height: size.height * 0.25,
              width: size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(size.width * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: size.width * 0.02,
                    offset: Offset(0, size.height * 0.005),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.width * 0.05),
                child: Image.asset(
                  _infoItems[_currentInfoIndex]['image']!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshHomeScreen() async {
    // Re-initialize or fetch any data you want refreshed
    await _wasteService.initializeUserStats();
    _checkNotifications();

    setState(() {
      // Optionally reset the info index or other state if needed
      _currentInfoIndex = 0;
    });
  }

  Future<bool> onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              Row(
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
                  const SizedBox(
                    width: 10,
                  ),
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (mounted) {
                          Navigator.of(context).pop(true);
                          Navigator.of(context).pushReplacementNamed('/signin');
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ')[0] ?? 'User';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshHomeScreen,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: MediaQuery.of(context).size.height * 0.31,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    ClipPath(
                      clipper: CustomCurveClipper(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.07),
                        ),
                      ),
                    ),
                    ClipPath(
                      clipper: CustomCurveClipper(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.33,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF34A853),
                              Color(0xFF144221),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.width * 0.1,
                            left: MediaQuery.of(context).size.height * 0.03,
                            right: MediaQuery.of(context).size.height * 0.03,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user?.uid)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            debugPrint(
                                                'Error in user profile stream: ${snapshot.error}');
                                            return const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Color(0xFF2E7D32),
                                            );
                                          }
                                          if (!snapshot.hasData) {
                                            return const CircularProgressIndicator();
                                          }
                                          final userData = snapshot.data?.data()
                                              as Map<String, dynamic>?;
                                          final profilePicture =
                                              userData?['profilePicture'];

                                          return ClipOval(
                                            child: profilePicture != null
                                                ? Image.memory(
                                                    base64Decode(
                                                        profilePicture),
                                                    height: 50,
                                                    width: 50,
                                                    fit: BoxFit.cover,
                                                    gaplessPlayback: true,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      debugPrint(
                                                          'Error loading profile picture: $error');
                                                      return const Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color:
                                                            Color(0xFF2E7D32),
                                                      );
                                                    },
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Color(0xFF2E7D32),
                                                  ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hi, $firstName!',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Start Recycling Today!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationsScreen(),
                                            ),
                                          );

                                          if (_hasUnreadNotifications) {
                                            if (user != null) {
                                              FirebaseFirestore.instance
                                                  .collection('notifications')
                                                  .where('userId',
                                                      isEqualTo: user.uid)
                                                  .where('read',
                                                      isEqualTo: false)
                                                  .get()
                                                  .then((notifications) {
                                                final batch = FirebaseFirestore
                                                    .instance
                                                    .batch();
                                                for (var doc
                                                    in notifications.docs) {
                                                  batch.update(doc.reference,
                                                      {'read': true});
                                                }
                                                return batch.commit();
                                              }).catchError((error) {
                                                debugPrint(
                                                    'Error marking notifications as read: $error');
                                              });
                                            }
                                          }
                                        },
                                        child: Stack(
                                          children: [
                                            const Icon(
                                              Icons.notifications_outlined,
                                              color: Colors.white,
                                            ),
                                            if (_hasUnreadNotifications)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                    minWidth: 8,
                                                    minHeight: 8,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildStatsContainer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: MediaQuery.of(context).size.height * 0.25,
              floating: false,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildInfoSection(),
              ),
            ),
            NearbyBinsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContainer() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _wasteService.getWasteStats(),
      builder: (context, snapshot) {
        // Show default values for any state (loading, error, or no data)
        final data = snapshot.data ??
            {
              'totalPoints': 0,
            };
        final points = data['totalPoints'];

        return Padding(
          padding: const EdgeInsets.all(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total points collected',
                      style: TextStyle(
                        color: Color.fromARGB(255, 116, 115, 115),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF34A853),
                            Color(0xFF144221),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$points pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
