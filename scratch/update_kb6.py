import re

with open('lib/services/nlp_knowledge_base.dart', 'r', encoding='utf-8') as f:
    content = f.read()

sasak_responses = {
    'status': """      'sas': {
        'anak': 'Ndak takut, Merapi gitak tyang. Dende bareng-bareng ye 😊. Taok gitan statusne: Aman / Waspade.',
        'dewasa': 'Status Gunung Merapi wayah niki nggeh. Info pelungguh wenten ring Magma Indonesia.',
        'lansia': 'STATUS GUNUNG MERAPI MANGKIN.\\n\\nPelungguh tetep tenang, becik-becik kemawon. Ngantosang arahan saking petugas nggeh.',
      },""",
    'abu': """      'sas': {
        'anak': 'Mun ujan abu, ndak lalo main langan jelo nggeh! Pake masker kance kacamata 😎.',
        'dewasa': 'Antisipasi ujan abu: Pake masker, kacamata, kance tutup aiq dait ajengan.',
        'lansia': 'TIPS YEN UJAN ABU:\\n\\n• Ngoyong leq bale\\n• Pake masker\\n• Tutup aiq kance ajengan\\n• Jaga kesehatan pelungguh',
      },""",
    'p3k': """      'sas': {
        'anak': 'P3K tie koteq kotak obat! Isinan plester kance obat merah nggeh 🩹.',
        'dewasa': 'Siapang kotak P3K isi obat-obatan darurat dait perban.',
        'lansia': 'PERSIAPAN P3K:\\n\\n• Siapang obat-obatan pribadi pelungguh\\n• P3K kotak\\n• Senter\\n• Masker',
      },""",
    'evakuasi': """      'sas': {
        'anak': 'Lalo bareng batur kance keluarga jok taok saq aman nggeh! 🏃‍♂️',
        'dewasa': 'Silaq evakuasi jok tiitik kumpul saq terdekat dait paling aman.',
        'lansia': 'ARAHAN EVAKUASI:\\n\\n• Ngiring evakuasi alon-alon\\n• Tutut arahan petugas\\n• Lalo jok taok saq aman',
      },""",
    'zona': """      'sas': {
        'anak': 'Ndak lalo jok taok begang nggeh, lalo jok saq aman bae! 🛑',
        'dewasa': 'Kenali zona bahaya letusan dait patuhi bates aman.',
        'lansia': 'ZONA BAHAYA:\\n\\n• Pelungguh patut tetep leq zona aman\\n• Endak parek jok zona bahaya',
      },""",
    'bantuan': """      'sas': {
        'anak': 'Mun butuh tolong, engat tulung leq batur saq toaq nggeh! 🆘',
        'dewasa': 'Hubungi nomer darurat mun side butuh bantuan.',
        'lansia': 'NEMBUN TELEPON BANTUAN:\\n\\n• Silaq telpon nomer darurat mun wenten napi-napi\\n• Endak bingung',
      },""",
    'persiapan': """      'sas': {
        'anak': 'Bungkus jaje kance aiq jok tas nggeh! 🎒',
        'dewasa': 'Sedia tas siaga bencana saq misi dokumen dait persediaan.',
        'lansia': 'TAS SIAGA BENCANA:\\n\\n• Siapang dokumen penting pelungguh\\n• Obat-obatan\\n• Klambi',
      },""",
    'pasca': """      'sas': {
        'anak': 'Bantu batur beresin bale mun wah aman nggeh! 🧹',
        'dewasa': 'Mulai pemulihan leq lingkungan sekitar mun kondisi wah aman.',
        'lansia': 'PASCA LETUSAN:\\n\\n• Bersihin abu leq bale\\n• Tetep waspada sampe pengumuman resmi',
      },""",
    'salam': """      'sas': {
        'anak': 'Halo uwaq! Ye tyang Si Gumi, melet betakon napi? 👋😊',
        'dewasa': 'Tabe! Tyang Si Gumi. Napi saq bau tyang bantu?',
        'lansia': 'TABE PELUNGGUH.\\n\\nTyang Si Gumi, napi saq pacang tyang bantu mangkin?',
      },""",
    'default': """      'sas': {
        'anak': 'Hmm, tyang endeq ne ngerti 🤔. Coba betakon soal Merapi atau evakuasi!',
        'dewasa': 'Ampura tyang endeq pati ngerti. Silaq betakon soal status merapi atau lokasi evakuasi.',
        'lansia': 'AMPURA PELUNGGUH.\\n\\nTyang endeq ngerti, silaq uinang pitaken soal merapi utawi evakuasi.',
      },"""
}

# The target we are looking for is:
for intent, sas in sasak_responses.items():
    ba_str = "'ba': {"
    intent_start_idx = content.find(f"'{intent}': {{")
    if intent_start_idx != -1:
        ba_idx = content.find(ba_str, intent_start_idx)
        if ba_idx != -1:
            close_idx = re.search(r'\n    \},', content[ba_idx:])
            if close_idx:
                insert_pos = ba_idx + close_idx.start()
                # Use real \n, not literal `\n` text
                content = content[:insert_pos] + "\n" + sas + content[insert_pos:]


# Add regional dictionary
reg_pattern = re.compile(r'(// ── Bali ──[\s\S]+?)\s*};')
if "// ── Sasak ──" not in content:
    sasak_dict = """
    // ── Sasak ──
    'berembe': 'bagaimana', 'napi': 'apa', 'mbe': 'mana',
    'jelo': 'hari', 'bale': 'rumah', 'aiq': 'air', 'tende': 'lari',
    'side': 'kamu', 'pelungguh': 'anda', 'tyang': 'aku'
"""
    # Note: re.sub \1 is \g<1> 
    content = reg_pattern.sub(r'\g<1>\n' + sasak_dict + '  };', content)

# Add Language Markers
if "static const Map<String, List<String>> languageMarkers" not in content:
    lang_markers = """
  /// Language Marker Words
  static const Map<String, List<String>> languageMarkers = {
    'jv': ['kowe', 'aku', 'piye', 'kepiye', 'saiki', 'ana', 'endi', 'mlayu', 'dalan', 'banyu', 'awu', 'udhan', 'omah'],
    'su': ['abdi', 'maneh', 'kumaha', 'ayeuna', 'aya', 'kamana', 'lebu', 'cai', 'bitu', 'imah'],
    'ba': ['tiang', 'ragane', 'kenken', 'mangkin', 'wenten', 'dija', 'margi', 'yeh', 'umah', 'mewali'],
    'sas': ['tiang', 'side', 'berembe', 'napi', 'mbe', 'jelo', 'bale', 'tende', 'aiq', 'pelungguh', 'tyang'],
    'en': ['how', 'what', 'where', 'when', 'who', 'is', 'are', 'status', 'volcano', 'evacuation', 'safe', 'danger'],
  };

"""
    content = content.replace('static const Map<String, List<String>> trainingPhrases = {', lang_markers + '  static const Map<String, List<String>> trainingPhrases = {')


with open('lib/services/nlp_knowledge_base.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done clean update!")
