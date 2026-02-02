# 🏗️ System Architecture

## High-Level System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           FLUTTER APP                               │
│                      (iOS & Android)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────┐                                                │
│  │  HomeScreen    │  (Presentation Layer)                          │
│  │   (UI/UX)      │                                                │
│  └────────┬───────┘                                                │
│           │                                                        │
│           ▼                                                        │
│  ┌────────────────────────────────────────────┐                   │
│  │         Service Layer                      │                   │
│  │  ┌──────────────┐  ┌──────────────┐      │                   │
│  │  │ HiveService  │  │UploadService │      │                   │
│  │  │  (Storage)   │  │  (Network)   │      │                   │
│  │  └──────┬───────┘  └──────┬───────┘      │                   │
│  │         │                  │               │                   │
│  │         │  ┌───────────────┴────────┐     │                   │
│  │         │  │ WorkManagerService     │     │                   │
│  │         │  │  (Background Tasks)    │     │                   │
│  │         │  └────────────────────────┘     │                   │
│  └────────┼─────────────┬───────────────────┘                   │
│           │             │                                         │
└───────────┼─────────────┼─────────────────────────────────────────┘
            │             │
            ▼             ▼
    ┌──────────────┐  ┌──────────────┐
    │  Hive DB     │  │  Python API  │
    │  (Local)     │  │  (Flask)     │
    └──────────────┘  └──────────────┘
```

---

## Component Details

### 1. Presentation Layer (HomeScreen)

**Responsibilities:**
- Display upload queue with real-time status
- Handle user interactions (camera, gallery, retry)
- Show configuration inputs (API URL, Patient/Wound IDs)
- Display status badges and indicators

**User Actions:**
```
Camera Button → ImagePicker → Process Image
Gallery Button → ImagePicker → Process Image
Process Queue Button → UploadService.processQueue()
Retry Failed Button → UploadService.retryAllFailed()
Clear All Button → HiveService.clearAllUploads()
Individual Retry → UploadService.retryUpload(id)
Save API URL → HiveService.setApiUrl(url)
```

---

### 2. Service Layer

#### A. HiveService (Storage)

**Purpose:** Manage local database operations

```dart
class HiveService {
  // Initialization
  static Future<void> initialize()
  
  // Upload Queue Operations
  static Future<void> addUpload(PendingUpload upload)
  static List<PendingUpload> getPendingUploads()
  static List<PendingUpload> getAllUploads()
  static Future<void> updateUpload(PendingUpload upload)
  static Future<void> removeUpload(String id)
  static Future<void> clearAllUploads()
  
  // Settings Operations
  static String getApiUrl()
  static Future<void> setApiUrl(String url)
}
```

**Storage Structure:**
```
Hive Boxes:
├── pending_uploads (Box<PendingUpload>)
│   └── {uploadId}: PendingUpload
│       ├── id: String
│       ├── imagePath: String
│       ├── patientId: String
│       ├── woundId: String
│       ├── createdAt: DateTime
│       ├── retryCount: int
│       ├── status: UploadStatus (enum)
│       ├── errorMessage: String?
│       └── lastAttempt: DateTime?
│
└── settings (Box)
    └── api_url: String
```

---

#### B. UploadService (Network)

**Purpose:** Handle HTTP uploads and retry logic

```dart
class UploadService {
  // Core Operations
  Future<bool> hasConnection()
  Future<bool> uploadImage(PendingUpload upload)
  Future<Map<String, int>> processQueue()
  Future<bool> retryUpload(String uploadId)
  Future<void> retryAllFailed()
}
```

**Upload Flow:**
```
uploadImage(upload)
    │
    ├─► Check file exists
    ├─► Update status: uploading
    ├─► Create FormData
    │   ├─► image: MultipartFile
    │   ├─► patientId: String
    │   ├─► woundId: String
    │   └─► metadata: JSON
    │
    ├─► POST to API
    │
    ├─► Success?
    │   ├─► YES: Delete file, remove from Hive
    │   └─► NO: Increment retry, update status: failed
    │
    └─► Return bool
```

**Retry Strategy:**
```
Retry Logic:
├── Max Retries: 5
├── Backoff: Exponential (WorkManager handles this)
├── Failed after max retries: Status stays "failed"
└── User can manually retry anytime
```

---

#### C. WorkManagerService (Background)

**Purpose:** Execute uploads in background

```dart
class WorkManagerService {
  // Initialization
  static Future<void> initialize()
  
  // Task Registration
  static Future<void> registerPeriodicTask()    // Every 15 min
  static Future<void> registerOneOffTask()      // Immediate
  
  // Task Management
  static Future<void> cancelAllTasks()
  static Future<void> cancelPeriodicTask()
}
```

**Background Task Flow:**
```
callbackDispatcher()
    │
    ├─► Initialize Hive in background isolate
    ├─► Register adapters
    ├─► Open boxes
    │
    ├─► Get pending uploads from Hive
    │
    ├─► For each upload:
    │   ├─► Check retry count < 5
    │   ├─► Create FormData
    │   ├─► Upload with Dio
    │   ├─► Success? Remove from Hive, delete file
    │   └─► Failed? Increment retry count
    │
    ├─► Close Hive
    │
    └─► Return true (success) or false (retry)
```

**Platform-Specific Execution:**

**iOS:**
- Uses BGTaskScheduler
- 15-minute minimum frequency
- 30-second execution limit
- Requires Background App Refresh enabled
- Must test on physical device

**Android:**
- Uses JobScheduler/WorkManager
- 15-minute minimum frequency
- No strict execution limit
- Survives Doze mode
- Respects battery optimization

---

## Data Flow Diagrams

### Scenario 1: Online Upload (Immediate Success)

```
User taps Camera
     │
     ▼
Pick Image (ImagePicker)
     │
     ▼
Copy to app documents directory
     │
     ▼
Create PendingUpload in Hive
     │
     ▼
Check connectivity (ONLINE)
     │
     ▼
Upload immediately with Dio
     │
     ▼
API returns 200 OK
     │
     ▼
Delete local file
     │
     ▼
Remove from Hive
     │
     ▼
Show "✅ Upload successful!"
```

---

### Scenario 2: Offline Queue (Background Upload)

```
User taps Camera
     │
     ▼
Pick Image
     │
     ▼
Copy to local storage
     │
     ▼
Save to Hive (status: pending)
     │
     ▼
Check connectivity (OFFLINE)
     │
     ▼
Show "📡 Offline - queued"
     │
     ▼
Image stays in Hive
     │
     │ [User closes app]
     │
     ▼
[15 minutes later]
     │
     ▼
WorkManager wakes up
     │
     ▼
Check Hive for pending
     │
     ▼
Found pending uploads
     │
     ▼
Upload in background
     │
     ▼
Success → Cleanup
     │
     ▼
[User reopens app]
     │
     ▼
Queue is empty ✅
```

---

### Scenario 3: Failed Upload (Manual Retry)

```
User taps Gallery
     │
     ▼
Pick Image
     │
     ▼
Save to Hive
     │
     ▼
Try upload → API is down
     │
     ▼
Upload fails (DioException)
     │
     ▼
Update Hive:
  - status: failed
  - retryCount: 1
  - errorMessage: "Connection refused"
     │
     ▼
Show in queue with ❌ icon
     │
     │ [User fixes API, taps retry icon]
     │
     ▼
Reset status to pending
     │
     ▼
Try upload again
     │
     ▼
Success → Cleanup ✅
```

---

## State Management

### PendingUpload State Machine

```
        ┌─────────────┐
        │   PENDING   │ ◄────┐
        └─────┬───────┘      │
              │              │
              │ Upload       │ Retry
              │ Triggered    │
              ▼              │
        ┌─────────────┐      │
        │ UPLOADING   │      │
        └─────┬───────┘      │
              │              │
          ┌───┴───┐          │
          │       │          │
      SUCCESS   FAILURE      │
          │       │          │
          ▼       ▼          │
      ┌───────┐ ┌──────┐    │
      │DELETE │ │FAILED│────┘
      │       │ └──────┘
      └───────┘
      
States:
- PENDING: Waiting to be uploaded
- UPLOADING: Currently uploading
- SUCCESS: Upload succeeded (transient - item deleted)
- FAILED: Upload failed, can retry
```

---

## API Communication

### Request Format (Multipart)

```http
POST /api/upload HTTP/1.1
Host: 192.168.1.100:5000
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="image"; filename="uuid.jpg"
Content-Type: image/jpeg

[BINARY IMAGE DATA]
------WebKitFormBoundary
Content-Disposition: form-data; name="patientId"

PATIENT_001
------WebKitFormBoundary
Content-Disposition: form-data; name="woundId"

WOUND_001
------WebKitFormBoundary
Content-Disposition: form-data; name="metadata"

{"retryCount": 0}
------WebKitFormBoundary--
```

### Response Format

**Success (200):**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "filename": "20260202_143025_uuid.jpg",
    "size": 245670,
    "patientId": "PATIENT_001",
    "woundId": "WOUND_001",
    "timestamp": "20260202_143025"
  }
}
```

**Failure (400/500):**
```json
{
  "success": false,
  "error": "Invalid file type"
}
```

---

## Performance Considerations

### File Storage Strategy

**Why store files separately (not in Hive)?**
- ✅ Better memory efficiency
- ✅ Faster Hive operations
- ✅ Easy cleanup
- ✅ No size limits

**Storage Location:**
```
iOS: /var/mobile/Containers/Data/Application/{UUID}/Documents/
Android: /data/data/com.example.app/app_flutter/
```

### Hive Performance

**Advantages:**
- Lightning-fast reads/writes
- No SQL overhead
- Type-safe with generated adapters
- Lazy-loading support

**Box Strategy:**
- `pending_uploads`: One box for all uploads
- `settings`: Separate box for configuration
- Both use auto-increment keys (String for uploads, String for settings)

---

## Error Handling

### Error Types & Handling

```
DioException
├─► ConnectionTimeout → Retry (network issue)
├─► ReceiveTimeout → Retry (slow server)
├─► SendTimeout → Retry (large file)
├─► Response (4xx) → Don't retry (client error)
└─► Response (5xx) → Retry (server error)

FileSystemException
├─► File not found → Mark failed (can't recover)
└─► Permission denied → Mark failed (needs user action)

HiveError
├─► Box not open → Re-initialize
└─► Adapter not registered → Re-register
```

### User-Facing Errors

```dart
Error Display Strategy:
- DioException → "Network error, will retry in background"
- File not found → "Image file missing, please capture again"
- Max retries reached → "Upload failed after 5 attempts, tap to retry"
- API 4xx → "Invalid request, please check configuration"
- API 5xx → "Server error, will retry automatically"
```

---

## Security Considerations

### POC Level (Current)
- ⚠️ No authentication
- ⚠️ Unencrypted Hive storage
- ⚠️ Plain HTTP (for local testing)

### Production Requirements
- ✅ JWT/OAuth authentication
- ✅ Encrypted Hive boxes (HiveAesCipher)
- ✅ HTTPS only
- ✅ Refresh token storage in flutter_secure_storage
- ✅ Token refresh in background tasks
- ✅ PHI data encryption at rest

---

## Scalability

### Current Limitations
- Single user (no multi-tenant)
- No upload queue size limits
- No image compression
- Simple retry logic

### Production Enhancements
- User-specific upload queues
- Configurable queue size limits
- Image compression before upload
- Smart retry with exponential backoff
- Upload prioritization
- Bandwidth monitoring
- Upload scheduling (WiFi-only option)

---

## Testing Strategy

### Unit Tests (TODO)
- [ ] HiveService CRUD operations
- [ ] UploadService retry logic
- [ ] WorkManagerService task registration
- [ ] PendingUpload model serialization

### Integration Tests (TODO)
- [ ] End-to-end upload flow
- [ ] Background task execution
- [ ] Queue persistence across restarts

### Manual Testing (Current)
- ✅ Use TESTING_CHECKLIST.md
- ✅ Test on physical devices (iOS & Android)
- ✅ Simulate network conditions
- ✅ Test background task execution

---

## Monitoring & Debugging

### Logging Strategy

**Current (Development):**
```dart
print('✅') // Success
print('❌') // Error
print('📤') // Uploading
print('📡') // Network check
print('🔔') // Background task
print('🗑️') // Cleanup
```

**Production:**
```dart
// Replace with proper logging
Logger.info('Upload succeeded', metadata)
Logger.error('Upload failed', error, stackTrace)
Analytics.trackEvent('upload_success')
Crashlytics.recordError(error, stackTrace)
```

### Debug Tools
- Flutter DevTools for performance
- Xcode debugger for iOS background tasks
- `adb shell dumpsys jobscheduler` for Android WorkManager
- Python server logs for upload verification

---

## Future Enhancements

### Phase 1: Production Readiness
1. Add authentication & token management
2. Encrypt sensitive data
3. Add image compression
4. Implement proper error tracking
5. Add analytics/monitoring

### Phase 2: Advanced Features
1. Upload progress tracking
2. Pause/resume uploads
3. Upload prioritization
4. Batch uploads
5. Upload scheduling options

### Phase 3: Optimization
1. Smart retry with exponential backoff
2. Bandwidth monitoring
3. Upload queue size management
4. Background upload throttling
5. WiFi-only mode

---

**This architecture provides a solid foundation for integrating offline upload capabilities into Atlas 2.0 while maintaining code quality, testability, and scalability.**
