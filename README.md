# Work Manager Demo App Key Takeaways
1. Work manager works in foreground on both iOS and Android and this is obvious and self-explanatory.

2. On Android, work manager works perfectly when app is either backgrounded or killed / terminated without any issues whatsoever.

3. On iPhone, work manager periodic task works when app is in background but NOT when killed. Also, when the task runs, it has restricted file access and the image inside applicationDocumentsDirectory is not accessible.
4. Therefore, we decided to encode the image as a ByteArray in Hive.

# Work Manager Current Flow

1. Whenever app is opened, a periodic task is registered. The policy is set to ExistingWorkPolicy.update, which means the next occurrence will always happen after 15 minutes whenever app is opened. This will help avoid any coincidental clashes.

2. Whenever app is opened, a one-off task in the background is run which tries uploading pending images.

3. On the image screen, we can show the status of pending images to the user and give options for retrying specific images, retrying all, deleting, cancelling, etc. This will happen on the Flutter side, i.e., using Futures / regular dart code and not a background task.