# API Calls Inventory - Wanderwani App

## External API Calls (Non-Firebase)

### 1. **IP Address Lookup API** 
**Location:** `lib/services/auth_service.dart` (lines 12-24)
```dart
Future<String> _getIpAddress() async {
  final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
}
```
- **Endpoint:** `https://api64.ipify.org?format=json`
- **Method:** GET
- **Purpose:** Fetch user's IP address for activity logging
- **Used in:** User sign-up and sign-in activity logging
- **Authentication:** None required (public API)
- **Response:** 
  ```json
  {
    "ip": "123.456.789.012"
  }
  ```

### 2. **Bin Activation API** ⭐ NEW
**Location:** `lib/services/bin_service.dart` (lines 23-65)
```dart
Future<Map<String, dynamic>> activateBin({...}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/bins/activate'),
    headers: _headers,
    body: jsonEncode({...}),
  );
}
```
- **Endpoint:** `https://your-domain.com/api/bins/activate` (⚠️ NEEDS CONFIGURATION)
- **Method:** POST
- **Purpose:** Activate recycling bin after QR scan
- **Authentication:** Firebase Auth Bearer token
- **Request:**
  ```json
  {
    "binId": "bin_001",
    "userId": "abc123xyz789",
    "scannedAt": "2025-11-10T08:30:00Z",
    "location": {
      "latitude": 14.5995,
      "longitude": 120.9842
    }
  }
  ```
- **Success Response (200):**
  ```json
  {
    "success": true,
    "data": {
      "binId": "bin_001",
      "name": "Main Street Bin",
      "status": "active",
      "currentUser": "abc123xyz789",
      "activatedAt": "2025-11-10T08:30:00Z",
      "sessionId": "session_abc123",
      "expiresAt": "2025-11-10T09:30:00Z",
      "apiKey": "BIN_ABC123XYZ789"
    }
  }
  ```
- **Error Responses:**
  - **404:** Bin not found
  - **409:** Bin already in use by another user

### 3. **Bin Deactivation API** ⭐ NEW
**Location:** `lib/services/bin_service.dart` (lines 72-104)
```dart
Future<Map<String, dynamic>> deactivateBin({...}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/bins/deactivate'),
    headers: _headers,
    body: jsonEncode({...}),
  );
}
```
- **Endpoint:** `https://your-domain.com/api/bins/deactivate` (⚠️ NEEDS CONFIGURATION)
- **Method:** POST
- **Purpose:** Deactivate bin when user finishes recycling
- **Authentication:** Firebase Auth Bearer token + API Key header
- **Request:**
  ```json
  {
    "userId": "abc123xyz789"
  }
  ```
  **Headers:**
  ```
  x-api-key: BIN_ABC123XYZ789
  ```
- **Success Response (200):**
  ```json
  {
    "success": true,
    "data": {
      "sessionDuration": 180,
      "totalPoints": 150,
      "itemsRecycled": 3,
      "deactivatedAt": "2025-11-10T08:33:00Z"
    }
  }
  ```
- **Error Responses:**
  - **403:** Unauthorized to deactivate this bin

---

## Firebase Services (Not HTTP APIs, but Cloud Services)

### Firebase Authentication
**Location:** `lib/services/auth_service.dart`
- Sign up with email/password
- Sign in with email/password
- Sign out
- Email verification
- User profile updates

### Firebase Firestore
**Collections Used:**

1. **`userActivities`** (auth_service.dart)
   - Logs user online/offline status
   - Stores IP address, timestamp, timezone

2. **`otp_verification`** (otp_service.dart)
   - Stores OTP codes with expiration
   - Tracks OTP usage status

3. **`users`** (waste_service.dart, profile_service.dart)
   - User profile data
   - Total points and items
   - Profile statistics

4. **`deposits`** (deposit_service.dart)
   - Deposit records per bin
   - User deposit history
   - Item types and amounts

5. **`recycling_stats`** (profile_service.dart)
   - User recycling statistics

6. **`bins`** (implied from bincard_controller.dart)
   - Bin information
   - Bin status and levels
   - Bin locations

7. **`notifications`** (implied from notifications_screen)
   - User notifications
   - Read/unread status

### Firebase Storage
**Location:** `lib/screens/profile/profile_screen.dart`
- Profile picture uploads
- Image storage

---

## Email Service (SMTP)

### Gmail SMTP
**Location:** `lib/services/otp_service.dart` (lines 54-116)
```dart
final smtpServer = gmail('ecoearn2025@gmail.com', 'ynlw wnhe pivz jdkb');
```
- **Service:** Gmail SMTP
- **Purpose:** Send OTP verification emails
- **Email:** ecoearn2025@gmail.com
- **⚠️ Security Note:** App password is hardcoded (should be in environment variables)

---

## Third-Party Package APIs

### OpenStreetMap Tiles
**Location:** `lib/screens/map/map.dart`
```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
)
```
- **Endpoint:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Purpose:** Map tiles for route display
- **Authentication:** None required

---

## Summary Table

| API/Service | Type | Status | Auth Required | Configuration Needed |
|-------------|------|--------|---------------|---------------------|
| ipify.org | External HTTP | ✅ Working | No | None |
| Bin Activation | External HTTP | ⚠️ Needs Backend | Firebase Token | ⚠️ URL Config |
| Bin Deactivation | External HTTP | ⚠️ Needs Backend | Firebase Token | ⚠️ URL Config |
| Firebase Auth | Firebase SDK | ✅ Working | User Credentials | None |
| Firebase Firestore | Firebase SDK | ✅ Working | Firebase Token | None |
| Firebase Storage | Firebase SDK | ✅ Working | Firebase Token | None |
| Gmail SMTP | SMTP | ✅ Working | App Password | ⚠️ Move to env |
| OpenStreetMap | External HTTP | ✅ Working | No | None |

---

## Action Items

### 🔴 Critical
1. **Configure Bin API URLs** in `lib/services/bin_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-actual-backend.com/api';
   ```

2. **Implement Backend Endpoints:**
   - POST /bins/activate
   - POST /bins/deactivate

### 🟡 Medium Priority
3. **Move Gmail credentials to environment variables:**
   - Don't hardcode email password in source code
   - Use flutter_dotenv or similar package

### 🟢 Low Priority
4. **Add API error handling logging:**
   - Log API failures to analytics
   - Monitor API response times

5. **Add API caching where appropriate:**
   - Cache bin information
   - Reduce Firestore reads

---

## API Dependencies

```
┌─────────────────────────────────────────────┐
│          Wanderwani Flutter App             │
└─────────────────────────────────────────────┘
                    │
                    ├─────────── Firebase Services
                    │            ├─ Authentication
                    │            ├─ Firestore (7 collections)
                    │            └─ Storage
                    │
                    ├─────────── External APIs
                    │            ├─ ipify.org (IP lookup)
                    │            ├─ Your Backend API (bin control) ⚠️
                    │            └─ OpenStreetMap (map tiles)
                    │
                    └─────────── Email Service
                                 └─ Gmail SMTP (OTP delivery)
```

---

## Notes

- **No payment gateway APIs found** (if implementing rewards redemption, you'll need to add one)
- **No analytics APIs found** (consider adding Firebase Analytics or similar)
- **No push notification APIs found** (consider adding FCM for notifications)
- **No image processing APIs** (all image handling is local/Firebase)
- **ESP32 Bluetooth communication** is planned but not yet implemented

---

## Security Recommendations

1. ✅ **Do:** Use Firebase Auth tokens for bin APIs (already implemented)
2. ⚠️ **Fix:** Move email credentials to secure storage
3. ⚠️ **Fix:** Implement backend API with proper validation
4. ✅ **Do:** Use HTTPS for all external APIs (already using)
5. ⚠️ **Consider:** Add rate limiting to prevent API abuse
6. ⚠️ **Consider:** Add API request timeout handling
7. ⚠️ **Consider:** Implement retry logic for failed requests

---

**Last Updated:** 2025-11-10  
**Reviewed By:** GitHub Copilot CLI
