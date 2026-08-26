#!/usr/bin/env bash
# 50-giris-ekrani.sh — SDDM (giris ekrani), kilit ekrani, onyukleme.
#
#   bash masaustu/50-giris-ekrani.sh --goster     # sudo gerekmez, sadece anlatir
#   sudo bash masaustu/50-giris-ekrani.sh         # uygular
#
# BU DOSYADAKI SDDM AYARI PAHALI OGRENILDI - aynen kopyalamadan once oku.

set -uo pipefail
GOSTER=0
[[ "${1:-}" == "--goster" ]] && GOSTER=1

SDDM_CONF=/etc/sddm.conf.d/10-wayland.conf

if [[ $GOSTER -eq 0 && $EUID -ne 0 ]]; then
  echo "HATA: sudo ile calistir (ya da --goster kullan)."; exit 1
fi

cat <<'EOF'
SDDM — WAYLAND GREETER

Neden: SDDM'nin varsayilan X11 greeter'i iki sorun cikariyordu.

  1. Cift monitor: giris formu her iki ekranda da beliriyordu. Wayland
     greeter'da form yalnizca birincil ekranda cikiyor.

  2. Daha sinsi olani: X11 greeter kapanirken ardinda bir Xorg sureci
     birakiyordu (vt2, -noreset) ve o surec oturum boyunca :0'i tutuyordu.
     Sonucu, gamescope kendi ic Xwayland'ini baslatamiyordu:
         "Failed to bind socket @/tmp/.X11-unix/X0"

TUZAK — bunu atlarsan BOOT LOOP olur:
  Paketin varsayilani  CompositorCommand=weston --shell=kiosk
  ama bu sistemde weston KURULU DEGIL. Sadece DisplayServer=wayland yazip
  CompositorCommand'i ezmezsen SDDM acilamaz ve dongude kalir.
  Bu yuzden asagidaki dosya ikisini BIRLIKTE yaziyor.
EOF

if [[ $GOSTER -eq 1 ]]; then
  echo
  echo "YAZILACAK: $SDDM_CONF"
  echo "  [General] DisplayServer=wayland"
  echo "  [General] GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell"
  echo "  [Wayland] CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1"
  echo
  echo "KILIT EKRANI (kullanici ayari, sudo gerekmez):"
  echo "  kscreenlockerrc [Daemon] Autolock=false  Timeout=0"
  echo
  echo "ONYUKLEME:"
  echo "  plymouth teması: bgrt  (firmware logosunu kullanir, ek tema gerekmez)"
  echo "  onyukleyici: GRUB (varsayilan yapilandirma, ozellestirilmedi)"
  echo
  echo "(--goster kipi: hicbir sey yazilmadi)"
  exit 0
fi

command -v sddm >/dev/null || { echo "UYARI: sddm kurulu degil, atlaniyor."; exit 0; }
command -v kwin_wayland >/dev/null || { echo "HATA: kwin_wayland yok. Bu ayar boot loop'a yol acar. Duruyorum."; exit 1; }

mkdir -p "$(dirname "$SDDM_CONF")"
[[ -f "$SDDM_CONF" ]] && cp -n "$SDDM_CONF" "$SDDM_CONF.backup"

cat > "$SDDM_CONF" <<'CONF'
# SDDM'i Wayland greeter'a al.
#
# Iki sorunu birden cozer:
#  1. Cift monitor: giris formu primary ekranda tek basina cikar,
#     ikinci ekranda kopyasi olusmaz.
#  2. X11 greeter'in birakip gitmedigi Xorg sureci (vt2, -noreset) oturum
#     boyunca :0'i tutuyordu; bu yuzden gamescope kendi ic Xwayland'ini
#     baslatamiyordu ("Failed to bind socket @/tmp/.X11-unix/X0").
#
# DIKKAT: paket varsayilani CompositorCommand=weston --shell=kiosk ve
# weston bu sistemde kurulu olmayabilir. Asagidaki override olmadan bu
# dosya dogrudan boot loop'a yol acar.

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1
CONF
echo
echo "  [ok] $SDDM_CONF"

# Kilit ekrani kullanici ayari - sudo ile calisiyoruz, gercek kullaniciya yaz.
GERCEK="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
if [[ "$GERCEK" != "root" ]]; then
  sudo -u "$GERCEK" kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock --type bool false
  sudo -u "$GERCEK" kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
  echo "  [ok] kilit ekrani: otomatik kilit kapali"
fi

echo
echo "Test etmeden once: baska bir TTY'de (Ctrl+Alt+F3) acik oturum birak."
echo "  sudo systemctl restart sddm"
echo "Bozulursa:  sudo rm $SDDM_CONF && sudo systemctl restart sddm"