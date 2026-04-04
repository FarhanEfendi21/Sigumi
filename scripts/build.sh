#!/bin/bash

# 1. Cek apakah folder flutter sudah ada (untuk caching)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Tambahkan flutter ke PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Jalankan build web dengan Environment Variables
echo "Building Flutter Web..."
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

echo "Build finished successfully!"
