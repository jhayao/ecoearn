// Example integration for adding QR scanner to home screen
// Add this to lib/screens/home/home_screen.dart

// 1. Add import at the top:
import '../qr_scanner_screen.dart';
import '../bin_control_screen.dart';

// 2. Add this method to _HomeScreenState class:
Future<void> _openQRScanner() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const QRScannerScreen(),
    ),
  );

  if (result != null && result['activated'] == true && mounted) {
    // Navigate to bin control screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BinControlScreen(
          binId: result['binId'],
          sessionId: result['sessionId'],
        ),
      ),
    );
  }
}

// 3. Add a FloatingActionButton to the Scaffold widget in the build method:
// Update the Scaffold widget around line 215 to:

return Scaffold(
  // ... existing body code ...
  floatingActionButton: FloatingActionButton.extended(
    onPressed: _openQRScanner,
    icon: const Icon(Icons.qr_code_scanner),
    label: const Text('Scan Bin'),
    backgroundColor: const Color(0xFF34A853),
    foregroundColor: Colors.white,
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
);

// Alternative: Add a button in the header section
// Add this where you want the button (e.g., near the notifications icon):

GestureDetector(
  onTap: _openQRScanner,
  child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(
      Icons.qr_code_scanner,
      color: Colors.white,
      size: 24,
    ),
  ),
)
