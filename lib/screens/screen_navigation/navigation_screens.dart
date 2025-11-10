import 'package:another_flushbar/flushbar.dart';
import 'package:ecoearn/screens/report/report_screen.dart';
import 'package:ecoearn/screens/screen_navigation/qr.dart';
import 'package:flutter/material.dart';
import 'package:ecoearn/screens/home/home_screen.dart';
import 'package:ecoearn/screens/learn/learn.dart';
import 'package:ecoearn/screens/profile/profile_screen.dart';

class NavigationScreens extends StatefulWidget {
  const NavigationScreens({super.key});

  @override
  State<NavigationScreens> createState() => _NavigationScreensState();
}

class _NavigationScreensState extends State<NavigationScreens> {
  int _currentIndex = 0;

  final List<Widget> body = [
    const HomeScreen(),
    const LearnScreen(),
    const ReportScreen(),
     ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 0,
            child: body[_currentIndex],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );

          if (result != null) {
            Flushbar(
              message: "Scanned: $result",
              icon: const Icon(Icons.qr_code, color: Colors.white),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              flushbarPosition: FlushbarPosition.TOP,
              borderRadius: BorderRadius.circular(8),
              margin: const EdgeInsets.all(12),
              // ignore: use_build_context_synchronously
            ).show(context);
          }
        },
        shape: const CircleBorder(),
        // ignore: deprecated_member_use
        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.7),
        child: const Image(
          image: AssetImage('assets/images/qr-code.png'),
          height: 25,
          fit: BoxFit.contain,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navBarItem(icon: Icons.home_outlined, index: 0),
                _navBarItem(icon: Icons.lightbulb_outline, index: 1),
                const SizedBox(width: 40), // Space for FAB
                _navBarItem(icon: Icons.flag_outlined, index: 2),
                _navBarItem(icon: Icons.person_outline, index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBarItem({required IconData icon, required int index}) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              // ignore: deprecated_member_use
              isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
        ),
      ),
    );
  }
}
