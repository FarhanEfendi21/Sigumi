-- ============================================================
-- Migration 012: Seed Data Nomor Telepon Darurat
-- Nasional + Yogyakarta (Merapi) + Bali (Agung) + Lombok (Rinjani)
-- ============================================================

INSERT INTO public.emergency_contacts
  (name, phone, description, category, region, sort_order)
VALUES
  -- ── NASIONAL ──
  ('BNPB',        '117',           'Badan Nasional Penanggulangan Bencana',       'nasional', 'Nasional',   1),
  ('SAR / Basarnas', '115',        'Badan SAR Nasional',                           'nasional', 'Nasional',   2),
  ('Ambulans',    '118',           'Layanan Ambulans Darurat Nasional',            'nasional', 'Nasional',   3),
  ('Polisi',      '110',           'Kepolisian Negara Republik Indonesia',         'nasional', 'Nasional',   4),
  ('Damkar',      '113',           'Pemadam Kebakaran',                            'nasional', 'Nasional',   5),
  ('PMI',         '021-7992325',   'Palang Merah Indonesia',                       'faskes',   'Nasional',   6),
  ('PLN',         '123',           'Pengaduan Gangguan Listrik',                   'nasional', 'Nasional',   7),

  -- ── YOGYAKARTA (Merapi) ──
  ('BPBD DIY',              '(0274) 555679',  'BPBD Daerah Istimewa Yogyakarta',              'posko',   'Yogyakarta', 10),
  ('BPBD Jawa Tengah',      '(024) 3512441',  'BPBD Jawa Tengah',                             'posko',   'Yogyakarta', 11),
  ('Posko Merapi',          '(0274) 896573',  'Posko Pengamatan Gunung Merapi — BPPTKG',      'posko',   'Yogyakarta', 12),
  ('RSUP Dr. Sardjito',     '(0274) 587333',  'Rumah Sakit Umum Pusat Dr. Sardjito',          'faskes',  'Yogyakarta', 13),
  ('RS Bethesda Yogyakarta','(0274) 586688',  'Rumah Sakit Bethesda Yogyakarta',              'faskes',  'Yogyakarta', 14),
  ('Polres Sleman',         '(0274) 868484',  'Kepolisian Resor Sleman',                      'nasional','Yogyakarta', 15),
  ('Dinkes DIY',            '(0274) 514868',  'Dinas Kesehatan DIY — Posko Bencana',          'faskes',  'Yogyakarta', 16),

  -- ── BALI (Agung) ──
  ('BPBD Provinsi Bali',    '(0361) 256043',  'BPBD Provinsi Bali',                           'posko',   'Bali',       10),
  ('BPBD Karangasem',       '(0363) 21396',   'BPBD Kabupaten Karangasem',                    'posko',   'Bali',       11),
  ('Posko Agung',           '(0363) 21008',   'Posko Pengamatan Gunung Agung',                'posko',   'Bali',       12),
  ('RSUP Sanglah',          '(0361) 227911',  'Rumah Sakit Umum Pusat Sanglah Denpasar',      'faskes',  'Bali',       13),
  ('RS Karangasem',         '(0363) 21005',   'RSUD Karangasem',                              'faskes',  'Bali',       14),
  ('Polda Bali',            '(0361) 224111',  'Kepolisian Daerah Bali',                       'nasional','Bali',       15),
  ('Dinkes Bali',           '(0361) 246343',  'Dinas Kesehatan Provinsi Bali',                'faskes',  'Bali',       16),

  -- ── LOMBOK (Rinjani) ──
  ('BPBD Provinsi NTB',     '(0370) 640974',  'BPBD Provinsi Nusa Tenggara Barat',           'posko',   'Lombok',     10),
  ('BPBD Lombok Utara',     '(0370) 6194100', 'BPBD Kabupaten Lombok Utara',                  'posko',   'Lombok',     11),
  ('Posko Rinjani',         '(0370) 6298999', 'Posko Pengamatan Gunung Rinjani',              'posko',   'Lombok',     12),
  ('RSUD Mataram',          '(0370) 622254',  'Rumah Sakit Umum Daerah Mataram',              'faskes',  'Lombok',     13),
  ('RS Harapan Keluarga',   '(0370) 671111',  'RS Harapan Keluarga Mataram',                  'faskes',  'Lombok',     14),
  ('Polda NTB',             '(0370) 622222',  'Kepolisian Daerah NTB',                        'nasional','Lombok',     15),
  ('Dinkes NTB',            '(0370) 623154',  'Dinas Kesehatan Provinsi NTB',                 'faskes',  'Lombok',     16)

ON CONFLICT DO NOTHING;
