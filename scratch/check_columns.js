import { supabase } from "../lib/supabase/client.js";

async function checkSchema() {
    const { data, error } = await supabase.from('shelters').select('id, name, location').limit(1);
    console.log("Standard location:", data?.[0]?.location);

    const { data: data2, error: error2 } = await supabase.from('shelters').select('id, name, location').eq('id', data?.[0]?.id).single();
    console.log("Single select location:", data2?.location);
}

checkSchema();
