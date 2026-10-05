# SIGUMI

SIGUMI - Sistem Informasi Gunung Berapi Mitigasi Inklusif

## Build & Run

Login SIGUMI memakai Supabase Auth. Untuk VPS saat ini, konfigurasi aplikasi mengizinkan gateway `http://187.53.141.200:8000` dan host HTTP tersebut dibatasi di konfigurasi Android. HTTP tidak mengenkripsi kata sandi maupun token sesi; pindahkan ke URL HTTPS sebelum penggunaan produksi. Gunakan **anon/public key** VPS, jangan gunakan `service_role` key di aplikasi.

```bash
flutter run --dart-define=SUPABASE_URL=http://187.53.141.200:8000 --dart-define=SUPABASE_ANON_KEY=ANON_PUBLIC_KEY_VPS
```

Untuk sekaligus menjalankan fitur Chatbot (Ollama VPS) yang memerlukan autentikasi Basic Auth:

```bash
flutter run --dart-define=SUPABASE_URL=http://187.53.141.200:8000 --dart-define=SUPABASE_ANON_KEY=ANON_PUBLIC_KEY_VPS --dart-define=OLLAMA_USER=username_anda --dart-define=OLLAMA_PASS=password_anda
```

Pada VPS self-hosted, anon key dapat dilihat di file konfigurasi Supabase (`ANON_KEY`). Ganti `ANON_PUBLIC_KEY_VPS` dengan nilainya saat menjalankan perintah.

> **Keamanan:** `ANON_KEY`/publishable key memang digunakan oleh aplikasi client. Jangan pernah menggunakan atau membagikan `service_role` key di aplikasi, build arguments yang disimpan publik, atau Git. Jaga password Ollama tetap privat.
