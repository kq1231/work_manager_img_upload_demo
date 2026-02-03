# 🐛 WorkManager Debugging Guide

Complete guide for debugging background tasks on Android and iOS.

---

## 🎯 What Was Added

### Android Debugging ✅
- **NotificationDebugHandler** in `MyApplication.kt` ⭐ **NEW!**
- Shows WorkManager status as **Android notifications**
- No need to connect to adb logcat!
- See task events right on your device
- Custom Application class registered in AndroidManifest
- Notification permissions added

### iOS Debugging ✅
- **NotificationDebugHandler** in `AppDelegate.swift` ⭐ **NEW!**
- Shows WorkManager status as **iOS notifications**
- No need to connect to Xcode!
- See task events right on your device
- Notification permissions requested automatically

### Enhanced Callback Logging ✅
- Comprehensive timestamps
- Task duration tracking
- Error stack traces
- Isolate identification

---

## 📱 Android Debugging

### 🔔 View WorkManager Notifications (Easiest!)

The app is configured with **NotificationDebugHandler** which shows task status as notifications!

**What You'll See:**

Notifications will appear for:
- ✅ **Task Scheduled** - When periodic/one-off task is registered
- 🚀 **Task Started** - When background task begins execution
- ✅ **Task Completed** - When task finishes successfully
- ❌ **Task Failed** - When task encounters an error
- 🔄 **Task Retrying** - When WorkManager schedules a retry

**Notification Content:**
- Task name (e.g., "uploadPendingImages")
- Task status
- Execution time
- Error messages (if any)

**Example Notifications:**

```
📱 WorkManager Debug
   Task Started: uploadPendingImages
   Time: 14:30:25
   
📱 WorkManager Debug
   Task Completed: uploadPendingImages  
   Duration: 3s
   Result: Success
   
📱 WorkManager Debug
   Task Failed: uploadPendingImages
   Error: Network connection failed
   Will retry
```

**No adb logcat needed!** Just watch your notification shade! 📱

**Note:** On Android 13+ (API 33+), you may need to grant notification permission when you first open the app.

### View WorkManager Logs (Alternative)

If you prefer logcat over notifications:

```bash
# Method 1: Filter by WorkManager (shows plugin logs)
adb logcat | grep WorkManager

# Method 2: Filter by our app logs (shows our custom logs)
adb logcat | grep "BACKGROUND TASK"

# Method 3: Filter by app package
adb logcat | grep com.example.work_manager_img_upload_demo

# Method 4: Clear and watch fresh logs
adb logcat -c && adb logcat | grep -E "WorkManager|BACKGROUND"
```

### Switch Between Notification and Logging Handlers

**Current:** NotificationDebugHandler (shows notifications)

**To switch to LoggingDebugHandler** (shows in logcat only):

Edit `android/app/.../MyApplication.kt`:

```kotlin
// Change this:
import dev.fluttercommunity.workmanager.NotificationDebugHandler
WorkmanagerDebug.setCurrent(NotificationDebugHandler())

// To this:
import dev.fluttercommunity.workmanager.LoggingDebugHandler
WorkmanagerDebug.setCurrent(LoggingDebugHandler())
```

### Inspect Job Scheduler

```bash
# View all scheduled jobs for our app
adb shell dumpsys jobscheduler | grep work_manager_img_upload_demo

# View detailed job info
adb shell dumpsys jobscheduler com.example.work_manager_img_upload_demo

# Check if job is pending
adb shell dumpsys jobscheduler | grep -A 20 "work_manager"
```

### Force Run Job (Testing Only)

```bash
# First, find the job ID
adb shell dumpsys jobscheduler | grep work_manager

# Then force run (replace JOB_ID with actual ID, e.g., 10001)
adb shell cmd jobscheduler run -f com.example.work_manager_img_upload_demo JOB_ID
```

### Battery Optimization Checks

```bash
# Check if app is whitelisted from battery optimization
adb shell dumpsys deviceidle whitelist | grep work_manager

# Check battery optimization status
adb shell settings get global battery_saver_constants

# Force device into Doze mode (testing)
adb shell dumpsys deviceidle force-idle

# Exit Doze mode
adb shell dumpsys deviceidle unforce

# Check app standby bucket
adb shell dumpsys usagestats | grep work_manager
```

### Common Android Issues

#### Issue: Tasks not running in background

**Possible Causes:**
1. Battery optimization is enabled for the app
2. App is in "App Standby" mode
3. Device is in Doze mode
4. Constraints are too restrictive

**Solutions:**

```bash
# 1. Disable battery optimization for the app
adb shell settings put global app_standby_enabled 0

# 2. Check Doze mode status
adb shell dumpsys deviceidle

# 3. Whitelist app from battery optimization (requires manual action)
# Go to: Settings → Apps → Your App → Battery → Unrestricted

# 4. Check current job status
adb shell dumpsys jobscheduler | grep -A 30 work_manager
```

#### Issue: Tasks running too frequently

**Solution:** Android enforces minimum 15-minute intervals for periodic tasks. Check your `frequency` setting.

---

## 🍎 iOS Debugging

### 🔔 View WorkManager Notifications (Easiest!)

The app is configured with **NotificationDebugHandler** which shows task status as notifications!

**What You'll See:**

Notifications will appear for:
- ✅ **Task Scheduled** - When periodic/one-off task is registered
- 🚀 **Task Started** - When background task begins execution
- ✅ **Task Completed** - When task finishes successfully
- ❌ **Task Failed** - When task encounters an error
- 🔄 **Task Retrying** - When WorkManager schedules a retry

**Notification Content:**
- Task name (e.g., "uploadPendingImages")
- Task status
- Execution time
- Error messages (if any)

**How It Works:**
```swift
// In AppDelegate.swift
WorkmanagerDebug.setCurrent(NotificationDebugHandler())
```

**First Launch:**
- App will request notification permissions
- **Tap "Allow"** when prompted
- You'll start seeing WorkManager event notifications!

**Testing:**
1. Launch the app → See "Task Scheduled" notification
2. Wait 15 minutes or trigger manually → See "Task Started" notification
3. Upload completes → See "Task Completed" notification
4. Any errors → See "Task Failed" notification with details

**Switch to Console Logging:**

If you prefer Xcode console logs instead:

```swift
// In AppDelegate.swift, change:
WorkmanagerDebug.setCurrent(NotificationDebugHandler())
// to:
WorkmanagerDebug.setCurrent(LoggingDebugHandler())
```

### View Logs in Xcode

1. **Connect device** and run app from Xcode
2. **Open Console** (View → Debug Area → Activate Console)
3. **Filter logs** by searching for "BACKGROUND TASK"
4. **Look for** the detailed logging we added

### Trigger Background Fetch Manually

**Option 1: Using Xcode Menu**
1. Run app on device/simulator
2. Go to **Debug → Simulate Background Fetch**
3. Check console for execution logs

**Option 2: Using LLDB Console**
```
# In Xcode LLDB console while app is running
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.example.workManagerImgUploadDemo.uploadPendingImages"]
```

### Check Scheduled Tasks

The app logs scheduled tasks on startup. Look for:
```
[BGTaskScheduler] Task Identifier: your.task.id
[BGTaskScheduler] earliestBeginDate: 2026.02.03 PM 11:10:12
```

### Common iOS Issues

#### Issue: Background App Refresh disabled

**Check Settings:**
- Settings → General → Background App Refresh → ON
- Settings → Your App → Background App Refresh → ON

#### Issue: Tasks never execute

**Possible Causes:**
1. App hasn't been used recently (iOS learning algorithm)
2. Task identifiers don't match Info.plist
3. Missing BGTaskSchedulerPermittedIdentifiers
4. Battery Low mode enabled

**Solutions:**
1. Use app regularly (iOS learns usage patterns)
2. Verify Info.plist has correct identifiers
3. Check that AppDelegate.swift registers tasks
4. Disable Low Power Mode during testing

#### Issue: Tasks stop after 30 seconds

**iOS Limit:** BGTaskScheduler has a **30-second execution limit**.

**Solutions:**
1. Optimize upload logic
2. Process uploads in batches
3. Return quickly if no work to do

---

## 🔍 What to Look For

### Successful Background Execution (Android)

```
adb logcat output:

🔔 [BACKGROUND TASK] Started
📋 Task: uploadPendingImages
⏰ Start time: 2026-02-03T14:30:00.000
📦 Initializing Hive...
✅ UploadStatusAdapter registered
✅ PendingUploadAdapter registered
📂 Opening Hive boxes...
✅ Hive boxes opened
🚀 Starting upload process...
🔄 Processing upload queue...
📋 Found 2 pending uploads
📤 Uploading abc123 to http://192.168.1.100:5001/api/upload
✅ Upload successful: abc123
🗑️  Deleted local image: /path/to/image.jpg
🗑️  Removed from queue: abc123
✅ [BACKGROUND TASK] COMPLETED
📊 Results: 2/2 succeeded, 0 failed
⏱️  Duration: 3s
```

### Failed Execution (Need to Debug)

```
❌ [BACKGROUND TASK] FAILED
💥 Error: SocketException: Connection refused
📋 Stack trace: ...
⏱️  Duration: 2s
```

---

## 🧪 Testing Workflow

### Android Testing Steps

1. **Build and install** the app:
   ```bash
   flutter build apk
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Monitor logs** in one terminal:
   ```bash
   adb logcat -c && adb logcat | grep -E "WorkManager|BACKGROUND"
   ```

3. **Queue an image** while offline

4. **Close the app** completely

5. **Turn WiFi back on**

6. **Wait** for background task (15 minutes) OR **force run**:
   ```bash
   # Find job ID first
   adb shell dumpsys jobscheduler | grep work_manager_img_upload_demo
   
   # Force run
   adb shell cmd jobscheduler run -f com.example.work_manager_img_upload_demo [JOB_ID]
   ```

7. **Check logs** for execution

8. **Reopen app** to verify queue is empty

### iOS Testing Steps

1. **Run on physical device** (simulator doesn't support background tasks)

2. **Enable Background App Refresh** in Settings

3. **Queue an image** while offline

4. **Close the app**

5. **Turn WiFi back on**

6. **Trigger manually** using Xcode: Debug → Simulate Background Fetch

7. **Check Xcode console** for logs

8. **Reopen app** to verify

---

## 📊 Monitor Task Health

Use the "Test Background Task" button in the app:
- Schedules a one-off task in 5 seconds
- Great for testing without waiting 15 minutes
- Watch logcat/Xcode console for execution

---

## 🚨 Troubleshooting Commands

### Android: Check Everything

```bash
# Full diagnostic
adb shell dumpsys jobscheduler | grep -A 50 work_manager_img_upload_demo
adb shell dumpsys deviceidle
adb shell dumpsys battery
adb shell settings get global battery_saver_constants
```

### Android: Reset Everything

```bash
# Clear app data (loses Hive database!)
adb shell pm clear com.example.work_manager_img_upload_demo

# Reinstall
flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS: Check Console

In Xcode Console, filter by:
- "BACKGROUND TASK" - Our logs
- "BGTaskScheduler" - iOS system logs
- "WorkManager" - Plugin logs

---

## 💡 Pro Tips

### 1. Use the "Test Background Task" Button
The app has a button to test background execution in 5 seconds instead of waiting 15 minutes!

### 2. Watch Logs in Real-Time
Always have logcat/Xcode console open when testing.

### 3. Test on Real Devices
Simulators/emulators don't accurately represent background task behavior.

### 4. Disable Battery Optimization During Testing
For accurate testing, disable battery optimization for your app.

### 5. Check System Logs
Both platforms log when tasks are scheduled, executed, or cancelled.

---

## 📝 Log Markers Reference

| Emoji | Meaning |
|-------|---------|
| 🔔 | Background task event |
| 📋 | Task information |
| ⏰ | Timestamp |
| 📦 | Hive initialization |
| ✅ | Success |
| ❌ | Error |
| 📤 | Upload attempt |
| 🗑️ | Cleanup action |
| ⏱️ | Duration |
| 💥 | Exception/crash |

---

## 🎯 Quick Reference

### Watch Android Logs
```bash
adb logcat -c && adb logcat | grep -E "WorkManager|BACKGROUND|UploadService"
```

### Force Android Job
```bash
adb shell cmd jobscheduler run -f com.example.work_manager_img_upload_demo [JOB_ID]
```

### Test Button in App
Tap "Test Background Task (5s)" to trigger immediate execution

### Check if Task is Registered
**Android:** `adb shell dumpsys jobscheduler | grep work_manager`  
**iOS:** Look for BGTaskScheduler logs in Xcode console

---

## ⚠️ Important Notes

1. **Background execution is never guaranteed** - OS controls when tasks run
2. **Android Doze Mode** can delay tasks up to hours
3. **iOS learns user patterns** - tasks run more frequently after regular use
4. **Battery optimization** will prevent background execution
5. **Always design for graceful degradation** when background tasks don't run

---

## 📚 Additional Resources

- [WorkManager Debugging Docs](https://docs.page/fluttercommunity/flutter_workmanager/debugging)
- [Android Background Execution Limits](https://developer.android.com/guide/background)
- [iOS Background Tasks](https://developer.apple.com/documentation/backgroundtasks)
- [Android JobScheduler](https://developer.android.com/reference/android/app/job/JobScheduler)
- [BGTaskScheduler](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler)

---

**Debugging is essential for understanding background task behavior. Alhamdulillah, these tools will help you see exactly what's happening!** 🚀
