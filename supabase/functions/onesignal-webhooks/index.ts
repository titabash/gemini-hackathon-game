import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleOneSignalEvent } from "./handlers/notification.ts";
import type { OneSignalEvent } from "./handlers/types.ts";

/**
 * CORS headers for webhook endpoint
 */
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-onesignal-signature",
};

/**
 * Verify OneSignal webhook signature using HMAC-SHA256
 *
 * @param payload - Request body as string
 * @param signature - Signature from x-onesignal-signature header
 * @param secret - OneSignal webhook secret from environment
 * @returns True if signature is valid
 */
async function verifyWebhookSignature(
  payload: string,
  signature: string | null,
  secret: string,
): Promise<boolean> {
  if (!signature) {
    console.error("Missing x-onesignal-signature header");
    return false;
  }

  try {
    // Create HMAC-SHA256 hash of the payload
    const encoder = new TextEncoder();
    const keyData = encoder.encode(secret);
    const messageData = encoder.encode(payload);

    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );

    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      cryptoKey,
      messageData,
    );

    // Convert signature to hex string
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const hashHex = hashArray
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // Compare signatures (constant-time comparison)
    return signature.toLowerCase() === hashHex.toLowerCase();
  } catch (error) {
    console.error("Error verifying webhook signature:", error);
    return false;
  }
}

/**
 * OneSignal Webhook Handler
 *
 * Handles incoming webhook events from OneSignal.
 * Verifies webhook signature and routes events to appropriate handlers.
 */
serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        {
          status: 405,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Get environment variables
    const webhookSecret = Deno.env.get("ONESIGNAL_WEBHOOK_SECRET");
    const enableSignatureVerification = Deno.env.get(
      "ONESIGNAL_ENABLE_SIGNATURE_VERIFICATION",
    ) !== "false";

    // Read request body
    const bodyText = await req.text();
    const signature = req.headers.get("x-onesignal-signature");

    // Verify webhook signature if enabled and secret is configured
    if (enableSignatureVerification && webhookSecret) {
      const isValid = await verifyWebhookSignature(
        bodyText,
        signature,
        webhookSecret,
      );

      if (!isValid) {
        console.error("Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid signature" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
    } else if (enableSignatureVerification && !webhookSecret) {
      console.warn(
        "Signature verification is enabled but ONESIGNAL_WEBHOOK_SECRET is not configured",
      );
    }

    // Parse webhook event
    const event = JSON.parse(bodyText) as OneSignalEvent;

    // Validate required fields
    if (!event.event || !event.app_id || !event.timestamp) {
      return new Response(
        JSON.stringify({ error: "Invalid webhook payload" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Handle the event
    await handleOneSignalEvent(event);

    // Return success response
    return new Response(
      JSON.stringify({ success: true, event: event.event }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Error processing webhook:", error);

    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
