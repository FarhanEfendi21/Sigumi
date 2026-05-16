import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// ──────────────────────────────────────────────
// Target gunung yang dipantau Sigumi
// Key harus cocok dengan MAGMA laporan-harian URL/content
// ──────────────────────────────────────────────
const VOLCANO_TARGETS = [
  { key: "merapi",  nameVariants: ["merapi"],          displayName: "Merapi" },
  { key: "agung",   nameVariants: ["agung"],            displayName: "Agung" },
  { key: "rinjani", nameVariants: ["rinjani"],          displayName: "Rinjani" },
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
  // fallback to today
  return new Date().toISOString().substring(0, 10);
}

// ──────────────────────────────────────────────
// Parse period "00:00-06:00 WIB" → { start, end, tz }
// ──────────────────────────────────────────────
function parsePeriod(periodStr: string): { start: string | null; end: string | null; tz: string } {
  const tzMatch = periodStr.match(/\b(WIB|WITA|WIT)\b/i);
  const tz = tzMatch ? tzMatch[1].toUpperCase() : "WIB";

  const timeMatch = periodStr.match(/(\d{1,2}[:\.]\d{2})\s*[-–]\s*(\d{1,2}[:\.]\d{2})/);
  if (timeMatch) {
    return {
      start: timeMatch[1].replace(".", ":"),
      end: timeMatch[2].replace(".", ":"),
      tz,
    };
  }
  return { start: null, end: null, tz };
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
// Parse HTML halaman laporan-harian MAGMA
// Struktur: tanggal header → list laporan per gunung per periode
// ──────────────────────────────────────────────
function parseHtml(html: string): VolcanicReport[] {
  const reports: VolcanicReport[] = [];

  // Extract tanggal: "Laporan Harian - Sabtu, 16 Mei 2026"
  const dateHeaderRegex = /Laporan Harian\s*-\s*([A-Z]+,\s+)?(\d{1,2}\s+\w+\s+\d{4})/i;
  const dateMatch = dateHeaderRegex.exec(html);
  const todayDate = dateMatch ? parseIndonesianDate(dateMatch[2]) : new Date().toISOString().substring(0, 10);

  // Split HTML per block level (berdasarkan card-header yang berisi <h6 class="slim-card-title">Level...</h6>)
  const levelBlocks = html.split('<div class="card-header">');

  for (let i = 1; i < levelBlocks.length; i++) {
    const block = levelBlocks[i];
    
    // Extract level badge text
    const levelMatch = block.match(/<h6[^>]*>(Level\s+[IVX]+\s*\([^)]+\))<\/h6>/i);
    if (!levelMatch) continue;

    const levelName = levelMatch[1];
    const levelCode = parseLevelCode(levelName);

    // Split rows dalam tabel
    const rows = block.split(/<tr[^>]*>/i);
    for (let j = 1; j < rows.length; j++) {
      const row = rows[j];
      
      // Ambil isi setiap <td>
      const tdMatches = [...row.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)];
      
      // Data row valid biasanya punya minimal 5 kolom (No, Nama, Visual, Kegempaan, Rekomendasi)
      if (tdMatches.length < 5) continue;

      const rawName = tdMatches[1][1].replace(/<[^>]+>/g, "").trim();
      const target = matchVolcano(rawName);
      
      if (!target) continue; // Skip jika bukan gunung target (Merapi, Agung, Rinjani)

      // Ambil ringkasan dari kolom Visual
      const summary = tdMatches[2][1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();

      reports.push({
        report_date: todayDate,
        volcano_name: target.displayName,
        volcano_key: target.key,
        level_code: levelCode,
        level_name: levelName,
        period_start: "00:00",
        period_end: "24:00",
        timezone: "WIB",
        summary: summary,
        detail_url: null,
        author: "PVMBG",
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

    // Fetch halaman laporan-harian MAGMA
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

    // Parse HTML
    const reports = parseHtml(html);
    console.log(`[scrape-magma] Parsed ${reports.length} reports for target volcanoes`);

    if (reports.length === 0) {
      // Kembalikan info tapi tidak error — mungkin MAGMA belum update
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

    // Upsert ke Supabase (ON CONFLICT: volcano_key + report_date + period_start)
    const { error, count } = await supabase
      .from("volcanic_daily_reports")
      .upsert(reports, {
        onConflict: "volcano_key,report_date,period_start",
        ignoreDuplicates: false, // update jika sudah ada (summary bisa berubah)
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
