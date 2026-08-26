#!/usr/bin/env bash
# test-konsole.sh — Konsole kisayollarini dogrular.
#
#   bash ~/klavye/test-konsole.sh
#
# Otomatik olan kismi otomatik olcer; tus basmak gerekenleri sana yaptirip
# sonucu KENDISI okur (senin "calisti galiba" demene birakmaz).
#
# ONEMLI: Bunu Konsole'u TAMAMEN KAPATIP yeniden actiktan sonra calistir.
# Kisayol semasi uygulama acilisinda okunuyor; acik olan pencerede eski
# kisayollar gecerli kalir.

set -uo pipefail
SEMA_DIZIN="$HOME/.local/share/kxmlgui5/konsole"
gecti=0; kaldi=0
ok()   { gecti=$((gecti+1)); printf '  \033[32m[ok]\033[0m    %s\n' "$1"; }
hata() { kaldi=$((kaldi+1)); printf '  \033[31m[HATA]\033[0m  %s\n' "$1"; }

echo "OTOMATIK OLCUMLER"

# Sema KULLANILMIYOR: KXmlGui semayi ayri bir .shortcuts dosyasinda ariyor,
# Konsole onu hic yazmiyor. Kisayollar ui.rc'deki kosulsuz ActionProperties'te.
# Dolayisiyla "Current Scheme" ayarli OLMAMALI - ayarliysa bizimkini ezebilir.
if [[ -z "$(kreadconfig6 --file konsolerc --group 'Shortcut Schemes' --key 'Current Scheme')" ]]; then
  ok "konsolerc: Current Scheme bos (dogru)"
else
  hata "konsolerc: Current Scheme ayarli - kisayollari ezebilir"
fi

for f in konsoleui.rc sessionui.rc; do
  if [[ -f "$SEMA_DIZIN/$f" ]] && xmllint --noout "$SEMA_DIZIN/$f" 2>/dev/null; then
    ok "$f gecerli XML"
  else
    hata "$f yok veya bozuk"
  fi
done

bekle=(edit_copy edit_paste select-all edit_find edit_find_next edit_find_prev close-session new-tab)
for a in "${bekle[@]}"; do
  if grep -qE "<Action name=\"$a\" shortcut=" "$SEMA_DIZIN"/*.rc 2>/dev/null; then
    tus=$(grep -hoE "<Action name=\"$a\" shortcut=\"[^\"]+\"" "$SEMA_DIZIN"/*.rc | sed 's/.*shortcut="//;s/"//')
    ok "$a -> $tus"
  else
    hata "$a icin kisayol yazilmamis"
  fi
done

# Konsole icinde miyiz? Degilsek etkilesimli testler anlamsiz.
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
echo

# --- 1) SIGINT, secim YOKKEN -------------------------------------------------
echo "1/3  SIGINT (hicbir sey secili DEGILKEN)"
echo "     Simdi 'sleep 30' baslatacagim. Fareyle HICBIR SEY SECME,"
echo "     sadece Ctrl+C'ye bas."
read -r -p "     Hazirsan Enter... " _
sleep 30
kod=$?
if [[ $kod -eq 130 ]]; then
  ok "Ctrl+C -> SIGINT gitti (cikis kodu 130). Katman 1 CALISIYOR."
elif [[ $kod -eq 0 ]]; then
  hata "sleep normal bitti - Ctrl+C'ye basmadin ya da tus yutuldu"
  echo "         Yutulduysa katman 2 gerekiyor: bash ~/klavye/04-konsole-kisayol.sh --keytab"
else
  hata "beklenmeyen cikis kodu: $kod"
fi

# --- 2) Kopyala / yapistir ---------------------------------------------------
echo
echo "2/3  Kopyala / yapistir"
ETIKET="qf-test-$RANDOM"
echo "     Asagidaki satiri FAREYLE SEC, Ctrl+C'ye bas:"
echo
echo "         $ETIKET"
echo
read -r -p "     Kopyaladiysan Enter... " _
PANO="$(qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.getClipboardContents 2>/dev/null | tr -d '\n')"
if [[ "$PANO" == *"$ETIKET"* ]]; then
  ok "Ctrl+C -> panoya gitti (Klipper'dan okundu)"
else
  hata "pano beklenen metni icermiyor (okunan: '${PANO:0:40}')"
fi

# --- 3) SIGTSTP dokunulmamis mi ---------------------------------------------
echo
echo "3/3  Ctrl+Z hala islemi uyutuyor mu (SIGTSTP)"
echo "     'sleep 30' baslatacagim. Ctrl+Z'ye bas (durdurmak icin DEGIL, uyutmak icin)."
read -r -p "     Hazirsan Enter... " _
set +m
sleep 30 &
PID=$!
set -m
read -r -p "     Ctrl+Z'ye bastiktan sonra Enter... " _
DURUM="$(ps -o stat= -p $PID 2>/dev/null | tr -d ' ')"
kill $PID 2>/dev/null
if [[ "$DURUM" == T* ]]; then
  ok "surec T (stopped) durumunda - SIGTSTP saglam"
else
  echo "  [bilgi] arka plan sureci uzerinde olculemedi (durum: '${DURUM:-yok}')."
  echo "          Elle dene: 'sleep 30' -> Ctrl+Z -> 'fg'"
fi

echo
echo "SONUC: $gecti gecti, $kaldi kaldi"
echo
echo "Elle bakilacak iki sey daha:"
echo "  · nano /tmp/qf-test  ->  Ctrl+X ile cikabiliyor musun?"
echo "  · Ctrl+T yeni sekme, Ctrl+W sekmeyi kapatiyor mu?"
exit $(( kaldi > 0 ))
