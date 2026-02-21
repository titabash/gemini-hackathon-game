# OneSignal Webhooks Edge Function

Supabase Edge Function for handling OneSignal webhook events (notification
displayed, clicked, dismissed).

## Features

- **Event Handling**: Supports all OneSignal notification events
  - `notification.displayed` - When notification is shown to user
  - `notification.clicked` - When user taps notification
  - `notification.dismissed` - When user dismisses notification
- **HMAC Signature Verification**: Validates webhook authenticity using SHA-256
- **Type Safety**: Full TypeScript type definitions for OneSignal events
- **CORS Support**: Properly configured for cross-origin requests
- **Error Handling**: Comprehensive error handling with detailed logging

## Setup

### 1. Environment Variables

Add to `env/secrets.env`:

```bash
# OneSignal Webhook Secret (from OneSignal Dashboard > Settings > Keys & IDs)
ONESIGNAL_WEBHOOK_SECRET=your_webhook_secret_here

# Optional: Disable signature verification for development/testing
# ONESIGNAL_ENABLE_SIGNATURE_VERIFICATION=false
```

### 2. Deploy Edge Function

```bash
# Deploy to Supabase
supabase functions deploy onesignal-webhooks

# Or use make command
make deploy-functions
```

### 3. Get Webhook URL

After deployment, your webhook URL will be:

```
https://<project-ref>.supabase.co/functions/v1/onesignal-webhooks
```

### 4. Configure OneSignal Webhook

#### Option A: OneSignal Dashboard

1. Go to [OneSignal Dashboard](https://app.onesignal.com/)
2. Select your app
3. Navigate to **Settings** > **Webhooks**
4. Click **Add Webhook**
5. Enter your Edge Function URL
6. Select events to receive:
   - ✅ Notification Displayed
   - ✅ Notification Clicked
   - ✅ Notification Dismissed
7. Save configuration

#### Option B: OneSignal API

```bash
curl -X POST https://onesignal.com/api/v1/apps/<app-id>/webhooks \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://<project-ref>.supabase.co/functions/v1/onesignal-webhooks",
    "events": ["displayed", "clicked", "dismissed"]
  }'
```

## Webhook Event Types

### notification.displayed

Triggered when a notification is displayed to the user.

```json
{
  "event": "notification.displayed",
  "app_id": "your-app-id",
  "notification_id": "notification-uuid",
  "player_id": "player-uuid",
  "external_user_id": "supabase-user-id",
  "heading": "Notification Title",
  "content": "Notification body text",
  "additional_data": {},
  "timestamp": 1673456789
}
```

### notification.clicked

Triggered when a user clicks on a notification.

```json
{
  "event": "notification.clicked",
  "app_id": "your-app-id",
  "notification_id": "notification-uuid",
  "player_id": "player-uuid",
  "external_user_id": "supabase-user-id",
  "heading": "Notification Title",
  "content": "Notification body text",
  "url": "https://example.com/page",
  "additional_data": {},
  "timestamp": 1673456789
}
```

### notification.dismissed

Triggered when a user dismisses a notification without clicking.

```json
{
  "event": "notification.dismissed",
  "app_id": "your-app-id",
  "notification_id": "notification-uuid",
  "player_id": "player-uuid",
  "external_user_id": "supabase-user-id",
  "timestamp": 1673456789
}
```

## Implementation

### Event Handlers

Event handlers are defined in `handlers/notification.ts`:

```typescript
// Example: Handle notification clicked event
export async function handleNotificationClicked(
  event: NotificationClickedEvent,
): Promise<void> {
  // Your business logic here
  // - Record click event in analytics
  // - Update user engagement metrics
  // - Process additional_data for custom actions
}
```

### Type Definitions

All OneSignal webhook types are defined in `handlers/types.ts`:

- `OneSignalEvent` - Union type of all events
- `NotificationDisplayedEvent` - Displayed event structure
- `NotificationClickedEvent` - Clicked event structure
- `NotificationDismissedEvent` - Dismissed event structure

## Testing

### Local Testing

```bash
# Start Supabase locally
supabase start

# Serve function locally
supabase functions serve onesignal-webhooks

# Test webhook with curl
curl -X POST http://localhost:54321/functions/v1/onesignal-webhooks \
  -H "Content-Type: application/json" \
  -H "x-onesignal-signature: your-test-signature" \
  -d '{
    "event": "notification.clicked",
    "app_id": "test-app-id",
    "notification_id": "test-notification-id",
    "player_id": "test-player-id",
    "external_user_id": "test-user-id",
    "heading": "Test Notification",
    "content": "Test body",
    "timestamp": 1673456789
  }'
```

### Disable Signature Verification for Testing

Set in `env/secrets.env`:

```bash
ONESIGNAL_ENABLE_SIGNATURE_VERIFICATION=false
```

### Generate Test Signature (Optional)

```typescript
// Example: Generate HMAC-SHA256 signature
const crypto = require("crypto");
const payload = JSON.stringify(webhookEvent);
const secret = "your_webhook_secret";
const signature = crypto
  .createHmac("sha256", secret)
  .update(payload)
  .digest("hex");
```

## Monitoring

### View Logs

```bash
# View real-time logs
supabase functions logs onesignal-webhooks --follow

# Or via Supabase Dashboard
# Settings > Edge Functions > onesignal-webhooks > Logs
```

### Common Log Messages

- ✅ `Notification displayed: ...` - Event received and processed
- ✅ `Notification clicked: ...` - Click event recorded
- ✅ `Notification dismissed: ...` - Dismissal event tracked
- ⚠️ `Invalid webhook signature` - Signature verification failed
- ⚠️ `Unknown event type: ...` - Unsupported event type received
- ❌ `Error processing webhook: ...` - Internal processing error

## Security

### Webhook Signature Verification

This function verifies OneSignal webhook signatures using HMAC-SHA256:

1. OneSignal sends `x-onesignal-signature` header with each webhook
2. Function computes HMAC-SHA256 hash of request body using your webhook secret
3. Signatures are compared using constant-time comparison
4. Invalid signatures return `401 Unauthorized`

**IMPORTANT**: Always enable signature verification in production by setting
`ONESIGNAL_WEBHOOK_SECRET`.

### Best Practices

- ✅ Always use HTTPS for webhook URLs (enforced by OneSignal)
- ✅ Keep `ONESIGNAL_WEBHOOK_SECRET` in environment variables, never in code
- ✅ Enable signature verification in production
- ✅ Monitor webhook logs for suspicious activity
- ✅ Implement rate limiting if processing expensive operations

## Troubleshooting

### Webhook not receiving events

1. **Check OneSignal Dashboard**:
   - Verify webhook is active
   - Confirm URL is correct (HTTPS required)
   - Check event types are enabled

2. **Check Edge Function Logs**:
   ```bash
   supabase functions logs onesignal-webhooks --follow
   ```

3. **Verify Environment Variables**:
   ```bash
   # Check if secret is set
   supabase secrets list | grep ONESIGNAL
   ```

### Signature verification failing

1. **Verify Secret**: Ensure `ONESIGNAL_WEBHOOK_SECRET` matches OneSignal
   Dashboard
2. **Check Headers**: Verify `x-onesignal-signature` header is present
3. **Payload Integrity**: Ensure request body is not modified before
   verification
4. **Temporary Disable**: Set `ONESIGNAL_ENABLE_SIGNATURE_VERIFICATION=false` to
   test

### High latency or timeouts

1. **Optimize Handlers**: Ensure event handlers complete quickly
2. **Async Operations**: Move heavy operations to background jobs
3. **Database Queries**: Add indexes for frequently queried fields
4. **Batch Processing**: Consider batching updates instead of processing
   individually

## Resources

- [OneSignal Webhook Documentation](https://documentation.onesignal.com/docs/webhooks)
- [OneSignal API Reference](https://documentation.onesignal.com/reference)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [OneSignal Dashboard](https://app.onesignal.com/)

## Sources

- [OneSignal Webhooks Documentation](https://documentation.onesignal.com/docs/webhooks)
- [OneSignal REST API](https://documentation.onesignal.com/reference)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
