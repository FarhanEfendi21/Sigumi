# Dokumentasi Modul Chatbot NLP SIGUMI

## 1. Arsitektur Sistem
Modul chatbot SIGUMI beroperasi menggunakan teknologi pemrosesan bahasa alami (NLP) yang dijalankan secara **lokal pada perangkat (on-device)** tanpa bergantung pada API eksternal. Hal ini untuk memastikan aplikasi tetap bisa digunakan di wilayah pegunungan yang rawan minim sinyal.

Alur pemrosesan:
1. **Input**: Pengguna memberikan pesan lewat suara (Voice Command) atau teks.
2. **Normalisasi**: `NlpEngine` membersihkan tanda baca dan menerjemahkan kata-kata bahasa daerah ke bahasa Indonesia.
3. **Similarity Check**: Engine menghitung "Cosine / Dice Coefficient Similarity" dari kueri input terhadap semua *training phrases* yang ada di `NlpKnowledgeBase`.
4. **Intent Classification**: Menemukan *intent* dengan tingkat kecocokan (confidence score) tertinggi.
5. **Localization**: Menghasilkan respon berdasarkan intent dan bahasa yang dipilih pengguna saat ini (ID, EN, JV, SU, BA).
6. **Output**: Pesan ditampilkan pada layer presentasi dan dibacakan (diucapkan) melalui teknologi Text-to-Speech.

---

## 2. Struktur NLP Engine

`nlp_engine.dart` menyimpan semua logika analitis:
- Metode `detectIntent(String query)`: Melakukan loop pada *training phrases* untuk mencocokkan kemiripan struktur karakter (n-grams). Ambang batas confidence score minimal ditentukan sekitar 0.25, jika kurang dari itu, akan memicu respons *default fallback*.
- Metode `_normalizeText()`: Mengubah semuanya menjadi huruf kecil (*lowercase*) dan menghapus karakter *special formatting*.
- Metode `_translateRegionalWords()`: Dictionary mapper sederhana untuk menerjemahkan bahasa daerah (seperti "kepiye", "kumaha", "kenken" menjadi "bagaimana") sehingga mesin tetap dapat menangkap maknanya dalam model data utama.

---

## 3. Knowledge Base
Data dan *intent corpus* berada pada `nlp_knowledge_base.dart`. Disinilah bot diprogram untuk memahami:
- **status**: Menanyakan kondisi gunung merapi.
- **evakuasi**: Jalur dan rute evakuasi.
- **zona**: Zona bahaya/radius kawasan rawan bencana (KRB).
- **abu**: Antisipasi dan hujan abu vulkanik.
- **p3k**: Pertolongan pertama di lokasi bencana.
- **bantuan**: Kontak darurat, posko, ambulans, SAR.
- **persiapan**: Persiapan menghadapi bahaya gunung meletus.
- **pasca**: Mitigasi pasca letusan lahar/hujan.

Respon disusun secara dinamis mendukung variasi multi-bahasa dengan map bersarang:
```dart
'status': {
  'id': '...',
  'en': '...',
  'jv': '...',
  'su': '...',
  'ba': '...',
}
```

---

## 4. Voice Command & Text-To-Speech
Bagian ini dihandle oleh `voice_service.dart`.
- Menggunakan library `speech_to_text: ^7.0.0` untuk merekam suara dari mik dan mengubahnya menjadi *recognized words*. Modul memvalidasi *permissions* sebelum digunakan.
- Menggunakan library `flutter_tts: ^4.2.0` untuk membacakan (*speak*) jawaban chatbot ke pengguna. Bahasa yang digunakan disesuaikan menjadi parameter internal `flutter_tts` seperti `id-ID` atau `en-US`.

> [!NOTE]
> Pada bahasa daerah (Jawa, Sunda, Bali), TTS akan membaca konfigurasi dialek bahasa Indonesia (`id-ID`) karena batasan mesin pada sistem operasi ponsel standar.

---

## 5. Komponen UI (Chatbot Screen)
Layar `chatbot_screen.dart` merangkum semuanya ke antarmuka pengguna interaktif:
1. **Language Dropdown**: Diletakkan pada Action Bar untuk mengganti bahasa secara instan (switch on the fly).
2. **Text Field & Mic Button**: Memiliki 2 opsi input. Mic dikonfigurasi dengan animasi pulse ketika bot sedang dalam fasa "Mendengarkan".
3. **Animated Confidence Badge**: Fitur transparansi untuk memberi tahu pengguna tingkat keyakinan NLP. Label ditampilkan pada sudut bawah bubble text balasan robot.
4. **Voice Bubble Indicator**: Pesan input pengguna dari suara ditandai secara visual oleh ikon 🎤 "Pesan Suara".

---

## 6. Panduan Penggunaan
- **Input Suara**: Ketuk tombol **Mikrofon**, bicaralah sampai selesai, kemudian chatbot akan secara otomatis mengirim teks tersebut jika berhenti menangkap pembicaraan.
- **Input Teks**: Ketik pesan sebagaimana biasa dan gunakan fitur *Quick Action* untuk mempercepat kueri.
- **Ganti Bahasa**: Di pojok kanan atas, tekan menu ID/EN/JV/DLL untuk mengubah format tanggapan chatbot.
- Chatbot akan menimpa pembacaan (TTS) yang sedang berlangsung apabila Anda memencet kembali tombol merekam atau beralih sesi chat.
