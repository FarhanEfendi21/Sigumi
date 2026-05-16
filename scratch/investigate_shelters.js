const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// Read .env.local
const envPath = path.join(__dirname, '../.env.local');
const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) {
        env[key.trim()] = value.trim().replace(/^\"|\"$/g, '');
    }
});

const supabase = createClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

async function investigate() {
  console.log('--- Checking Shelters Schema ---');
  const { data: shelterSample, error: shelterError } = await supabase.from('shelters').select('*').limit(1);
  if (shelterError) {
    console.error('Error fetching shelter sample:', shelterError);
  } else {
    console.log('Shelter sample column names:', Object.keys(shelterSample[0] || {}));
    if (shelterSample.length === 0) console.log('Shelters table is empty.');
  }

  console.log('\n--- Checking Volcanoes ---');
  const { data: volcanoes, error: volcanoError } = await supabase.from('volcanoes').select('id, name');
  if (volcanoError) {
    console.error('Error fetching volcanoes:', volcanoError);
  } else {
    console.log('Volcanoes list:', volcanoes);
  }

  console.log('\n--- Test Insert ---');
  const testPayload = {
    name: "Test Filter",
    type: "posko_evakuasi",
    address: "Test Address",
    lokasi: "Yogyakarta",
    volcanoes_id: "a1b2c3d4-e5f6-7890-abcd-111111111111", // Using Merapi ID from prev fetch
    is_active: true
  };
  
  const { data: insertResult, error: insertError } = await supabase.from('shelters').insert([testPayload]).select();
  if (insertError) {
    console.error('Insert failed:', insertError);
  } else {
    console.log('Insert success:', insertResult);
    // Cleanup
    await supabase.from('shelters').delete().eq('id', insertResult[0].id);
    console.log('Cleanup: deleted test record.');
  }

  process.exit();
}

investigate();
