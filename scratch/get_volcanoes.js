const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env.local' });

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

async function getVolcanoes() {
  const { data, error } = await supabase
    .from('volcanoes')
    .select('id, name')
    .in('name', ['Gunung Merapi', 'Gunung Agung', 'Gunung Rinjani']);
  
  if (error) {
    console.error('Error:', error);
    return;
  }
  
  console.log(JSON.stringify(data, null, 2));
}

getVolcanoes();
