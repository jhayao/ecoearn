import 'package:ecoearn/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignUpManager {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool acceptedTerms = false;

  void disposeControllers() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  void setAcceptedTerms(bool value) {
    acceptedTerms = value;
  }

  void showTermsAndPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms & Policy'),
          content: const SingleChildScrollView(
            child: Text(
                'Welcome to EcoEarn! By accessing or using our services, you agree to comply with the following terms and policies...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> handleSignUp(BuildContext context) async {
    if (!acceptedTerms) return false;

    String? error = await _authService.signUpWithEmail(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    if (error != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return false;
    }

    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/verify-email');
    return true;
  }

  List<Widget> buildFormFields(BuildContext context) {
    return [
      TextFormField(
        controller: nameController,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter your name' : null,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: emailController,
        validator: (value) => value == null || value.isEmpty
            ? 'Please enter a valid email'
            : null,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: passwordController,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter a password' : null,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: confirmPasswordController,
        validator: (value) =>
            value != passwordController.text ? 'Passwords do not match' : null,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Confirm password'),
      ),
    ];
  }
}
