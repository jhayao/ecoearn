// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class LearnScreen2 extends StatelessWidget {
  const LearnScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

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
                    horizontal:
                        isPortrait ? screenWidth * 0.05 : screenWidth * 0.15,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: isPortrait
                              ? screenHeight * 0.03
                              : screenHeight * 0.05),
                      _buildComparisonSection(
                          screenWidth, screenHeight, isPortrait),
                      SizedBox(
                          height: isPortrait
                              ? screenHeight * 0.04
                              : screenHeight * 0.06),
                      _buildImpactStats(screenWidth, isPortrait),
                      SizedBox(
                          height: isPortrait
                              ? screenHeight * 0.04
                              : screenHeight * 0.06),
                      _buildBenefitsSection(screenWidth, isPortrait),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34A853),
            Color(0xFF1B5E20),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                'Sustainable Living',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            'Smart Swaps for a Greener Future',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Small changes create big impacts. Switching to reusable bottles helps reduce plastic waste and conserve resources.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: screenWidth * 0.038,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(
      double screenWidth, double screenHeight, bool isPortrait) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildProductCard(
              'Single-Use Plastic',
              'assets/images/image 37.png',
              Colors.red[100]!,
              screenWidth,
              screenHeight,
              isPortrait,
            ),
            _buildProductCard(
              'Reusable Bottle',
              'assets/images/image 38.png',
              Colors.green[100]!,
              screenWidth,
              screenHeight,
              isPortrait,
            ),
          ],
        ),
        SizedBox(
            height: isPortrait ? screenHeight * 0.02 : screenHeight * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconWithLabel(Icons.close, 'Avoid', Colors.red, screenWidth),
            _buildIconWithLabel(
                Icons.check, 'Choose', const Color(0xFF2E7D32), screenWidth),
          ],
        ),
      ],
    );
  }

  Widget _buildProductCard(String label, String imagePath, Color bgColor,
      double screenWidth, double screenHeight, bool isPortrait) {
    return Column(
      children: [
        Container(
          width: isPortrait ? screenWidth * 0.35 : screenWidth * 0.25,
          height: isPortrait ? screenHeight * 0.2 : screenHeight * 0.25,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isPortrait ? screenWidth * 0.04 : screenWidth * 0.025,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildIconWithLabel(
      IconData icon, String label, Color color, double screenWidth) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: screenWidth * 0.08,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStats(double screenWidth, bool isPortrait) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPortrait ? 20 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights,
                  color: Colors.green[800], size: screenWidth * 0.06),
              const SizedBox(width: 8),
              Text(
                'Environmental Impact',
                style: TextStyle(
                  fontSize:
                      isPortrait ? screenWidth * 0.05 : screenWidth * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: isPortrait ? 16 : 24),
          _buildStatItem(
              '156', 'plastic bottles saved per year', screenWidth, isPortrait),
          SizedBox(height: isPortrait ? 12 : 18),
          _buildStatItem(
              '50%', 'reduction in carbon footprint', screenWidth, isPortrait),
          SizedBox(height: isPortrait ? 12 : 18),
          _buildStatItem('\$200+', 'annual savings', screenWidth, isPortrait),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, double screenWidth, bool isPortrait) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: isPortrait ? screenWidth * 0.04 : screenWidth * 0.025,
                color: Colors.grey[800],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$value ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                TextSpan(text: label),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(double screenWidth, bool isPortrait) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Benefits:',
            style: TextStyle(
              fontSize: isPortrait ? screenWidth * 0.05 : screenWidth * 0.03,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B5E20),
            ),
          ),
          SizedBox(height: isPortrait ? 16 : 24),
          _buildBenefitItem(
            'Stay hydrated with clean water while reducing plastic waste',
            Icons.water_drop,
            screenWidth,
            isPortrait,
          ),
          SizedBox(height: isPortrait ? 12 : 18),
          _buildBenefitItem(
            'Save money by avoiding costly bottled water purchases',
            Icons.savings,
            screenWidth,
            isPortrait,
          ),
          SizedBox(height: isPortrait ? 12 : 18),
          _buildBenefitItem(
            'Reduce your carbon footprint with every refill',
            Icons.eco,
            screenWidth,
            isPortrait,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
      String text, IconData icon, double screenWidth, bool isPortrait) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: isPortrait ? screenWidth * 0.06 : screenWidth * 0.04,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isPortrait ? screenWidth * 0.04 : screenWidth * 0.025,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
