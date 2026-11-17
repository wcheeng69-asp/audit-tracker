// Admin-only user management for Audit Tracker.
// Actions: create, reset_password, set_role, delete.
// Requires the caller to be signed in with profiles.role = 'admin'.
// verify_jwt is off at the gateway (compatible with asymmetric JWT signing keys);
// the function validates the caller's token itself via auth.getUser().
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const EMAIL_DOMAIN = "audit-tracker.local";
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

  // Identify the caller
  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Not signed in" }, 401);
  const { data: who, error: whoErr } = await admin.auth.getUser(token);
  if (whoErr || !who?.user) return json({ error: "Not signed in" }, 401);
  const { data: me } = await admin.from("profiles").select("role").eq("id", who.user.id).single();
  if (me?.role !== "admin") return json({ error: "Only administrators can manage users" }, 403);

  let body: Record<string, string>;
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }
  const action = body.action;

  try {
    if (action === "create") {
      const username = String(body.username || "").trim().toLowerCase();
      const password = String(body.password || "");
      const fullName = String(body.full_name || username).trim();
      const role = body.role === "admin" ? "admin" : "auditor";
      if (!/^[a-z0-9._-]{2,40}$/.test(username)) return json({ error: "Username must be 2–40 characters: letters, numbers, . _ -" }, 400);
      if (password.length < 6) return json({ error: "Initial password must be at least 6 characters" }, 400);
      const { data, error } = await admin.auth.admin.createUser({
        email: `${username}@${EMAIL_DOMAIN}`,
        password,
        email_confirm: true,
        user_metadata: { username, full_name: fullName },
      });
      if (error) return json({ error: error.message.includes("already") ? "That username is already taken" : error.message }, 400);
      await admin.from("profiles").update({ role, must_change_password: true, full_name: fullName }).eq("id", data.user.id);
      return json({ ok: true, id: data.user.id });
    }

    if (action === "reset_password") {
      const password = String(body.password || "");
      if (password.length < 6) return json({ error: "Password must be at least 6 characters" }, 400);
      const { error } = await admin.auth.admin.updateUserById(body.user_id, { password });
      if (error) return json({ error: error.message }, 400);
      await admin.from("profiles").update({ must_change_password: true }).eq("id", body.user_id);
      return json({ ok: true });
    }

    if (action === "set_role") {
      const role = body.role === "admin" ? "admin" : "auditor";
      if (body.user_id === who.user.id && role !== "admin") return json({ error: "You cannot remove your own admin role" }, 400);
      const { error } = await admin.from("profiles").update({ role }).eq("id", body.user_id);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    if (action === "delete") {
      if (body.user_id === who.user.id) return json({ error: "You cannot delete your own account" }, 400);
      const { error } = await admin.auth.admin.deleteUser(body.user_id);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    return json({ error: "Unknown action" }, 400);
  } catch (e) {
    return json({ error: (e as Error).message }, 500);
  }
});
