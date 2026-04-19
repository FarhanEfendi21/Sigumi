import re

content = open('lib/services/nlp_knowledge_base.dart', 'r', encoding='utf-8').read()

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

# Add regional dictionary
reg_pattern = re.compile(r'(// ── Bali ──[\s\S]+?)\s*};')
if "// ── Sasak ──" not in content:
    sasak_dict = """
    // ── Sasak ──
    'berembe': 'bagaimana', 'napi': 'apa', 'mbe': 'mana',
    'jelo': 'hari', 'bale': 'rumah', 'aiq': 'air', 'tende': 'lari',
    'side': 'kamu', 'pelungguh': 'anda'
"""
    content = reg_pattern.sub(r'\g<1>\n' + sasak_dict + '  };', content)

# Add Language Markers
if "static const Map<String, List<String>> languageMarkers" not in content:
    lang_markers = """
  /// Language Marker Words
  static const Map<String, List<String>> languageMarkers = {
    'jv': ['kowe', 'aku', 'piye', 'kepiye', 'saiki', 'ana', 'endi', 'mlayu', 'dalan', 'banyu', 'awu', 'udhan', 'omah'],
    'su': ['abdi', 'maneh', 'kumaha', 'ayeuna', 'aya', 'kamana', 'lebu', 'cai', 'bitu', 'imah'],
    'ba': ['tiang', 'ragane', 'kenken', 'mangkin', 'wenten', 'dija', 'margi', 'yeh', 'umah', 'mewali'],
    'sas': ['tiang', 'side', 'berembe', 'napi', 'mbe', 'jelo', 'bale', 'tende', 'aiq', 'pelungguh'],
    'en': ['how', 'what', 'where', 'when', 'who', 'is', 'are', 'status', 'volcano', 'evacuation', 'safe', 'danger'],
  };

"""
    content = content.replace('static const Map<String, List<String>> trainingPhrases = {', lang_markers + '  static const Map<String, List<String>> trainingPhrases = {')


# Splitting content by intent manually
import json

lines = content.split('\\n')
new_lines = []
current_intent = None

for line in lines:
    new_lines.append(line)
    
    # Check if we enter an intent block like: 'status': {
    intent_match = re.match(r"^\s*'(\w+)':\s*\{", line)
    if intent_match:
        current_intent = intent_match.group(1)
        
    # Check if we are closing a language inside an intent. Wait, 'ba': { ... },
    if current_intent and current_intent in sasak_responses and re.match(r"^\s*\},$", line):
        # We need to know which language just closed. 
        # Actually this is too brittle.
        pass

# Just use simple regex replacement for the 'ba' block inside the responses section.
# We will split the file by 'static const Map<String, Map<String, Map<String, String>>> responses = {'
parts = content.split('static const Map<String, Map<String, Map<String, String>>> responses = {')
if len(parts) == 2:
    responses_str = parts[1]
    for intent, sas_block in sasak_responses.items():
        if "'sas':" not in responses_str:
            # We want to insert sas_block after the 'ba' block of the specified intent.
            # Find the intent block
            pattern = re.compile(rf"('{intent}':\s*\{{)(.*?)(\s*\}}\s*,)(\s*'(?:\w+)'|\s*\}};)", re.DOTALL)
            def repl(m):
                # m.group(2) is the content of the intent. It ends with the last language block.
                # Just append sas_block at the end of m.group(2)
                return m.group(1) + m.group(2) + "\\n" + sas_block + m.group(3) + m.group(4)
            responses_str = pattern.sub(repl, responses_str, count=1)
    
    content = parts[0] + 'static const Map<String, Map<String, Map<String, String>>> responses = {' + responses_str


with open('lib/services/nlp_knowledge_base.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated KB")
