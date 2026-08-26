#!/usr/bin/env bash
# test-klavye-ctrl.sh — F duzeninde Ctrl+<harf> kisayollari Q'daki fiziksel
# konumda mi? Bunu KEYMAP'IN YAPISINDAN degil, KWin'in CANLI davranisindan olcer.
#
#   bash ~/klavye/test-klavye-ctrl.sh
#
# NEDEN AYRI BIR TEST: test-f_custom.sh keymap'in YAPISINI olcuyor (diskteki
# dosya dogru mu). Ama KWin keymap'i oturum acilisinda derleyip saklıyor -
# dosya dogru olsa da KWin bes gun onceki kopyayi kullaniyor olabilir.
# Bir tur tam bu yuzden kaybedildi. Bu script o acigi kapatiyor.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAMGA_DOSYA="${XDG_STATE_HOME:-$HOME/.local/state}/qf-keymap-yenilendi"
XKB=/usr/share/X11/xkb

gecti=0; kaldi=0
ok()   { gecti=$((gecti+1)); printf '  \033[32m[ok]\033[0m    %s\n' "$1"; }
hata() { kaldi=$((kaldi+1)); printf '  \033[31m[HATA]\033[0m  %s\n' "$1"; }
bilgi(){ printf '  \033[33m[?]\033[0m     %s\n' "$1"; }

echo "OTOMATIK OLCUMLER"

# --- 1) Diskteki keymap 5 seviyeli mi -----------------------------------
AB03="$(xkbcli compile-keymap --layout tr --variant f_custom 2>/dev/null \
        | grep -A3 'key <AB03>' | grep -oE '\[.*\]' | head -1)"
if [[ "$AB03" == *","*","*","*","* ]]; then
  ok "diskteki keymap 5 seviyeli: <AB03> = ${AB03}"
else
  hata "diskteki keymap 5 seviyeli DEGIL: ${AB03:-okunamadi}"
  echo "         cozum: sudo bash $KOK/03-xkb-kur.sh"
fi

# Ctrl seviyesi dogru harf mi (AB03 = Q'nun C tusu -> Ctrl ile 'c' olmali)
if [[ "$AB03" == *"c ]"* ]]; then
  ok "<AB03> Ctrl seviyesi = c  (Q'nun C tusu, Ctrl ile kopyalama)"
else
  hata "<AB03> Ctrl seviyesi beklenen 'c' degil"
fi

# --- 2) KWin canli keymap'i f_custom iceriyor mu -------------------------
CANLI="$(WAYLAND_DEBUG=1 timeout 5 xkbcli interactive-wayland --verbose 2>&1 || true)"
SEMBOL="$(grep -m1 'Compiling xkb_symbols' <<<"$CANLI")"
if [[ -z "$SEMBOL" ]]; then
  bilgi "KWin canli keymap'i okunamadi (Wayland oturumu disinda misin?)"
elif [[ "$SEMBOL" == *"f_custom"* ]]; then
  ok "KWin canli keymap: ${SEMBOL#*Compiling }"
else
  hata "KWin keymap'inde f_custom yok: ${SEMBOL#*Compiling }"
fi

# --- 3) Keymap BAYAT mi (XKB dosyalari son yenilemeden sonra mi degisti) --
# Bu, "kod dogru ama calismiyor" tuzagini yakalayan olcum.
if [[ -f "$DAMGA_DOSYA" ]]; then
  DAMGA=$(stat -c %Y "$DAMGA_DOSYA")
  YENI=""
  for f in "$XKB/symbols/tr" "$XKB/types/complete"; do
    [[ -f "$f" ]] && (( $(stat -c %Y "$f") > DAMGA )) && YENI="$YENI $(basename "$f")"
  done
  if [[ -z "$YENI" ]]; then
    ok "keymap taze (son yenileme: $(date -d @"$DAMGA" '+%d.%m %H:%M'))"
  else
    hata "keymap BAYAT - su dosyalar yenilemeden sonra degisti:$YENI"
    echo "         cozum: bash $KOK/yenile-keymap.sh"
  fi
else
  hata "hic yenileme yapilmamis (damga dosyasi yok)"
  echo "         cozum: bash $KOK/yenile-keymap.sh"
fi

# --- Aktif duzen ---------------------------------------------------------
DUZEN="?"
if ham="$(busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayoutsList 2>/dev/null)"; then
  idx="$(busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayout 2>/dev/null | awk '{print $2}')"
  DUZEN="$(/usr/bin/python3 -c "
import re,sys
p=re.findall(r'\"((?:[^\"\\\\]|\\\\.)*)\"', sys.argv[1])
u=[p[i:i+3] for i in range(0,len(p),3)]
i=int(sys.argv[2])
print((u[i][1] or u[i][0]) if i < len(u) else '?')" "$ham" "${idx:-0}" 2>/dev/null)"
fi
echo
echo "AKTIF KLAVYE DUZENI: $DUZEN"

echo
echo "SONUC (otomatik): $gecti gecti, $kaldi kaldi"

# ------------------------------------------------------------------------
# CANLI TUS OLCUMU — asil kanit
# ------------------------------------------------------------------------
cat <<'EOF'

===========================================================================
CANLI TUS OLCUMU  (asil kanit - 20 saniye)

Yukaridaki olcumler keymap'in YAPISINI dogruluyor. Asagidaki ise KWin'in
tusa BASILDIGINDA gercekten ne urettigini olcuyor.

Simdi kucuk bir pencere acilacak. Yapacaklarin:

  1. Panel dugmesinden duzeni  F  yap
  2. Acilan pencereye TIKLA (odak almasi icin)
  3. Ctrl'u basili tutup, klavyende  C  YAZAN tusa bas
  4. Esc ile pencereyi kapat

BEKLENEN: "keysym [ c ]" ve modifier listesinde Control
YANLIS   : "keysym [ v ]"  -> Ctrl seviyesi devrede degil
===========================================================================
EOF
read -r -p "Hazirsan Enter... " _ || true

LOG="$(mktemp)"
timeout 60 xkbcli interactive-wayland > "$LOG" 2>&1 || true

echo
echo "OLCUM SONUCU"
BASIM="$(grep -iE "keysym" "$LOG" | grep -viE "keysym \[ *(Control|Shift|Alt|Super|Escape)" | head -5)"
if [[ -z "$BASIM" ]]; then
  bilgi "hicbir tus basimi kaydedilmedi (pencereye tiklamayi unutmus olabilirsin)"
else
  echo "$BASIM" | sed 's/^/    /'
  echo
  if grep -qiE "keysym \[ *c *\]" <<<"$BASIM"; then
    ok "keysym 'c' uretildi -> Ctrl seviyesi CALISIYOR"
    grep -qi "Control" <<<"$BASIM" \
      && ok "Control modifier'i da iletiliyor (preserve calisiyor)" \
      || hata "Control modifier'i GORUNMUYOR - preserve[] devrede degil"
  elif grep -qiE "keysym \[ *v *\]" <<<"$BASIM"; then
    hata "keysym 'v' uretildi -> Ctrl seviyesi DEVREDE DEGIL"
    echo "         Once:  bash $KOK/yenile-keymap.sh"
    echo "         Sonra da olmazsa oturumu kapatip ac."
  else
    bilgi "beklenen c/v disinda bir keysym geldi - yanlis tusa basmis olabilirsin"
  fi
fi
rm -f "$LOG"

echo
echo "TOPLAM: $gecti gecti, $kaldi kaldi"
exit $(( kaldi > 0 ))