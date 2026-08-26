#!/usr/bin/env bash
# 05-panel-widget.sh — iki klavye duzenini kaydeder ve Q/F panel widget'ini kurar.
#
#   bash ~/klavye/05-panel-widget.sh          (sudo GEREKMEZ)
#   bash ~/klavye/05-panel-widget.sh --kaldir
#
# SIRA ONEMLI: once kxkbrc'ye iki duzen yazilir, sonra widget kurulur.
# Cunku kxkbrc su an tek duzen tutuyordu (LayoutList=tr) ve o haliyle
# switchToNextLayout HICBIR SEY yapmaz - widget kurulsa da tiklama olu olurdu.

set -euo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEDEF="$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle"
KALDIR=0
[[ "${1:-}" == "--kaldir" ]] && KALDIR=1

if [[ $KALDIR -eq 1 ]]; then
  rm -rf "$HEDEF"
  kwriteconfig6 --file kxkbrc --group Layout --key LayoutList  "tr"
  kwriteconfig6 --file kxkbrc --group Layout --key VariantList ""
  kwriteconfig6 --file kxkbrc --group Layout --key DisplayNames ""
  qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
  echo "kaldirildi (tek duzen: tr/Q)"
  exit 0
fi

# ------------------------------------------------------- 1) iki duzen kaydi
# Elle dosya duzenlemek yerine kwriteconfig6: KDE'nin kendi yazicisi, bicimi
# bozmaz, dosya yoksa olusturur.
echo "1/3  kxkbrc: iki duzen kaydediliyor"
# --notify SART. Olculdu: KWin duzen listesini KConfigWatcher ile izliyor
# (KWin::KeyboardLayout::handleXkbConfigChanged). --notify olmadan dosya
# degisir ama KWin haberdar olmaz; "qdbus6 ... KWin.reconfigure" de xkb'yi
# tazelemiyor - denendi, liste tek duzende kaldi.
YAZ=(kwriteconfig6 --notify --file kxkbrc --group Layout --key)
"${YAZ[@]}" Use          true
"${YAZ[@]}" VariantList  ",f_custom"
# DisplayNames sayesinde hem stok gosterge hem bizim widget dogrudan "Q"/"F"
# okur; QML tarafinda string ayiklamaya gerek kalmaz.
"${YAZ[@]}" DisplayNames "Q,F"
"${YAZ[@]}" SwitchMode   "Global"

# IKINCI TUZAK (olculdu): kwriteconfig6, deger ZATEN AYNIYSA dosyaya yazmiyor -
# yazmayinca --notify de bildirim gondermiyor ve KWin haberdar olmuyor.
# Scripti ikinci kez calistirdiginda tam da bu olur. Bu yuzden LayoutList once
# bilerek FARKLI bir degere, sonra gercek degere yaziliyor; ikinci yazim her
# zaman gercek bir degisiklik oldugu icin bildirim garanti.
"${YAZ[@]}" LayoutList "tr"
sleep 1
"${YAZ[@]}" LayoutList "tr,tr"
sleep 2

echo "     kayitli duzenler:"
# qdbus6 a(sss) tipini --literal olmadan basamiyor; busctl temiz cikti veriyor.
busctl --user call org.kde.keyboard /Layouts org.kde.KeyboardLayouts getLayoutsList 2>/dev/null \
  | tr -s ' ' | sed 's/^/       /' || echo "       (okunamadi)"

# ------------------------------------------------------------ 2) widget kur
echo "2/3  widget kuruluyor -> $HEDEF"
mkdir -p "$(dirname "$HEDEF")"
rm -rf "$HEDEF"
cp -a "$KOK/payload/plasmoid/org.kaan.qftoggle" "$HEDEF"

# Sag tik yardim panelinin icerigi. Kopyalamadan SONRA uretilir, cunku
# yukaridaki rm -rf onu da silerdi. Icerik canli sistemden okunuyor.
bash "$KOK/uret-yardim.sh" | sed 's/^/     /'

# --------------------------------------------------- 3) plasmashell yeniden
# plasma-org.kde.plasma.desktop-appletsrc'ye ELLE dokunulmaz: plasmashell
# calisirken kendi bellek kopyasini uzerine yazar ve degisiklik kaybolur.
# Widget'i panele SEN surukleyeceksin (tek seferlik).
echo "3/3  plasmashell yeniden baslatiliyor"
# systemd birimi uzerinden: bu sistemde plasma-plasmashell.service AKTIF.
# "kquitapp6 + kstart" ikilisi kstart basarisiz olursa paneli olu birakir;
# systemd birimi geri getirmeyi kendi garanti eder. Birim yoksa eski yola duser.
if systemctl --user is-active --quiet plasma-plasmashell.service; then
  systemctl --user restart plasma-plasmashell.service
else
  kquitapp6 plasmashell 2>/dev/null || true
  sleep 2
  (setsid kstart plasmashell >/dev/null 2>&1 &)
fi
sleep 3
if pgrep -x plasmashell >/dev/null; then
  echo "     plasmashell ayakta (pid $(pgrep -x plasmashell | head -1))"
else
  echo "     !! plasmashell ayaga kalkmadi. Elle: systemctl --user restart plasma-plasmashell.service"
fi

echo
echo "bitti. Son adim SENDE:"
echo "  Panele sag tikla -> 'Bilesenleri Duzenle' -> 'Bilesen Ekle'"
echo "  -> 'Q/F Degistirici' arat -> panele surukle"