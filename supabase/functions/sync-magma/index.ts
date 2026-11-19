import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for Edge Functions
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FETCH_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
};

interface MagmaVolcano {
  name: string;
  region: string;
  level: number;
  levelName: string;
  reportUrl: string;
}

interface SeismicEntry {
  count: number;
  detail?: string;
}

interface ParsedVarReport {
  reportDate: string;
  periodStart: string;
  periodEnd: string;
  timezone: string;
  visualPhotoUrl: string | null;
  visibility: string | null;
  craterSmoke: string | null;
  avalancheNotes: string | null;
  seismicity: Record<string, SeismicEntry>;
  summary: string | null;
  author: string | null;
  weather: string | null;
  windDirection: string | null;
  windSpeedText: string | null;
  tempMin: number | null;
  tempMax: number | null;
  humidityMin: number | null;
  humidityMax: number | null;
  pressureMin: number | null;
  pressureMax: number | null;
}

function parseMagmaHtml(content: string): MagmaVolcano[] {
  const volcanoes: MagmaVolcano[] = [];

  const tableIndex = content.indexOf("<table");
  if (tableIndex === -1) return volcanoes;
  const tableContent = content.substring(tableIndex);

  const levelDefs = [
    { level: 4, name: "Awas", marker: "Level IV (Awas)" },
    { level: 3, name: "Siaga", marker: "Level III (Siaga)" },
    { level: 2, name: "Waspada", marker: "Level II (Waspada)" },
    { level: 1, name: "Normal", marker: "Level I (Normal)" },
  ];

  for (let i = 0; i < levelDefs.length; i++) {
    const { level, name: levelName, marker } = levelDefs[i];
    const startIndex = tableContent.indexOf(marker);
    if (startIndex === -1) continue;

    let endIndex: number;
    if (i < levelDefs.length - 1) {
      endIndex = tableContent.indexOf(levelDefs[i + 1].marker, startIndex);
    } else {
      endIndex = tableContent.indexOf("</table>", startIndex);
    }

    const sectionHtml = endIndex !== -1 ? tableContent.substring(startIndex, endIndex) : tableContent.substring(startIndex);

    if (sectionHtml.includes("Tidak ada gunung api")) {
      continue;
    }

    // Match each volcano line
    // e.g. Lewotobi Laki-laki - Nusa Tenggara Timur <a href="https://magma.esdm.go.id/v1/gunung-api/laporan/...
    const rowRegex = /<td>\s*([\s\S]*?)\s+-\s+([\s\S]*?)\s*<a\s+href="([^"]+)"/gi;
    let rowMatch: RegExpExecArray | null;
    while ((rowMatch = rowRegex.exec(sectionHtml)) !== null) {
      const volcanoName = rowMatch[1].replace(/<[^>]*>/g, "").trim();
      const region = rowMatch[2].replace(/<[^>]*>/g, "").trim();
      const reportUrl = rowMatch[3].trim();

      volcanoes.push({
        name: volcanoName,
        region,
        level,
        levelName,
        reportUrl,
      });
    }
  }

  return volcanoes;
}

function normalizeName(str: string): string {
  return str.toLowerCase().replace(/gunung/gi, "").trim();
}

function volcanoKeyFromName(name: string): string | null {
  const norm = normalizeName(name);
  if (norm.includes("merapi")) return "merapi";
  if (norm.includes("agung")) return "agung";
  if (norm.includes("rinjani")) return "rinjani";
  return null;
}

function defaultTimezoneForKey(volcanoKey: string): string {
  return volcanoKey === "merapi" ? "WIB" : "WITA";
}

function generateDescription(name: string, level: number, levelName: string, region: string): string {
  switch (level) {
    case 4:
      return `Status Level IV (Awas). Aktivitas vulkanik Gunung ${name} (${region}) mengalami peningkatan sangat tinggi atau sedang erupsi. Masyarakat dan wisatawan dilarang beraktivitas di dalam radius bahaya sesuai rekomendasi PVMBG/MAGMA Indonesia.`;
    case 3:
      return `Status Level III (Siaga). Aktivitas vulkanik Gunung ${name} (${region}) memperlihatkan peningkatan nyata atau erupsi berkala. Harap mematuhi rekomendasi zona bahaya PVMBG/MAGMA Indonesia.`;
    case 2:
      return `Status Level II (Waspada). Hasil pengamatan visual dan instrumental Gunung ${name} (${region}) mulai memperlihatkan peningkatan aktivitas di atas normal. Waspadai potensi erupsi sewaktu-waktu.`;
    case 1:
    default:
      return `Status Level I (Normal). Aktivitas vulkanik Gunung ${name} (${region}) fluktuatif namun tidak memperlihatkan peningkatan aktivitas yang signifikan berdasarkan pengamatan PVMBG/MAGMA Indonesia.`;
  }
}

function stripHtml(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|li|div|tr|h[1-6])>/gi, "\n")
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#0?39;/gi, "'")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/[ \t]+/g, " ")
    .replace(/\n\s*\n+/g, "\n")
    .trim();
}

function resolveAbsoluteUrl(src: string): string | null {
  const cleaned = src.trim();
  if (!cleaned || cleaned.startsWith("data:")) return null;
  if (cleaned.startsWith("https://") || cleaned.startsWith("http://")) return cleaned;
  if (cleaned.startsWith("//")) return `https:${cleaned}`;
  if (cleaned.startsWith("/")) return `https://magma.esdm.go.id${cleaned}`;
  return null;
}

function extractVisualPhotoUrl(html: string): string | null {
  const imgRegex = /<img[^>]+src=["']([^"']+)["'][^>]*>/gi;
  let match: RegExpExecArray | null;
  while ((match = imgRegex.exec(html)) !== null) {
    const tag = match[0].toLowerCase();
    const src = match[1];
    const lowerSrc = src.toLowerCase();
    if (
      lowerSrc.includes("logo") ||
      lowerSrc.includes("icon") ||
      lowerSrc.includes("avatar") ||
      lowerSrc.includes("favicon") ||
      lowerSrc.endsWith(".svg") ||
      tag.includes("logo")
    ) {
      continue;
    }
    const url = resolveAbsoluteUrl(src);
    if (url && /\.(jpe?g|png|webp)(\?|$)/i.test(url)) {
      return url;
    }
  }
  return null;
}

function extractSection(plainText: string, heading: string, stopHeadings: string[]): string | null {
  const headingRe = new RegExp(`(?:^|\\n)\\s*${heading}[^\\n]*\\n`, "i");
  const startMatch = headingRe.exec(plainText);
  if (!startMatch) return null;

  const afterStart = plainText.slice(startMatch.index + startMatch[0].length);
  let endPos = afterStart.length;
  for (const stop of stopHeadings) {
    const stopRe = new RegExp(`(?:^|\\n)\\s*${stop}\\b`, "i");
    const stopMatch = stopRe.exec(afterStart);
    if (stopMatch && stopMatch.index < endPos) {
      endPos = stopMatch.index;
    }
  }
  const chunk = afterStart.slice(0, endPos).trim();
  return chunk.length > 0 ? chunk : null;
}

function parseIndonesianDate(text: string): string | null {
  const months: Record<string, string> = {
    januari: "01",
    februari: "02",
    maret: "03",
    april: "04",
    mei: "05",
    juni: "06",
    juli: "07",
    agustus: "08",
    september: "09",
    oktober: "10",
    november: "11",
    desember: "12",
  };
  const m = text.match(
    /(\d{1,2})\s+(Januari|Februari|Maret|April|Mei|Juni|Juli|Agustus|September|Oktober|November|Desember)\s+(\d{4})/i,
  );
  if (!m) return null;
  const day = m[1].padStart(2, "0");
  const month = months[m[2].toLowerCase()];
  const year = m[3];
  return month ? `${year}-${month}-${day}` : null;
}

function parseSeismicityFromText(text: string): Record<string, SeismicEntry> {
  const result: Record<string, SeismicEntry> = {};
  const lines = text
    .split(/[\n;•]+/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  const add = (key: string, count: number, detail?: string) => {
    if (result[key]) {
      result[key] = {
        count: result[key].count + count,
        detail: result[key].detail ?? detail,
      };
    } else {
      result[key] = detail ? { count, detail } : { count };
    }
  };

  for (const line of lines) {
    const lower = line.toLowerCase();
    const ampMatch = line.match(/amplitudo\s+([\d.,]+(?:\s*-\s*[\d.,]+)?\s*mm)/i);
    const durMatch = line.match(/(?:lama\s+gempa|durasi)\s+([\d.,]+(?:\s*-\s*[\d.,]+)?\s*(?:detik|dtk|s))/i);
    const detailParts = [
      ampMatch ? `Amp ${ampMatch[1].trim()}` : null,
      durMatch ? `Dur ${durMatch[1].trim()}` : null,
    ].filter(Boolean) as string[];
    const detail = detailParts.length > 0 ? detailParts.join(" · ") : undefined;

    const matchCategory = (re: RegExp): number | null => {
      const m = lower.match(re);
      return m ? Number.parseInt(m[1], 10) : null;
    };

    const guguran = matchCategory(/(\d+)\s*(?:kali\s+)?(?:gempa\s+)?guguran\b/);
    if (guguran !== null && !lower.includes("guguran lava")) {
      add("guguran", guguran, detail);
    }

    const hembusan = matchCategory(/(\d+)\s*(?:kali\s+)?(?:gempa\s+)?hembusan\b/);
    if (hembusan !== null) {
      add("hembusan", hembusan, detail);
    }

    const vulkanik = matchCategory(
      /(\d+)\s*(?:kali\s+)?(?:gempa\s+)?(?:vulkanik(?:\s+(?:dangkal|dalam))?|hybrid|fase\s+banyak)\b/,
    );
    if (vulkanik !== null) {
      add("vulkanik", vulkanik, detail);
    }

    const tektonik = matchCategory(/(\d+)\s*(?:kali\s+)?(?:gempa\s+)?tektonik(?:\s+(?:lokal|jauh))?\b/);
    if (tektonik !== null) {
      add("tektonik", tektonik, detail);
    }
  }

  return result;
}

function normalizeClockToHhMmSs(raw: string): string {
  const cleaned = raw.trim().replace(".", ":");
  const m = cleaned.match(/^(\d{1,2}):(\d{2})(?::(\d{2}))?$/);
  if (!m) return cleaned;
  return `${m[1].padStart(2, "0")}:${m[2]}:${m[3] ?? "00"}`;
}

function parseVarReportHtml(html: string, volcanoKey: string): ParsedVarReport {
  const plainText = stripHtml(html);
  const visualPhotoUrl = extractVisualPhotoUrl(html);
  const fallbackTz = defaultTimezoneForKey(volcanoKey);

  const periodMatch = plainText.match(
    /(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})\s*(WIB|WITA|WIT)/i,
  );
  const periodStart = normalizeClockToHhMmSs(
    periodMatch ? periodMatch[1] : "00:00",
  );
  const periodEnd = normalizeClockToHhMmSs(
    periodMatch ? periodMatch[2] : "24:00",
  );
  const timezone = periodMatch ? periodMatch[3].toUpperCase() : fallbackTz;

  const reportDate =
    parseIndonesianDate(plainText) ?? new Date().toISOString().slice(0, 10);

  const visualSection = extractSection(plainText, "Pengamatan Visual|Visual", [
    "Klimatologi",
    "Pengamatan Kegempaan",
    "Kegempaan",
    "Keterangan Lainnya",
    "Rekomendasi",
  ]);
  const climateSection = extractSection(plainText, "Klimatologi", [
    "Pengamatan Visual",
    "Pengamatan Kegempaan",
    "Kegempaan",
    "Rekomendasi",
  ]);
  const seismicSection = extractSection(
    plainText,
    "Pengamatan Kegempaan|Kegempaan",
    ["Keterangan Lainnya", "Rekomendasi", "Kesimpulan", "Penyusun"],
  );
  const otherSection = extractSection(plainText, "Keterangan Lainnya", [
    "Rekomendasi",
    "Kesimpulan",
    "Penyusun",
  ]);

  let visibility: string | null = null;
  let craterSmoke: string | null = null;
  let avalancheNotes: string | null = null;

  const visualCandidates = [visualSection, otherSection]
    .filter(Boolean)
    .join("\n")
    .split(/(?<=[.!?])\s+|\n+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  for (const s of visualCandidates) {
    const lower = s.toLowerCase();
    if (!visibility && /(terlihat\s+jelas|tertutup\s+kabut|kabut\s+0-|visibilitas)/.test(lower)) {
      visibility = s;
    }
    if (!craterSmoke && /(asap\s+kawah|asap\s+putih|asap\s+kelabu|hembusan\s+asap|solfatara)/.test(lower)) {
      craterSmoke = s;
    }
    if (!avalancheNotes && /(guguran\s+lava|awan\s+panas|guguran\s+pijar|jarak\s+luncur|sinar\s+api|lontaran|kubah\s+lava)/.test(lower)) {
      avalancheNotes = s;
    }
  }

  const seismicity = parseSeismicityFromText(seismicSection ?? plainText);

  const authorMatch = plainText.match(/(?:Penyusun|Dibuat oleh)\s*[:\-]?\s*([^\n]{3,80})/i);
  const author = authorMatch ? authorMatch[1].trim() : "PVMBG · MAGMA Indonesia";

  const tempMatch = (climateSection ?? plainText).match(/suhu\s+udara\s+([\d.]+)\s*[-–]\s*([\d.]+)\s*°?c/i);
  const humMatch = (climateSection ?? plainText).match(/kelembaban\s+([\d.]+)\s*[-–]\s*([\d.]+)\s*%/i);
  const pressMatch = (climateSection ?? plainText).match(/tekanan\s+udara\s+([\d.]+)\s*[-–]\s*([\d.]+)\s*mmhg/i);
  const windMatch = (climateSection ?? plainText).match(/angin\s+(lemah|sedang|kencang)?\s*(?:ke\s+arah\s+)?([a-z\s-]+?)(?:[.,\n]|$)/i);
  const weatherMatch = (climateSection ?? "").match(/^([^.\n]{3,60})/);

  const summaryParts = [visualSection, seismicSection, otherSection].filter(Boolean) as string[];
  const summary = summaryParts.length > 0 ? summaryParts.join("\n\n") : null;

  return {
    reportDate,
    periodStart,
    periodEnd,
    timezone,
    visualPhotoUrl,
    visibility,
    craterSmoke,
    avalancheNotes,
    seismicity,
    summary,
    author,
    weather: weatherMatch ? weatherMatch[1].trim() : null,
    windDirection: windMatch ? windMatch[2].trim() : null,
    windSpeedText: windMatch && windMatch[1] ? windMatch[1].trim() : null,
    tempMin: tempMatch ? Number.parseFloat(tempMatch[1]) : null,
    tempMax: tempMatch ? Number.parseFloat(tempMatch[2]) : null,
    humidityMin: humMatch ? Number.parseFloat(humMatch[1]) : null,
    humidityMax: humMatch ? Number.parseFloat(humMatch[2]) : null,
    pressureMin: pressMatch ? Number.parseFloat(pressMatch[1]) : null,
    pressureMax: pressMatch ? Number.parseFloat(pressMatch[2]) : null,
  };
}

const VONA_VOLCANO_CODES: Record<string, string> = {
  merapi: "MER",
  agung: "AGU",
  rinjani: "RIN",
};

async function fetchLatestVonaMap(): Promise<Record<string, string>> {
  const vonaByKey: Record<string, string> = {};
  await Promise.all(
    Object.entries(VONA_VOLCANO_CODES).map(async ([key, code]) => {
      try {
        const res = await fetch(`https://magma.esdm.go.id/v1/vona?code=${code}`, {
          headers: FETCH_HEADERS,
        });
        if (!res.ok) return;
        const html = await res.text();
        // Match first/latest VONA timeline card badge:
        // <div class="timeline-time"><small>...</small><a ...>Yellow</a></div>
        const match = html.match(
          /<div\s+class=["']timeline-time["'][^>]*>[\s\S]*?<a[^>]*>\s*(Green|Yellow|Orange|Red)\s*<\/a>/i,
        );
        if (match) {
          vonaByKey[key] = match[1].toUpperCase();
        }
      } catch (err) {
        console.warn(`Failed to fetch VONA for ${key} (${code}):`, err);
      }
    }),
  );
  return vonaByKey;
}

Deno.serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variables.");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Fetch live page from MAGMA Indonesia
    console.log("Fetching live data from MAGMA Indonesia...");
    const magmaRes = await fetch("https://magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas", {
      headers: FETCH_HEADERS,
    });

    if (!magmaRes.ok) {
      throw new Error(`Failed to fetch MAGMA website: ${magmaRes.status} ${magmaRes.statusText}`);
    }

    const html = await magmaRes.text();
    const magmaList = parseMagmaHtml(html);
    console.log(`Parsed ${magmaList.length} volcanoes from MAGMA Indonesia.`);

    if (magmaList.length === 0) {
      throw new Error("No volcanoes parsed from MAGMA page. The HTML structure might have changed.");
    }

    // 2. Query existing volcanoes in database
    const { data: dbVolcanoes, error: dbError } = await supabase
      .from("volcanoes")
      .select("id, name, status_level, status_description, region");

    if (dbError) {
      throw new Error(`Failed to fetch volcanoes from database: ${dbError.message}`);
    }

    const updates = [];
    const varSyncResults = [];
    const now = new Date().toISOString();
    const vonaByKey = await fetchLatestVonaMap();

    for (const dbV of dbVolcanoes || []) {
      const normDbName = normalizeName(dbV.name);
      const match = magmaList.find((m) => normalizeName(m.name) === normDbName);

      if (match) {
        const hasLevelChanged = dbV.status_level !== match.level;
        const newDesc = generateDescription(match.name, match.level, match.levelName, match.region);

        // Update database row (triggers Supabase Realtime for subscribers)
        const { error: updateError } = await supabase
          .from("volcanoes")
          .update({
            status_level: match.level,
            status_description: newDesc,
            last_update: now,
          })
          .eq("id", dbV.id);

        if (updateError) {
          console.error(`Error updating ${dbV.name}:`, updateError.message);
        } else {
          updates.push({
            id: dbV.id,
            name: dbV.name,
            previousLevel: dbV.status_level,
            currentLevel: match.level,
            levelChanged: hasLevelChanged,
            status: match.levelName,
          });
        }

        // 3. Non-blocking VAR + VONA sync into volcano_summarizer for tracked volcanoes
        const volcanoKey = volcanoKeyFromName(dbV.name);
        if (volcanoKey && match.reportUrl) {
          try {
            const reportRes = await fetch(match.reportUrl, { headers: FETCH_HEADERS });
            if (reportRes.ok) {
              const reportHtml = await reportRes.text();
              const parsed = parseVarReportHtml(reportHtml, volcanoKey);
              const { error: varErr } = await supabase
                .from("volcano_summarizer")
                .upsert(
                  {
                    fetched_at: now,
                    report_date: parsed.reportDate,
                    volcano_name: dbV.name,
                    volcano_key: volcanoKey,
                    level_code: match.level,
                    level_name: match.levelName,
                    period_start: parsed.periodStart,
                    period_end: parsed.periodEnd,
                    timezone: parsed.timezone,
                    summary: parsed.summary,
                    detail_url: match.reportUrl,
                    author: parsed.author,
                    weather: parsed.weather,
                    wind_direction: parsed.windDirection,
                    wind_speed_text: parsed.windSpeedText,
                    temp_min: parsed.tempMin,
                    temp_max: parsed.tempMax,
                    humidity_min: parsed.humidityMin,
                    humidity_max: parsed.humidityMax,
                    pressure_min: parsed.pressureMin,
                    pressure_max: parsed.pressureMax,
                    visual_photo_url: parsed.visualPhotoUrl,
                    vona_color_code: vonaByKey[volcanoKey] ?? null,
                    visibility: parsed.visibility,
                    crater_smoke: parsed.craterSmoke,
                    avalanche_notes: parsed.avalancheNotes,
                    seismicity: parsed.seismicity,
                  },
                  { onConflict: "volcano_key,report_date,period_start" },
                );

              if (varErr) {
                console.warn(`VAR upsert warning for ${volcanoKey}:`, varErr.message);
              } else {
                varSyncResults.push({
                  volcanoKey,
                  reportDate: parsed.reportDate,
                  period: `${parsed.periodStart}-${parsed.periodEnd} ${parsed.timezone}`,
                  vona: vonaByKey[volcanoKey] ?? null,
                  hasPhoto: Boolean(parsed.visualPhotoUrl),
                });
              }
            }
          } catch (varFetchErr) {
            console.warn(`VAR fetch warning for ${volcanoKey}:`, varFetchErr);
          }
        }
      }
    }

    console.log(`Successfully synced ${updates.length} volcanoes and ${varSyncResults.length} VAR reports.`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Synced ${updates.length} volcanoes from MAGMA Indonesia`,
        timestamp: now,
        totalMagmaParsed: magmaList.length,
        updates,
        varSyncResults,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Sync error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
