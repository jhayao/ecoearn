import 'package:ecoearn/screens/screen_navigation/navigation_screens.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/sign_in/sign_in_screen.dart';
import 'screens/auth/sign_up/sign_up_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/otp_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EcoEarn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        textTheme: GoogleFonts.latoTextTheme(),
        useMaterial3: true,
      ),
      // Use a home widget to dynamically determine the initial screen
      home: const AuthWrapper(),
      routes: {
        // Removed '/' entry to avoid conflict with home
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/verify-email': (context) => const EmailVerificationScreen(),
        '/verify-otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return OTPVerificationScreen(
            email: args?['email'] ?? '',
            name: args?['name'] ?? '',
            password: args?['password'] ?? '',
          );
        },
        '/home': (context) => const NavigationScreens(),
      },
    );
  }
}


// Wrapper for user app to check authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          // Since we're using OTP verification, users are automatically verified
          // when they reach this point (account is created after OTP verification)
          return const NavigationScreens(); // Redirect to home screen
        }
        return const OnboardingScreen(); // Show onboarding for unauthenticated users
      },
    );
  }
}
