#!/usr/bin/env bash
# uret-yardim.sh — widget'in sag tik yardim panelinde gosterilecek icerigi uretir.
#
#   bash ~/klavye/uret-yardim.sh
#
# NEDEN URETILIYOR, QML'e GOMULMUYOR:
# Yardim paneline elle liste yazsaydik, sen bir kisayolu degistirdiginde panel
# YALAN SOYLERDI. Bu script icerigi CANLI SISTEMDEN okur:
#   - kayitli klavye duzenleri      -> kxkbrc / DBus
#   - Konsole kisayollari           -> kesfedilen-aksiyonlar.json (04 uretti)
#   - global kisayollar             -> kglobalshortcutsrc [services]
#   - SIGINT hangi katmanda         -> keytab dosyasi var mi
# 04 ve 05 scriptleri bitiste bunu cagirir; elle de calistirabilirsin.

set -uo pipefail
HEDEF="$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle/contents/data"
mkdir -p "$HEDEF"

/usr/bin/python3 - "$HEDEF/kisayollar.json" <<'PYEOF'
import json, os, re, subprocess, sys, datetime, pathlib

cikti = sys.argv[1]
EV = os.path.expanduser('~')

def kabuk(*a):
    try:
        return subprocess.run(a, capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return ''

def satir(tus, ne, notu=''):
    return {'tus': tus, 'ne': ne, 'not': notu}

bolumler = []

# ------------------------------------------------------------- 1) bu dugme
bolumler.append({'baslik': 'Bu düğme', 'satirlar': [
    satir('Sol tık',  'Q ↔ F düzenini değiştir'),
    satir('Sağ tık',  'Bu pencereyi aç / kapat'),
    satir('Tekerlek', 'Düzenler arasında gez'),
]})

# --------------------------------------------------------- 2) klavye duzeni
duzen_satirlari = []
ham = kabuk('busctl', '--user', 'call', 'org.kde.keyboard', '/Layouts',
            'org.kde.KeyboardLayouts', 'getLayoutsList')
parcalar = re.findall(r'"((?:[^"\\]|\\.)*)"', ham)
def coz(s):
    try:
        return s.encode().decode('unicode_escape').encode('latin1').decode('utf-8')
    except Exception:
        return s
parcalar = [coz(p) for p in parcalar]
uclu = [parcalar[i:i+3] for i in range(0, len(parcalar), 3)]
for n, grup in enumerate(uclu):
    kisa, gorunen, uzun = (grup + ['', '', ''])[:3]
    duzen_satirlari.append(satir(f'[{n}] {gorunen or kisa}', uzun))

if len(uclu) < 2:
    duzen_satirlari.append(satir('!', 'Tek düzen kayıtlı — geçiş yapacak ikinci düzen yok',
                                 'bash ~/klavye/05-panel-widget.sh'))

duzen_satirlari += [
    satir('Kural', 'Harfler F klavyeden, semboller Q klavyeden'),
    satir('AltGr', 'Katman Q ile bire bir aynı — hiçbir karakter kaybolmadı'),
    satir('AltGr + Q tuşu', '@  (F düzeninde o tuşta "f" var, ama @ yerinde)'),
    satir('AltGr + E / T / Ü', '€  /  ₺  /  ~'),
    satir('x harfi', 'Q\'nun "ç" tuşunda', 'çünkü virgül tuşu Q\'daki gibi korundu'),
]
bolumler.append({'baslik': 'Klavye düzeni', 'satirlar': duzen_satirlari})

# --------------------------------------------------------------- 3) Konsole
kons = []
kesif = pathlib.Path(EV, '.local/share/kxmlgui5/konsole/kesfedilen-aksiyonlar.json')
if kesif.exists():
    try:
        for ad, _aksiyon, tus in json.loads(kesif.read_text(encoding='utf-8')):
            kons.append(satir(tus.split(';')[0].strip(), ad))
    except Exception:
        pass

# Kisayol "fiziksel tus" degil "o harfi ureten tus" demek. F duzenine gecince
# c ve v yer degistiriyor. Widget'in isi zaten duzen degistirmek oldugu icin
# bu uyarinin yeri tam burasi.
kons.append(satir('— düzen uyarısı —', 'F moduna geçince kısayol harfleri kayar'))
kons.append(satir('F: Ctrl+C', "Q klavyedeki  V  tuşuna bas"))
kons.append(satir('F: Ctrl+V', "Q klavyedeki  C  tuşuna bas"))
kons.append(satir('Ctrl+Insert', 'Kopyala — düzenden BAĞIMSIZ', 'Insert tuşu hiç taşınmaz'))
kons.append(satir('Shift+Insert', 'Yapıştır — düzenden BAĞIMSIZ'))

keytab_var = pathlib.Path(EV, '.local/share/konsole/VSCode.keytab').exists()
if kons:
    kons.append(satir('Ctrl+Shift+C', 'İşlemi durdur (SIGINT)',
                      'keytab katmanı' if keytab_var else 'seçim yokken Ctrl+C de durdurur'))
else:
    kons.append(satir('—', 'Konsole şeması henüz kurulmadı',
                      'bash ~/klavye/04-konsole-kisayol.sh'))
bolumler.append({'baslik': 'Konsole', 'satirlar': kons})

# ---------------------------------------------------------------- 4) global
glob = []
kgs = pathlib.Path(EV, '.config/kglobalshortcutsrc')
if kgs.exists():
    metin = kgs.read_text(encoding='utf-8', errors='replace')
    for m in re.finditer(r'^\[services\]\[([^\]]+)\]\n((?:(?!\[).*\n)*)', metin, re.M):
        govde = m.group(2)
        tus = re.search(r'^_launch=([^,]*)', govde, re.M)
        ad  = re.search(r'^_k_friendly_name=(.*)', govde, re.M)
        if tus and tus.group(1) not in ('', 'none'):
            glob.append(satir(tus.group(1), ad.group(1) if ad else m.group(1)))
if not glob:
    glob.append(satir('—', 'Kayıtlı uygulama kısayolu yok',
                      'bash ~/klavye/06-global-kisayol.sh'))
bolumler.append({'baslik': 'Global (KDE)', 'satirlar': glob})

# ---------------------------------------------------- 4.5) satir duzenleme
sat = []
if pathlib.Path(EV, '.local/share/qf-klavye/bashrc-qf.sh').exists():
    sat = [
        satir('Ctrl+A', 'Yazdigin satirin TAMAMINI sil')
            if pathlib.Path(EV, '.local/state/qf-ctrl-a-sil').exists()
            else satir('Ctrl+Shift+A', 'Konsole: tumunu sec'),
        satir('Delete', 'Imlec satir sonundaysa satiri komple siler'),
        satir('Alt+Delete', 'Yanlislikla sileni geri getir'),
        satir('Ctrl+U', 'Yazdigin satirin TAMAMINI sil'),
        satir('Ctrl+Shift+Del', 'Panodakini satirdan cikar', 'once Ctrl+C ile kopyala'),
        satir('Ctrl+Backspace', 'Onceki kelimeyi sil'),
        satir('Yukari / Asagi', 'Yazdiginin basina uyan komutlari ara'),
    ]
else:
    sat = [satir('—', 'Satir duzenleme kurulmadi', 'bash ~/klavye/07-satir-sil.sh')]
bolumler.append({'baslik': 'Satır düzenleme', 'satirlar': sat})

# ------------------------------------------------------ 5) dokunulmayanlar
bolumler.append({'baslik': 'Kasten dokunulmadı', 'satirlar': [
    satir('Ctrl+Z', 'İşlemi uyutur (SIGTSTP) — "geri al" DEĞİL', 'geri getir: fg'),
    satir('Ctrl+X', 'Terminale geçer — nano\'dan çıkış çalışıyor'),
    satir('Ctrl+W', 'Sekme kapatır; kelime silmek için Alt+Backspace'),
    satir('Giriş ekranı', 'Her zaman Q — parolan güvende'),
    satir('Kilit ekranı', 'Oturumun o anki düzenini kullanır', 'F\'deyken kilitlersen F olur'),
]})

json.dump({
    'uretim': datetime.datetime.now().strftime('%Y-%m-%d %H:%M'),
    'bolumler': bolumler,
}, open(cikti, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)

print(f'uretildi: {cikti}  ({sum(len(b["satirlar"]) for b in bolumler)} satir, '
      f'{len(bolumler)} bolum)')
PYEOF