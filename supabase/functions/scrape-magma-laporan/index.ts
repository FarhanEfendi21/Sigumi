import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ──────────────────────────────────────────────
// Target gunung yang dipantau Sigumi
// ──────────────────────────────────────────────
const VOLCANO_TARGETS = [
  { key: "merapi",  nameVariants: ["merapi"],  displayName: "Merapi" },
  { key: "agung",   nameVariants: ["agung"],   displayName: "Agung" },
  { key: "rinjani", nameVariants: ["rinjani"], displayName: "Rinjani" },
];

const MAGMA_BASE_URL = "https://magma.esdm.go.id/v1/gunung-api/laporan-harian";

// Maks berapa hari ke belakang untuk fallback (Agung/Rinjani mungkin 3-7 hari lama)
const MAX_FALLBACK_DAYS = 7;

interface VolcanicReport {
  report_date: string;
  volcano_name: string;
  volcano_key: string;
  level_code: number;
  level_name: string;
  period_start: string | null;
  period_end: string | null;
  timezone: string;
  summary: string | null;
  detail_url: string | null;
  author: string | null;
  // ── Klimatologi terstruktur ──
  weather: string | null;
  wind_direction: string | null;
  wind_speed_text: string | null;
  temp_min: number | null;
  temp_max: number | null;
  humidity_min: number | null;
  humidity_max: number | null;
  pressure_min: number | null;
  pressure_max: number | null;
}

// ──────────────────────────────────────────────
// Date helpers
// ──────────────────────────────────────────────
function toIsoDate(d: Date): string {
  return d.toISOString().substring(0, 10);
}

function subtractDays(d: Date, n: number): Date {
  const result = new Date(d);
  result.setDate(result.getDate() - n);
  return result;
}

// ──────────────────────────────────────────────
// Parse level text → int
// ──────────────────────────────────────────────
function parseLevelCode(levelText: string): number {
  if (levelText.includes("IV") || levelText.toLowerCase().includes("awas")) return 4;
  if (levelText.includes("III") || levelText.toLowerCase().includes("siaga")) return 3;
  if (levelText.includes("II") || levelText.toLowerCase().includes("waspada")) return 2;
  return 1;
}

// ──────────────────────────────────────────────
// Parse tanggal Indonesia → ISO date string
// e.g. "Sabtu, 16 Mei 2026" → "2026-05-16"
// ──────────────────────────────────────────────
function parseIndonesianDate(dateStr: string): string {
  const months: Record<string, string> = {
    januari: "01", februari: "02", maret: "03", april: "04",
    mei: "05", juni: "06", juli: "07", agustus: "08",
    september: "09", oktober: "10", november: "11", desember: "12",
  };

  const lower = dateStr.toLowerCase();
  for (const [monthName, monthNum] of Object.entries(months)) {
    if (lower.includes(monthName)) {
      const parts = lower.replace(/[a-zà-ÿ,]/g, " ").trim().split(/\s+/).filter(Boolean);
      if (parts.length >= 2) {
        const day = parts[0].padStart(2, "0");
        const year = parts[parts.length - 1];
        return `${year}-${monthNum}-${day}`;
      }
    }
  }
  return new Date().toISOString().substring(0, 10);
}

// ──────────────────────────────────────────────
// Cek apakah nama cocok dengan target gunung
// ──────────────────────────────────────────────
function matchVolcano(name: string): typeof VOLCANO_TARGETS[0] | null {
  const lower = name.toLowerCase().replace(/gunung\s*/i, "").trim();
  for (const target of VOLCANO_TARGETS) {
    if (target.nameVariants.some((v) => lower.includes(v))) return target;
  }
  return null;
}

// ──────────────────────────────────────────────
// Parse range angka dari teks
// ──────────────────────────────────────────────
function parseRange(text: string): [number, number] | null {
  const rangeMatch = text.match(/([\d]+(?:[.,][\d]+)?)\s*[-–]\s*([\d]+(?:[.,][\d]+)?)/);
  if (rangeMatch) {
    const a = parseFloat(rangeMatch[1].replace(",", "."));
    const b = parseFloat(rangeMatch[2].replace(",", "."));
    if (!isNaN(a) && !isNaN(b)) return [a, b];
  }
  const singleMatch = text.match(/([\d]+(?:[.,][\d]+)?)/);
  if (singleMatch) {
    const v = parseFloat(singleMatch[1].replace(",", "."));
    if (!isNaN(v)) return [v, v];
  }
  return null;
}

// ──────────────────────────────────────────────
// Parse klimatologi dari teks summary
// ──────────────────────────────────────────────
interface Climatology {
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

function parseClimatology(summary: string): Climatology {
  const result: Climatology = {
    weather: null, windDirection: null, windSpeedText: null,
    tempMin: null, tempMax: null, humidityMin: null, humidityMax: null,
    pressureMin: null, pressureMax: null,
  };

  // Cuaca
  const cuacaMatch = summary.match(/[Cc]uaca\s+([^,.\n]+)/);
  if (cuacaMatch) {
    result.weather = cuacaMatch[1].trim();
    result.weather = result.weather.charAt(0).toUpperCase() + result.weather.slice(1);
  }

  // Angin
  const anginMatch = summary.match(/[Aa]ngin\s+([^.]+)/);
  if (anginMatch) {
    const anginText = anginMatch[1].toLowerCase();
    const speedWords = ["tenang", "lemah", "sedang", "kencang", "sangat kencang"];
    for (const sw of speedWords) {
      if (anginText.includes(sw)) {
        result.windSpeedText = sw.charAt(0).toUpperCase() + sw.slice(1);
        break;
      }
    }
    const arahMatch = anginText.match(/(?:ke arah|menuju|dari arah)\s+([a-z\s]+?)(?:\s*[,.\d]|$)/);
    if (arahMatch) {
      const arah = arahMatch[1].trim();
      result.windDirection = arah.charAt(0).toUpperCase() + arah.slice(1);
    } else {
      const compassWords = [
        "utara", "selatan", "timur", "barat",
        "timur laut", "tenggara", "barat daya", "barat laut",
      ];
      for (const compass of compassWords) {
        if (anginText.includes(compass)) {
          result.windDirection = compass.charAt(0).toUpperCase() + compass.slice(1);
          break;
        }
      }
    }
  }

  // Suhu
  const suhuMatch = summary.match(
    /[Ss]uhu(?:\s+udara)?\s+(?:sekitar\s+)?([\d.,\s\-–]+)\s*(?:°|&deg;|derajat)?\s*[Cc]/
  );
  if (suhuMatch) {
    const range = parseRange(suhuMatch[1]);
    if (range) { result.tempMin = range[0]; result.tempMax = range[1]; }
  }

  // Kelembaban
  const lembaMatch = summary.match(/[Kk]elembaban\s+(?:udara\s+)?([\d.,\s\-–]+)\s*%/);
  if (lembaMatch) {
    const range = parseRange(lembaMatch[1]);
    if (range) { result.humidityMin = range[0]; result.humidityMax = range[1]; }
  }

  // Tekanan
  const tekananMatch = summary.match(/[Tt]ekanan\s+udara\s+([\d.,\s\-–]+)\s*mm[Hh]g/);
  if (tekananMatch) {
    const range = parseRange(tekananMatch[1]);
    if (range) { result.pressureMin = range[0]; result.pressureMax = range[1]; }
  }

  return result;
}

// ──────────────────────────────────────────────
// Fetch HTML dari MAGMA untuk tanggal tertentu
// ──────────────────────────────────────────────
async function fetchMagmaHtml(date: string): Promise<string> {
  const url = `${MAGMA_BASE_URL}/${date}`;
  console.log(`[scrape-magma] Fetching: ${url}`);
  const res = await fetch(url, {
    headers: {
      "User-Agent": "Sigumi-App/1.0 (educational research, volcanic monitoring)",
      "Accept": "text/html,application/xhtml+xml",
    },
  });
  if (!res.ok) throw new Error(`MAGMA fetch failed for ${date}: ${res.status} ${res.statusText}`);
  return res.text();
}

// ──────────────────────────────────────────────
// Parse HTML laporan-harian MAGMA
// Returns: reports found in this HTML (any target volcano)
// ──────────────────────────────────────────────
function parseHtml(html: string, explicitDate?: string): VolcanicReport[] {
  const reports: VolcanicReport[] = [];

  // Extract tanggal dari header HTML
  const dateHeaderRegex = /Laporan Harian\s*-\s*([A-Z]+,\s+)?(\d{1,2}\s+\w+\s+\d{4})/i;
  const dateMatch = dateHeaderRegex.exec(html);
  const todayDate = explicitDate ?? (dateMatch ? parseIndonesianDate(dateMatch[2]) : new Date().toISOString().substring(0, 10));

  // Split per level card-header
  const levelBlocks = html.split('<div class="card-header">');

  for (let i = 1; i < levelBlocks.length; i++) {
    const block = levelBlocks[i];

    const levelMatch = block.match(/<h6[^>]*>(Level\s+[IVX]+\s*\([^)]+\))<\/h6>/i);
    if (!levelMatch) continue;

    const levelName = levelMatch[1];
    const levelCode = parseLevelCode(levelName);

    const rows = block.split(/<tr[^>]*>/i);
    for (let j = 1; j < rows.length; j++) {
      const row = rows[j];
      const tdMatches = [...row.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)];
      if (tdMatches.length < 5) continue;

      const rawName = tdMatches[1][1].replace(/<[^>]+>/g, "").trim();
      const target = matchVolcano(rawName);
      if (!target) continue;

      const rawSummary = tdMatches[2][1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
      const clim = parseClimatology(rawSummary);

      reports.push({
        report_date: todayDate,
        volcano_name: target.displayName,
        volcano_key: target.key,
        level_code: levelCode,
        level_name: levelName,
        period_start: "00:00",
        period_end: "24:00",
        timezone: "WIB",
        summary: rawSummary,
        detail_url: null,
        author: "PVMBG",
        weather: clim.weather,
        wind_direction: clim.windDirection,
        wind_speed_text: clim.windSpeedText,
        temp_min: clim.tempMin,
        temp_max: clim.tempMax,
        humidity_min: clim.humidityMin,
        humidity_max: clim.humidityMax,
        pressure_min: clim.pressureMin,
        pressure_max: clim.pressureMax,
      });
    }
  }

  return reports;
}

// ──────────────────────────────────────────────
// Main Handler
// ──────────────────────────────────────────────
Deno.serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const today = new Date();
    const allReports: VolcanicReport[] = [];

    // Track gunung mana yang sudah ditemukan
    const foundKeys = new Set<string>();

    // ─── Step 1: Fetch hari ini ───
    const todayStr = toIsoDate(today);
    try {
      const html = await fetchMagmaHtml(todayStr);
      console.log(`[scrape-magma] HTML ${todayStr} fetched, size: ${html.length} chars`);
      const reports = parseHtml(html, todayStr);
      for (const r of reports) {
        allReports.push(r);
        foundKeys.add(r.volcano_key);
      }
      console.log(`[scrape-magma] Found today (${todayStr}): ${reports.map(r => r.volcano_name).join(", ") || "none"}`);
    } catch (e) {
      console.warn(`[scrape-magma] Failed to fetch today ${todayStr}: ${e}`);
    }

    // ─── Step 2: Fallback hari sebelumnya untuk gunung yang belum ditemukan ───
    const missingTargets = VOLCANO_TARGETS.filter(t => !foundKeys.has(t.key));

    if (missingTargets.length > 0) {
      console.log(`[scrape-magma] Missing volcanoes: ${missingTargets.map(t => t.displayName).join(", ")}. Fetching fallback days...`);

      for (let dayOffset = 1; dayOffset <= MAX_FALLBACK_DAYS; dayOffset++) {
        // Cek apakah semua target sudah ditemukan
        const stillMissing = VOLCANO_TARGETS.filter(t => !foundKeys.has(t.key));
        if (stillMissing.length === 0) break;

        const fallbackDate = toIsoDate(subtractDays(today, dayOffset));
        console.log(`[scrape-magma] Fallback day -${dayOffset}: ${fallbackDate}, still need: ${stillMissing.map(t => t.displayName).join(", ")}`);

        try {
          const html = await fetchMagmaHtml(fallbackDate);
          const reports = parseHtml(html, fallbackDate);

          for (const r of reports) {
            // Hanya tambah jika gunung ini belum ditemukan dari hari yang lebih baru
            if (!foundKeys.has(r.volcano_key)) {
              allReports.push(r);
              foundKeys.add(r.volcano_key);
              console.log(`[scrape-magma] Found ${r.volcano_name} from fallback ${fallbackDate} (${r.level_name})`);
            }
          }
        } catch (e) {
          console.warn(`[scrape-magma] Failed to fetch fallback ${fallbackDate}: ${e}`);
        }
      }
    }

    console.log(`[scrape-magma] Total parsed: ${allReports.length} reports`);

    // Log summary
    for (const r of allReports) {
      console.log(`[scrape-magma] → ${r.volcano_name} (${r.level_name}) date=${r.report_date} weather=${r.weather} temp=${r.temp_min}–${r.temp_max}°C`);
    }

    if (allReports.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No matching reports found in MAGMA page (all days checked)",
          scraped_at: new Date().toISOString(),
          count: 0,
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const { error, count } = await supabase
      .from("volcanic_daily_reports")
      .upsert(allReports, {
        onConflict: "volcano_key,report_date,period_start",
        ignoreDuplicates: false,
      })
      .select("id", { count: "exact", head: true });

    if (error) throw error;

    console.log(`[scrape-magma] Upserted ${count} reports`);

    return new Response(
      JSON.stringify({
        success: true,
        scraped_at: new Date().toISOString(),
        count: allReports.length,
        volcanoes: allReports.map((r) => `${r.volcano_name} @ ${r.report_date} (${r.level_name})`),
        sample_climatology: allReports[0] ? {
          volcano: allReports[0].volcano_name,
          report_date: allReports[0].report_date,
          weather: allReports[0].weather,
          wind_direction: allReports[0].wind_direction,
          wind_speed: allReports[0].wind_speed_text,
          temp_range: `${allReports[0].temp_min}–${allReports[0].temp_max}°C`,
          humidity_range: `${allReports[0].humidity_min}–${allReports[0].humidity_max}%`,
          pressure_range: `${allReports[0].pressure_min}–${allReports[0].pressure_max} mmHg`,
        } : null,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[scrape-magma] Error:", msg);
    return new Response(
      JSON.stringify({ success: false, error: msg }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
