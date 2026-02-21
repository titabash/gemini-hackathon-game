// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

import { Database } from "../domain/entity/__generated__/schema.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

console.log("Hello from Functions!");

const supabaseClient = createClient<Database>(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_ANON_KEY") ?? "",
);

Deno.serve(async (_req) => {
  const query = await supabaseClient
    .from("general_users")
    .select("name")
    .limit(1);
  console.log(query.data);
  const generalUser = query.data?.[0];
  const data = {
    message: `Hello ${generalUser?.name ?? "World"}!`,
  };

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
});
