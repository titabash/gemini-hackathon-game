import type {
  NotificationClickedEvent,
  NotificationDismissedEvent,
  NotificationDisplayedEvent,
  OneSignalEvent,
} from "./types.ts";

/**
 * Handle notification displayed event
 *
 * Triggered when a notification is displayed to the user.
 * This can be used for analytics, tracking delivery rates, etc.
 */
export async function handleNotificationDisplayed(
  event: NotificationDisplayedEvent,
): Promise<void> {
  console.log("Notification displayed:", {
    notification_id: event.notification_id,
    player_id: event.player_id,
    external_user_id: event.external_user_id,
    heading: event.heading,
    timestamp: new Date(event.timestamp * 1000).toISOString(),
  });

  // TODO: Implement your business logic here
  // Examples:
  // - Store notification delivery record in database
  // - Update analytics/metrics
  // - Trigger follow-up actions based on notification type

  // Placeholder for future async operations
  await Promise.resolve();
}

/**
 * Handle notification clicked event
 *
 * Triggered when a user clicks on a notification.
 * This is useful for tracking engagement and user behavior.
 */
export async function handleNotificationClicked(
  event: NotificationClickedEvent,
): Promise<void> {
  console.log("Notification clicked:", {
    notification_id: event.notification_id,
    player_id: event.player_id,
    external_user_id: event.external_user_id,
    heading: event.heading,
    url: event.url,
    timestamp: new Date(event.timestamp * 1000).toISOString(),
  });

  // TODO: Implement your business logic here
  // Examples:
  // - Record click event in analytics
  // - Update user engagement metrics
  // - Process additional_data for custom actions
  // - Trigger conversion tracking

  // Placeholder for future async operations
  await Promise.resolve();
}

/**
 * Handle notification dismissed event
 *
 * Triggered when a user dismisses a notification without clicking.
 * Useful for understanding notification effectiveness.
 */
export async function handleNotificationDismissed(
  event: NotificationDismissedEvent,
): Promise<void> {
  console.log("Notification dismissed:", {
    notification_id: event.notification_id,
    player_id: event.player_id,
    external_user_id: event.external_user_id,
    timestamp: new Date(event.timestamp * 1000).toISOString(),
  });

  // TODO: Implement your business logic here
  // Examples:
  // - Track dismissal rate for notification optimization
  // - Adjust notification strategies based on user preferences

  // Placeholder for future async operations
  await Promise.resolve();
}

/**
 * Route OneSignal webhook event to appropriate handler
 */
export async function handleOneSignalEvent(
  event: OneSignalEvent,
): Promise<void> {
  switch (event.event) {
    case "notification.displayed":
      await handleNotificationDisplayed(event);
      break;
    case "notification.clicked":
      await handleNotificationClicked(event);
      break;
    case "notification.dismissed":
      await handleNotificationDismissed(event);
      break;
    default:
      console.warn("Unknown event type:", (event as OneSignalEvent).event);
  }
}
