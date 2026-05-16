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

async function getRealVolcanoes() {
  const { data, error } = await supabase
    .from('volcanoes')
    .select('id, name');
  
  if (error) {
    console.error('Error fetching volcanoes:', error);
  } else {
    console.log('REAL_VOLCANOES_START');
    console.log(JSON.stringify(data, null, 2));
    console.log('REAL_VOLCANOES_END');
  }
  process.exit();
}

getRealVolcanoes();
