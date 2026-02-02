# 🚀 Quick Start Guide

Get the POC running in 3 simple steps!

## Step 1: Start Python API Server

**macOS/Linux:**
```bash
chmod +x start_server.sh
./start_server.sh
```

**Windows:**
```bash
cd python_api
pip install -r requirements.txt
python server.py
```

**Note the Local IP displayed!** Example: `http://192.168.1.100:5000`

## Step 2: Run Flutter App

Open a new terminal:

```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Step 3: Configure & Test

1. **Enter API URL** in the app (use the Local IP from Step 1)
2. **Click "Save"**
3. **Click "Camera" or "Gallery"** to pick an image
4. **Watch it upload!** ✅

---

## 🧪 Quick Tests

### Test 1: Online Upload (30 seconds)
1. Pick an image → Should upload immediately
2. Check server terminal → Should see upload log
3. Image disappears from queue → Success! ✅

### Test 2: Offline Queue (1 minute)
1. Turn off WiFi
2. Pick an image → Stays in "pending" status
3. Turn WiFi back on
4. Click "Process Queue"
5. Image uploads → Success! ✅

### Test 3: Background Upload (15 minutes)
1. Queue an image while offline
2. **Close the app** (swipe away)
3. Turn WiFi back on
4. Wait 15 minutes
5. Reopen app → Image should be gone (uploaded in background!) ✅

### Test 4: Failed Upload Retry (1 minute)
1. Stop the server (Ctrl+C)
2. Try to upload → Should fail with red icon
3. Start server again (`./start_server.sh`)
4. Click retry icon on failed upload
5. Should succeed! ✅

---

## 🐛 Troubleshooting

### "Connection Failed"
- ✅ Check API URL is correct
- ✅ Ensure server is running
- ✅ Device and computer on same WiFi network

### "Permission Denied"
- ✅ Grant Camera permission in device Settings
- ✅ Grant Storage permission in device Settings

### "Background task not working"
**iOS:**
- Test on physical device (simulator doesn't support background tasks)
- Enable Background App Refresh in Settings

**Android:**
- Disable battery optimization for the app
- Check app has internet permission

---

## 📱 App Features

| Button | Function |
|--------|----------|
| **Camera** | Take new photo |
| **Gallery** | Select existing photo |
| **Process Queue** | Manually upload all pending |
| **Retry Failed** | Retry all failed uploads |
| **Clear All** | Delete all uploads |
| **Retry Icon** (on failed items) | Retry single upload |

## 🔍 What to Look For

### App Shows:
- ✅ Upload count badge (orange)
- ✅ Real-time status (pending/uploading/success/failed)
- ✅ Retry count per upload
- ✅ Error messages for failures

### Server Logs Show:
```
============================================================
✅ [SUCCESS] Image Upload Received
   Filename: 20260202_143025_image.jpg
   Size: 245.67 KB
   Patient ID: PATIENT_001
   Wound ID: WOUND_001
   Timestamp: 2026-02-02T14:30:25.123456
============================================================
```

---

## 🎯 Key Validations

This POC validates:

✅ **Offline-first storage** - Images saved locally when offline  
✅ **Automatic background retry** - WorkManager runs every 15 min  
✅ **Persistent queue** - Survives app restart & device reboot  
✅ **Cross-platform** - Same code works on iOS & Android  
✅ **Real-time status** - Users see what's happening  
✅ **Manual retry** - Users can force retry  

---

## 📞 Need Help?

1. Check `README.md` for full documentation
2. Check Python server logs for upload details
3. Check Flutter console for debug logs
4. Look for logs starting with:
   - `✅` - Success
   - `❌` - Error
   - `📤` - Uploading
   - `🔔` - Background task

---

**Ready to integrate into Atlas 2.0?** 🚀

All concepts are validated and production-ready patterns are established!
