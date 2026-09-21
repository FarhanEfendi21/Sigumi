# SIGUMI

SIGUMI - Sistem Informasi Gunung Berapi Mitigasi Inklusif

## Build & Run

Untuk menjalankan aplikasi dengan fitur Chatbot (Ollama VPS) yang memerlukan autentikasi Basic Auth, gunakan perintah berikut:

```bash
flutter run --dart-define=OLLAMA_USER=username_anda --dart-define=OLLAMA_PASS=password_anda
```

> **Keamanan:** Jangan pernah menyimpan (`hardcode`) kredensial ini langsung di dalam source code atau men-commitnya ke Git repository.
