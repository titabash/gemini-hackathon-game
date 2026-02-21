/**
 * OneSignal Webhook Event Types
 *
 * Based on OneSignal Webhook documentation:
 * https://documentation.onesignal.com/docs/webhooks
 */

/**
 * OneSignal webhook event types
 */
export type OneSignalEventType =
  | "notification.displayed"
  | "notification.clicked"
  | "notification.dismissed";

/**
 * Base OneSignal webhook event structure
 */
export interface OneSignalWebhookEvent {
  /** Event type */
  event: OneSignalEventType;
  /** OneSignal App ID */
  app_id: string;
  /** Timestamp of the event */
  timestamp: number;
}

/**
 * Notification displayed event
 * Triggered when a notification is displayed to the user
 */
export interface NotificationDisplayedEvent extends OneSignalWebhookEvent {
  event: "notification.displayed";
  /** Notification ID */
  notification_id: string;
  /** OneSignal Player ID (Subscription ID) */
  player_id: string;
  /** External user ID (e.g., Supabase user ID) */
  external_user_id?: string;
  /** Notification heading/title */
  heading?: string;
  /** Notification content/body */
  content?: string;
  /** Additional data attached to the notification */
  additional_data?: Record<string, unknown>;
}

/**
 * Notification clicked event
 * Triggered when a user clicks on a notification
 */
export interface NotificationClickedEvent extends OneSignalWebhookEvent {
  event: "notification.clicked";
  /** Notification ID */
  notification_id: string;
  /** OneSignal Player ID (Subscription ID) */
  player_id: string;
  /** External user ID (e.g., Supabase user ID) */
  external_user_id?: string;
  /** Notification heading/title */
  heading?: string;
  /** Notification content/body */
  content?: string;
  /** Additional data attached to the notification */
  additional_data?: Record<string, unknown>;
  /** URL opened (if applicable) */
  url?: string;
}

/**
 * Notification dismissed event
 * Triggered when a user dismisses a notification without clicking
 */
export interface NotificationDismissedEvent extends OneSignalWebhookEvent {
  event: "notification.dismissed";
  /** Notification ID */
  notification_id: string;
  /** OneSignal Player ID (Subscription ID) */
  player_id: string;
  /** External user ID (e.g., Supabase user ID) */
  external_user_id?: string;
}

/**
 * Union type of all possible OneSignal webhook events
 */
export type OneSignalEvent =
  | NotificationDisplayedEvent
  | NotificationClickedEvent
  | NotificationDismissedEvent;

/**
 * Webhook verification header
 */
export interface WebhookHeaders {
  /** OneSignal webhook signature for HMAC verification */
  "x-onesignal-signature"?: string;
  /** Content type */
  "content-type"?: string;
}
