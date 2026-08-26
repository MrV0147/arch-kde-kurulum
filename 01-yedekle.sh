#!/usr/bin/env bash
# 01-yedekle.sh — dokunulacak her dosyayi yedekler ve giris ekranini Q'ya sabitler.
#
#   sudo bash ~/klavye/01-yedekle.sh
#
# Iki katmanli yedek:
#   1) yedek/YYYYMMDD-HHMMSS/  -> zaman damgali tam kopya + manifest
#   2) <dosya>.backup           -> gorevde istenen sabit yedek, VAR OLANI EZMEZ
#      (cp -n: ilk temiz hali korunur, ikinci calistirmada bozulmus hali
#       uzerine yazilmaz)
#
# Manifest neden onemli: /etc/X11/xorg.conf.d/00-keyboard.conf su an YOK.
# Rollback'in "geri yukle" degil "SIL" yapmasi gerekiyor. Manifest bunu kaydeder.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "HATA: sudo ile calistir."; exit 1; }

GERCEK_KULLANICI="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
EV="$(getent passwd "$GERCEK_KULLANICI" | cut -d: -f6)"
KOK="$EV/klavye"
DAMGA="$(date +%Y%m%d-%H%M%S)"
YEDEK="$KOK/yedek/$DAMGA"
MANIFEST="$YEDEK/manifest.txt"

SISTEM_DOSYALARI=(
  /usr/share/X11/xkb/symbols/tr
  /usr/share/X11/xkb/rules/evdev.xml
  /usr/share/X11/xkb/rules/evdev.lst
  /etc/X11/xorg.conf.d/00-keyboard.conf
)
KULLANICI_DOSYALARI=(
  "$EV/.config/kxkbrc"
  "$EV/.config/konsolerc"
  "$EV/.config/kglobalshortcutsrc"
  "$EV/.bashrc"
)

mkdir -p "$YEDEK"
: > "$MANIFEST"

yedekle() {
  local kaynak="$1" sabit_yedek="${2:-hayir}"
  local hedef="$YEDEK/$(echo "${kaynak#/}" | tr / _)"
  if [[ -e "$kaynak" ]]; then
    cp -a "$kaynak" "$hedef"
    echo "VAR   $kaynak" >> "$MANIFEST"
    if [[ "$sabit_yedek" == "evet" ]]; then
      # -n: var olani EZME. Ilk temiz hal kutsaldir.
      cp -n "$kaynak" "$kaynak.backup" 2>/dev/null && echo "      -> $kaynak.backup olusturuldu" \
        || echo "      -> $kaynak.backup zaten vardi, dokunulmadi"
    fi
    echo "  [+] $kaynak"
  else
    echo "YOKTU $kaynak" >> "$MANIFEST"
    echo "  [.] $kaynak  (yok - rollback bunu SILECEK)"
  fi
}

echo "yedek klasoru: $YEDEK"
echo
echo "sistem dosyalari:"
for f in "${SISTEM_DOSYALARI[@]}"; do yedekle "$f" evet; done
echo
echo "kullanici dosyalari:"
for f in "${KULLANICI_DOSYALARI[@]}"; do yedekle "$f"; done

ln -sfn "$YEDEK" "$KOK/yedek/SON"
chown -R "$GERCEK_KULLANICI:$GERCEK_KULLANICI" "$KOK/yedek"

# ------------------------------------------------- giris ekrani (SDDM) = Q
# Olculen sorun: localectl -> "X11 Layout: (unset)", 00-keyboard.conf yok.
# Yani SDDM'nin hangi duzeni kullanacagina dair yazili bir dayanak yok. Oturum
# icinde f_custom dolasirken parola ekraninda hangi duzende oldugunu bilemezsin.
#
# Cozum: sistem X11 keymap'i ACIKCA duz tr (Q, varyantsiz). Oturum ici kxkbrc
# bundan bagimsiz -> giris ekrani hep Q, oturumda Q/F serbest.
echo
echo "giris ekrani Q'ya sabitleniyor..."
localectl set-x11-keymap tr
echo "  localectl X11 layout:"
localectl status | sed -n 's/^ *X11 /    X11 /p'

echo
echo "bitti. rollback:  sudo bash $KOK/02-rollback.sh"