// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class LearnScreen1 extends StatelessWidget {
  const LearnScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, screenWidth),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildImageRow(screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.03),
                      _buildRecyclableItemCard(
                        context: context,
                        title: 'Soda Cans (Recyclable)',
                        icon: Icons.recycling,
                        points: '+10 pts each',
                        description: [
                          'Made of aluminum which is infinitely recyclable',
                          'Empty and rinse cans before recycling',
                          "Leave labels on - they won't get removed during processing",
                          'Keep cans separate from other materials'
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildRecyclableItemCard(
                        context: context,
                        title: 'Plastic Bottles (Recyclable)',
                        icon: Icons.local_drink,
                        points: '+10 pts each',
                        description: [
                          'Keep the Bottles clean',
                          'Remove the water inside the bottles',
                          "Leave labels on - they won't get removed during processing",
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildDidYouKnowCard(context, screenWidth),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF34A853),
            Color(0xFF144221),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    width: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Text(
                'Learn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            'Bottles & Cans Recycling',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'Learn how to properly recycle beverage containers to maximize their reuse potential and earn rewards.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: screenWidth * 0.035,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.4,
      height: screenHeight * 0.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/ChatGPT Image Apr 15, 2025, 12_50_01 PM.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildRecyclableItemCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String points,
    required List<String> description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF34A853),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ),
                Chip(
                  backgroundColor: const Color(0xFFE8F5E9),
                  label: Text(
                    points,
                    style: const TextStyle(
                      color: Color(0xFF34A853),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...description.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0, right: 8.0),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF34A853),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDidYouKnowCard(BuildContext context, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFBC02D),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Did You Know?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF34A853),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recycling just one aluminum can saves enough energy to power a TV for 3 hours. '
              'Plastic bottles can take up to 450 years to decompose in landfills!',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: screenWidth * 0.035,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}