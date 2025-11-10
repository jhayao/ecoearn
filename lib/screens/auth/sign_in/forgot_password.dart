import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final email = TextEditingController();

  final isSubmit = false.obs;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(height: 80),

              // Title
              const Text(
                "Forgot Password",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              const Text(
                "Opps. It happens to the best of us. Input your email address to fix the issue.",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Email Input Field
              const Text(
                "Email",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: email,
                  cursorColor: Colors.grey,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    suffixIcon:
                        const Icon(Icons.email_outlined, color: Colors.white54),
                    hintText: "Enter your email",
                    hintStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              GestureDetector(
                onTap: forgot,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF34A853),
                        Color(0xFF144221),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Center(
                    child: Obx(() => Text(
                          isSubmit.value ? 'Submitting...' : "Submit",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void forgot() async {
    await _auth.sendPasswordResetEmail(email: email.text);
    isSubmit.value = true;
    Get.back();
    Get.snackbar('Success', 'Please check your email reset link!',
        colorText: Colors.black);
    if (email.text == '') {
      isSubmit.value = false;
    }
  }
}
