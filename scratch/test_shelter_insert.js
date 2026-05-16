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
  console.log('--- Test Insert with Mapping ---');
  
  // Mapping defined in service
  const volcanoToRegion = {
    "a1b2c3d4-e5f6-7890-abcd-111111111111": "Yogyakarta", // Merapi
    "a1b2c3d4-e5f6-7890-abcd-222222222222": "Bali",       // Agung
    "a1b2c3d4-e5f6-7890-abcd-333333333333": "Lombok",     // Rinjani
  }

  const testPayload = {
    name: "Test Geometry Fix",
    type: "posko_evakuasi",
    address: "Test Address",
    volcano_id: "a1b2c3d4-e5f6-7890-abcd-111111111111", // Merapi
    location: "POINT(110.4463 -7.5407)",
    lokasi: "Yogyakarta", 
    is_active: true
  };
  
  const { data, error } = await supabase.from('shelters').insert([testPayload]).select();
  
  if (error) {
    console.error('INSERT_ERROR:', error);
  } else {
    console.log('INSERT_SUCCESS:', data);
    // Cleanup
    await supabase.from('shelters').delete().eq('id', data[0].id);
  }

  process.exit();
}

investigate();
