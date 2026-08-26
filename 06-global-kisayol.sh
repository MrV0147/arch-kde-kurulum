#!/usr/bin/env bash
# 06-global-kisayol.sh — KDE genelinde uygulama baslatma kisayollari.
#
#   bash ~/klavye/06-global-kisayol.sh            # sadece ONAYLANAN: Ctrl+Shift+Esc
#   bash ~/klavye/06-global-kisayol.sh --tumu     # onerilen digerlerini de ekle
#   bash ~/klavye/06-global-kisayol.sh --kaldir
#
# OLCULEN GERCEK — dururken bilinmesi gereken:
# Bu sistemde global kisayol servisini (org.kde.kglobalaccel) ayri bir daemon
# degil, DOGRUDAN kwin_wayland tutuyor (plasma-kglobalaccel.service inactive).
# KGlobalAccel kglobalshortcutsrc dosyasini izlemez; baslangicta okur.
# Dolayisiyla buraya yazilan kayit ANINDA degil, bir sonraki oturum acilisinda
# (ya da KWin yeniden baslatilinca) etkin olur. Script bunu gizlemiyor -
# hemen etkili olmasini istersen alttaki 3 tiklik yol da basiliyor.

set -euo pipefail
UYG="$HOME/.local/share/applications"
TUMU=0; KALDIR=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tumu)   TUMU=1; shift ;;
    --kaldir) KALDIR=1; shift ;;
    *) echo "bilinmeyen secenek: $1" >&2; exit 2 ;;
  esac
done

# ad | gorunen ad | komut | ikon | kisayol | onaylandi_mi
KAYITLAR=(
  "qf-gorev-yoneticisi|Gorev Yoneticisi|plasma-systemmonitor|utilities-system-monitor|Ctrl+Shift+Esc|evet"
  "qf-dosya-yoneticisi|Dosya Yoneticisi|dolphin|system-file-manager|Meta+E|hayir"
  "qf-ekran-alintisi|Ekran Alintisi (bolge)|spectacle --region|spectacle|Meta+Shift+S|hayir"
  "qf-terminal|Terminal|konsole|utilities-terminal|Ctrl+Alt+T|hayir"
)

mkdir -p "$UYG"

for kayit in "${KAYITLAR[@]}"; do
  IFS='|' read -r ad gorunen komut ikon kisayol onayli <<< "$kayit"
  [[ $TUMU -eq 0 && "$onayli" != "evet" ]] && continue

  dosya="$UYG/$ad.desktop"

  if [[ $KALDIR -eq 1 ]]; then
    rm -f "$dosya"
    kwriteconfig6 --file kglobalshortcutsrc --group services --group "$ad.desktop" \
                  --key _launch --delete 2>/dev/null || true
    kwriteconfig6 --file kglobalshortcutsrc --group services --group "$ad.desktop" \
                  --key _k_friendly_name --delete 2>/dev/null || true
    echo "  [-] $gorunen"
    continue
  fi

  cat > "$dosya" <<EOF
[Desktop Entry]
Type=Application
Name=$gorunen
Exec=$komut
Icon=$ikon
Terminal=false
NoDisplay=true
X-KDE-Shortcuts=$kisayol
EOF

  kwriteconfig6 --file kglobalshortcutsrc --group services --group "$ad.desktop" \
                --key _k_friendly_name "$gorunen"
  kwriteconfig6 --file kglobalshortcutsrc --group services --group "$ad.desktop" \
                --key _launch "$kisayol,none,$gorunen"
  echo "  [+] $kisayol  ->  $gorunen  ($komut)"
done

[[ $KALDIR -eq 1 ]] && { echo; echo "kaldirildi."; exit 0; }

if [[ -d "$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle" ]]; then
  bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/uret-yardim.sh" >/dev/null
  echo "  (widget yardim paneli tazelendi)"
fi

echo
echo "yazildi: ~/.config/kglobalshortcutsrc  [services]"
echo
echo "ETKIN OLMASI ICIN (birini sec):"
echo "  a) Oturumu kapatip acmak  -> kayit oldugu gibi yuklenir"
echo "  b) Hemen istersen 3 tik:"
echo "     Sistem Ayarlari -> Kisayollar -> Ekle -> Uygulama"
echo "     -> yukaridaki uygulamayi sec -> tusa bas"
echo
echo "dogrulama: bash ~/klavye/durum.sh"