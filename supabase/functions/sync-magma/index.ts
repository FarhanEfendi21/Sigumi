import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers for Edge Functions
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface MagmaVolcano {
  name: string;
  region: string;
  level: number;
  levelName: string;
  reportUrl: string;
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
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
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
    const now = new Date().toISOString();

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
      }
    }

    console.log(`Successfully synced ${updates.length} volcanoes.`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Synced ${updates.length} volcanoes from MAGMA Indonesia`,
        timestamp: now,
        totalMagmaParsed: magmaList.length,
        updates,
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
