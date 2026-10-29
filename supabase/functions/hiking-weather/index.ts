import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { XMLParser } from "npm:fast-xml-parser@4.5.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const AREAS = [
  {
    region: "merapi",
    center: { lat: -7.5407, lng: 110.4457 },
    adm4: "34.04.17.2005",
    name: "Umbulharjo, Cangkringan, Sleman",
    timezone: "WIB",
    utcOffsetHours: 7,
  },
  {
    region: "lombok",
    center: { lat: -8.4111, lng: 116.4573 },
    adm4: "52.03.15.2002",
    name: "Sembalun Lawang, Lombok Timur",
    timezone: "WITA",
    utcOffsetHours: 8,
  },
  {
    region: "bali",
    center: { lat: -8.3433, lng: 115.5071 },
    adm4: "51.07.07.2004",
    name: "Sebudi, Selat, Karangasem",
    timezone: "WITA",
    utcOffsetHours: 8,
  },
];
const xmlParser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: "@",
  textNodeName: "#text",
  trimValues: true,
});

type WeatherSlot = {
  utc_datetime: string | null;
  local_datetime: string | null;
  temperature_c: number | null;
  humidity_percent: number | null;
  condition: string;
  condition_en: string;
  wind_kmh: number | null;
  wind_direction: string;
  cloud_percent: number | null;
  visibility_km: string;
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

function distanceKm(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const rad = (value: number) => (value * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

function findArea(lat: number, lng: number) {
  const point = { lat, lng };
  const area = AREAS
    .map((candidate) => ({ candidate, distance: distanceKm(point, candidate.center) }))
    .sort((a, b) => a.distance - b.distance)[0];
  return area && area.distance <= 15 ? area.candidate : null;
}

function collectSlots(value: unknown, slots: WeatherSlot[] = []): WeatherSlot[] {
  if (Array.isArray(value)) {
    for (const child of value) collectSlots(child, slots);
    return slots;
  }
  if (!value || typeof value !== "object") return slots;
  const row = value as Record<string, unknown>;
  if ("weather_desc" in row || "utc_datetime" in row || "local_datetime" in row) {
    slots.push({
      utc_datetime: typeof row.utc_datetime === "string" ? row.utc_datetime : null,
      local_datetime: typeof row.local_datetime === "string" ? row.local_datetime : null,
      temperature_c: numberOrNull(row.t),
      humidity_percent: numberOrNull(row.hu),
      condition: stringOr(row.weather_desc),
      condition_en: stringOr(row.weather_desc_en),
      wind_kmh: numberOrNull(row.ws),
      wind_direction: stringOr(row.wd),
      cloud_percent: numberOrNull(row.tcc),
      visibility_km: stringOr(row.vs_text),
    });
    return slots;
  }
  for (const child of Object.values(row)) collectSlots(child, slots);
  return slots;
}

function numberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function stringOr(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function findAnalysisDate(value: unknown): string {
  if (Array.isArray(value)) {
    for (const child of value) {
      const found = findAnalysisDate(child);
      if (found) return found;
    }
    return "";
  }
  if (!value || typeof value !== "object") return "";
  const row = value as Record<string, unknown>;
  if (typeof row.analysis_date === "string") return row.analysis_date;
  for (const child of Object.values(row)) {
    const found = findAnalysisDate(child);
    if (found) return found;
  }
  return "";
}

function asUtcIso(value: string) {
  if (!value) return "";
  return /(?:Z|[+-]\d{2}:?\d{2})$/i.test(value) ? value : `${value}Z`;
}

function pointInPolygon(lat: number, lng: number, polygon: Array<[number, number]>) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const [yi, xi] = polygon[i];
    const [yj, xj] = polygon[j];
    const crosses = (yi > lat) !== (yj > lat) &&
      lng < ((xj - xi) * (lat - yi)) / (yj - yi || Number.EPSILON) + xi;
    if (crosses) inside = !inside;
  }
  return inside;
}

function xmlText(node: Record<string, unknown> | null | undefined, key: string): string {
  if (!node) return "";
  const value = node[key];
  if (typeof value === "string" || typeof value === "number") return String(value).trim();
  if (value && typeof value === "object" && "#text" in value) {
    return String((value as Record<string, unknown>)["#text"] ?? "").trim();
  }
  return "";
}

function asArray<T>(value: T | T[] | null | undefined): T[] {
  if (value == null) return [];
  return Array.isArray(value) ? value : [value];
}

function xmlLink(item: Record<string, unknown>) {
  const link = item.link;
  if (typeof link === "string") return link.trim();
  if (link && typeof link === "object") {
    const record = link as Record<string, unknown>;
    return String(record["@href"] ?? record["#text"] ?? "").trim();
  }
  return "";
}

function parseCap(xml: string) {
  const parsed = xmlParser.parse(xml) as Record<string, unknown>;
  const alert = parsed.alert as Record<string, unknown> | undefined;
  const infos = asArray(alert?.info as Record<string, unknown> | Record<string, unknown>[] | undefined);
  const info = infos.find((item) => xmlText(item, "language").startsWith("id")) ?? infos[0];
  if (!alert || !info) return null;
  const polygons: Array<Array<[number, number]>> = [];
  const areas = asArray(info.area as Record<string, unknown> | Record<string, unknown>[] | undefined);
  for (const area of areas) {
    for (const polygonValue of asArray(area.polygon as string | string[] | undefined)) {
      const points = String(polygonValue).trim().split(/\s+/).map((pair) => {
        const [lat, lng] = pair.split(",").map(Number);
        return [lat, lng] as [number, number];
      }).filter(([lat, lng]) => Number.isFinite(lat) && Number.isFinite(lng));
      if (points.length >= 3) polygons.push(points);
    }
  }
  const identifier = xmlText(alert, "identifier");
  const sent = xmlText(alert, "sent");
  return {
    identifier,
    revision: sent || xmlText(alert, "references") || identifier,
    headline: xmlText(info, "headline") || xmlText(info, "event") || "Peringatan dini cuaca BMKG",
    description: xmlText(info, "description"),
    severity: xmlText(info, "severity") || "Unknown",
    urgency: xmlText(info, "urgency") || "Unknown",
    effective_at: xmlText(info, "effective") || null,
    expires_at: xmlText(info, "expires") || null,
    area_desc: areas.map((area) => xmlText(area, "areaDesc")).filter(Boolean).join("; "),
    polygons,
  };
}

function base64Url(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function encodeText(value: string) {
  return base64Url(new TextEncoder().encode(value));
}

function pemBytes(pem: string) {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  return Uint8Array.from(atob(body), (char) => char.charCodeAt(0));
}

let cachedGoogleToken: { value: string; expiresAt: number } | null = null;
async function getGoogleAccessToken(serviceAccount: Record<string, string>) {
  if (cachedGoogleToken && cachedGoogleToken.expiresAt > Date.now() + 60_000) {
    return cachedGoogleToken.value;
  }
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encodeText(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${encodeText(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)));
  const assertion = `${unsigned}.${base64Url(signature)}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`Google OAuth failed: ${response.status}`);
  const tokenData = await response.json();
  cachedGoogleToken = { value: tokenData.access_token, expiresAt: Date.now() + tokenData.expires_in * 1000 };
  return cachedGoogleToken.value;
}

async function sendFcm(serviceAccount: Record<string, string>, token: string, alert: ReturnType<typeof parseCap>) {
  if (!alert) return;
  const accessToken = await getGoogleAccessToken(serviceAccount);
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: alert.headline, body: alert.description.slice(0, 240) || alert.area_desc },
        data: { type: "hiking_weather_alert", alert_id: alert.identifier },
        android: { priority: "high" },
        apns: { headers: { "apns-priority": "10" } },
      },
    }),
  });
  if (!response.ok) throw new Error(`FCM send failed: ${response.status} ${await response.text()}`);
}

async function refreshAlerts(supabase: ReturnType<typeof createClient>, serviceAccount: Record<string, string>) {
  const rssResponse = await fetch("https://www.bmkg.go.id/alerts/nowcast/id", { headers: { Accept: "application/rss+xml, application/xml" } });
  if (!rssResponse.ok) throw new Error(`BMKG alert feed failed: ${rssResponse.status}`);
  const rss = xmlParser.parse(await rssResponse.text()) as Record<string, unknown>;
  const rssDoc = rss.rss as Record<string, unknown> | undefined;
  const channel = rssDoc?.channel as Record<string, unknown> | undefined;
  const items = asArray(channel?.item as Record<string, unknown> | Record<string, unknown>[] | undefined);
  const links = items.map((item) => ({
    title: xmlText(item, "title"),
    link: xmlLink(item),
  })).filter((entry) => /bali|nusa tenggara barat|ntb|yogyakarta|daerah istimewa yogyakarta|\bdiy\b/i.test(entry.title));
  const alerts = [];
  for (const entry of links) {
    if (!entry.link) continue;
    try {
      const detailUrl = new URL(entry.link, "https://www.bmkg.go.id").toString();
      const response = await fetch(detailUrl);
      if (!response.ok) continue;
      const alert = parseCap(await response.text());
      if (!alert?.identifier) continue;
      const expiry = alert.expires_at ? Date.parse(alert.expires_at) : Number.POSITIVE_INFINITY;
      if (expiry <= Date.now()) continue;
      const { error } = await supabase.from("hiking_weather_alerts").upsert({
        ...alert,
        updated_at: new Date().toISOString(),
      }, { onConflict: "identifier" });
      if (error) throw error;
      alerts.push(alert);
    } catch (error) {
      console.error("CAP alert parse/fetch failed", entry.title, error);
    }
  }

  const { data: sessions, error: sessionError } = await supabase
    .from("hiking_sessions")
    .select("id,user_id,last_latitude,last_longitude,last_point_at")
    .eq("status", "active")
    .not("last_latitude", "is", null)
    .not("last_longitude", "is", null)
    .gte("last_point_at", new Date(Date.now() - 15 * 60_000).toISOString());
  if (sessionError) throw sessionError;

  let sentCount = 0;
  for (const session of sessions ?? []) {
    const lat = Number(session.last_latitude);
    const lng = Number(session.last_longitude);
    const area = findArea(lat, lng);
    if (!area || !session.last_point_at) continue;
    for (const alert of alerts) {
      if (!alert || !alert.polygons.some((polygon) => pointInPolygon(lat, lng, polygon))) continue;
      const effective = alert.effective_at ? Date.parse(alert.effective_at) : 0;
      const expires = alert.expires_at ? Date.parse(alert.expires_at) : Number.POSITIVE_INFINITY;
      if (effective > Date.now() || expires <= Date.now()) continue;
      const { data: tokens, error: tokenError } = await supabase
        .from("user_notification_preferences")
        .select("fcm_token")
        .eq("user_id", session.user_id);
      if (tokenError) throw tokenError;
      if (!tokens?.length) continue;
      const { data: reservation, error: reserveError } = await supabase
        .from("hiking_weather_alert_deliveries")
        .insert({
          alert_identifier: alert.identifier,
          alert_revision: alert.revision,
          user_id: session.user_id,
          session_id: session.id,
        })
        .select("id")
        .maybeSingle();
      if (reserveError?.code === "23505") continue;
      if (reserveError) throw reserveError;
      if (!reservation) continue;
      let delivered = false;
      for (const row of tokens) {
        try {
          await sendFcm(serviceAccount, row.fcm_token, alert);
          sentCount++;
          delivered = true;
        } catch (error) {
          console.error("FCM send failed", error);
        }
      }
      if (!delivered) {
        await supabase.from("hiking_weather_alert_deliveries").delete().eq("id", reservation.id);
      }
    }
  }
  return { checked_sessions: sessions?.length ?? 0, active_alerts: alerts.length, sent: sentCount };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) throw new Error("Missing Supabase server configuration");
    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
    const body = await req.json();

    if (body.action === "weather") {
      const authorization = req.headers.get("Authorization") ?? "";
      const accessToken = authorization.replace(/^Bearer\s+/i, "");
      const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? req.headers.get("apikey") ?? "";
      const isAnonymousClient = Boolean(anonKey) && accessToken === anonKey && req.headers.get("apikey") === anonKey;
      if (!isAnonymousClient) {
        const { data: userData, error: userError } = await supabase.auth.getUser(accessToken);
        if (userError || !userData.user) return json({ error: "Authentication required" }, 401);
      }

      const latitude = Number(body.latitude);
      const longitude = Number(body.longitude);
      if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        return json({ error: "Invalid GPS coordinates" }, 400);
      }
      const area = findArea(latitude, longitude);
      if (!area) return json({ error: "Location is outside the supported hiking areas" }, 404);

      const { data: cached, error: cacheError } = await supabase.from("hiking_weather_cache")
        .select("payload,analysis_date,fetched_at,expires_at")
        .eq("adm4", area.adm4)
        .maybeSingle();
      if (cacheError) throw cacheError;
      let payload = cached?.payload;
      let fetchedAt = cached?.fetched_at;
      if (!cached || Date.parse(cached.expires_at) <= Date.now()) {
        const response = await fetch(`https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${encodeURIComponent(area.adm4)}`, {
          headers: { Accept: "application/json", "User-Agent": "SIGUMI/1.0 (hiking weather)" },
        });
        if (!response.ok) throw new Error(`BMKG forecast failed: ${response.status}`);
        const raw = await response.json();
        const slots = collectSlots(raw);
        if (slots.length === 0) throw new Error("BMKG returned no forecast slots");
        const analysisDate = asUtcIso(findAnalysisDate(raw));
        const now = new Date();
        payload = {
          area: {
            adm4: area.adm4,
            name: area.name,
            source: "BMKG",
            timezone: area.timezone,
            utc_offset_hours: area.utcOffsetHours,
          },
          analysis_date: analysisDate || null,
          fetched_at: now.toISOString(),
          forecast: slots,
        };
        fetchedAt = now.toISOString();
        const { error } = await supabase.from("hiking_weather_cache").upsert({
          adm4: area.adm4,
          area_name: area.name,
          analysis_date: analysisDate || null,
          fetched_at: fetchedAt,
          expires_at: new Date(now.getTime() + 3 * 60 * 60_000).toISOString(),
          payload,
        }, { onConflict: "adm4" });
        if (error) throw error;
      }

      if (payload && typeof payload === "object") {
        const cachedPayload = payload as Record<string, unknown>;
        const cachedArea = cachedPayload.area && typeof cachedPayload.area === "object"
          ? cachedPayload.area as Record<string, unknown>
          : {};
        payload = {
          ...cachedPayload,
          area: {
            ...cachedArea,
            adm4: area.adm4,
            name: area.name,
            source: "BMKG",
            timezone: area.timezone,
            utc_offset_hours: area.utcOffsetHours,
          },
        };
      }

      const { data: alertRows, error: alertsError } = await supabase.from("hiking_weather_alerts")
        .select("identifier,revision,headline,description,severity,urgency,effective_at,expires_at,area_desc,polygons")
        .gt("expires_at", new Date().toISOString())
        .gte("updated_at", new Date(Date.now() - 15 * 60_000).toISOString());
      if (alertsError) throw alertsError;
      const warnings = (alertRows ?? []).filter((alert) => {
        const effective = alert.effective_at ? Date.parse(alert.effective_at) : 0;
        const expires = alert.expires_at ? Date.parse(alert.expires_at) : Number.POSITIVE_INFINITY;
        return effective <= Date.now() && expires > Date.now() &&
          Array.isArray(alert.polygons) && alert.polygons.some((polygon) => pointInPolygon(latitude, longitude, polygon));
      }).map(({ polygons: _polygons, ...alert }) => alert);
      return json({ ...payload, fetched_at: fetchedAt, warnings });
    }

    if (body.action === "refresh_alerts") {
      const expectedSecret = Deno.env.get("HIKING_WEATHER_CRON_SECRET");
      const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
      const authorization = req.headers.get("Authorization") ?? "";
      if (!expectedSecret || authorization !== `Bearer ${expectedSecret}`) return json({ error: "Unauthorized scheduler" }, 401);
      if (!serviceAccountJson) throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON secret");
      const serviceAccount = JSON.parse(serviceAccountJson) as Record<string, string>;
      return json(await refreshAlerts(supabase, serviceAccount));
    }
    return json({ error: "Unsupported action" }, 400);
  } catch (error) {
    console.error("hiking-weather error", error);
    return json({ error: "Weather service is temporarily unavailable" }, 503);
  }
});
