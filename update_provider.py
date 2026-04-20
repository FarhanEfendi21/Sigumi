import sys

with open('lib/providers/volcano_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _isLoadingVolcanoes variable
content = content.replace(
    '  bool _isLoadingEruptions = false;',
    '  bool _isLoadingEruptions = false;\n  bool _isLoadingVolcanoes = true;'
)

# Add isLoadingVolcanoes getter
content = content.replace(
    '  bool get isLoadingEruptions => _isLoadingEruptions;',
    '  bool get isLoadingEruptions => _isLoadingEruptions;\n  bool get isLoadingVolcanoes => _isLoadingVolcanoes;'
)

# Replace loadVolcanoes logic
part1 = '''  Future<void> loadVolcanoes() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('volcanoes')
          .select()
          .order('name');'''

part1_rep = '''  Future<void> loadVolcanoes() async {
    if (!SupabaseConfig.isConfigured) {
      _isLoadingVolcanoes = false;
      notifyListeners();
      return;
    }

    _isLoadingVolcanoes = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('volcanoes')
          .select()
          .order('name');'''
content = content.replace(part1, part1_rep)

part2 = '''      // Set volcano pertama atau sesuai region
      _updateSelectedVolcano();
      notifyListeners();
    } catch (e) {
      debugPrint('[VolcanoProvider] Load volcanoes error: $e');
      // Fallback ke mock data tetap tersedia
    }
  }'''

part2_rep = '''      // Set volcano pertama atau sesuai region
      _updateSelectedVolcano();

      // Sinkronisasikan status dari MAGMA sebelum me-render badge & memberhentikan loading
      if (_magmaClient != null) {
        await _syncMagmaStatusForCurrentVolcano();
      }

      _isLoadingVolcanoes = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[VolcanoProvider] Load volcanoes error: $e');
      // Fallback ke mock data tetap tersedia
      _isLoadingVolcanoes = false;
      notifyListeners();
    }
  }'''
content = content.replace(part2, part2_rep)

# processMagmaPayload replace microtasks
part3 = '''       if (_volcano.statusLevel != newStatusLevel) {
          debugPrint('[MAGMA] ✅ Perubahan Terdeteksi! $volcanoName: Level $newStatusLevel');
          
          // Gunakan microtask agar tidak bentrok dengan siklus render UI Web
          Future.microtask(() {
            updateVolcanoStatus(newStatusLevel, newDescription);
          });
       }
    } else if (!foundInList && _volcano.name.isEmpty) {
       // Jika list kosong (init state), langsung set via microtask
       Future.microtask(() {
         updateVolcanoStatus(newStatusLevel, newDescription);
       });
    }
    
    // Hanya notifyListeners jika ada data masuk, bungkus agar aman di Web
    if (foundInList) {
       Future.microtask(() => notifyListeners());
    }'''

part3_rep = '''       if (_volcano.statusLevel != newStatusLevel) {
          debugPrint('[MAGMA] ✅ Perubahan Terdeteksi! $volcanoName: Level $newStatusLevel');
          updateVolcanoStatus(newStatusLevel, newDescription);
       }
    } else if (!foundInList && _volcano.name.isEmpty) {
       updateVolcanoStatus(newStatusLevel, newDescription);
    }
    
    if (foundInList) {
       notifyListeners();
    }'''
content = content.replace(part3, part3_rep)

# _initMagmaRealtime replacement
part4 = '''  void _initMagmaRealtime() {
    // Jalankan dengan sedikit delay agar tidak bentrok dengan inisialisasi utama (penting untuk Web)
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        debugPrint('[MAGMA] 🚀 Inisialisasi Klien Kedua (MAGMA)...');
        _magmaClient = SupabaseClient(SupabaseConfig.magmaUrl, SupabaseConfig.magmaAnonKey);
        
        // 1. Test Fetch Manual (Pastikan RLS & Key OK)
        await _testMagmaConnection();

        // 2. Setup Realtime Channel dengan nama unik agar tidak bentrok di Web
        _magmaChannel = _magmaClient!.channel('sigumi_magma_sync');
        
        _magmaChannel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'volcanoes',
          callback: (payload) {
            debugPrint('[MAGMA] 🔥 DATA REALTIME MASUK! Event: ${payload.eventType}');
            _processMagmaPayload(payload.newRecord);
          }
        ).subscribe((status, [error]) {
          debugPrint('[MAGMA] 📡 Status Channel: $status');
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('[MAGMA] ✅ Realtime MAGMA Aktif!');
          }
          if (error != null) {
            debugPrint('[MAGMA] ❌ Error Realtime: $error');
            // Jika Realtime gagal di Web, kita gunakan sistem Polling sebagai cadangan
            if (!_isPollingActive) _startMagmaPolling();
          }
        });

      } catch (e) {
        debugPrint('[MAGMA] ❌ Fatal Error Inisialisasi: $e');
        _startMagmaPolling();
      }
    });
  }'''

part4_rep = '''  void _initMagmaRealtime() {
    try {
      debugPrint('[MAGMA] 🚀 Inisialisasi Klien Kedua (MAGMA)...');
      _magmaClient = SupabaseClient(SupabaseConfig.magmaUrl, SupabaseConfig.magmaAnonKey);
      
      // Jalankan realtime setup dengan sedikit delay agar tidak bentrok (penting untuk Web)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          // 1. Test Fetch Manual (Pastikan RLS & Key OK)
          await _testMagmaConnection();

          // 2. Setup Realtime Channel dengan nama unik agar tidak bentrok di Web
          _magmaChannel = _magmaClient!.channel('sigumi_magma_sync');
          
          _magmaChannel!.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'volcanoes',
            callback: (payload) {
              debugPrint('[MAGMA] 🔥 DATA REALTIME MASUK! Event: ${payload.eventType}');
              _processMagmaPayload(payload.newRecord);
            }
          ).subscribe((status, [error]) {
            debugPrint('[MAGMA] 📡 Status Channel: $status');
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('[MAGMA] ✅ Realtime MAGMA Aktif!');
            }
            if (error != null) {
              debugPrint('[MAGMA] ❌ Error Realtime: $error');
              if (!_isPollingActive) _startMagmaPolling();
            }
          });

        } catch (e) {
          debugPrint('[MAGMA] ❌ Error Realtime: $e');
          _startMagmaPolling();
        }
      });
    } catch (e) {
      debugPrint('[MAGMA] ❌ Fatal Error Inisialisasi: $e');
      _startMagmaPolling();
    }
  }'''
content = content.replace(part4, part4_rep)

open('lib/providers/volcano_provider.dart', 'w', encoding='utf-8').write(content)
print("Done")
