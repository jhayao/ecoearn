import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a 5-digit OTP
  String _generateOTP() {
    final random = Random();
    return (10000 + random.nextInt(90000)).toString();
  }

  // Get current time in Philippines timezone (UTC+8)
  DateTime _getPhilippinesTime() {
    final now = DateTime.now().toUtc();
    return now.add(const Duration(hours: 8)); // Philippines is UTC+8
  }

  // Store OTP in Firestore with expiration
  Future<void> _storeOTP(String email, String otp) async {
    final now = _getPhilippinesTime();
    final expiration = now.add(const Duration(minutes: 5)); // OTP expires in 5 minutes

    await _firestore.collection('otp_verification').doc(email).set({
      'otp': otp,
      'email': email,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiration),
      'isUsed': false,
      'timezone': 'Asia/Manila', // Store timezone info
    });
  }

  // Send OTP to user via Gmail
  Future<bool> sendOTP(String email) async {
    try {
      final otp = _generateOTP();
      await _storeOTP(email, otp);
      
      // Send real email via Gmail
      await _sendEmailOTP(email, otp);
      
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Send OTP via Gmail
  Future<void> _sendEmailOTP(String email, String otp) async {
    try {
      // Configure Gmail SMTP server
      final smtpServer = gmail('ecoearn2025@gmail.com', 'ynlw wnhe pivz jdkb');
      
      final message = Message()
        ..from = const Address('ecoearn2025@gmail.com', 'EcoEarn')
        ..recipients.add(email)
        ..subject = 'EcoEarn - OTP Verification Code'
        ..html = '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>EcoEarn OTP</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #34A853, #0D652D); color: white; padding: 30px; text-align: center; }
              .content { padding: 30px; }
              .otp-code { font-size: 32px; font-weight: bold; color: #34A853; text-align: center; margin: 20px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px; letter-spacing: 5px; }
              .footer { background-color: #f8f9fa; padding: 20px; text-align: center; color: #666; font-size: 14px; }
              .warning { color: #ff6b6b; font-weight: bold; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🌱 EcoEarn</h1>
                <p>Your OTP Verification Code</p>
              </div>
              <div class="content">
                <h2>Hello!</h2>
                <p>You're almost ready to join EcoEarn! Use the verification code below to complete your registration:</p>
                
                <div class="otp-code">$otp</div>
                
                <p><strong>Important:</strong></p>
                <ul>
                  <li>This code will expire in <span class="warning">5 minutes</span></li>
                  <li>Do not share this code with anyone</li>
                  <li>If you didn't request this code, please ignore this email</li>
                </ul>
                
                <p>Thank you for helping make our planet greener! 🌍</p>
              </div>
              <div class="footer">
                <p>© 2024 EcoEarn - Waste Management App</p>
                <p>This is an automated message, please do not reply.</p>
              </div>
            </div>
          </body>
          </html>
        ''';
      
      await send(message, smtpServer);
      print('OTP email sent successfully to $email');
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String enteredOTP) async {
    try {
      final doc = await _firestore.collection('otp_verification').doc(email).get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'OTP not found. Please request a new one.',
        };
      }

      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final isUsed = data['isUsed'] as bool;

      // Check if OTP is already used
      if (isUsed) {
        return {
          'success': false,
          'message': 'OTP has already been used. Please request a new one.',
        };
      }

      // Check if OTP is expired (using Philippines time)
      final currentTime = _getPhilippinesTime();
      if (currentTime.isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // Check if OTP matches
      if (enteredOTP != storedOTP) {
        return {
          'success': false,
          'message': 'Wrong code, please try again.',
        };
      }

      // Mark OTP as used
      await _firestore.collection('otp_verification').doc(email).update({
        'isUsed': true,
      });

      return {
        'success': true,
        'message': 'OTP verified successfully!',
      };
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String email) async {
    try {
      // Delete existing OTP
      await _firestore.collection('otp_verification').doc(email).delete();
      
      // Generate and send new OTP
      return await sendOTP(email);
    } catch (e) {
      print('Error resending OTP: $e');
      return false;
    }
  }

  // Clean up expired OTPs (call this periodically)
  Future<void> cleanupExpiredOTPs() async {
    try {
      final currentTime = _getPhilippinesTime();
      final query = await _firestore
          .collection('otp_verification')
          .where('expiresAt', isLessThan: Timestamp.fromDate(currentTime))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }
}
