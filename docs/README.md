# 📚 Dokumentasi Proyek SIGUMI

Folder ini memuat seluruh dokumen spesifikasi fitur, panduan integrasi, arsitektur, dan laporan pengujian aplikasi **SIGUMI (Sistem Informasi Gunung Berapi Mitigasi Inklusif)**.

---

## 🗂️ Daftar Isi Dokumentasi

### 1. Fitur Pendakian & Tanggap Darurat (Hiking & SOS)
- [**TRACKING_PENDAKIAN.md**](./TRACKING_PENDAKIAN.md): Panduan lengkap sistem tracking pendakian, *geofencing*, pencatatan koordinat GPS, sinkronisasi offline, dan penanganan darurat SOS.
- [**HIKING_WEATHER_SETUP.md**](./HIKING_WEATHER_SETUP.md): Panduan deployment layanan prakiraan cuaca BMKG dan peringatan darurat (*CAP push alerts*) via Supabase Edge Function & Scheduler.
- [**HIKING_SOS_BACKOFFICE_PROMPT.md**](./HIKING_SOS_BACKOFFICE_PROMPT.md): Spesifikasi kontrak data alert SOS mobile dan panduan integrasi real-time ke web backoffice/SAR.

### 2. Monitoring & Integrasi Vulkanik
- [**VOLCANO_SUMMARIZER_USAGE.md**](./VOLCANO_SUMMARIZER_USAGE.md): Panduan penggunaan model, repositori, provider, serta widget ringkasan status vulkanik Merapi.
- [**SYNC_MAGMA_GUIDE.md**](./SYNC_MAGMA_GUIDE.md): Panduan sinkronisasi otomatis status aktivitas gunung dari API MAGMA Indonesia (PVMBG) ke database Supabase via Edge Functions & Cron Job.

### 3. Spesifikasi Produk (PRD) & Keamanan
- [**PRD-reset-password.md**](./PRD-reset-password.md): Product Requirement Document (PRD) untuk alur registrasi email pemulihan, reset password, dan verifikasi OTP.

### 4. Rencana & Laporan Pengujian (QA & Stress Test)
- [**RENCANA_PENGUJIAN_SIGUMI.md**](./RENCANA_PENGUJIAN_SIGUMI.md): Dokumen master rencana pengujian sistemik, mencakup unit test, widget test, integrasi API, load/stress test, hingga rencana E2E.
- [**REKAP_STRESS_TEST_MOBILE_SIGUMI.md**](./REKAP_STRESS_TEST_MOBILE_SIGUMI.md): Laporan eksekusi automated stress test mobile (P0/P1/P2), *fault-injection*, dan analisis sebelum-sesudah perbaikan 6 bottleneck kritis.
- [**REKAP_PENGUJIAN_CHATBOT_POSTMAN.md**](./REKAP_PENGUJIAN_CHATBOT_POSTMAN.md): Laporan pengujian performa API server chatbot LLM (Ollama) untuk 5 bahasa daerah menggunakan Postman CLI.

