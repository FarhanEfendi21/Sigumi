# Deploy cuaca dan peringatan pendakian

## Prakiraan

1. Terapkan `migrations/20261028_hiking_weather.sql` setelah migrasi tracking pendakian.
2. Deploy Edge Function `hiking-weather`.
3. Fungsi memilih kode wilayah desa terdekat yang didukung: Umbulharjo, Cangkringan (`34.04.17.2005`, WIB) untuk Merapi, Sembalun Lawang (`52.03.15.2002`, WITA) untuk Rinjani, dan Sebudi (`51.07.07.2004`, WITA) untuk Agung. Kartu menamai wilayah sumber; data ini adalah prakiraan desa, bukan observasi pada kawah atau ketinggian pendaki.

## Peringatan push

Atur secret di environment Supabase Edge Functions, jangan di source code:

- `HIKING_WEATHER_CRON_SECRET`: rahasia acak yang juga disimpan pada scheduler VPS.
- `FIREBASE_SERVICE_ACCOUNT_JSON`: isi service account Firebase dengan izin FCM HTTP v1.

Jalankan action `refresh_alerts` melalui scheduler VPS setiap 5 menit:

```sh
curl --fail-with-body --silent --show-error \
  -X POST "$SUPABASE_URL/functions/v1/hiking-weather" \
  -H "Authorization: Bearer $HIKING_WEATHER_CRON_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"action":"refresh_alerts"}'
```

Pekerja memeriksa alert CAP untuk Bali, NTB, dan DI Yogyakarta. Pekerja hanya mengirim alert yang masih berlaku, memiliki polygon, mencakup posisi terakhir sesi aktif yang berumur maksimal 15 menit, dan belum dikirim untuk revisi alert tersebut. Pantau log Edge Function dan status HTTP scheduler setelah mengaktifkan secret serta job.

## Batasan cakupan awal

BMKG prakiraan meminta kode `adm4`, bukan koordinat atau elevasi. Cakupan awal adalah Merapi, Agung, dan Rinjani; gunung lain menampilkan status prakiraan belum tersedia. Sistem menolak posisi lebih dari 15 km dari pusat gunung yang didukung, menampilkan zona waktu wilayah, nama desa sumber, serta catatan bahwa cuaca di ketinggian dapat berbeda. Setelah mengubah function, salin ulang direktori `hiking-weather` ke volume functions VPS dan buat ulang/restart service `functions` agar metadata WIB/WITA serta pemetaan Merapi aktif.
