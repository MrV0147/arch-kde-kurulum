#!/usr/bin/env bash
# test-konsole.sh — Konsole kisayollarini dogrular.
#
#   bash ~/klavye/test-konsole.sh
#
# ONEMLI: Konsole'u TAMAMEN KAPATIP yeniden actiktan sonra calistir. Kisayollar
# uygulama acilisinda okunuyor; acik pencerede eskiler gecerli kalir.
#
# Bu script Ctrl+C'ye BASMANI istiyor. Ctrl+C normalde scripti de oldururdu -
# bu yuzden SIGINT tuzaga aliniyor ve olcum olarak sayiliyor.

set -uo pipefail
SEMA_DOSYA="$HOME/.local/share/konsole/shortcuts/VSCode"
gecti=0; kaldi=0
ok()   { gecti=$((gecti+1)); printf '  \033[32m[ok]\033[0m    %s\n' "$1"; }
hata() { kaldi=$((kaldi+1)); printf '  \033[31m[HATA]\033[0m  %s\n' "$1"; }
bilgi(){ printf '  \033[33m[?]\033[0m     %s\n' "$1"; }

echo "OTOMATIK OLCUMLER"

# Kisayollar NEREDE: ~/.local/share/konsole/shortcuts/<SemaAdi>
# (kxmlgui5/konsole/ altinda DEGIL - orada sadece menu yapisi ve aksiyon adlari
#  var. Bir tur oraya yazdik, sessizce hicbir sey olmadi.)
if [[ -f "$SEMA_DOSYA" ]] && xmllint --noout "$SEMA_DOSYA" 2>/dev/null; then
  ok "sema dosyasi var ve gecerli XML"
else
  hata "sema dosyasi yok/bozuk: $SEMA_DOSYA"
fi

SEMA_AKTIF="$(kreadconfig6 --file konsolerc --group 'Shortcut Schemes' --key 'Current Scheme')"
if [[ "$SEMA_AKTIF" == "VSCode" ]]; then
  ok "konsolerc: Current Scheme=VSCode"
else
  hata "konsolerc: Current Scheme='$SEMA_AKTIF' (VSCode olmali)"
fi

bekle=(edit_copy edit_paste select-all edit_find edit_find_next edit_find_prev close-session new-tab)
for a in "${bekle[@]}"; do
  if tus=$(grep -oE "name=\"$a\" shortcut=\"[^\"]+\"" "$SEMA_DOSYA" 2>/dev/null | sed 's/.*shortcut="//;s/"//'); [[ -n "$tus" ]]; then
    ok "$a -> $tus"
  else
    hata "$a semada yok"
  fi
done

# ---------------------------------------------------------------- DUZEN BILGISI
# Kisayol "fiziksel tus" degil, "o harfi ureten tus" demektir. Duzen degisince
# o tus tasinir. Kullaniciya SU AN hangi tusa basmasi gerektigini soyleyelim.
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
if [[ "$DUZEN" == "F" ]]; then
  cat <<'EOF'
  DIKKAT — F duzenindesin. Kisayol harfleri Q'ya gore YER DEGISTIRDI:
      Ctrl+C (kopyala)  ->  Q klavyedeki  V  tusuna bas
      Ctrl+V (yapistir) ->  Q klavyedeki  C  tusuna bas
      Ctrl+A (sec)      ->  Q klavyedeki  F  tusuna bas
  Ya da duzenden bagimsiz olanlari kullan:  Ctrl+Insert / Shift+Insert
EOF
else
  echo "  Q duzenindesin - tuslar alistigin yerde."
fi

if [[ "${KONSOLE_VERSION:-}" == "" ]]; then
  echo
  echo "  NOT: Bu kabuk Konsole'da degil (KONSOLE_VERSION bos)."
  echo "  Etkilesimli testler icin bu scripti KONSOLE icinde calistir."
  echo
  echo "SONUC: $gecti gecti, $kaldi kaldi  (etkilesimli kisim atlandi)"
  exit $(( kaldi > 0 ))
fi

echo
echo "ETKILESIMLI OLCUMLER — sana soyleneni yap, sonucu ben okurum"

# --- 1) AYIRT EDICI TEST: secim VARKEN Ctrl+C kopyaliyor mu? -----------------
# Bu test "kisayol yuklendi mi" sorusunu tek basina yanitlar. SIGINT testi
# yanitlamaz: kisayol hic yuklenmemis olsa da Ctrl+C SIGINT gonderirdi.
echo
echo "1/3  KOPYALAMA  (bu test 'kisayol gercekten yuklendi mi' sorusunu yanitlar)"
ETIKET="qf-test-$RANDOM-$RANDOM"
qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.setClipboardContents "bos-$RANDOM" >/dev/null 2>&1
echo
echo "     Asagidaki satiri FAREYLE SEC, sonra Ctrl+C'ye bas:"
echo
echo "         $ETIKET"
echo
read -r -p "     Kopyaladiysan Enter'a bas... " _ || true
PANO="$(qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.getClipboardContents 2>/dev/null | tr -d '\n')"
if [[ "$PANO" == *"$ETIKET"* ]]; then
  ok "Ctrl+C panoya kopyaladi -> KISAYOL AKTIF"
else
  hata "pano beklenen metni icermiyor (okunan: '${PANO:0:45}')"
  echo "         Sebep olabilir:"
  echo "           · Konsole'u kisayollar yazildiktan SONRA yeniden acmadin"
  echo "           · F duzenindesin ve yanlis fiziksel tusa bastin (yukari bak)"
  echo "           · Metni secmeden Ctrl+C'ye bastin"
fi

# --- 2) SIGINT, secim YOKKEN -------------------------------------------------
echo
echo "2/3  SIGINT  (hicbir sey secili DEGILKEN Ctrl+C hala islemi durduruyor mu)"
echo "     'sleep 20' baslatiyorum. HICBIR SEY SECME, sadece Ctrl+C'ye bas."
echo

SIGINT_GELDI=0
trap 'SIGINT_GELDI=1' INT      # Ctrl+C scripti oldurmesin, olcum olarak sayilsin
for i in 3 2 1; do printf "\r     %d..." "$i"; sleep 1; done
printf "\r     SIMDI Ctrl+C'ye bas!   \n"
sleep 20
KOD=$?
trap - INT

if [[ $SIGINT_GELDI -eq 1 || $KOD -eq 130 ]]; then
  ok "Ctrl+C -> SIGINT gitti. Katman 1 CALISIYOR, keytab'a gerek yok."
elif [[ $KOD -eq 0 ]]; then
  hata "sleep 20 sonuna kadar bekledi - SIGINT gelmedi"
  echo "         Ctrl+C yutulmus olabilir. Katman 2:"
  echo "           bash ~/klavye/04-konsole-kisayol.sh --keytab"
else
  bilgi "beklenmeyen cikis kodu: $KOD"
fi

# --- 3) Ctrl+Z dokunulmamis mi ----------------------------------------------
echo
echo "3/3  Ctrl+Z hala islemi uyutuyor mu (SIGTSTP)"
echo "     Bunu elle dogrula, 10 saniye surer:"
echo "         sleep 30      -> Ctrl+Z'ye bas  ->  [1]+ Stopped  yazmali"
echo "         fg            -> geri gelmeli"
echo "     (F duzenindeysen Ctrl+Z icin Q'daki N tusuna basacaksin)"

echo
echo "SONUC: $gecti gecti, $kaldi kaldi"
echo
echo "Elle bakilacak son sey:  nano /tmp/qf-test  ->  Ctrl+X ile cikabiliyor musun?"
exit $(( kaldi > 0 ))