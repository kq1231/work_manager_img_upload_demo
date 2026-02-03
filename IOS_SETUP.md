# 🍎 iOS WorkManager Setup - Option C (BGTaskScheduler)

Complete iOS configuration for periodic background tasks with custom frequency.

---

## ✅ Current Configuration

Our POC uses **Option C: Periodic Tasks with Custom Frequency** which provides:
- ✅ BGTaskScheduler with 15-minute frequency
- ✅ More reliable than Background Fetch (Option A)
- ✅ Better control than simple periodic tasks (Option B)
- ✅ iOS 13.0+ support

---

## 📋 Configuration Checklist

### 1. Info.plist ✅

**Location:** `ios/Runner/Info.plist`

```xml
<!-- Background Modes for WorkManager -->
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>  <!-- For BGTaskScheduler -->
    <string>fetch</string>        <!-- For Background Fetch -->
</array>

<!-- Background Task Scheduler Identifiers -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.workManagerImgUploadDemo.uploadPendingImages</string>
</array>

<!-- Camera and Photo Library Permissions -->
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to capture wound images for upload.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images for upload.</string>
```

### 2. AppDelegate.swift ✅

**Location:** `ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Enable debug logging
    WorkmanagerDebug.setCurrent(LoggingDebugHandler())
    
    // Register plugin callback
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    // ⭐ Option C: Register periodic task with custom frequency
    WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.example.workManagerImgUploadDemo.uploadPendingImages",
        frequency: NSNumber(value: 15 * 60) // 15 minutes (minimum)
    )
    
    if #available(iOS 13.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. Minimum Deployment Target ✅

**Requirement:** iOS 13.0+

Check `ios/Podfile`:
```ruby
platform :ios, '13.0'
```

---

## 🎯 How It Works

### BGTaskScheduler Flow

```
1. App launches → AppDelegate registers periodic task
   ↓
2. iOS schedules task with 15-minute minimum interval
   ↓
3. iOS decides actual execution time based on:
   - User behavior patterns
   - Device charging status
   - Network availability
   - Battery level
   - Time of day
   ↓
4. Task executes (max 30 seconds)
   ↓
5. Task completes → iOS schedules next execution
```

### Frequency Control

```swift
frequency: NSNumber(value: 15 * 60)  // 15 minutes minimum
```

**Valid frequencies:**
- ✅ 15 minutes (900 seconds) - Minimum allowed
- ✅ 20 minutes (1200 seconds)
- ✅ 30 minutes (1800 seconds)
- ✅ 1 hour (3600 seconds)
- ❌ Less than 15 minutes - iOS enforces minimum

**Note:** iOS controls actual timing. Your 15-minute frequency is a **minimum** - iOS may delay execution based on device conditions.

---

## 🔍 Task Identifier Matching

**Critical:** The identifier must match across:

1. **Info.plist:**
```xml
<string>com.example.workManagerImgUploadDemo.uploadPendingImages</string>
```

2. **AppDelegate.swift:**
```swift
withIdentifier: "com.example.workManagerImgUploadDemo.uploadPendingImages"
```

3. **Flutter Code (optional):**
```dart
// In Dart, WorkManager uses task name "uploadPendingImages"
// The plugin automatically maps it to the full identifier
```

**If identifiers don't match:** Tasks won't execute!

---

## 📱 iOS Requirements

### User Requirements

1. **Background App Refresh Enabled**
   - Settings → General → Background App Refresh → ON
   - Settings → Your App → Background App Refresh → ON

2. **Not in Low Power Mode**
   - Tasks may not run in Low Power Mode
   - Test with normal power mode

3. **Regular App Usage**
   - iOS learns usage patterns
   - Tasks run more frequently for apps used regularly

### Device Requirements

- iOS 13.0 or later
- Physical device (simulator doesn't support background tasks)
- Network connection (if constraint is set)
- Sufficient battery

---

## 🧪 Testing on iOS

### Method 1: Xcode Debugger (Recommended)

1. **Connect device** and run from Xcode
2. **Set breakpoint** in callback function
3. **Use Debug menu:** Debug → Simulate Background Fetch
4. **Check console** for logs

### Method 2: LLDB Console

In Xcode console while app is running:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.example.workManagerImgUploadDemo.uploadPendingImages"]
```

### Method 3: Wait for Natural Execution

1. Queue an image while offline
2. Close app completely
3. Turn WiFi on
4. Wait 15-30 minutes
5. Check Xcode console logs
6. Reopen app - uploads should be done

---

## 🐛 Common iOS Issues

### Issue: Tasks Never Execute

**Possible Causes:**
1. ❌ Background App Refresh disabled
2. ❌ Task identifiers don't match
3. ❌ BGTaskSchedulerPermittedIdentifiers missing/incorrect
4. ❌ App not used regularly (iOS hasn't learned pattern)
5. ❌ Low Power Mode enabled

**Solutions:**
- Verify all identifiers match exactly
- Enable Background App Refresh
- Use app regularly for a few days
- Test with Xcode debugger
- Check Info.plist configuration

### Issue: Tasks Stop After Working

**Possible Causes:**
1. User disabled Background App Refresh
2. iOS battery optimization kicked in
3. App removed from recent apps too often
4. Low Power Mode enabled

**Solutions:**
- Check Background App Refresh settings
- Test on device that's not battery-optimized
- Don't force-quit app frequently
- Disable Low Power Mode during testing

### Issue: Tasks Hit 30-Second Limit

**iOS Enforcement:** BGTaskScheduler tasks have a **hard 30-second limit**.

**Solutions:**
1. Optimize upload logic
2. Process uploads in batches
3. Return quickly if no work to do
4. Use efficient network code

Our POC handles this by:
- Quick Hive read (milliseconds)
- Parallel uploads would help (not implemented yet)
- Exits immediately if no pending uploads

---

## 📊 iOS vs Android Differences

| Feature | iOS | Android |
|---------|-----|---------|
| **Minimum Frequency** | 15 minutes | 15 minutes |
| **Execution Control** | OS decides timing | More predictable |
| **Execution Limit** | 30 seconds (hard limit) | No strict limit |
| **Battery Impact** | Heavily optimized by iOS | More configurable |
| **Background Refresh** | Must be enabled | Always works |
| **Testing** | Xcode debugger required | Can force with adb |
| **Reliability** | Less predictable | More predictable |

**Key Difference:** iOS is **much more restrictive** about background execution. This is intentional for battery life and user experience.

---

## 🔧 Advanced Configuration

### Longer Intervals

For less frequent uploads (e.g., every hour):

```swift
WorkmanagerPlugin.registerPeriodicTask(
    withIdentifier: "com.example.workManagerImgUploadDemo.uploadPendingImages",
    frequency: NSNumber(value: 60 * 60) // 1 hour
)
```

### Multiple Task Identifiers

If you need different background tasks:

**Info.plist:**
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.example.app.uploadImages</string>
    <string>com.example.app.syncData</string>
    <string>com.example.app.cleanupOldFiles</string>
</array>
```

**AppDelegate.swift:**
```swift
// Register each task separately
WorkmanagerPlugin.registerPeriodicTask(
    withIdentifier: "com.example.app.uploadImages",
    frequency: NSNumber(value: 15 * 60)
)
WorkmanagerPlugin.registerPeriodicTask(
    withIdentifier: "com.example.app.syncData",
    frequency: NSNumber(value: 30 * 60)
)
```

---

## 📝 iOS Logs to Watch For

### Successful Registration

```
✅ Periodic task registered with 15-minute frequency
⚠️  iOS controls actual execution timing based on user patterns
⚠️  Background App Refresh must be enabled in Settings
```

### Task Execution

```
🔔 [BACKGROUND TASK] Started
📋 Task: uploadPendingImages
⏰ Start time: 2026-02-03T14:30:25.123456
...
✅ [BACKGROUND TASK] COMPLETED
⏱️  Duration: 3s
```

### BGTaskScheduler Logs

iOS system logs (in Xcode console):
```
[BGTaskScheduler] Task com.example.workManagerImgUploadDemo.uploadPendingImages registered
[BGTaskScheduler] Task scheduled for earliest begin date: 14:45:00
[BGTaskScheduler] Task launched: uploadPendingImages
[BGTaskScheduler] Task completed: uploadPendingImages
```

---

## 💡 Best Practices

### 1. Keep Tasks Quick
- iOS enforces 30-second limit
- Optimize upload logic
- Exit early if no work

### 2. Handle Task Expiration
```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final startTime = DateTime.now();
    
    // Process uploads
    await uploadService.processQueue();
    
    final duration = DateTime.now().difference(startTime);
    if (duration.inSeconds > 25) {
      print('⚠️  Approaching 30-second limit!');
    }
    
    return true;
  });
}
```

### 3. Test Thoroughly
- Test on physical device
- Test with Background App Refresh enabled/disabled
- Test after app is force-quit
- Test after device reboot

### 4. Log Everything
- Add comprehensive logging
- Track execution times
- Monitor success/failure rates

### 5. Plan for Delays
- iOS may delay tasks for hours
- Design app to work even if background tasks don't run
- Show appropriate UI to users

---

## 🎓 Understanding iOS Background Execution

### Apple's Philosophy

iOS is **aggressive** about background execution to:
- Maximize battery life
- Provide best user experience
- Prevent apps from abusing background

### iOS Learning Algorithm

iOS learns when you use apps and schedules background tasks accordingly:
- App used every morning at 8am → Background tasks more likely at 7:30am
- App used randomly → Background tasks less predictable
- App used daily → Background tasks more frequent
- App rarely used → Background tasks very infrequent

### Battery Optimization

iOS may skip background tasks if:
- Battery is low
- Device is not charging
- User is actively using device
- Too many apps requesting background time
- Device temperature is high

---

## 📚 Resources

- [BGTaskScheduler Documentation](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler)
- [WWDC 2019: Advances in App Background Execution](https://developer.apple.com/videos/play/wwdc2019/707/)
- [WWDC 2020: Background execution demystified](https://developer.apple.com/videos/play/wwdc2020/10063/)
- [WorkManager iOS Documentation](https://docs.page/fluttercommunity/flutter_workmanager/quickstart#ios)
- [Apple's Background Execution Guide](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html)

---

## ✅ Verification Checklist

Before releasing, verify:

- [ ] Info.plist has UIBackgroundModes with "processing"
- [ ] Info.plist has BGTaskSchedulerPermittedIdentifiers
- [ ] Task identifier matches everywhere
- [ ] AppDelegate calls WorkmanagerPlugin.registerPeriodicTask
- [ ] Minimum deployment target is iOS 13.0+
- [ ] Tested on physical device
- [ ] Background App Refresh works
- [ ] Tasks complete within 30 seconds
- [ ] Comprehensive logging added
- [ ] Graceful handling when tasks don't run

---

**Alhamdulillah! iOS is now properly configured with Option C (BGTaskScheduler with custom frequency). May Allah make this POC beneficial for Atlas 2.0!** 🍎✨
