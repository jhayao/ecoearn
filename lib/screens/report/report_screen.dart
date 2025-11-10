import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../report/report_controller.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}
 
class _ReportScreenState extends State<ReportScreen> {
  final ReportController _reportController = ReportController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isLoading = false;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserInfo();
    await _fetchLocation();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showFlushbar('User not logged in. Please log in to submit a report.', isError: true);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;

      setState(() {
        _userId = user.uid;
        _userName = userDoc.data()?['userName'] ?? 'Unknown';
      });
    } catch (e) {
      _showFlushbar('Failed to fetch user data: $e', isError: true);
    }
  }

  void _showFlushbar(String message, {bool isError = false}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      icon: Icon(
        isError ? Icons.error : Icons.check,
        color: Colors.white,
      ),
    ).show(context);
  }

  Future<void> _getImage() async {
    try {
      // Show bottom sheet to choose between camera and gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Add Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  
                  // Options
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Camera Option
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF34A853),
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Camera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: const Text(
                            'Take a new photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        ),
                        
                        // Gallery Option
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Color(0xFF34A853),
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: const Text(
                            'Choose from your photos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom padding
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );

      if (source == null || !mounted) return;

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (!mounted) return;

      if (pickedFile != null) {
        // Show loading indicator during compression
        setState(() {
          _isLoading = true;
        });

        try {
          // Compress the image if it's larger than 1MB
          final compressedFile = await _compressImage(File(pickedFile.path));
          
          if (mounted) {
            setState(() {
              _image = compressedFile;
              _isLoading = false;
            });
            
            // Show compression feedback
            final fileSize = await compressedFile.length();
            if (fileSize > 1024 * 1024) {
              _showFlushbar('Image compressed for optimal upload', isError: false);
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showFlushbar('Error processing image: $e', isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showFlushbar('Error picking image: $e', isError: true);
      }
    }
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      // Check file size first
      final fileSize = await imageFile.length();
      const maxSize = 1024 * 1024; // 1MB
      
      // If file is already under 1MB, return as is
      if (fileSize <= maxSize) {
        return imageFile;
      }

      // Read the image file
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate compression ratio based on file size
      double compressionRatio = 1.0;
      if (fileSize > 5 * 1024 * 1024) { // > 5MB
        compressionRatio = 0.3;
      } else if (fileSize > 2 * 1024 * 1024) { // > 2MB
        compressionRatio = 0.5;
      } else if (fileSize > maxSize) { // > 1MB
        compressionRatio = 0.7;
      }

      // Calculate new dimensions
      final newWidth = (originalImage.width * compressionRatio).round();
      final newHeight = (originalImage.height * compressionRatio).round();
      
      // Resize the image
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Get temporary directory for compressed image
      final tempDir = await getTemporaryDirectory();
      final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Encode as JPEG with quality based on file size
      int quality = 85;
      if (fileSize > 5 * 1024 * 1024) {
        quality = 60;
      } else if (fileSize > 2 * 1024 * 1024) {
        quality = 70;
      } else if (fileSize > maxSize) {
        quality = 80;
      }

      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      // Write compressed image to file
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      // Check if compression was successful and file is under 1MB
      final compressedSize = await compressedFile.length();
      if (compressedSize > maxSize) {
        // If still too large, compress more aggressively
        final moreCompressedImage = img.copyResize(
          originalImage,
          width: (originalImage.width * 0.4).round(),
          height: (originalImage.height * 0.4).round(),
          interpolation: img.Interpolation.linear,
        );
        
        final moreCompressedBytes = img.encodeJpg(moreCompressedImage, quality: 50);
        final moreCompressedPath = '${tempDir.path}/more_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final moreCompressedFile = File(moreCompressedPath);
        await moreCompressedFile.writeAsBytes(moreCompressedBytes);
        
        return moreCompressedFile;
      }

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // Return original file if compression fails
      return imageFile;
    }
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showFlushbar('Location services are disabled.', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showFlushbar('Location permission denied.', isError: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      setState(() {
        _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      _showFlushbar('Error fetching location: $e', isError: true);
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _image == null) {
      _showFlushbar('Please fill all fields and add an image', isError: true);
      return;
    }

    if (_userId == null || _userName == null) {
      _showFlushbar('User info missing. Please log in again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if file exists and is readable
      if (!_image!.existsSync()) {
        _showFlushbar('Image file not found. Please try again.', isError: true);
        return;
      }

      // Get file size to check if it's too large
      final fileSize = await _image!.length();
      const maxSize = 5 * 1024 * 1024; // 5MB limit (reduced from 10MB)
      
      if (fileSize > maxSize) {
        _showFlushbar('Image file is too large even after compression. Please choose a smaller image.', isError: true);
        return;
      }

      // Show compression info to user
      if (fileSize > 1024 * 1024) { // If larger than 1MB
        _showFlushbar('Image compressed successfully for upload', isError: false);
      }

      final imageBytes = await _image!.readAsBytes();
      
      // Validate that we actually got image data
      if (imageBytes.isEmpty) {
        _showFlushbar('Invalid image file. Please try again.', isError: true);
        return;
      }

      final base64Image = _reportController.encodeImage(imageBytes);

      await _reportController.submitReport(
        description: _descriptionController.text,
        location: _locationController.text,
        base64Image: base64Image,
        userId: _userId!,
      );

      _showFlushbar('Report submitted successfully');

      _descriptionController.clear();
      _locationController.clear();
      setState(() {
        _image = null;
      });

      await _fetchLocation();
    } catch (e) {
      _showFlushbar('Error submitting report: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Report',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 16),
              const Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _getImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 241, 241, 241),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? _isLoading
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF34A853)),
                                SizedBox(height: 8),
                                Text('Processing image...', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 32, color: Color(0xFF34A853)),
                                SizedBox(height: 8),
                                Text('Click To Upload Photo', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.red, size: 32),
                                      SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A9C45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromARGB(255, 241, 241, 241),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
