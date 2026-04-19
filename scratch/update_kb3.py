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

with open('lib/services/nlp_knowledge_base.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_intent = None
in_ba = False

import re

for line in lines:
    new_lines.append(line)
    
    # Track the intent we are in
    intent_match = re.match(r"^\s*'(\w+)':\s*\{", line)
    if intent_match:
        in_intent = intent_match.group(1)
        in_ba = False
        continue

    # If we are in an intent, look for 'ba'
    if in_intent and re.match(r"^\s*'ba':\s*\{", line):
        in_ba = True
        continue
        
    # If we are in 'ba' block and find its closing brace `      },`
    if in_ba and re.match(r"^\s*\},", line):
        if in_intent in sasak_responses:
            # We found the end of the 'ba' block. Next line we insert sasak.
            new_lines.append(sasak_responses[in_intent] + "\\n")
        in_ba = False
        in_intent = None # Finished processing this intent

with open('lib/services/nlp_knowledge_base.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Line by line replacement complete!")
