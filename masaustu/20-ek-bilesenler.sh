#!/usr/bin/env bash
# 20-ek-bilesenler.sh — ucuncu parti plasmoid / tema / KWin scriptlerini kurar.
#
#   bash masaustu/20-ek-bilesenler.sh --liste   # ne kurulacagini goster
#   bash masaustu/20-ek-bilesenler.sh           # kur
#
# NEDEN DOSYALARI DEPOYA KOYMUYORUZ:
# Bunlarin hepsi baskalarinin isi ve kendi lisanslari var (GPL-3.0, LGPL, MIT).
# Baskasinin eserini kendi depoma kopyalamak yerine KAYNAGINDAN indiriyoruz -
# hem lisansa saygili, hem de guncel surumu almis oluyoruz.

set -uo pipefail
LISTE=0
[[ "${1:-}" == "--liste" ]] && LISTE=1

# ad | tur | lisans | kaynak
BILESENLER=(
  "Krohnkite (dosen pencere yoneticisi)|kwinscript|MIT|https://github.com/anametologin/krohnkite"
  "YoRHa HUD|plasmoid|GPL-3.0-or-later|https://github.com/AxZoRos/YoRHa-HUD"
  "Plasma Audio Visualizer|plasmoid|MIT|https://github.com/muddyblack/plasma-audio-visualizer"
  "Vector Clock|plasmoid|GPL-3.0+|https://store.kde.org/p/2137726/"
  "Side Menu|plasmoid|MIT|https://store.kde.org/ (Lucy)"
  "Nothing (tema + genel gorunum)|tema|GPL-3+/LGPL|https://seduccionlinux.wordpress.com"
  "Scratchy (tema + genel gorunum)|tema|GPL-3+/LGPL|https://seduccionlinux.wordpress.com"
  "Smart Video Wallpaper Reborn|duvarkagidi|GPL-3.0|https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn"
  "Panel Colorizer|plasmoid|GPL-3.0|https://github.com/luisbocanegra/plasma-panel-colorizer"
  "Darkly (widget stili + dekorasyon)|paket|GPL|AUR: darkly-bin"
  "Papirus-Dark (simge teması)|paket|GPL-3.0|pacman: papirus-icon-theme"
  "Bibata-Modern-Ice (imleç)|paket|GPL-3.0|AUR: bibata-cursor-theme"
  "Noto Sans (yazı tipi)|paket|OFL|pacman: noto-fonts"
)

# Depo paketiyle gelenler - tek komutla:
#   sudo pacman -S papirus-icon-theme noto-fonts
#   AUR (yay/paru):  darkly-bin bibata-cursor-theme

echo "Bu masaustu kurulumunun kullandigi ucuncu parti bilesenler:"
echo
printf "  %-38s %-14s %-22s %s\n" "AD" "TUR" "LISANS" "KAYNAK"
printf "  %-38s %-14s %-22s %s\n" "--" "---" "------" "------"
for b in "${BILESENLER[@]}"; do
  IFS='|' read -r ad tur lisans kaynak <<< "$b"
  printf "  %-38s %-14s %-22s %s\n" "$ad" "$tur" "$lisans" "$kaynak"
done

echo
if [[ $LISTE -eq 1 ]]; then
  echo "(--liste kipi: hicbir sey kurulmadi)"
  exit 0
fi

cat <<'EOF'
KURULUM

Bunlarin cogu KDE'nin kendi "Yeni ... Al" penceresinden tek tikla kurulur:

  Plasmoid'ler:  Panele sag tik -> Bilesenleri Duzenle -> Bilesen Ekle
                 -> "Yeni Bilesen Al" -> ada gore ara

  Temalar:       Sistem Ayarlari -> Gorunum -> Genel Gorunum
                 -> "Yeni Genel Gorunum Al"

  KWin script:   Sistem Ayarlari -> Pencere Yonetimi -> KWin Scriptleri
                 -> "Yeni Script Al"  (Krohnkite)

  Dekorasyon:    Sistem Ayarlari -> Gorunum -> Pencere Dekorasyonlari

GitHub'daki bilesenler icin depo README'lerindeki kurulum adimlarini izle;
cogu "kpackagetool6 -t Plasma/Applet -i ." ile kuruluyor.

Hicbiri ZORUNLU degil - klavye ve kisayol tarafi bunlar olmadan da calisir.
EOF