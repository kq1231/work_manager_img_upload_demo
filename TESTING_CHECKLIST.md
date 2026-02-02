# 🧪 Testing Checklist for POC

Use this checklist to systematically validate all features of the offline upload POC.

## ✅ Pre-Test Setup

- [ ] Python server is running
- [ ] Local IP address noted (e.g., `192.168.1.100`)
- [ ] Flutter app is running on device/simulator
- [ ] API URL is configured in app and saved
- [ ] Permissions granted (Camera, Storage)

---

## 📋 Test Scenarios

### Test 1: Basic Upload (Online)

**Goal:** Verify immediate upload when online works correctly.

**Steps:**
1. [ ] Ensure WiFi/Mobile data is ON
2. [ ] Tap "Camera" or "Gallery" button
3. [ ] Select/capture an image
4. [ ] Observe upload happens immediately

**Expected Results:**
- [ ] Toast shows "Uploading image..."
- [ ] Toast shows "✅ Upload successful!"
- [ ] Image disappears from queue
- [ ] Server logs show upload received
- [ ] Local image file is deleted

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 2: Offline Queueing

**Goal:** Verify images are queued when offline.

**Steps:**
1. [ ] Turn OFF WiFi and Mobile data
2. [ ] Tap "Camera" or "Gallery"
3. [ ] Select/capture an image
4. [ ] Observe image is added to queue

**Expected Results:**
- [ ] Toast shows "📡 Offline - queued for background upload"
- [ ] Image appears in queue with "pending" status (orange icon)
- [ ] Badge shows "1 pending"
- [ ] Image file is saved locally

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 3: Manual Queue Processing

**Goal:** Verify manual upload trigger works.

**Steps:**
1. [ ] Queue 2-3 images while offline (from Test 2)
2. [ ] Turn WiFi/Mobile data back ON
3. [ ] Tap "Process Queue" button
4. [ ] Wait for uploads to complete

**Expected Results:**
- [ ] All pending images upload successfully
- [ ] Toast shows "✅ X/X uploads succeeded"
- [ ] Images disappear from queue
- [ ] Server receives all images
- [ ] Badge count updates to 0

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 4: Background Upload (App Closed)

**Goal:** Verify WorkManager uploads in background.

**Steps:**
1. [ ] Queue an image while offline
2. [ ] **Close the app completely** (swipe away from app switcher)
3. [ ] Turn WiFi/Mobile data back ON
4. [ ] Wait 15-20 minutes
5. [ ] Reopen the app

**Expected Results:**
- [ ] Image is no longer in queue (uploaded in background)
- [ ] Server logs show upload received while app was closed
- [ ] Queue shows "No uploads yet"

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

**⚠️ iOS Note:** Test on physical device. Background tasks don't work in simulator.

---

### Test 5: Failed Upload & Retry

**Goal:** Verify failure handling and manual retry.

**Steps:**
1. [ ] **Stop the Python server** (Ctrl+C in server terminal)
2. [ ] Try to upload an image
3. [ ] Observe failure status
4. [ ] **Start the server** again (`./start_server.sh`)
5. [ ] Tap retry icon on failed upload

**Expected Results:**
- [ ] Upload fails initially
- [ ] Image shows "failed" status (red icon)
- [ ] Error message is displayed
- [ ] Retry count increments
- [ ] After retry: Upload succeeds
- [ ] Image disappears from queue

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 6: Retry All Failed

**Goal:** Verify bulk retry functionality.

**Steps:**
1. [ ] Stop the server
2. [ ] Queue 3-5 images (all will fail)
3. [ ] Wait for all to fail
4. [ ] Start the server
5. [ ] Tap "Retry Failed" button

**Expected Results:**
- [ ] All failed uploads retry
- [ ] All succeed and disappear from queue
- [ ] Server receives all images
- [ ] Badge count goes to 0

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 7: Multiple Images Upload

**Goal:** Verify handling of multiple simultaneous uploads.

**Steps:**
1. [ ] Queue 5-10 images rapidly
2. [ ] Observe upload progress
3. [ ] Check server logs

**Expected Results:**
- [ ] All images upload successfully
- [ ] Status updates in real-time
- [ ] No crashes or hangs
- [ ] Server receives all images in correct format
- [ ] All local files are cleaned up

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 8: App Restart Persistence

**Goal:** Verify queue persists across app restarts.

**Steps:**
1. [ ] Queue 2-3 images while offline
2. [ ] **Close the app** (don't force quit, just home button)
3. [ ] **Reopen the app**
4. [ ] Check if queued images are still there

**Expected Results:**
- [ ] All queued images still present
- [ ] Status preserved (pending)
- [ ] Retry counts preserved
- [ ] Can still upload manually

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 9: Device Reboot Persistence

**Goal:** Verify queue persists across device reboots.

**Steps:**
1. [ ] Queue 1-2 images while offline
2. [ ] **Reboot the device**
3. [ ] Reopen the app after reboot
4. [ ] Check if queued images are still there

**Expected Results:**
- [ ] Queued images still present after reboot
- [ ] Can process queue successfully
- [ ] WorkManager task still registered

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 10: Clear All Uploads

**Goal:** Verify cleanup functionality.

**Steps:**
1. [ ] Queue several images
2. [ ] Tap "Clear All" button
3. [ ] Confirm the dialog
4. [ ] Check queue and local storage

**Expected Results:**
- [ ] All uploads removed from queue
- [ ] All local image files deleted
- [ ] Queue shows "No uploads yet"
- [ ] Badge count is 0

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 11: Max Retry Limit

**Goal:** Verify uploads stop after max retries.

**Steps:**
1. [ ] Keep server stopped
2. [ ] Upload an image (will fail)
3. [ ] Manually retry 5 times
4. [ ] Observe behavior after 5th retry

**Expected Results:**
- [ ] After 5 retries, upload stays as "failed"
- [ ] System doesn't retry automatically anymore
- [ ] User can still manually retry if desired

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 12: Server Failure Simulation

**Goal:** Verify handling of server errors.

**Steps:**
1. [ ] Configure server to simulate failures:
   ```bash
   curl -X POST http://localhost:5000/api/config \
     -H "Content-Type: application/json" \
     -d '{"simulateFailure": true}'
   ```
2. [ ] Try to upload an image
3. [ ] Disable simulation:
   ```bash
   curl -X POST http://localhost:5000/api/config \
     -H "Content-Type: application/json" \
     -d '{"simulateFailure": false}'
   ```
4. [ ] Retry the upload

**Expected Results:**
- [ ] Upload fails with simulated error
- [ ] Error message shows in app
- [ ] After disabling simulation, retry succeeds

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 13: Connectivity Change Detection

**Goal:** Verify app responds to connectivity changes.

**Steps:**
1. [ ] Start with WiFi ON
2. [ ] Turn WiFi OFF
3. [ ] Try to upload → should queue
4. [ ] Turn WiFi ON
5. [ ] Tap "Process Queue"

**Expected Results:**
- [ ] App detects offline state correctly
- [ ] Queues upload when offline
- [ ] Detects online state correctly
- [ ] Processes queue when online

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 14: Patient/Wound ID Changes

**Goal:** Verify metadata is correctly sent.

**Steps:**
1. [ ] Change Patient ID to "TEST_PATIENT_123"
2. [ ] Change Wound ID to "TEST_WOUND_456"
3. [ ] Upload an image
4. [ ] Check server logs

**Expected Results:**
- [ ] Server logs show correct Patient ID
- [ ] Server logs show correct Wound ID
- [ ] Upload succeeds with custom metadata

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

### Test 15: API URL Change

**Goal:** Verify API URL can be changed at runtime.

**Steps:**
1. [ ] Note current API URL
2. [ ] Change to a different URL (e.g., add port)
3. [ ] Tap "Save"
4. [ ] Try to upload (may fail if invalid)
5. [ ] Change back to correct URL
6. [ ] Try to upload again

**Expected Results:**
- [ ] API URL is saved in Hive
- [ ] URL persists after app restart
- [ ] Upload uses new URL
- [ ] Invalid URL shows appropriate error

**Status:** ⬜ Pass | ⬜ Fail | ⬜ N/A

**Notes:**
```


```

---

## 📊 Test Summary

**Total Tests:** 15  
**Passed:** _____  
**Failed:** _____  
**N/A:** _____  

**Overall Pass Rate:** _____%

---

## 🐛 Issues Found

| Test # | Issue Description | Severity | Status |
|--------|------------------|----------|--------|
| | | High/Med/Low | Open/Fixed |
| | | | |
| | | | |

---

## ✅ Sign-off

**Tested By:** _________________  
**Date:** _________________  
**Device/OS:** _________________  
**Build Version:** 1.0.0+1  

**Ready for Integration?** ⬜ Yes | ⬜ No | ⬜ With Changes

**Notes:**
```




```

---

## 📝 Additional Observations

Document any unexpected behavior, performance issues, or suggestions:

```








```
