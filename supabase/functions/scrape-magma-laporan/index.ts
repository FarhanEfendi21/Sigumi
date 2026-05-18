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

const MAGMA_URL = "https://magma.esdm.go.id/v1/gunung-api/laporan-harian";

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
  weather: string | null;          // "Cerah hingga mendung"
  wind_direction: string | null;   // "Timur"
  wind_speed_text: string | null;  // "Tenang" / "Lemah" / "Sedang"
  temp_min: number | null;         // 19.5
  temp_max: number | null;         // 22.4
  humidity_min: number | null;     // 73.0
  humidity_max: number | null;     // 79.1
  pressure_min: number | null;     // 871.8
  pressure_max: number | null;     // 914.44
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
// Parse range angka dari teks, e.g. "19.5-22.4" → [19.5, 22.4]
// Juga handle "sekitar 19.5" → [19.5, 19.5]
// ──────────────────────────────────────────────
function parseRange(text: string): [number, number] | null {
  // Coba range dulu: "19.5-22.4" atau "19.5 - 22.4"
  const rangeMatch = text.match(/([\d]+(?:[.,][\d]+)?)\s*[-–]\s*([\d]+(?:[.,][\d]+)?)/);
  if (rangeMatch) {
    const a = parseFloat(rangeMatch[1].replace(",", "."));
    const b = parseFloat(rangeMatch[2].replace(",", "."));
    if (!isNaN(a) && !isNaN(b)) return [a, b];
  }
  // Single value: "sekitar 19.5"
  const singleMatch = text.match(/([\d]+(?:[.,][\d]+)?)/);
  if (singleMatch) {
    const v = parseFloat(singleMatch[1].replace(",", "."));
    if (!isNaN(v)) return [v, v];
  }
  return null;
}

// ──────────────────────────────────────────────
// Parse klimatologi dari teks summary MAGMA
// Input contoh:
//   "Cuaca cerah hingga mendung, angin tenang ke arah timur.
//    Suhu udara sekitar 19.5-22.4°C. Kelembaban 73-79.1%.
//    Tekanan udara 871.8-914.44 mmHg."
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
  const lower = summary.toLowerCase();
  const result: Climatology = {
    weather: null,
    windDirection: null,
    windSpeedText: null,
    tempMin: null,
    tempMax: null,
    humidityMin: null,
    humidityMax: null,
    pressureMin: null,
    pressureMax: null,
  };

  // ── Cuaca (kondisi langit) ──
  // Cari kalimat yang mengandung "cuaca" atau kondisi langit
  const cuacaMatch = summary.match(/[Cc]uaca\s+([^,.\n]+)/);
  if (cuacaMatch) {
    // Ambil sampai koma/titik, trim
    result.weather = cuacaMatch[1].trim();
    // Kapitalisasi huruf pertama
    result.weather = result.weather.charAt(0).toUpperCase() + result.weather.slice(1);
  }

  // ── Angin ──
  // Cari pola: "angin [kecepatan] ke arah [arah]"
  // atau "angin [arah]" atau "angin [kecepatan]"
  const anginMatch = summary.match(/[Aa]ngin\s+([^.]+)/);
  if (anginMatch) {
    const anginText = anginMatch[1].toLowerCase();

    // Speed kata kunci
    const speedWords = ["tenang", "lemah", "sedang", "kencang", "sangat kencang"];
    for (const sw of speedWords) {
      if (anginText.includes(sw)) {
        result.windSpeedText = sw.charAt(0).toUpperCase() + sw.slice(1);
        break;
      }
    }

    // Arah: cari setelah "ke arah" atau "menuju"
    const arahMatch = anginText.match(/(?:ke arah|menuju|dari arah)\s+([a-z\s]+?)(?:\s*[,.\d]|$)/);
    if (arahMatch) {
      const arah = arahMatch[1].trim();
      result.windDirection = arah.charAt(0).toUpperCase() + arah.slice(1);
    } else {
      // Coba langsung setelah kata angin + speed
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

  // ── Suhu udara ──
  // Format MAGMA bervariasi:
  //   "Suhu udara sekitar 19.5-22.4°C"
  //   "Suhu udara 20-28°C"
  //   "Suhu 20-28 °C"
  //   "suhu udara sekitar 19.5 - 22.4 derajat"
  const suhuMatch = summary.match(
    /[Ss]uhu(?:\s+udara)?\s+(?:sekitar\s+)?([\d.,\s\-–]+)\s*(?:°|&deg;|derajat)?\s*[Cc]/
  );
  if (suhuMatch) {
    const range = parseRange(suhuMatch[1]);
    if (range) {
      result.tempMin = range[0];
      result.tempMax = range[1];
    }
  }

  // ── Kelembaban ──
  // Pola: "Kelembaban 73-79.1%" atau "kelembaban udara 80%"
  const lembaMatch = summary.match(/[Kk]elembaban\s+(?:udara\s+)?([\d.,\s\-–]+)\s*%/);
  if (lembaMatch) {
    const range = parseRange(lembaMatch[1]);
    if (range) {
      result.humidityMin = range[0];
      result.humidityMax = range[1];
    }
  }

  // ── Tekanan udara ──
  // Pola: "Tekanan udara 871.8-914.44 mmHg"
  const tekananMatch = summary.match(/[Tt]ekanan\s+udara\s+([\d.,\s\-–]+)\s*mm[Hh]g/);
  if (tekananMatch) {
    const range = parseRange(tekananMatch[1]);
    if (range) {
      result.pressureMin = range[0];
      result.pressureMax = range[1];
    }
  }

  return result;
}

// ──────────────────────────────────────────────
// Parse HTML halaman laporan-harian MAGMA
// ──────────────────────────────────────────────
function parseHtml(html: string): VolcanicReport[] {
  const reports: VolcanicReport[] = [];

  // Extract tanggal: "Laporan Harian - Sabtu, 16 Mei 2026"
  const dateHeaderRegex = /Laporan Harian\s*-\s*([A-Z]+,\s+)?(\d{1,2}\s+\w+\s+\d{4})/i;
  const dateMatch = dateHeaderRegex.exec(html);
  const todayDate = dateMatch ? parseIndonesianDate(dateMatch[2]) : new Date().toISOString().substring(0, 10);

  // Split per block level
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

      // Ambil full teks kolom Visual (kolom ke-3) — gabungkan semua teks
      const rawSummary = tdMatches[2][1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();

      // Parse klimatologi dari summary
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
        // Klimatologi terstruktur
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

    console.log("[scrape-magma] Fetching MAGMA laporan-harian...");
    const res = await fetch(MAGMA_URL, {
      headers: {
        "User-Agent": "Sigumi-App/1.0 (educational research, volcanic monitoring)",
        "Accept": "text/html,application/xhtml+xml",
      },
    });

    if (!res.ok) {
      throw new Error(`MAGMA fetch failed: ${res.status} ${res.statusText}`);
    }

    const html = await res.text();
    console.log(`[scrape-magma] HTML fetched, size: ${html.length} chars`);

    const reports = parseHtml(html);
    console.log(`[scrape-magma] Parsed ${reports.length} reports`);

    // Log sample klimatologi untuk debug
    if (reports.length > 0) {
      const r = reports[0];
      console.log(`[scrape-magma] Sample klimatologi ${r.volcano_name}:`, {
        weather: r.weather,
        wind_direction: r.wind_direction,
        wind_speed_text: r.wind_speed_text,
        temp: `${r.temp_min}–${r.temp_max}°C`,
        humidity: `${r.humidity_min}–${r.humidity_max}%`,
        pressure: `${r.pressure_min}–${r.pressure_max} mmHg`,
      });
    }

    if (reports.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No matching reports found in MAGMA page",
          scraped_at: new Date().toISOString(),
          count: 0,
        }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const { error, count } = await supabase
      .from("volcanic_daily_reports")
      .upsert(reports, {
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
        count: reports.length,
        volcanoes: reports.map((r) => `${r.volcano_name} (${r.level_name})`),
        sample_climatology: reports[0] ? {
          volcano: reports[0].volcano_name,
          weather: reports[0].weather,
          wind_direction: reports[0].wind_direction,
          wind_speed: reports[0].wind_speed_text,
          temp_range: `${reports[0].temp_min}–${reports[0].temp_max}°C`,
          humidity_range: `${reports[0].humidity_min}–${reports[0].humidity_max}%`,
          pressure_range: `${reports[0].pressure_min}–${reports[0].pressure_max} mmHg`,
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
