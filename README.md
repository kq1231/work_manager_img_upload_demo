# Offline Image Upload POC with WorkManager & Hive

A proof-of-concept Flutter app demonstrating offline image upload capabilities with automatic background retry using WorkManager and local persistence with Hive.

## 📋 Features

- ✅ **Offline-First**: Images queued locally when offline
- ✅ **Automatic Background Sync**: WorkManager retries every 15 minutes
- ✅ **Persistent Storage**: Hive database survives app restarts
- ✅ **Real-time Status**: See upload status (pending/uploading/success/failed)
- ✅ **Manual Retry**: Retry failed uploads manually
- ✅ **Configurable API URL**: Easy testing on different networks
- ✅ **Camera & Gallery**: Pick images from both sources

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                        │
├─────────────────────────────────────────────────────────┤
│  HomeScreen (UI)                                        │
│    ↓                                                    │
│  UploadService (Upload Logic)                          │
│    ↓                                                    │
│  HiveService (Local Storage)                           │
│    ↓                                                    │
│  WorkManagerService (Background Tasks)                 │
└─────────────────────────────────────────────────────────┘
         ↓                              ↓
    [Hive DB]                    [Python API Server]
  (Local Storage)                  (Upload Endpoint)
```

## 🚀 Setup Instructions

### 1. Install Dependencies

```bash
cd /Users/mac/Documents/fLuTTeR-PrOjEcTs/work_manager_img_upload_demo
flutter pub get
```

### 2. Generate Hive Adapters

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Setup Python API Server

```bash
cd python_api
pip install -r requirements.txt
python server.py
```

The server will start on `http://0.0.0.0:5000`

### 4. Get Your Local IP Address

**macOS/Linux:**
```bash
ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'
```

**Windows:**
```bash
ipconfig | findstr IPv4
```

Example output: `192.168.1.100`

### 5. Run the Flutter App

**For iOS:**
```bash
flutter run -d ios
```

**For Android:**
```bash
flutter run -d android
```

### 6. Configure API URL in App

1. Open the app
2. Enter your API URL in the format: `http://YOUR_LOCAL_IP:5000`
   - Example: `http://192.168.1.100:5000`
3. Click "Save"

## 📱 How to Use

### Basic Workflow

1. **Capture/Pick Image**
   - Tap "Camera" to take a new photo
   - Tap "Gallery" to select existing photo

2. **Automatic Upload**
   - If online: Uploads immediately
   - If offline: Queued for background upload

3. **Monitor Status**
   - See upload queue with real-time status
   - Pending uploads shown with orange badge

4. **Background Sync**
   - WorkManager runs every 15 minutes
   - Automatically retries pending uploads
   - Works even when app is closed

### Manual Controls

- **Process Queue**: Manually trigger upload of all pending
- **Retry Failed**: Retry all failed uploads
- **Clear All**: Remove all uploads and delete local files
- **Individual Retry**: Tap retry icon on failed uploads

## 🧪 Testing Scenarios

### Test 1: Successful Upload (Online)

1. Ensure API server is running
2. Set correct API URL in app
3. Pick an image from gallery
4. Should see "✅ Upload successful!" message
5. Image disappears from queue

### Test 2: Offline Queueing

1. Turn off WiFi/Mobile data
2. Pick an image
3. Should see "📡 Offline - queued for background upload"
4. Image stays in queue with "pending" status

### Test 3: Background Upload (App Closed)

1. Queue an image while offline
2. Close the app completely (swipe away)
3. Turn WiFi/Mobile data back on
4. Wait 15 minutes for WorkManager to run
5. Reopen app - image should be gone (uploaded)

### Test 4: Failed Upload Retry

1. Stop the Python API server
2. Try to upload an image
3. Should fail and show "failed" status
4. Start the server again
5. Tap the retry icon
6. Should succeed

### Test 5: Simulated Failure

1. Configure server to simulate failures:
   ```bash
   curl -X POST http://localhost:5000/api/config \
     -H "Content-Type: application/json" \
     -d '{"simulateFailure": true}'
   ```
2. Try to upload - should fail
3. Disable simulation:
   ```bash
   curl -X POST http://localhost:5000/api/config \
     -H "Content-Type: application/json" \
     -d '{"simulateFailure": false}'
   ```
4. Retry - should succeed

### Test 6: Multiple Images

1. Queue 5-10 images
2. Observe upload progress
3. Check server logs for received uploads

## 🔧 Configuration

### WorkManager Settings

In `lib/services/workmanager_service.dart`:

```dart
frequency: const Duration(minutes: 15),  // Change interval
constraints: Constraints(
  networkType: NetworkType.connected,    // Require internet
),
```

### Max Retry Count

In `lib/services/upload_service.dart`:

```dart
if (upload.retryCount >= 5) {  // Change max retries
  // Skip or mark as permanently failed
}
```

### API Timeout

In `lib/services/upload_service.dart`:

```dart
sendTimeout: const Duration(seconds: 30),    // Change timeout
receiveTimeout: const Duration(seconds: 30),
```

## 📊 Monitoring

### View Upload Status

The app shows:
- Total uploads in queue
- Pending count (orange badge)
- Failed count (red text)
- Status for each upload (pending/uploading/success/failed)
- Retry count per upload
- Error messages for failed uploads

### Check Server Logs

The Python server logs all uploads:

```
============================================================
✅ [SUCCESS] Image Upload Received
   Filename: 20260202_143025_test_image.jpg
   Size: 245.67 KB
   Patient ID: PATIENT_001
   Wound ID: WOUND_001
   Saved to: uploads/20260202_143025_test_image.jpg
   Timestamp: 2026-02-02T14:30:25.123456
============================================================
```

### Check WorkManager Execution

**iOS:**
- Use Xcode debugger
- Check console for "🔔 [BACKGROUND TASK]" logs

**Android:**
```bash
adb shell dumpsys jobscheduler | grep -A 20 workmanager
```

## 🐛 Troubleshooting

### Issue: "Image Upload Failed"

**Solution:**
- Check API URL is correct
- Ensure Python server is running
- Verify device is on same network as server
- Check server logs for errors

### Issue: Background sync not working

**iOS:**
- Check Background App Refresh is enabled in Settings
- Test on physical device (simulator doesn't support background tasks)
- Note: iOS controls timing, may not be exactly 15 minutes

**Android:**
- Check app is not battery optimized
- Verify internet permission granted
- Check WorkManager logs with dumpsys

### Issue: Hive adapter errors

**Solution:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Issue: Camera permission denied

**Solution:**
- Go to device Settings → App → Permissions
- Enable Camera and Storage permissions

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── pending_upload.dart      # Hive entity model
│   └── pending_upload.g.dart    # Generated adapter
├── services/
│   ├── hive_service.dart        # Local storage operations
│   ├── upload_service.dart      # Upload logic
│   └── workmanager_service.dart # Background task manager
└── screens/
    └── home_screen.dart         # Main UI

python_api/
├── server.py                    # Flask API server
├── requirements.txt             # Python dependencies
└── uploads/                     # Uploaded images folder
```

## 🔑 Key Concepts Validated

### 1. Offline-First Pattern
- Save to local storage first
- Try immediate upload if online
- Background task handles retries

### 2. WorkManager Reliability
- Survives app restarts
- Survives device reboots
- Respects battery and network constraints

### 3. Hive Persistence
- Fast local storage
- Type-safe with generated adapters
- Survives app updates

### 4. Cross-Platform Compatibility
- Same codebase for iOS and Android
- Platform-specific configurations minimal

## 🎯 Next Steps for Production

After validating this POC:

1. **Authentication**
   - Add token management
   - Store refresh token securely
   - Handle token expiry in background

2. **Encryption**
   - Encrypt Hive boxes for sensitive data
   - Use flutter_secure_storage for tokens

3. **Error Handling**
   - More granular error types
   - Better retry strategies (exponential backoff)
   - User notifications for failures

4. **Image Compression**
   - Add flutter_image_compress
   - Optimize before upload

5. **Multi-tenant Support**
   - Per-user upload queues
   - Logout cleanup

6. **Analytics**
   - Track upload success/failure rates
   - Monitor background task execution
   - Alert on persistent failures

## 📄 License

This is a proof-of-concept for internal use. Not for production deployment.

## 💡 Credits

Built following Atlas 2.0 offline upload requirements, inspired by the offline fallback plan.

---

**For questions or issues, refer to the troubleshooting section or check the Python API server logs.**
