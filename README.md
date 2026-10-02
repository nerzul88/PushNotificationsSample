# PushNotificationsSample

A minimal demo project for an article about rich push notifications on iOS.

The project contains:
- the main application target;
- `NotificationsServiceExtension`, which downloads media and creates `UNNotificationAttachment` objects for real remote notifications;
- `NotificationsContentExtension`, which displays custom content for two notification categories;
- `Event.apns` and `PushWithImage.apns` sample payloads.

All three targets use iOS 16.0 as their deployment target.

## Categories

- `pushWithImageCategory` — shows the large image in a custom notification UI.
- `eventCategory` — shows a separate event layout with SF Symbols for date and location.

The same category identifiers are registered by the main application with `UNUserNotificationCenter`.

## Local Simulator test: eventCategory

`Event.apns` can be dragged onto a booted Simulator, or sent from Terminal:

```bash
xcrun simctl push booted com.PushNotificationsSample Event.apns
```

Put the app in the background if you want to see the notification banner. Expand the notification to see the custom `eventCategory` layout.

If you change the main target's bundle identifier, update both `Simulator Target Bundle` in the `.apns` files and the bundle identifier passed to `simctl`.

## Important Simulator limitation

A locally simulated notification (`.apns` drag-and-drop or `xcrun simctl push`) is not equivalent to a real remote notification delivered by APNs. Apple notes that real remote notifications support more features, including Notification Service Extensions, than locally simulated notifications.

Therefore `PushWithImage.apns` demonstrates the expected payload structure, but it is not a reliable end-to-end test of `NotificationsServiceExtension`. To verify media downloading and attachment creation, use a real remote notification delivered through APNs.

The published demo intentionally does not include the Push Notifications capability or `aps-environment` entitlement. This keeps the locally testable `Event.apns` scenario usable without APNs provisioning. For real APNs testing, configure your own App ID/signing and enable Push Notifications.

## Image payload

```json
{
  "aps": {
    "alert": {
      "title": "Image notification",
      "body": "This payload demonstrates Notification Service Extension"
    },
    "sound": "default",
    "mutable-content": 1,
    "category": "pushWithImageCategory"
  },
  "smallImageURL": "https://example.com/preview.jpg",
  "bigImageURL": "https://example.com/content.jpg"
}
```

`category` and `mutable-content` belong inside `aps`. Application-specific image URLs are top-level custom keys.

## Event payload

```json
{
  "aps": {
    "alert": {
      "title": "iOS Community Meetup",
      "body": "Don't forget about today's meetup"
    },
    "sound": "default",
    "category": "eventCategory"
  },
  "eventDate": "October 15, 19:00",
  "eventLocation": "Community Hall"
}
```

This payload doesn't need `mutable-content`, because the event notification doesn't require preprocessing by the service extension.

## Notes

`NotificationServiceExtension` has limited execution time. If media downloading doesn't finish before the deadline, `serviceExtensionTimeWillExpire()` returns the best content prepared so far.

`NotificationContentExtension` uses `content.categoryIdentifier` instead of parsing `aps.category` manually.

Apple references:
- Xcode 14 Release Notes, Simulator section.
- UNNotificationServiceExtension documentation.
