#!/usr/bin/env bash
# 30-gorunum.sh — tema yigini: renk semasi, ikon, imlec, pencere dekorasyonu,
# widget stili, GTK uyumu.
#
#   bash masaustu/30-gorunum.sh --goster   # yazmadan goster
#   bash masaustu/30-gorunum.sh            # uygula
#
# NOT: Buradaki tema/ikon/imlec PAKETLERI depoda YOK - hepsi baskalarinin isi ve
# kendi lisanslari var. Once 20-ek-bilesenler.sh listesine bakip kur, sonra bunu
# calistir. Kurulu olmayan bir tema secilirse KDE sessizce varsayilana duser,
# bu yuzden script her adimda "kurulu mu" diye BAKAR ve eksigi soyler.

set -uo pipefail
GOSTER=0
[[ "${1:-}" == "--goster" ]] && GOSTER=1

RENK_SEMASI="Lucy"                 # sari vurgulu koyu sema (255,229,0)
IKON="Papirus-Dark"
IMLEC="Bibata-Modern-Ice"
WIDGET_STILI="Darkly"
DEKORASYON_LIB="org.kde.darkly"
GENEL_GORUNUM="Nothing"
VURGU="255,229,0"

eksik=0
kontrol() {  # aciklama, aranan yol(lar) - joker karakter destekli
  local ad="$1"; shift
  for kalip in "$@"; do
    # Qt eklentileri surum sonekiyle gelebiliyor (darkly -> darkly6.so),
    # dekorasyonlar da kdecoration2 yerine kdecoration3'te olabiliyor.
    # Bu yuzden duz dosya testi degil, joker genisletmesi kullaniliyor.
    for y in $kalip; do
      [[ -e "$y" ]] && { printf '  [var]    %s\n' "$ad"; return 0; }
    done
  done
  printf '  [EKSIK]  %s\n' "$ad"; eksik=$((eksik+1)); return 1
}

echo "KURULU MU?"
kontrol "renk semasi: $RENK_SEMASI" \
  ~/.local/share/color-schemes/$RENK_SEMASI.colors /usr/share/color-schemes/$RENK_SEMASI.colors
kontrol "ikon teması: $IKON" \
  ~/.local/share/icons/$IKON /usr/share/icons/$IKON
kontrol "imleç: $IMLEC" \
  ~/.local/share/icons/$IMLEC /usr/share/icons/$IMLEC
kontrol "genel görünüm: $GENEL_GORUNUM" \
  ~/.local/share/plasma/look-and-feel/$GENEL_GORUNUM /usr/share/plasma/look-and-feel/$GENEL_GORUNUM
kontrol "pencere dekorasyonu: $DEKORASYON_LIB" \
  "/usr/lib/qt6/plugins/org.kde.kdecoration*/$DEKORASYON_LIB.so"
kontrol "widget stili: $WIDGET_STILI  (paket: darkly-bin)" \
  "/usr/lib/qt6/plugins/styles/${WIDGET_STILI,,}*.so"

[[ $eksik -gt 0 ]] && echo "  -> $eksik eksik. bash masaustu/20-ek-bilesenler.sh --liste"

if [[ $GOSTER -eq 1 ]]; then
  cat <<EOF

UYGULANACAK (--goster kipi, hicbir sey yazilmadi)
  kdeglobals [General] ColorScheme      = $RENK_SEMASI
  kdeglobals [General] AccentColor      = $VURGU
  kdeglobals [General] accentColorFromWallpaper = false
  kdeglobals [Icons]   Theme            = $IKON
  kdeglobals [KDE]     widgetStyle      = $WIDGET_STILI
  kdeglobals [KDE]     LookAndFeelPackage = $GENEL_GORUNUM
  kdeglobals [KDE]     contrast=4  frameContrast=0.2
  kcminputrc [Mouse]   cursorTheme      = $IMLEC
  kwinrc [org.kde.kdecoration2] library = $DEKORASYON_LIB
  gtk-3.0/settings.ini + gtk-4.0/settings.ini  (ikon/imlec/koyu tema uyumu)
EOF
  exit 0
fi

echo
echo "UYGULANIYOR"
kwriteconfig6 --file kdeglobals --group General --key ColorScheme  "$RENK_SEMASI"
kwriteconfig6 --file kdeglobals --group General --key AccentColor  "$VURGU"
kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper --type bool false
kwriteconfig6 --file kdeglobals --group Icons   --key Theme        "$IKON"
kwriteconfig6 --file kdeglobals --group KDE     --key widgetStyle  "$WIDGET_STILI"
kwriteconfig6 --file kdeglobals --group KDE     --key LookAndFeelPackage "$GENEL_GORUNUM"
kwriteconfig6 --file kdeglobals --group KDE     --key contrast      4
kwriteconfig6 --file kdeglobals --group KDE     --key frameContrast 0.2
kwriteconfig6 --file kcminputrc --group Mouse   --key cursorTheme  "$IMLEC"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "$DEKORASYON_LIB"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme   ""
echo "  [ok] KDE"

# GTK uygulamalari (Firefox, GIMP...) KDE temasini kendiliginden almaz.
for s in gtk-3.0 gtk-4.0; do
  d="$HOME/.config/$s"; mkdir -p "$d"
  f="$d/settings.ini"
  grep -q "^\[Settings\]" "$f" 2>/dev/null || echo "[Settings]" > "$f"
  /usr/bin/python3 - "$f" "$IKON" "$IMLEC" <<'PY'
import sys, re, pathlib
yol, ikon, imlec = sys.argv[1:4]
p = pathlib.Path(yol); t = p.read_text(encoding='utf-8')
ayar = {
    'gtk-application-prefer-dark-theme': 'true',
    'gtk-icon-theme-name': ikon,
    'gtk-cursor-theme-name': imlec,
    'gtk-cursor-theme-size': '24',
    'gtk-decoration-layout': 'icon:minimize,maximize,close',
}
for k, v in ayar.items():
    if re.search(rf'^{re.escape(k)}=', t, re.M):
        t = re.sub(rf'^{re.escape(k)}=.*$', f'{k}={v}', t, flags=re.M)
    else:
        t = t.rstrip('\n') + f'\n{k}={v}\n'
p.write_text(t, encoding='utf-8')
PY
done
echo "  [ok] GTK 3 + GTK 4"

qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
echo
echo "bitti. Bazi degisiklikler oturumu yeniden acinca tam oturur."