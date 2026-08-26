#!/usr/bin/env bash
# 60-standart-kisayollar.sh — KDE'nin UYGULAMA GENELI standart kisayollari.
#
#   bash masaustu/60-standart-kisayollar.sh --goster
#   bash masaustu/60-standart-kisayollar.sh
#
# Bunlar kdeglobals [Shortcuts] altinda durur ve KDE uygulamalarinin TAMAMINI
# etkiler (Dolphin, Kate, Gwenview, Okular...). Konsole'un kendi semasindan
# (04-konsole-kisayol.sh) ve KWin'in global kisayollarindan AYRI bir katman.

set -uo pipefail
GOSTER=0
[[ "${1:-}" == "--goster" ]] && GOSTER=1

# anahtar | deger | aciklama
AYARLAR=(
  "Copy|Ctrl+C|Kopyala (varsayilan, acikca sabitlendi)"
  "Cut|Ctrl+X|Kes (varsayilan, acikca sabitlendi)"
  "Paste|Ctrl+V|Yapistir (varsayilan, acikca sabitlendi)"
  "Redo|Ctrl+R|Yinele — VARSAYILAN DEGIL (KDE'de Ctrl+Shift+Z'dir)"
  "Replace||Degistir kisayolu KALDIRILDI — Ctrl+R'yi Redo'ya birakmak icin"
)

echo "KDE UYGULAMA GENELI KISAYOLLARI  (kdeglobals [Shortcuts])"
echo
printf "  %-10s %-16s %s\n" "ANAHTAR" "DEGER" "ACIKLAMA"
printf "  %-10s %-16s %s\n" "-------" "-----" "--------"
for a in "${AYARLAR[@]}"; do
  IFS='|' read -r k v aciklama <<< "$a"
  printf "  %-10s %-16s %s\n" "$k" "${v:-(bos)}" "$aciklama"
done

echo
cat <<'EOF'
DIKKAT — Ctrl+R takasi
  KDE'de Ctrl+R varsayilan olarak "Degistir" (Find & Replace) icindir.
  Burada Redo'ya veriliyor ve Replace bosaltiliyor. Yani Kate/KWrite'ta
  metin degistirme penceresini artik menuden acarsin (Duzen -> Degistir).
  Bu takasi istemiyorsan bu scripti calistirma - digerleri zaten varsayilan.
EOF

if [[ $GOSTER -eq 1 ]]; then
  echo
  echo "(--goster kipi: hicbir sey yazilmadi)"
  exit 0
fi

echo
for a in "${AYARLAR[@]}"; do
  IFS='|' read -r k v _ <<< "$a"
  kwriteconfig6 --file kdeglobals --group Shortcuts --key "$k" "$v"
done
echo "  [ok] kdeglobals [Shortcuts] yazildi"
echo "  Acik KDE uygulamalarini yeniden baslat."