import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:image_picker/image_picker.dart';
import '../services/bin_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final BinService _binService = BinService();
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;
  String? _currentSessionId;
  String? _currentBinId;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final binId = barcode.rawValue!;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showError('Please log in to use this feature');
        return;
      }

      // Get current location
      final position = await _getCurrentLocation();

      // Activate bin
      final result = await _binService.activateBin(
        binId: binId,
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _currentSessionId = result['data']['sessionId'];
        _currentBinId = binId;
      });

      _showSuccess('Bin activated successfully!');
      
      // Navigate back or to bin control screen
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, {
            'sessionId': _currentSessionId,
            'binId': _currentBinId,
            'activated': true,
          });
        }
      });
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Please enable location services');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission is required');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  void _showError(String message) {
    Future.microtask(() {
      Flushbar(
        message: message,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(8),
      ).show(context);
    });
  }

  void _showSuccess(String message) {
    Future.microtask(() {
      Flushbar(
        message: message,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(8),
      ).show(context);
    });
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() => _isProcessing = true);

      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);

      if (capture == null || capture.barcodes.isEmpty) {
        _showError('No QR code found in the image');
        setState(() => _isProcessing = false);
        return;
      }

      final barcode = capture.barcodes.first;
      if (barcode.rawValue == null) {
        _showError('Invalid QR code');
        setState(() => _isProcessing = false);
        return;
      }

      final binId = barcode.rawValue!;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showError('Please log in to use this feature');
        setState(() => _isProcessing = false);
        return;
      }

      final position = await _getCurrentLocation();

      final result = await _binService.activateBin(
        binId: binId,
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _currentSessionId = result['data']['sessionId'];
        _currentBinId = binId;
      });

      _showSuccess('Bin activated successfully!');
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, {
            'sessionId': _currentSessionId,
            'binId': _currentBinId,
            'activated': true,
          });
        }
      });
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: const Color(0xFF34A853),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_scannerController.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Scanning frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions and Gallery button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Position QR code within the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The bin will unlock automatically',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickImageAndScan,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick from Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Activating bin...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
