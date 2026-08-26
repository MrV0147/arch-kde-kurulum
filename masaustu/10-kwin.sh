#!/usr/bin/env bash
# 10-kwin.sh — KWin: kose eylemleri, efektler, pencere gecisi, dekorasyon.
#
#   bash masaustu/10-kwin.sh            # uygula
#   bash masaustu/10-kwin.sh --goster   # sadece ne yapacagini yazdir
#
# NEDEN dotfile KOPYALAMIYORUZ: ~/.config/kwinrc icinde makineye ozgu seyler var
# (masaustu UUID'leri, ekran UUID'leri, dosen tile duzenleri). Onlari baska bir
# makineye kopyalamak ise yaramaz, hatta karistirir. Bu yuzden burada sadece
# TASINABILIR ayarlar, kwriteconfig6 ile yaziliyor.

set -euo pipefail
GOSTER=0
[[ "${1:-}" == "--goster" ]] && GOSTER=1

yaz() {  # grup anahtar deger [tip]
  local grup="$1" anahtar="$2" deger="$3" tip="${4:-}"
  if [[ $GOSTER -eq 1 ]]; then
    printf '  [%s] %s = %s\n' "$grup" "$anahtar" "$deger"
    return
  fi
  if [[ -n "$tip" ]]; then
    kwriteconfig6 --file kwinrc --group "$grup" --key "$anahtar" --type "$tip" "$deger"
  else
    kwriteconfig6 --file kwinrc --group "$grup" --key "$anahtar" "$deger"
  fi
}

echo "KOSE EYLEMLERI (fareyi ekran kosesine goturunce)"
# KWin ElectricBorder sirasi: 0=Ust 1=SagUst 2=Sag 3=SagAlt 4=Alt 5=SolAlt 6=Sol 7=SolUst 8=Yok
yaz ElectricBorders BottomLeft  showdesktop          # sol alt  -> masaustunu goster
yaz ElectricBorders BottomRight lockscreen           # sag alt  -> ekrani kilitle
yaz ElectricBorders TopRight    applicationlauncher  # sag ust  -> uygulama baslatici
yaz Effect-overview BorderActivate 7                 # sol ust  -> Genel Gorunum

echo
echo "EFEKTLER"
yaz Plugins blurEnabled          true  bool
yaz Plugins glideEnabled         true  bool
yaz Plugins magiclampEnabled     true  bool
yaz Plugins translucencyEnabled  true  bool
yaz Plugins wobblywindowsEnabled true  bool
yaz Plugins kwin_gesturesEnabled true  bool
yaz Plugins cubeEnabled          false bool
yaz Plugins fallapartEnabled     false bool

echo
echo "PENCERE GECISI (Alt+Tab)"
yaz TabBox LayoutName       coverswitch
yaz TabBox HighlightWindows true bool
yaz TabBox MultiScreenMode  0
yaz TabBox ApplicationsMode 0

echo
echo "DIGER"
yaz Windows      RollOverDesktops        true  bool   # kenardan tasinca oteki masaustune gec
yaz Wayland      EnablePrimarySelection  false bool   # orta tik yapistirmayi kapat
yaz Compositing  AllowTearing            false bool
yaz Effect-cube  BackgroundColor         "13,15,18"

if [[ $GOSTER -eq 1 ]]; then
  echo
  echo "(--goster kipi: hicbir sey yazilmadi)"
  exit 0
fi

echo
echo "KWin yeniden yapilandiriliyor..."
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || \
  echo "  (qdbus6 yok veya KWin calismiyor - oturumu yeniden acinca gecerli olur)"
echo "bitti."
