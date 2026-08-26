#!/usr/bin/env bash
# durum.sh — NE KURULU, NE AKTIF? Dosyadan degil, SISTEMDEN okur.
#
#   bash ~/klavye/durum.sh
#
# Altı ay sonra "ben buna ne yapmistim?" dedigin an calistiracagin script bu.
# Hicbir sey degistirmez, sadece okur.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XKB=/usr/share/X11/xkb

y()  { printf '  %-38s %s\n' "$1" "$2"; }
var() { [[ -e "$1" ]] && echo "VAR" || echo "yok"; }
baslik() { printf '\n\033[1m%s\033[0m\n' "$1"; }

printf '\033[1m== KLAVYE / KISAYOL DURUMU ==\033[0m   %s\n' "$(date '+%Y-%m-%d %H:%M')"

baslik "XKB (klavye duzeni tanimi)"
y "f_custom, symbols/tr icinde" \
  "$(grep -qc 'xkb_symbols "f_custom"' $XKB/symbols/tr 2>/dev/null && echo "VAR (satir $(grep -n 'xkb_symbols "f_custom"' $XKB/symbols/tr | cut -d: -f1))" || echo "yok")"
y "f_custom, rules/evdev.xml icinde" \
  "$(grep -q '<name>f_custom</name>' $XKB/rules/evdev.xml 2>/dev/null && echo VAR || echo yok)"
y "f_custom, rules/evdev.lst icinde" \
  "$(grep -q 'f_custom' $XKB/rules/evdev.lst 2>/dev/null && echo VAR || echo yok)"
y "keymap derleniyor" \
  "$(xkbcli compile-keymap --layout tr --variant f_custom >/dev/null 2>&1 && echo EVET || echo HAYIR)"
y "tr (Q) hala derleniyor" \
  "$(xkbcli compile-keymap --layout tr >/dev/null 2>&1 && echo EVET || echo HAYIR)"
y "pacman hook" "$(var /etc/pacman.d/hooks/95-xkb-f_custom.hook)"
# Keymap tazeligi: KWin keymap'i oturum acilisinda derliyor. XKB dosyalari son
# yenilemeden SONRA degistiyse KWin hala eski kopyayi kullaniyor demektir.
DMG="${XDG_STATE_HOME:-$HOME/.local/state}/qf-keymap-yenilendi"
if [[ -f "$DMG" ]]; then
  _d=$(stat -c %Y "$DMG"); _bayat=""
  for _f in $XKB/symbols/tr $XKB/types/complete; do
    [[ -f "$_f" ]] && (( $(stat -c %Y "$_f") > _d )) && _bayat="$_bayat $(basename "$_f")"
  done
  [[ -z "$_bayat" ]] \
    && y "KWin keymap tazeligi" "TAZE ($(date -d @$_d '+%d.%m %H:%M'))" \
    || y "KWin keymap tazeligi" "BAYAT ->$_bayat  (yenile-keymap.sh)"
else
  y "KWin keymap tazeligi" "hic yenilenmemis (yenile-keymap.sh)"
fi
y ".backup yedekleri" \
  "$(ls $XKB/symbols/tr.backup $XKB/rules/evdev.xml.backup >/dev/null 2>&1 && echo VAR || echo EKSIK)"

if xkbcli compile-keymap --layout tr --variant f_custom >/dev/null 2>&1; then
  ozet="$(bash "$KOK/test-f_custom.sh" 2>/dev/null | grep '^SONUC' || true)"
  y "test-f_custom.sh" "${ozet:-calistirilamadi}"
else
  y "test-f_custom.sh" "(f_custom kurulu degil, atlandi)"
fi

baslik "GIRIS EKRANI (SDDM) — Q'ya sabit olmali"
y "localectl X11 layout" "$(localectl status 2>/dev/null | sed -n 's/.*X11 Layout: *//p' | head -1)"
y "localectl X11 variant" "$(localectl status 2>/dev/null | sed -n 's/.*X11 Variant: *//p' | head -1 || echo '(bos = Q, dogru)')"
y "00-keyboard.conf" "$(var /etc/X11/xorg.conf.d/00-keyboard.conf)"

baslik "OTURUM KLAVYE DUZENI"
y "kxkbrc LayoutList"   "$(kreadconfig6 --file kxkbrc --group Layout --key LayoutList)"
y "kxkbrc VariantList"  "$(kreadconfig6 --file kxkbrc --group Layout --key VariantList)"
y "kxkbrc DisplayNames" "$(kreadconfig6 --file kxkbrc --group Layout --key DisplayNames)"
# qdbus6 a(sss) tipini --literal olmadan basamiyor; busctl temiz cikti veriyor.
if listem="$(busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayoutsList 2>/dev/null)"; then
  idx="$(busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayout 2>/dev/null | awk '{print $2}')"
  /usr/bin/python3 - "$listem" "${idx:-0}" <<'PY'
import re, sys
ham, idx = sys.argv[1], int(sys.argv[2])
# a(sss) N "kisa" "gorunen" "uzun" ...  -> ucerli grupla
parcalar = re.findall(r'"((?:[^"\\]|\\.)*)"', ham)
parcalar = [p.encode().decode('unicode_escape').encode('latin1').decode('utf-8', 'replace')
            for p in parcalar]
uclu = [parcalar[i:i+3] for i in range(0, len(parcalar), 3)]
for n, (kisa, gorunen, uzun) in enumerate(uclu):
    isaret = '<<< AKTIF' if n == idx else ''
    print(f"  {'  [' + str(n) + '] ' + (gorunen or kisa):<38} {uzun}  {isaret}")
PY
else
  y "SU AN AKTIF" "(DBus okunamadi - oturum disinda misin?)"
fi

baslik "KONSOLE"
sema="$(kreadconfig6 --file konsolerc --group "Shortcut Schemes" --key "Current Scheme")"
y "kisayol semasi" "${sema:-(varsayilan)}"
# Sema dosyasi kxmlgui5 altinda DEGIL: KShortcutSchemesHelper onu
# AppDataLocation/shortcuts/<ad> yolunda ariyor -> ~/.local/share/konsole/shortcuts/
SD="$HOME/.local/share/konsole/shortcuts/$( kreadconfig6 --file konsolerc --group 'Shortcut Schemes' --key 'Current Scheme' )"
y "sema dosyasi" "$([[ -f "$SD" ]] && echo "VAR ($(grep -c '<Action ' "$SD") kisayol)" || echo "yok")"
if [[ -f "$HOME/.local/share/kxmlgui5/konsole/kesfedilen-aksiyonlar.json" ]]; then
  /usr/bin/python3 -c "
import json,sys
for ad,aksiyon,tus in json.load(open('$HOME/.local/share/kxmlgui5/konsole/kesfedilen-aksiyonlar.json')):
    print(f'  {ad:<38} {tus}   [{aksiyon}]')
" 2>/dev/null
fi
y "keytab (SIGINT katman 2)" "$(var "$HOME/.local/share/konsole/VSCode.keytab")"
y "stty intr (bu terminalde)" "$(stty -a 2>/dev/null | tr ';' '\n' | sed -n 's/.*intr = //p' | head -1 || echo '(tty yok)')"
y "Ctrl+X / Ctrl+Z" "atanmadi - terminale geciyor (kasten)"
y "klipper SyncClipboards" "$(kreadconfig6 --file klipperrc --group General --key SyncClipboards)"

baslik "SATIR DUZENLEME (bash)"
y ".bashrc blogu" "$(grep -q 'qf-klavye satir duzenleme' "$HOME/.bashrc" 2>/dev/null && echo VAR || echo yok)"
y "kod dosyasi" "$(var "$HOME/.local/share/qf-klavye/bashrc-qf.sh")"
_TS="${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"
if [[ -r "$_TS" ]]; then
  y "olculmus tuslar" "$(wc -l < "$_TS") adet"
  sed 's/^/    /' "$_TS"
else
  y "olculmus tuslar" "yok - bash ~/klavye/olc-tus.sh"
fi
y "Ctrl+U" "satirin tamamini siler (kill-whole-line)"

baslik "GLOBAL KISAYOLLAR"
if [[ -f "$HOME/.config/kglobalshortcutsrc" ]]; then
  /usr/bin/python3 - <<'PY'
import configparser, os, re
yol = os.path.expanduser('~/.config/kglobalshortcutsrc')
metin = open(yol, encoding='utf-8', errors='replace').read()
bulundu = False
for m in re.finditer(r'^\[services\]\[([^\]]+)\]\n((?:(?!\[).*\n)*)', metin, re.M):
    dosya, govde = m.group(1), m.group(2)
    tus = re.search(r'^_launch=([^,]*)', govde, re.M)
    ad  = re.search(r'^_k_friendly_name=(.*)', govde, re.M)
    print(f"  {(ad.group(1) if ad else dosya):<38} {tus.group(1) if tus else '?'}")
    bulundu = True
if not bulundu:
    print('  (kayitli uygulama kisayolu yok)')
PY
fi

baslik "PANEL WIDGET"
W="$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle"
# metadata.json'a bak, klasore degil: uret-yardim.sh contents/data/ klasorunu
# widget kurulmadan da yaratabiliyor -> klasor varligi yanlis pozitif verirdi.
y "org.kaan.qftoggle kurulu" "$(var "$W/metadata.json")"
y "panelde" \
  "$(grep -q 'org.kaan.qftoggle' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null && echo EVET || echo "hayir (panele suruklenmemis)")"
YRD="$W/contents/data/kisayollar.json"
y "sag tik yardim paneli" \
  "$([[ -f "$YRD" ]] && /usr/bin/python3 -c "
import json;d=json.load(open('$YRD'))
print(f\"VAR ({sum(len(b['satirlar']) for b in d['bolumler'])} satir, uretim {d['uretim']})\")" 2>/dev/null || echo "yok - bash ~/klavye/uret-yardim.sh")"
echo "  sol tik: duzen degistir  ·  sag tik: kisayol listesi  ·  tekerlek: gez"

baslik "GERI ALMA"
y "son yedek" "$([[ -d "$KOK/yedek/SON" ]] && readlink -f "$KOK/yedek/SON" || echo "yok - once 01-yedekle.sh")"
echo "  tek komut:  sudo bash $KOK/02-rollback.sh"
echo