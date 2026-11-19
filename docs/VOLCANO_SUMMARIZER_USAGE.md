## 📋 Integrasi Volcano Summarizer - Panduan Penggunaan

### ✅ Apa yang Sudah Dibuat

#### 1. **Model (`lib/models/volcano_summarizer.dart`)**
   - Class `VolcanoSummarizer` untuk merepresentasikan data dari tabel `volcano_summarizer`
   - Method `fromJson()` untuk parsing data dari Supabase
   - Helper methods:
     - `levelLabel` - label status (Normal, Waspada, Siaga, Awas)
     - `levelColor` - warna berdasarkan level (1-4)
     - `temperatureRange` - rentang suhu formatted
     - `humidityRange` - rentang kelembaban formatted
     - `pressureRange` - rentang tekanan formatted

#### 2. **Repository (`lib/repositories/volcano_repository.dart`)**
   Ditambahkan 2 method:
   ```dart
   // Fetch list ringkasan (default 30 hari terakhir)
   Future<List<VolcanoSummarizer>> getVolcanoSummaries(
     String volcanoKey,
     {int limit = 30}
   )
   
   // Fetch ringkasan terbaru saja
   Future<VolcanoSummarizer?> getLatestVolcanoSummary(String volcanoKey)
   ```

#### 3. **Provider (`lib/providers/volcano_provider.dart`)**
   Ditambahkan:
   - State variables: `_volcanoSummaries`, `_latestVolcanoSummary`, `_isLoadingSummaries`
   - Getters: `volcanoSummaries`, `latestVolcanoSummary`, `isLoadingSummaries`, `hasVolcanoSummaries`
   - Methods:
     ```dart
     Future<void> fetchVolcanoSummaries(volcanoKey, {limit = 30})
     Future<void> fetchLatestVolcanoSummary(volcanoKey)
     ```

#### 4. **UI Widgets (`lib/widgets/volcano_summarizer_widget.dart`)**
   Tersedia 3 widget:
   
   a) **`VolcanoSummarizerCard`** - Menampilkan satu kartu ringkasan
   ```dart
   VolcanoSummarizerCard(summary: summary)
   ```
   
   b) **`VolcanoSummarizerListSection`** - Menampilkan list lengkap
   ```dart
   VolcanoSummarizerListSection(
     volcanoKey: 'merapi',
     limit: 30,
     title: 'Ringkasan Aktivitas Harian'
   )
   ```
   
   c) **`VolcanoLatestSummaryCard`** - Menampilkan hanya yang terbaru
   ```dart
   VolcanoLatestSummaryCard(volcanoKey: 'merapi')
   ```

#### 5. **Integrasi ke Halaman CCTV**
   - Sudah ditambahkan di `lib/screens/visual/visual_merapi_screen.dart`
   - Section "Ringkasan Aktivitas Harian" ditampilkan di halaman pantauan CCTV
   - Hanya muncul untuk gunung Merapi (`if (hasCctv)`)

---

### 🚀 Cara Menggunakan

#### **Option 1: Menampilkan List Lengkap (Historical)**
```dart
VolcanoSummarizerListSection(
  volcanoKey: 'merapi',  // Sesuaikan dengan volcano_key di tabel
  limit: 30,              // Jumlah hari (default 30)
  title: 'Ringkasan Aktivitas Harian'
)
```

#### **Option 2: Menampilkan Ringkasan Terbaru Saja**
```dart
VolcanoLatestSummaryCard(
  volcanoKey: 'merapi',
  autoRefresh: true
)
```

#### **Option 3: Manual dengan Provider**
```dart
Consumer<VolcanoProvider>(
  builder: (context, provider, _) {
    // Fetch data manual
    provider.fetchVolcanoSummaries('merapi');
    
    // Gunakan data
    return ListView(
      children: provider.volcanoSummaries
          .map((s) => VolcanoSummarizerCard(summary: s))
          .toList()
    );
  }
)
```

---

### 📊 Data yang Ditampilkan

Setiap kartu ringkasan menampilkan:
- ✅ Nama gunung & status level (Normal/Waspada/Siaga/Awas)
- ✅ Tanggal laporan & periode waktu
- ✅ Ringkasan aktivitas (text)
- ✅ Cuaca, arah angin, kecepatan angin
- ✅ Suhu min-max
- ✅ Kelembaban min-max
- ✅ Tekanan min-max
- ✅ Sumber/Author
- ✅ Link detail (jika ada)

---

### 🔧 Customization

#### Mengubah volcano_key
```dart
// Ganti 'merapi' dengan kunci gunung lainnya
volcanoKey: 'kelud'  // atau volcano_key yang lain
```

#### Mengubah jumlah hari
```dart
VolcanoSummarizerListSection(
  volcanoKey: 'merapi',
  limit: 60,  // Tampilkan 60 hari
)
```

#### Mengubah title
```dart
VolcanoSummarizerListSection(
  volcanoKey: 'merapi',
  title: 'Laporan Status Gunung Merapi'  // Custom title
)
```

---

### ⚠️ Requirements

1. Pastikan tabel `volcano_summarizer` sudah dibuat di Supabase dengan schema:
   ```sql
   CREATE TABLE public.volcano_summarizer (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     fetched_at TIMESTAMP DEFAULT now(),
     report_date DATE NOT NULL,
     volcano_name TEXT NOT NULL,
     volcano_key TEXT NOT NULL,
     level_code INTEGER DEFAULT 1,
     level_name TEXT NOT NULL,
     period_start TEXT,
     period_end TEXT,
     timezone TEXT DEFAULT 'WIB',
     summary TEXT,
     detail_url TEXT,
     author TEXT,
     weather TEXT,
     wind_direction TEXT,
     wind_speed_text TEXT,
     temp_min NUMERIC(5,2),
     temp_max NUMERIC(5,2),
     humidity_min NUMERIC(5,2),
     humidity_max NUMERIC(5,2),
     pressure_min NUMERIC(8,2),
     pressure_max NUMERIC(8,2),
     UNIQUE(volcano_key, report_date, period_start)
   );
   ```

2. Data harus diisi terlebih dahulu (bisa via admin panel atau API integration)

3. Supabase config harus sudah ter-setup di `lib/config/supabase_config.dart`

---

### 📝 Contoh Data dalam Tabel

```
id: uuid
report_date: 2026-08-13
volcano_name: Gunung Merapi
volcano_key: merapi
level_code: 2
level_name: Waspada
period_start: 00:00
period_end: 24:00
timezone: WIB
summary: "Gempa vulkanik tercatat 5 kali. Status tetap normal."
weather: "Mendung"
wind_direction: "Timur"
wind_speed_text: "15 km/h"
temp_min: 18.5
temp_max: 28.3
humidity_min: 45.0
humidity_max: 85.0
pressure_min: 1008.5
pressure_max: 1013.2
author: "PVMBG"
detail_url: "https://merapi.bnpb.go.id/..."
```

---

### 🎯 Status Implementasi

- ✅ Model dibuat
- ✅ Repository methods dibuat
- ✅ Provider state & methods dibuat
- ✅ UI widgets dibuat (3 varian)
- ✅ Integrasi ke halaman CCTV
- ✅ Dokumentasi dibuat

**Siap digunakan!** 🚀
