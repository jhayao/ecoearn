import 'package:ecoearn/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignInManager {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void disposeControllers() {
    emailController.dispose();
    passwordController.dispose();
  }

  Future<bool> handleSignIn(BuildContext context) async {
    String? error = await _authService.signInWithEmail(
      email: emailController.text,
      password: passwordController.text,
    );

    if (error != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return false;
    }
    return true;
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34A853),
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Successfully Signed In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome back to EcoEarn!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 112, 111, 111),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF34A853),
                        Color(0xFF144221),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacementNamed(
                          context, '/home'); // Navigate to home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> buildFormFields(
      BuildContext context, VoidCallback ontap, bool isPasswordVisible) {
    return [
      TextFormField(
        controller: emailController,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter your email' : null,
        decoration: const InputDecoration(
          labelText: 'Email',
          filled: true,
          fillColor: Color.fromARGB(255, 243, 243, 243),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      const SizedBox(height: 15),
      TextFormField(
        controller: passwordController,
        validator: (value) => value == null || value.isEmpty
            ? 'Please enter your password'
            : null,
        obscureText: isPasswordVisible,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: ontap,
          ),
          hintStyle: const TextStyle(color: Colors.black54),
          labelText: 'Password',
          filled: true,
          fillColor: const Color.fromARGB(255, 243, 243, 243),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    ];
  }
}
