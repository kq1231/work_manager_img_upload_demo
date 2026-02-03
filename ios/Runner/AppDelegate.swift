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
    
    // Request notification permissions for iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
          NSLog("✅ Notification permissions granted")
        } else {
          NSLog("⚠️  Notification permissions denied")
        }
      }
      UNUserNotificationCenter.current().delegate = self
    }

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

    // Enable WorkManager debug notifications for iOS
    // You will see notifications for all WorkManager events! 🔔
    WorkmanagerDebug.setCurrent(LoggingDebugHandler())

    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
