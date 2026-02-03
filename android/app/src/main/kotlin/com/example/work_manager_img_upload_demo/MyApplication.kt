package com.example.work_manager_img_upload_demo

import io.flutter.app.FlutterApplication
import dev.fluttercommunity.workmanager.WorkmanagerDebug
import dev.fluttercommunity.workmanager.NotificationDebugHandler

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        
        // Enable WorkManager debug notifications
        // This will show notifications for task status updates
        // You'll see notifications when tasks are:
        // - Scheduled
        // - Started
        // - Completed
        // - Failed
        // - Retried
        WorkmanagerDebug.setCurrent(NotificationDebugHandler())
        
        android.util.Log.d("MyApplication", "WorkManager debugging enabled with NotificationDebugHandler")
        android.util.Log.d("MyApplication", "You will see notifications for all WorkManager task events")
    }
}
