#!/usr/bin/env bash
# 03-xkb-kur.sh — tr(f_custom) varyantini XKB agacina enjekte eder.
#
# Kullanim:
#   sudo bash 03-xkb-kur.sh                  # gercek sisteme kur
#   bash 03-xkb-kur.sh --kok /tmp/xkbtest    # sanal koke kur (sudo gerekmez, test icin)
#   sudo bash 03-xkb-kur.sh --sessiz         # pacman hook'undan
#   sudo bash 03-xkb-kur.sh --kaldir         # sadece sok
#
# IDEMPOTENT: blok zaten varsa once silinir, sonra yazilir. Pacman hook'u
# guncelleme sonrasi tekrar cagirdiginda bu sayede temiz calisir.
#
# GUVENLIK: hicbir sey gercek dosyaya YAZILMADAN once tum degisiklikler bir
# sanal kokte denenir; xmllint + xkbcli derlemesi gecmeden kurulum yapilmaz.
#
# /etc/X11/xorg.conf.d/00-keyboard.conf'a KASTEN DOKUNULMAZ: giris ekrani (SDDM)
# hep Q kalsin diye. Bkz. 01-yedekle.sh.

set -euo pipefail
KOK_DIZIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XKB_KOK="/usr/share/X11/xkb"
SESSIZ=0
KALDIR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kok)    XKB_KOK="$2"; shift 2 ;;
    --sessiz) SESSIZ=1; shift ;;
    --kaldir) KALDIR=1; shift ;;
    *) echo "bilinmeyen secenek: $1" >&2; exit 2 ;;
  esac
done

log() { [[ $SESSIZ -eq 1 ]] || echo "$@"; }

PAYLOAD="$KOK_DIZIN/payload/tr-f_custom.xkb"
TIP_PAYLOAD="$KOK_DIZIN/payload/qf-ctrl-type.xkb"
if [[ $KALDIR -eq 0 && ! -f "$PAYLOAD" ]]; then
  log "payload yok, uretiliyor..."
  bash "$KOK_DIZIN/uret-f_custom.sh" >/dev/null
fi

command -v xmllint >/dev/null || { echo "HATA: xmllint yok (paket: libxml2)"; exit 1; }
command -v xkbcli  >/dev/null || { echo "HATA: xkbcli yok (paket: libxkbcommon)"; exit 1; }

# --------------------------------------------------------------- sanal kok
# Gercek agacin sembolik bag ciftligi; sadece degistirdigimiz 3 dosya gercek kopya.
SAHNE="$(mktemp -d)"
trap 'rm -rf "$SAHNE"' EXIT
for e in "$XKB_KOK"/*; do ln -s "$e" "$SAHNE/$(basename "$e")"; done
for alt in symbols rules types; do
  rm "$SAHNE/$alt"
  mkdir "$SAHNE/$alt"
  for e in "$XKB_KOK/$alt"/*; do ln -s "$e" "$SAHNE/$alt/$(basename "$e")"; done
done
for f in symbols/tr rules/evdev.xml rules/evdev.lst types/complete; do
  rm "$SAHNE/$f"; cp "$XKB_KOK/$f" "$SAHNE/$f"; chmod u+w "$SAHNE/$f"
done

# ------------------------------------------------------------- duzenleme
/usr/bin/python3 - "$SAHNE" "$PAYLOAD" "$KALDIR" "$TIP_PAYLOAD" <<'PYEOF'
import re, sys, pathlib

sahne, payload_yol, kaldir = sys.argv[1], sys.argv[2], sys.argv[3] == '1'
tip_payload_yol = sys.argv[4]
sahne = pathlib.Path(sahne)

BAS = '// >>> f_custom BASLANGIC (klavye/uret-f_custom.sh uretti) >>>'
BIT = '// <<< f_custom BITIS <<<'
BAS_TIP = '    // >>> QF_CTRL_ALPHABETIC BASLANGIC (klavye/03-xkb-kur.sh) >>>'
BIT_TIP = '    // <<< QF_CTRL_ALPHABETIC BITIS <<<'

# ------------------------------------------------------------- types/complete
# QF_CTRL_ALPHABETIC tipi. symbols/tr bu tipe ad ile basvurdugu icin ONCE
# burasi yazilmali, yoksa keymap derlenmez.
p = sahne / 'types' / 'complete'
metin = p.read_text(encoding='utf-8')
metin = re.sub(re.escape(BAS_TIP) + r'.*?' + re.escape(BIT_TIP) + r'\n?', '', metin, flags=re.S)
if not kaldir:
    tip = pathlib.Path(tip_payload_yol).read_text(encoding='utf-8')
    # xkb_types blogunun son kapanisindan hemen once ekle
    son = metin.rstrip().rfind('};')
    metin = (metin[:son] + BAS_TIP + '\n' + tip.rstrip('\n') + '\n' + BIT_TIP + '\n' + metin[son:])
p.write_text(metin, encoding='utf-8')

# ---------------------------------------------------------------- symbols/tr
p = sahne / 'symbols' / 'tr'
metin = p.read_text(encoding='utf-8')
# once eskiyi sok (idempotent)
metin = re.sub(re.escape(BAS) + r'.*?' + re.escape(BIT) + r'\n?', '', metin, flags=re.S)
if not kaldir:
    blok = pathlib.Path(payload_yol).read_text(encoding='utf-8')
    metin = metin.rstrip('\n') + '\n\n' + BAS + '\n' + blok.rstrip('\n') + '\n' + BIT + '\n'
else:
    # Enjeksiyon "\n\n" ekliyordu; sokerken de temizle ki dosya orijinaliyle
    # BIREBIR ayni kalsin (kaldirma testi bunu diff ile denetliyor).
    metin = metin.rstrip('\n') + '\n'
p.write_text(metin, encoding='utf-8')

# --------------------------------------------------------------- evdev.xml
# Capa: <name>tr</name> + <shortDescription>tr</shortDescription> ikilisi.
# Tek <name>tr</name> aramak YETMEZ - dosyada Almanya'nin "Turkish (Germany)"
# varyanti da <name>tr</name> tasiyor (satir ~3889). Iki capa birden aranir.
p = sahne / 'rules' / 'evdev.xml'
satirlar = p.read_text(encoding='utf-8').split('\n')

# eskiyi sok: <name>f_custom</name> iceren <variant> blogunu komple sil
i = 0
while i < len(satirlar):
    if '<name>f_custom</name>' in satirlar[i]:
        bas = i
        while bas > 0 and '<variant>' not in satirlar[bas]:
            bas -= 1
        son = i
        while son < len(satirlar) - 1 and '</variant>' not in satirlar[son]:
            son += 1
        del satirlar[bas:son + 1]
        i = bas
    else:
        i += 1

if not kaldir:
    tr_layout = None
    for i, s in enumerate(satirlar):
        if s.strip() == '<name>tr</name>':
            pencere = '\n'.join(satirlar[i:i + 4])
            if '<shortDescription>tr</shortDescription>' in pencere:
                tr_layout = i
                break
    if tr_layout is None:
        raise SystemExit('HATA: evdev.xml icinde tr layout capasi bulunamadi')

    # bu layout'un variantList'i icinde <name>f</name> varyantini bul
    ekleme = None
    for i in range(tr_layout, min(tr_layout + 200, len(satirlar))):
        if satirlar[i].strip() == '</layout>':
            break
        if satirlar[i].strip() == '<name>f</name>':
            j = i
            while '</variant>' not in satirlar[j]:
                j += 1
            ekleme = j + 1
            break
    if ekleme is None:
        raise SystemExit('HATA: tr layout icinde <name>f</name> varyanti bulunamadi')

    girinti = ' ' * (len(satirlar[ekleme - 1]) - len(satirlar[ekleme - 1].lstrip()))
    yeni = [
        f'{girinti}<variant>',
        f'{girinti}  <configItem>',
        f'{girinti}    <name>f_custom</name>',
        f'{girinti}    <description>Turkish (F letters, Q symbols)</description>',
        f'{girinti}  </configItem>',
        f'{girinti}</variant>',
    ]
    satirlar[ekleme:ekleme] = yeni

p.write_text('\n'.join(satirlar), encoding='utf-8')

# --------------------------------------------------------------- evdev.lst
# Bu dosya olmadan localectl/setxkbmap varyanti gormez (KDE evdev.xml'i okur,
# CLI araclari .lst'yi).
p = sahne / 'rules' / 'evdev.lst'
satirlar = [s for s in p.read_text(encoding='utf-8').split('\n')
            if not re.match(r'\s*f_custom\s+tr:', s)]
if not kaldir:
    for i, s in enumerate(satirlar):
        if re.match(r'\s*f\s+tr:\s*Turkish \(F\)\s*$', s):
            satirlar.insert(i + 1, '  f_custom        tr: Turkish (F letters, Q symbols)')
            break
    else:
        raise SystemExit('HATA: evdev.lst icinde "f  tr: Turkish (F)" satiri bulunamadi')
p.write_text('\n'.join(satirlar), encoding='utf-8')

print('duzenlendi: types/complete, symbols/tr, rules/evdev.xml, rules/evdev.lst')
PYEOF

# ------------------------------------------------------------- dogrulama
log ""
log "dogrulama (sanal kokte, gercek dosyalara henuz dokunulmadi):"

xmllint --noout "$SAHNE/rules/evdev.xml"
log "  [ok] evdev.xml gecerli XML"

XKB_CONFIG_ROOT="$SAHNE" xkbcli compile-keymap --layout tr >/dev/null
log "  [ok] tr (Q) hala derleniyor"

if [[ $KALDIR -eq 0 ]]; then
  XKB_CONFIG_ROOT="$SAHNE" xkbcli compile-keymap --layout tr --variant f_custom >/dev/null
  log "  [ok] tr(f_custom) derleniyor"
fi

# ----------------------------------------------------------------- kurulum
if [[ ! -w "$XKB_KOK/symbols/tr" || ! -w "$XKB_KOK/types/complete" ]]; then
  echo "HATA: $XKB_KOK/symbols/tr yazilabilir degil. 'sudo' ile calistir." >&2
  exit 1
fi

for f in symbols/tr rules/evdev.xml rules/evdev.lst types/complete; do
  cp "$SAHNE/$f" "$XKB_KOK/$f"
done
log ""
log "kuruldu -> $XKB_KOK"
[[ $KALDIR -eq 1 ]] && log "(f_custom kaldirildi)" || true

# ------------------------------------------------------------- pacman hook
# symbols/tr ve evdev.xml, xkeyboard-config paketine ait. Her paket
# guncellemesi bu dosyalari sifirlar ve f_custom SESSIZCE kaybolur.
# Hook, guncelleme sonrasi bu scripti tekrar calistirir.
HOOK=/etc/pacman.d/hooks/95-xkb-f_custom.hook
if [[ "$XKB_KOK" == "/usr/share/X11/xkb" && $EUID -eq 0 ]]; then
  if [[ $KALDIR -eq 1 ]]; then
    rm -f "$HOOK" && log "pacman hook kaldirildi"
  else
    mkdir -p "$(dirname "$HOOK")"
    cat > "$HOOK" <<HOOKEOF
# klavye/03-xkb-kur.sh tarafindan olusturuldu.
# xkeyboard-config guncellenince tr(f_custom) varyantini yeniden enjekte eder.
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = xkeyboard-config

[Action]
Description = tr(f_custom) klavye varyanti yeniden enjekte ediliyor...
When = PostTransaction
Exec = /bin/bash $KOK_DIZIN/03-xkb-kur.sh --sessiz
Depends = libxkbcommon
Depends = libxml2
HOOKEOF
    log "pacman hook kuruldu -> $HOOK"
  fi
fi