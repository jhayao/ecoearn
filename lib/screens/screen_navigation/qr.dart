import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/bin_service.dart';
import '../bin_status_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  bool _isPermissionGranted = false;
  bool _isScanning = true;
  String? _lastScannedCode;
  bool _isFlashOn = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.greenAccent.withOpacity(0.7),
      end: Colors.lightGreen.withOpacity(0.9),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      if (mounted) {
        _showErrorFlushbar(
          title: 'Permission Required',
          message: 'Camera access is needed to scan QR codes',
          icon: Icons.camera_alt,
        );
      }
    }
  }

  Future<void> _handleScannedData(String code) async {
    // Prevent duplicate scans
    if (code == _lastScannedCode || !_isScanning) return;
    
    // Haptic feedback for better UX
    HapticFeedback.mediumImpact();
    
    setState(() {
      _lastScannedCode = code;
      _isScanning = false;
    });

    // Stop the scanner immediately
    controller.stop();

    print('📷 QR Code scanned: $code');

    try {
      // Try to parse as JSON (bin data)
      final Map<String, dynamic> binData = jsonDecode(code);
      if (binData.containsKey('binId')) {
        print('✅ Detected bin QR code');
        // This is a bin QR code
        _showBinDetailsDialog(binData);
        return;
      }
    } catch (e) {
      // Not JSON, treat as URL or regular text
      print('ℹ️ Not a bin QR code, treating as URL/text');
    }

    // Handle as URL or regular text
    _showSuccessFlushbar(
      title: 'Scanned Successfully',
      message: code,
      onTap: () => _launchUrl(code),
    );

    await _launchUrl(code);
  }

  void _showBinDetailsDialog(Map<String, dynamic> binData) async {
    // Get user location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BinDetailsDialog(
        binData: binData,
        userLocation: position,
      ),
    );

    // If dialog was dismissed without activation (result is null or false), restart scanner
    if (result != true && mounted) {
      _restartScanner();
    }
  }

  Future<void> _launchUrl(String code) async {
    final Uri? uri = Uri.tryParse(code);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showInfoFlushbar(
          title: 'Scanned Content',
          message: code,
        );
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      controller.toggleTorch();
    });
  }

  void _restartScanner() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
    });
    // Restart the scanner
    controller.start();
  }

  void _showSuccessFlushbar({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    Flushbar(
      title: title,
      titleColor: Colors.white,
      message: message,
      messageColor: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      mainButton: TextButton(
        onPressed: onTap,
        child: const Text('OPEN', style: TextStyle(color: Colors.white)),
      ),
      onTap: (_) => onTap?.call(),
    ).show(context);
  }

  void _showErrorFlushbar({
    required String title,
    required String message,
    IconData? icon,
  }) {
    Flushbar(
      title: title,
      titleColor: Colors.white,
      message: message,
      messageColor: Colors.white,
      icon: Icon(icon ?? Icons.error, color: Colors.white),
      backgroundColor: Colors.red.shade600,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  void _showInfoFlushbar({
    required String title,
    required String message,
  }) {
    Flushbar(
      title: title,
      titleColor: Colors.white,
      message: message,
      messageColor: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      backgroundColor: Colors.blue.shade600,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR Scanner', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: !_isPermissionGranted
          ? _buildPermissionRequestView()
          : _buildScannerView(),
      floatingActionButton: !_isScanning
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                width: 150,
                height: 50,
                child: FloatingActionButton.extended(
                  onPressed: _restartScanner,
                  icon: const Image(
                    image: AssetImage('assets/images/qr-code.png'),
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  label: const Text('Scan Again',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green.shade700,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPermissionRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.white),
            const SizedBox(height: 30),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'To scan QR codes, we need access to your camera. Please grant permission to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _checkCameraPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 4,
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (barcodeCapture) {
            // Only process if we're actively scanning
            if (!_isScanning) return;
            
            final List<Barcode> barcodes = barcodeCapture.barcodes;
            if (barcodes.isNotEmpty && mounted) {
              final String? code = barcodes.first.rawValue;
              if (code != null && code.isNotEmpty) {
                _handleScannedData(code);
              }
            }
          },
        ),
        _buildScannerOverlay(),
        if (_isScanning) _buildScannerInstructions(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _colorAnimation.value!,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScannerInstructions() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: _isScanning ? 1.0 : 2.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                Text(
                  'Align QR Code',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Position the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Scanning automatically...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BinDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> binData;
  final Position? userLocation;

  const BinDetailsDialog({
    super.key,
    required this.binData,
    this.userLocation,
  });

  @override
  State<BinDetailsDialog> createState() => _BinDetailsDialogState();
}

class _BinDetailsDialogState extends State<BinDetailsDialog> {
  final BinService _binService = BinService();
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _activateBin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    if (widget.userLocation == null) {
      _showErrorSnackBar('Unable to get your location');
      return;
    }

    setState(() => _isActivating = true);

    try {
      print('📱 Starting bin activation...');
      print('📱 Bin ID: ${widget.binData['binId']}');
      print('📱 User ID: ${user.uid}');
      print('📱 Location: ${widget.userLocation!.latitude}, ${widget.userLocation!.longitude}');

      final response = await _binService.activateBin(
        binId: widget.binData['binId'],
        userId: user.uid,
        latitude: widget.userLocation!.latitude,
        longitude: widget.userLocation!.longitude,
      );

      print('✅ Activation response: $response');

      if (response['success'] == true) {
        final sessionId = response['data']['sessionId'];
        
        _showSuccessSnackBar('Bin activated successfully!');
        
        // Navigate to bin status screen after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            // Close the dialog with true result (successful activation)
            Navigator.of(context).pop(true);
            
            // Navigate to bin status screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BinStatusScreen(
                  binData: widget.binData,
                  sessionId: sessionId,
                ),
              ),
            );
          }
        });
      } else {
        _showErrorSnackBar(response['error'] ?? 'Failed to activate bin');
      }
    } catch (e, stackTrace) {
      print('❌ Activation error: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Show more detailed error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }
      _showErrorSnackBar('Error: $errorMessage');
    } finally {
      setState(() => _isActivating = false);
    }
  }

  void _showErrorSnackBar(String message) {
    print('🔴 Error shown to user: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    print('✅ Success shown to user: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34A853),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final binData = widget.binData;
    final fillLevel = binData['fillLevel'] as int? ?? binData['level'] as int? ?? 0;
    
    Color fillLevelColor = Colors.green;
    if (fillLevel >= 80) {
      fillLevelColor = Colors.red;
    } else if (fillLevel >= 50) {
      fillLevelColor = Colors.orange;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: Color(0xFF34A853),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          binData['name'] ?? 'Unknown Bin',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Recycling Bin Details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bin Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Bin ID', binData['binId'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Fill Level', '$fillLevel%', valueColor: fillLevelColor),
                    if (binData['location'] != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Location',
                        binData['location']['address'] ?? 'N/A',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Status Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Activate the bin to start recycling.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Activate Button
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isActivating ? null : _activateBin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isActivating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Activate Bin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

}
