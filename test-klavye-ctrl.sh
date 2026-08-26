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
# Iki deneme: ilk baglanti bazen zaman asimina ugruyor (olculdu - kullanicida
# iki kez "okunamadi" cikti, kalinti surec temizlenince duzeldi).
CANLI=""
for _d in 1 2; do
  CANLI="$(WAYLAND_DEBUG=1 timeout 6 xkbcli interactive-wayland --verbose 2>&1 || true)"
  grep -q 'Compiling xkb_symbols' <<<"$CANLI" && break
  sleep 1
done
# timeout ile oldurulen xkbcli bazen artakaliyor ve SONRAKI calistirmada
# Wayland baglantisini bozuyor (olculdu: kullanici Ctrl+C'leyince kalan
# surec yuzunden "canli keymap okunamadi" hatasi alindi). Temizle.
# KALIP ANKRAJLI: ankrajsiz "pkill -f xkbcli-interactive-wayland"
# cagiran kabugu de oldurdu, cunku onun komut satiri da o dizgeyi
# iceriyordu. Tam yol + ^$ ile yalnizca gercek surec eslesir.
pkill -f '^/usr/lib/xkbcommon/xkbcli-interactive-wayland$' 2>/dev/null || true
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
# CANLI TUS OLCUMU — asil kanit, dogrudan bu terminalde
#
# TUS SECIMI ONEMLI, iki tur denendi:
#
#   1. Ctrl+C ile olcmeye calistik. Kotu fikir: 0x03 SIGINT uretiyor, script
#      oluyordu. "stty -isig" ile sinyali kapatmayi denedik, o da terminali
#      bozdu - scriptin KENDI CIKTISI girdi olarak okundu (olculen baytlar
#      0x20 ve 0x53 cikti: kendi metnimizin bosluk ve 'S' harfi).
#   2. SIGINT'i tuzaga almayi denedik. Islemedi: bash tuzagi bloke bir
#      builtin bitene kadar calistirmiyor, read sonsuza kadar bekledi.
#
# COZUM: sinyal URETMEYEN bir tus cifti secmek. Q'nun A tusu tam da bu:
#
#   Q duzeni       : AC01 -> 'a'  ->  Ctrl+A = 0x01
#   f_custom (F)   : AC01 -> 'u'  yazarken,  Ctrl ile 'a'  ->  0x01
#   duzeltme yoksa : Ctrl ile 'u' -> 0x15
#
# 0x01 de 0x15 de terminal sinyali degil. Ne stty'ye dokunmak gerekiyor ne
# tuzaga; bash'in kendi "read -rsn1"i ham bayti okuyor.
# ------------------------------------------------------------------------

if [[ ! -t 0 ]]; then
  echo
  echo "  NOT: canli tus olcumu gercek bir terminal ister."
  echo "  Konsole'da calistir:  bash $KOK/test-klavye-ctrl.sh"
  echo
  echo "TOPLAM: $gecti gecti, $kaldi kaldi"
  exit $(( kaldi > 0 ))
fi

olc_bayt() {
  local c rc
  IFS= read -rsn1 c; rc=$?
  if (( rc != 0 )) || [[ -z "$c" ]]; then
    BAYT=yok
  else
    BAYT="$(printf '%02x' "'$c" 2>/dev/null)"
  fi
}

ad_bayt() {
  case "$1" in
    01)  echo "0x01  Ctrl+A" ;;
    15)  echo "0x15  Ctrl+U" ;;
    03)  echo "0x03  Ctrl+C" ;;
    0d|0a) echo "Enter" ;;
    yok) echo "(bayt gelmedi)" ;;
    *)   echo "0x$1" ;;
  esac
}

cat <<'EOF'

===========================================================================
CANLI TUS OLCUMU  (asil kanit)

Ayri pencere yok, tiklama yok - tusa BU terminalde basacaksin.

Olcum tusu:  Ctrl + uzerinde  A  YAZAN tus
(Ctrl+C degil: o SIGINT uretip olcumu bozuyor. A tusu ayni seyi
 sinyal uretmeden olcuyor - Q'da 'a', F'de duzeltme varsa yine 'a'.)
===========================================================================
EOF

# --- A) Q duzeninde kontrol olcumu ---------------------------------------
echo
echo "A) Once Q duzeninde (kontrol olcumu)"
echo "   Panel dugmesi  Q  gostersin, sonra:  Ctrl + A"
read -r -p "   Hazirsan Enter... " _ || true
printf "   basiliyor: "
olc_bayt; B="$BAYT"
echo "$(ad_bayt "$B")"
if [[ "$B" == "01" ]]; then
  ok "Q duzeni: Ctrl+A -> 0x01  (beklenen)"
else
  hata "Q duzeni: 0x01 bekleniyordu, $(ad_bayt "$B") geldi"
  echo "         Yanlis tusa basmis olabilirsin (Ctrl basili + A tusu)."
fi

# --- B) F duzeninde asil olcum -------------------------------------------
echo
echo "B) Simdi F duzenine gec (panel dugmesine tikla)"
echo "   Sonra yine:  Ctrl + uzerinde A YAZAN tus"
read -r -p "   F duzenine gectiysen Enter... " _ || true
printf "   basiliyor: "
olc_bayt; B="$BAYT"
echo "$(ad_bayt "$B")"
echo
if [[ "$B" == "01" ]]; then
  ok "F duzeni: Ctrl+A -> 0x01  ->  CTRL SEVIYESI CALISIYOR"
  echo "         Butun Ctrl+<harf> kisayollari iki duzende de ayni"
  echo "         fiziksel tusta. Ctrl+C de dahil."
elif [[ "$B" == "15" ]]; then
  hata "F duzeni: 0x15 (Ctrl+U) geldi -> Ctrl seviyesi DEVREDE DEGIL"
  echo "         KWin hala eski keymap'i kullaniyor. Sirasiyla:"
  echo "           bash $KOK/yenile-keymap.sh"
  echo "           bu testi tekrar calistir"
  echo "         Yine olmazsa oturumu kapatip ac."
else
  bilgi "beklenen 0x01/0x15 disinda: $(ad_bayt "$B")"
  echo "         Ctrl'u basili tutup A tusuna bastigindan emin ol."
fi

echo
echo "TOPLAM: $gecti gecti, $kaldi kaldi"
exit $(( kaldi > 0 ))
