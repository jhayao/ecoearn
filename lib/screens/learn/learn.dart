// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'learn_screen1.dart';
import 'learn_screen2.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(screenWidth),
                SizedBox(height: screenHeight * 0.02),
                _buildSectionTitle('Good to know', screenWidth),
                SizedBox(height: screenHeight * 0.03),
                _buildInfoCards(context, screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.03),
                _buildSectionTitle('Topic for you', screenWidth),
                SizedBox(height: screenHeight * 0.03),
                _buildTopicList(context, screenWidth, screenHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text.rich(
        TextSpan(
          text: 'Waste Less, ',
          style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.black),
          children: const [
            TextSpan(text: 'Live More!', style: TextStyle(color: Colors.green)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(left: screenWidth * 0.02),
      child: Text(
        title,
        style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoCards(
      BuildContext context, double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoCard(
          title: 'What plastics\ncan be recycled?',
          iconPath: 'assets/images/image 35.png',
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LearnScreen1()));
          },
        ),
        _buildInfoCard(
          title: 'Ways to\nreduce waste',
          iconPath: 'assets/images/image 37 (1).png',
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LearnScreen2()));
          },
        ),
      ],
    );
  }

  Widget _buildTopicList(
      BuildContext context, double screenWidth, double screenHeight) {
    final topics = [
      {
        'imagePath': 'assets/images/image (0).png',
        'title': 'Waste to artwork',
        'description':
            'Artists use recycled or reused objects to make attractive pieces of contemporary art.',
        'content':
            'Recycled art is transforming waste into beautiful creations. Artists worldwide are using materials like plastic bottles, scrap metal, and discarded electronics to create stunning sculptures, paintings, and installations. This movement not only reduces waste but also raises awareness about sustainability through creative expression.',
      },
      {
        'imagePath': 'assets/images/image (1).png',
        'title': 'Become a volunteer',
        'description':
            'Join efforts to recycle and reduce waste through volunteering activities in your community.',
        'content':
            'Volunteering for environmental causes makes a real difference. You can participate in beach cleanups, recycling drives, or educational programs. Many organizations need help sorting recyclables, organizing events, or teaching others about sustainable practices. Even a few hours a month can contribute significantly to your community\'s environmental health.',
      },
      {
        'imagePath': 'assets/images/image (2).png',
        'title': 'Community Recycling',
        'description':
            'Learn how communities work together to promote recycling and sustainability.',
        'content':
            'Community recycling programs are essential for effective waste management. Many neighborhoods now have shared composting systems, recycling centers, and repair cafes where items are fixed rather than discarded. Successful programs often involve local businesses, schools, and government working together to create convenient and effective recycling solutions tailored to their community\'s needs.',
      },
    ];

    return Column(
      children: topics.map((topic) {
        return Column(
          children: [
            _buildTopicCard(
              imagePath: topic['imagePath']!,
              title: topic['title']!,
              description: topic['description']!,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              onTap: () => _showTopicDetails(context, topic),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        );
      }).toList(),
    );
  }

  void _showTopicDetails(BuildContext context, Map<String, String> topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          topic['imagePath']!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topic['title']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topic['content']!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A9C45),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: screenHeight * 0.22,
        width: screenWidth * 0.4,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Image.asset(iconPath,
                height: screenHeight * 0.12, width: screenWidth * 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard({
    required String imagePath,
    required String title,
    required String description,
    required double screenWidth,
    required double screenHeight,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: screenHeight * 0.20,
          width: screenWidth * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4)
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                        color: Colors.white70, fontSize: screenWidth * 0.035),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
