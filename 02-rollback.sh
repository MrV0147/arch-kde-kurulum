#!/usr/bin/env bash
# 02-rollback.sh — HER SEYI geri alir. TTY'den tek komut:
#
#   sudo bash ~/klavye/02-rollback.sh
#
# Masaustu acilmasa bile calisir (Ctrl+Alt+F3 -> giris yap -> yukaridaki komut).
# Ekstra: --force  -> sonunda sormadan sddm'yi yeniden baslatir.
#
# TASARIM NOTU: TTY'de root olarak calisiyoruz, ama kullanici dosyalarini geri
# yaziyoruz. chown yapmazsak ~/.bashrc root'un olur ve oturum bir daha duzgun
# acilmaz. Her geri yazmadan sonra sahiplik duzeltiliyor.

set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "HATA: sudo ile calistir."; exit 1; }

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

GERCEK_KULLANICI="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
EV="$(getent passwd "$GERCEK_KULLANICI" | cut -d: -f6)"
KOK="$EV/klavye"
YEDEK="$KOK/yedek/SON"
UYARI=0

uyar() { echo "  [!]  $*"; UYARI=$((UYARI+1)); }

echo "== 1/6  XKB dosyalari (.backup'tan) =="
for f in /usr/share/X11/xkb/symbols/tr \
         /usr/share/X11/xkb/rules/evdev.xml \
         /usr/share/X11/xkb/rules/evdev.lst \
         /usr/share/X11/xkb/types/complete; do
  if [[ -f "$f.backup" ]]; then
    cp -a "$f.backup" "$f" && echo "  [ok] $f"
  else
    uyar "$f.backup YOK - bu dosya geri alinamadi"
  fi
done

echo "== 2/6  Kullanici config'leri (son yedekten) =="
if [[ -d "$YEDEK" ]]; then
  for f in "$EV/.config/kxkbrc" "$EV/.config/konsolerc" \
           "$EV/.config/kglobalshortcutsrc" "$EV/.bashrc"; do
    kaynak="$YEDEK/$(echo "${f#/}" | tr / _)"
    if [[ -f "$kaynak" ]]; then
      cp -a "$kaynak" "$f"
      chown "$GERCEK_KULLANICI:$GERCEK_KULLANICI" "$f"   # <- kritik
      echo "  [ok] $f"
    elif grep -qx "YOKTU $f" "$YEDEK/manifest.txt" 2>/dev/null; then
      rm -f "$f" && echo "  [ok] $f (eskiden yoktu -> silindi)"
    else
      uyar "$f icin yedek bulunamadi"
    fi
  done
else
  uyar "yedek klasoru yok ($YEDEK) - kullanici config'leri atlandi"
fi

echo "== 3/6  Giris ekrani keymap'i =="
KB=/etc/X11/xorg.conf.d/00-keyboard.conf
if grep -qx "YOKTU $KB" "$YEDEK/manifest.txt" 2>/dev/null; then
  rm -f "$KB" "$KB.backup" && echo "  [ok] $KB silindi (eskiden yoktu)"
elif [[ -f "$KB.backup" ]]; then
  cp -a "$KB.backup" "$KB" && echo "  [ok] $KB geri yuklendi"
else
  uyar "$KB icin kayit yok - elle kontrol et"
fi

echo "== 4/6  Konsole ozellestirmeleri =="
rm -rf  "$EV/.local/share/kxmlgui5/konsole"        && echo "  [ok] kxmlgui5/konsole"
rm -f   "$EV/.local/share/konsole/VSCode.keytab"   && echo "  [ok] VSCode.keytab"

echo "== 5/6  Panel widget'i =="
rm -rf "$EV/.local/share/plasma/plasmoids/org.kaan.qftoggle" && echo "  [ok] org.kaan.qftoggle"

echo "== 6/6  Pacman hook =="
rm -f /etc/pacman.d/hooks/95-xkb-f_custom.hook && echo "  [ok] hook kaldirildi"

echo
if [[ $UYARI -gt 0 ]]; then
  echo "!! $UYARI uyari var - yukariyi oku. Sessizce gecmedik."
else
  echo "Her sey geri alindi."
fi

# Dogrulama: f_custom artik derlenmemeli, tr(Q) derlenmeli.
echo
echo "dogrulama:"
xkbcli compile-keymap --layout tr >/dev/null 2>&1 \
  && echo "  [ok] tr (Q) derleniyor" || echo "  [HATA] tr derlenmiyor!"
xkbcli compile-keymap --layout tr --variant f_custom >/dev/null 2>&1 \
  && echo "  [!]  f_custom HALA derleniyor - temizlik eksik" \
  || echo "  [ok] f_custom artik yok"

echo
if [[ $FORCE -eq 1 ]]; then
  echo "sddm yeniden baslatiliyor..."
  systemctl restart sddm
else
  # TTY'de varsayilan HAYIR: once loglari okuma hakkin kalsin.
  read -r -p "sddm yeniden baslatilsin mi? (e/H) " c
  [[ "${c,,}" == "e" ]] && systemctl restart sddm || echo "atlandi. Hazir oldugunda: sudo systemctl restart sddm"
fi