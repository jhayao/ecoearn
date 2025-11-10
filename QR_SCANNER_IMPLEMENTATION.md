# QR Scanner Implementation Guide

## Overview

This implementation follows the Bin Activation & Deactivation APIs documented in `BIN_ACTIVATION_APIS.md`. The QR scanner allows users to scan a bin's QR code to activate it, use it for recycling, and then deactivate it when finished.

## Files Created

### 1. `lib/services/bin_service.dart`
Service class that handles API communication for bin activation and deactivation.

**Key Features:**
- `activateBin()` - Activates a bin after QR scan
- `deactivateBin()` - Deactivates a bin when user finishes
- Automatic Firebase Auth token management
- ESP32-CAM Bluetooth communication (placeholder for future implementation)

### 2. `lib/screens/qr_scanner_screen.dart`
QR scanner screen using the `mobile_scanner` package.

**Features:**
- Camera-based QR code scanning
- Real-time scanning with visual frame overlay
- Automatic location detection
- Bin activation on successful scan
- Error handling with Flushbar notifications
- Torch and camera switch controls

### 3. `lib/screens/bin_control_screen.dart`
Bin control screen displayed after successful activation.

**Features:**
- Real-time session timer
- Bin status display (active/locked)
- Session information (binId, sessionId)
- Auto-timeout countdown (5 minutes)
- Deactivate button
- Session summary dialog with points earned

## How to Use

### 1. Navigate to QR Scanner

Add a button in your app to navigate to the QR scanner:

```dart
import 'package:ecoearn/screens/qr_scanner_screen.dart';

// In your widget (e.g., HomeScreen or MapScreen):
ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
    
    // Handle the result if needed
    if (result != null && result['activated'] == true) {
      print('Bin activated: ${result['binId']}');
      print('Session ID: ${result['sessionId']}');
    }
  },
  child: const Text('Scan Bin QR Code'),
)
```

### 2. Integration Example for Map Screen

Add a floating action button to the map screen:

```dart
// In lib/screens/map/map.dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
    
    if (result != null && result['activated'] == true) {
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
  },
  icon: const Icon(Icons.qr_code_scanner),
  label: const Text('Scan QR'),
  backgroundColor: const Color(0xFF34A853),
),
```

### 3. Configure Backend API URL

Update the `baseUrl` in `lib/services/bin_service.dart`:

```dart
static const String baseUrl = 'https://your-domain.com/api';
```

Replace `your-domain.com` with your actual backend API URL.

## API Endpoints Required

Your backend must implement these endpoints:

### 1. Activate Bin
```
POST /bins/activate
Authorization: Bearer {firebase_token}
Content-Type: application/json

Body:
{
  "binId": "bin_001",
  "userId": "user_id",
  "scannedAt": "2025-11-10T08:30:00Z",
  "location": {
    "latitude": 14.5995,
    "longitude": 120.9842
  }
}

Response (200):
{
  "success": true,
  "message": "Bin activated successfully",
  "data": {
    "binId": "bin_001",
    "sessionId": "session_abc123",
    "userId": "user_id",
    "activatedAt": "2025-11-10T08:30:00Z",
    "expiresAt": "2025-11-10T09:30:00Z"
  }
}
```

### 2. Deactivate Bin
```
POST /bins/deactivate
Authorization: Bearer {firebase_token}
Content-Type: application/json

Body:
{
  "binId": "bin_001",
  "userId": "user_id",
  "sessionId": "session_abc123"
}

Response (200):
{
  "success": true,
  "message": "Bin deactivated successfully",
  "data": {
    "binId": "bin_001",
    "status": "inactive",
    "sessionDuration": 180,
    "totalPoints": 150,
    "itemsRecycled": 3,
    "deactivatedAt": "2025-11-10T08:33:00Z"
  }
}
```

## Permissions Required

Ensure these permissions are in your `AndroidManifest.xml`:

```xml
<!-- Camera permission for QR scanning -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

And in `Info.plist` for iOS:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes on recycling bins</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is required to activate nearby bins</string>
```

## ESP32-CAM Bluetooth Integration

The `_sendToESP32CAM()` method in `bin_service.dart` is a placeholder. To implement Bluetooth communication:

1. Add `flutter_blue_plus` to `pubspec.yaml`:
```yaml
dependencies:
  flutter_blue_plus: ^1.31.0
```

2. Update the `_sendToESP32CAM()` method:
```dart
Future<void> _sendToESP32CAM(String command) async {
  // Scan for ESP32-CAM device
  final device = await _findESP32Device();
  
  // Connect to device
  await device.connect();
  
  // Find the characteristic to write to
  final services = await device.discoverServices();
  final characteristic = _findWriteCharacteristic(services);
  
  // Write command
  await characteristic.write(utf8.encode(command + '\n'));
  
  // Disconnect
  await device.disconnect();
}
```

## Flow Diagram

```
User Opens App
    ↓
Navigates to Map/Home
    ↓
Taps "Scan QR Code"
    ↓
QR Scanner Opens
    ↓
Scans Bin QR Code
    ↓
App Activates Bin (API Call)
    ↓
Sends ACTIVATE_BIN command to ESP32-CAM
    ↓
Bin Control Screen Opens
    ↓
User Recycles Items
    ↓
User Taps "Finish & Lock Bin"
    ↓
App Deactivates Bin (API Call)
    ↓
Sends DEACTIVATE_BIN command to ESP32-CAM
    ↓
Session Summary Displayed
    ↓
Returns to Previous Screen
```

## Error Handling

The implementation handles these errors:

- **Bin not found (404)** - "Bin not found"
- **Bin already in use (409)** - "Bin is already in use by another user"
- **Unauthorized (403)** - "Unauthorized to deactivate this bin"
- **Location permission denied** - "Location permission is required"
- **Location services disabled** - "Please enable location services"
- **User not logged in** - "Please log in to use this feature"

## Testing

1. Test QR scanning with a sample QR code
2. Verify location permissions are requested
3. Test bin activation flow
4. Test bin deactivation flow
5. Test error scenarios (invalid QR, bin in use, etc.)

## Next Steps

1. Implement backend API endpoints
2. Set up ESP32-CAM Bluetooth communication
3. Add the QR scanner button to your main screens
4. Test with actual hardware
5. Configure production API URL
