---
name: supabase-edge-function
description: Create Supabase Edge Functions with TypeScript and Deno. Use when implementing serverless functions, webhooks, or backend API endpoints.
---

# Supabase Edge Function Creation Skill

Create a new Supabase Edge Function with TypeScript and Deno runtime.

## Task

You will create a serverless Edge Function in `supabase/functions/{function_name}/` with:
- TypeScript implementation
- CORS support
- Error handling
- Type-safe database access with Drizzle
- Proper project structure

## Implementation Steps

1. **Gather Requirements**:
   - Ask for the function name (e.g., "user-profile", "send-email")
   - Ask what the function should do
   - Ask if it needs database access
   - Ask if it needs external API calls

2. **Create Function Directory**:
   ```bash
   mkdir -p supabase/functions/{function_name}
   ```

3. **Create Main Entry Point** (`index.ts`):
   - Handle HTTP requests
   - Add CORS headers
   - Implement error handling
   - Return proper responses

4. **Create Deno Configuration** (`deno.json`):
   - Configure import maps
   - Set compiler options
   - Define tasks

5. **Add Type Definitions** (if needed):
   - Create handler types in `handlers/types.ts`
   - Import Drizzle schema for database operations
   - Import Supabase types if needed

6. **Test Locally**:
   ```bash
   supabase functions serve {function_name}
   ```

7. **Deploy**:
   ```bash
   supabase functions deploy {function_name}
   # Or use make command
   make deploy-functions
   ```

## Project Structure

```
supabase/functions/
├── {function_name}/
│   ├── index.ts           # Main entry point
│   ├── deno.json          # Deno configuration
│   ├── README.md          # Documentation
│   └── handlers/          # Optional: Business logic
│       ├── types.ts       # Type definitions
│       └── handler.ts     # Handler functions
```

## Example: Basic Edge Function

### index.ts (Simple GET endpoint):

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Your logic here
    const data = {
      message: "Hello from Edge Function!",
      timestamp: new Date().toISOString(),
    };

    return new Response(
      JSON.stringify(data),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
```

### index.ts (With Database Access using Drizzle):

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getDb } from "../_shared/infra/database.ts";
import { users } from "../../drizzle/schema/users.ts";
import { eq } from "npm:drizzle-orm@0.36.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse request
    const { userId } = await req.json();

    // Get database connection
    const db = getDb();

    // Query database with Drizzle
    const user = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1)
      .then((rows) => rows[0]);

    if (!user) {
      return new Response(
        JSON.stringify({ error: "User not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({ user }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
```

### index.ts (Webhook Handler):

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-signature",
};

/**
 * Verify webhook signature
 */
async function verifySignature(
  payload: string,
  signature: string | null,
  secret: string,
): Promise<boolean> {
  if (!signature) return false;

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

  const hashArray = Array.from(new Uint8Array(signatureBuffer));
  const hashHex = hashArray
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return signature.toLowerCase() === hashHex.toLowerCase();
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const webhookSecret = Deno.env.get("WEBHOOK_SECRET");
    const bodyText = await req.text();
    const signature = req.headers.get("x-webhook-signature");

    // Verify signature if secret is configured
    if (webhookSecret) {
      const isValid = await verifySignature(
        bodyText,
        signature,
        webhookSecret,
      );

      if (!isValid) {
        return new Response(
          JSON.stringify({ error: "Invalid signature" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
    }

    const event = JSON.parse(bodyText);

    // Process webhook event
    console.log("Webhook event:", event);

    return new Response(
      JSON.stringify({ success: true }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
```

## Best Practices

1. **CORS Headers**:
   - Always include CORS headers
   - Handle OPTIONS preflight requests
   - Set appropriate allowed headers

2. **Error Handling**:
   - Use try-catch blocks
   - Return proper HTTP status codes
   - Log errors for debugging
   - Return JSON error responses

3. **Type Safety**:
   - Use Drizzle schema for database types
   - Define TypeScript interfaces
   - Avoid `any` type

4. **Database Access**:
   - Use Drizzle ORM via `getDb()`
   - Import schema from `../../drizzle/schema/`
   - Close connections properly

5. **Environment Variables**:
   - Store secrets in environment
   - Access via `Deno.env.get()`
   - Document required variables

6. **Security**:
   - Verify webhook signatures
   - Validate input data
   - Sanitize user input
   - Use HTTPS in production

## Common Patterns

### Authentication Check:

```typescript
const authHeader = req.headers.get("authorization");
if (!authHeader) {
  return new Response(
    JSON.stringify({ error: "Unauthorized" }),
    { status: 401, headers: corsHeaders },
  );
}

const token = authHeader.replace("Bearer ", "");
// Verify token with Supabase
```

### Calling External API:

```typescript
const response = await fetch("https://api.example.com/data", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${apiKey}`,
  },
  body: JSON.stringify(data),
});

if (!response.ok) {
  throw new Error(`API error: ${response.statusText}`);
}

const result = await response.json();
```

### Transaction with Drizzle:

```typescript
const db = getDb();

await db.transaction(async (tx) => {
  await tx.insert(orders).values({ userId, total });
  await tx.update(users)
    .set({ balance: sql`${users.balance} - ${total}` })
    .where(eq(users.id, userId));
});
```

## Testing & Deployment

### Local Testing:

```bash
# Serve function locally
supabase functions serve {function_name}

# Test with curl
curl -X POST http://localhost:54321/functions/v1/{function_name} \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### Deploy to Supabase:

```bash
# Deploy single function
supabase functions deploy {function_name}

# Deploy all functions
make deploy-functions
```

### View Logs:

```bash
supabase functions logs {function_name} --follow
```

## Common Pitfalls

- ❌ Don't forget CORS headers
- ❌ Don't forget to handle OPTIONS requests
- ❌ Don't hardcode secrets in code
- ❌ Don't forget error handling
- ❌ Don't return non-JSON responses
- ❌ Don't forget to close database connections

## Notes

- Edge Functions run on Deno runtime
- Use TypeScript for type safety
- See CLAUDE.md for architecture guidelines
- Check `supabase/functions/onesignal-webhooks/` and `supabase/functions/polar-webhooks/` for complete examples
