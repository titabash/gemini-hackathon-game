# Core Notification Package

OneSignal push notification integration for Flutter app.

## Features

- **OneSignal SDK v5.3.5**: Latest Flutter SDK with user-centric APIs
- **Freezed Models**: Type-safe immutable notification data
- **Stream-based Events**: Reactive notification handling
- **Permission Management**: Easy permission request and state tracking
- **External User ID**: Link notifications to Supabase users

## Installation

This is a local package in the monorepo. Add to `pubspec.yaml`:

```yaml
dependencies:
  core_notification:
    path: ../packages/core/notification
```

## Usage

### Initialize OneSignal

```dart
import 'package:core_notification/core_notification.dart';

// Initialize in main.dart
final oneSignalService = OneSignalService(
  appId: 'YOUR_ONESIGNAL_APP_ID',
);

await oneSignalService.initialize();
```

### Request Permission

```dart
final granted = await oneSignalService.requestPermission();
if (granted) {
  print('Notification permission granted');
}
```

### Listen to Notifications

```dart
// Listen to received notifications (foreground)
oneSignalService.onNotificationReceived.listen((event) {
  print('Notification received: ${event.title}');
  print('Body: ${event.body}');
  print('Additional data: ${event.additionalData}');
});

// Listen to opened notifications (user tapped)
oneSignalService.onNotificationOpened.listen((event) {
  print('Notification opened: ${event.notificationId}');
  // Navigate to specific screen based on additionalData
});
```

### Link to Supabase User

```dart
// Set external user ID (Supabase user ID)
await oneSignalService.setExternalUserId(supabaseUserId);

// Remove on logout
await oneSignalService.removeExternalUserId();
```

### Set Custom Tags

```dart
// Add tags for targeting
await oneSignalService.setTags({
  'subscription_status': 'premium',
  'language': 'ja',
});

// Remove tags
await oneSignalService.deleteTags(['subscription_status']);
```

### Get Permission State

```dart
final state = oneSignalService.getPermissionState();
print('Notifications enabled: ${state.areNotificationsEnabled}');
print('Push token: ${state.pushToken}');
print('Subscription ID: ${state.subscriptionId}');
```

## Models

### NotificationEvent

Represents a received or opened notification:

```dart
final event = NotificationEvent(
  notificationId: 'notification_id',
  title: 'New Message',
  body: 'You have a new message',
  additionalData: {'screen': '/messages', 'messageId': '123'},
  isAction: false, // true if user tapped
  receivedAt: DateTime.now(),
);
```

### NotificationPermissionState

Represents the current permission state:

```dart
final state = NotificationPermissionState(
  areNotificationsEnabled: true,
  isPushDisabled: false,
  pushToken: 'device_token',
  subscriptionId: 'onesignal_player_id',
);
```

## Platform Setup

### Android

Add to `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33 // Must be at least 33
}
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### Web

OneSignal automatically handles web setup. Ensure your app is served over HTTPS in production.

## OneSignal Dashboard Setup

1. Create an account at [OneSignal](https://onesignal.com/)
2. Create a new app
3. Configure platforms:
   - **Apple (APNs)**: Upload .p8 key or .p12 certificate
   - **Google (FCM)**: Add Server Key from Firebase Console
4. Get your **App ID** from Settings > Keys & IDs
5. (Optional) Set up webhooks for event tracking

## Environment Variables

Add to your app's environment configuration:

```
ONESIGNAL_APP_ID=your_app_id_here
```

## Testing

Run tests with:

```bash
flutter test
```

## Resources

- [OneSignal Flutter SDK Documentation](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [OneSignal API Reference](https://documentation.onesignal.com/reference)
- [Flutter Package on pub.dev](https://pub.dev/packages/onesignal_flutter)

## Sources

- [OneSignal Flutter SDK setup](https://documentation.onesignal.com/docs/en/flutter-sdk-setup)
- [onesignal_flutter package on pub.dev](https://pub.dev/packages/onesignal_flutter)
- [OneSignal GitHub Repository](https://github.com/OneSignal/OneSignal-Flutter-SDK)
