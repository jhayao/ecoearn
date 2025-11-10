import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/otp_service.dart';
import '../../widgets/eco_earn_logo.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String password;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final OTPService _otpService = OTPService();
  final List<TextEditingController> _controllers = List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 0;
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _sendInitialOTP();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 300; // 5 minutes = 300 seconds
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  Future<void> _sendInitialOTP() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final success = await _otpService.sendOTP(widget.email);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (!success) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to send OTP. Please try again.';
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResending = true;
      _hasError = false;
    });

    final success = await _otpService.resendOTP(widget.email);
    
    if (mounted) {
      setState(() {
        _isResending = false;
      });
      
      if (success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((controller) => controller.text).join();
    
    if (otp.length != 5) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter the complete 5-digit code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await _otpService.verifyOTP(widget.email, otp);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // OTP verified successfully, now create the user account
        await _createUserAccount();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'];
        });
        
        // Clear all input fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _createUserAccount() async {
    try {
      // Create user account
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(widget.name);

      // Mark email as verified since we verified via OTP
      await userCredential.user?.reload();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 4) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const Spacer(flex: 1),
              
              // Logo
              const Center(
                child: EcoEarnLogo(height: 50),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Verify code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Instructions
              RichText(
                text: TextSpan(
                  text: 'Please enter the code we just sent to\n',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        color: Color(0xFF34A853),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasError ? Colors.red : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) {
                        _onDigitChanged(index, value);
                        if (value.isEmpty && index > 0) {
                          _onBackspace(index);
                        }
                      },
                      onTap: () {
                        if (_controllers[index].text.isNotEmpty) {
                          _controllers[index].selection = TextSelection.fromPosition(
                            TextPosition(offset: _controllers[index].text.length),
                          );
                        }
                      },
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 20),
              
              // Error Message
              if (_hasError)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Resend OTP
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Send code again ${(_resendTimer ~/ 60).toString().padLeft(2, '0')}:${(_resendTimer % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resendOTP,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF34A853),
                                ),
                              )
                            : const Text(
                                'Send code again',
                                style: TextStyle(
                                  color: Color(0xFF34A853),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
              ),
              
              const Spacer(flex: 2),
              
              // Verify Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34A853), Color(0xFF0D652D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
