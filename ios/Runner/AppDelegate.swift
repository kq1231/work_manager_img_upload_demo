import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set notification center delegate FIRST (before requesting permissions)
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification permissions for iOS
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      if granted {
        NSLog("✅ Notification permissions granted")
      } else {
        NSLog("⚠️  Notification permissions denied")
      }
    }

    // Enable WorkManager debug notifications for iOS
    // You will see notifications for all WorkManager events! 🔔
    WorkmanagerDebug.setCurrent(NotificationDebugHandler())

    // Register WorkManager background task for iOS
    // This enables background fetch capability
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    // Option C: Register periodic task with custom frequency (BGTaskScheduler)
    // Minimum frequency: 15 minutes (900 seconds)
    // We use 15 minutes to match Android behavior
    WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "com.example.workManagerImgUploadDemo.uploadPendingImages",
        frequency: NSNumber(value: 15 * 60) // 15 minutes in seconds
    )
    NSLog("✅ Periodic task registered with 15-minute frequency")
    NSLog("⚠️  iOS controls actual execution timing based on user patterns")
    NSLog("⚠️  Background App Refresh must be enabled in Settings")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // CRITICAL: Override to show notifications even when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler(.alert) // shows banner even if app is in foreground
  }
}
