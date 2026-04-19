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

# Add Sasak responses
parts = content.split("static const Map<String, Map<String, Map<String, String>>> responses = {")
if len(parts) == 2:
    responses_str = parts[1]
    for intent, sas_block in sasak_responses.items():
        if "'sas': {" not in responses_str:
            # We want to find the exact dictionary closing of 'ba'
            # Look for:
            #       'ba': {
            #         ...
            #       },
            # followed by the intent's closing brace `    },`
            # For each intent we can capture its string length
            
            # Since dart file structure is very predictable:
            intent_start = responses_str.find(f"'{intent}': {{")
            if intent_start != -1:
                # Find the next `    },` that belongs to the intent, which comes after `      },` of 'ba'
                ba_start = responses_str.find("'ba': {", intent_start)
                if ba_start != -1:
                    ba_end = responses_str.find("},", ba_start)
                    # Insert right after `      },`
                    insert_pos = ba_end + 2
                    responses_str = responses_str[:insert_pos] + '\n' + sas_block + responses_str[insert_pos:]

    content = parts[0] + "static const Map<String, Map<String, Map<String, String>>> responses = {" + responses_str

with open('lib/services/nlp_knowledge_base.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated KB Sasak Block")
