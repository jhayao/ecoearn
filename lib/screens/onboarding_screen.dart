// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../widgets/eco_earn_logo.dart';

class CustomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(
        0, size.height - size.height * 0.2); // Start lower for the curve

    var controlPoint = Offset(size.width / 2, size.height + size.height * 0.2);
    var endPoint = Offset(size.width, size.height - size.height * 0.2);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                isLastPage = index == 2;
              });
            },
            children: [
              Container(
                color: Colors.white,
                child: Center(
                  child: EcoEarnLogo(height: screenHeight * 0.05),
                ),
              ),
              OnboardingPage(
                image: 'assets/images/Group 36700.png',
                title: 'Recycle',
                description:
                    'New memories will be made. A much better option than being discarded and forgotten by becoming part of the adventure - recycle now!',
                backgroundColor: const Color(0xFF2E7D32),
                controller: _controller,
                isLastPage: isLastPage,
              ),
              OnboardingPage(
                image: 'assets/images/rewards_illustration.png',
                title: 'Get Rewards',
                description:
                    'You can participate and earn points. You will be rewarded with prizes from us when you complete a challenge recycle.',
                backgroundColor: const Color(0xFF2E7D32),
                showButton: true,
                controller: _controller,
                isLastPage: isLastPage,
                onButtonPressed: () {
                  Navigator.pushReplacementNamed(context, '/signin');
                },
              ),
            ],
          ),
          Positioned(
            bottom: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.40),
              child: Container(
                height: screenHeight * 0.02,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 241, 241),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const WormEffect(
                      spacing: 7,
                      dotHeight: 7,
                      dotWidth: 7,
                      dotColor: Colors.black26,
                      activeDotColor: Color(0xFF2E7D32),
                    ),
                    onDotClicked: (index) => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final Color backgroundColor;
  final bool showButton;
  final VoidCallback? onButtonPressed;
  final PageController controller;
  final bool isLastPage;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.controller,
    required this.isLastPage,
    this.showButton = false,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    double getFontSize(double smallScreenSize, double largeScreenSize) {
      return isLargeScreen ? largeScreenSize : smallScreenSize;
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _buildCurvedBackground(size.height * 0.42, size.height * 0.4),
                SafeArea(
                  child: Center(
                    child: Image.asset(
                      image,
                      height: size.height * 0.35,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.05),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: getFontSize(size.width * 0.07, size.width * 0.05),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lato',
                  color: Colors.black54,
                  fontSize: getFontSize(size.width * 0.05, size.width * 0.04),
                ),
              ),
            ),
            if (showButton)
              Padding(
                padding: EdgeInsets.only(top: size.height * 0.05),
                child: GestureDetector(
                  onTap: onButtonPressed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.25,
                      vertical: size.height * 0.015,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34A853), Color(0xFF144221)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: getFontSize(size.width * 0.05, size.width * 0.04),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedBackground(double lightHeight, double gradientHeight) {
    return Stack(
      children: [
        ClipPath(
          clipper: CustomCurveClipper(),
          child: Container(
            height: lightHeight,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.05)),
          ),
        ),
        ClipPath(
          clipper: CustomCurveClipper(),
          child: Container(
            height: gradientHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF34A853), Color(0xFF144221)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
