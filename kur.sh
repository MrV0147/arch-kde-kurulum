#!/usr/bin/env bash
# kur.sh — sirali kurulum rehberi. sudo gerektiren adimlari KENDI calistirir
# demez; sana komutu verir ve orada durur.
#
#   bash ~/klavye/kur.sh

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

adim() { printf '\n\033[1m── %s ─────────────────────────────\033[0m\n' "$1"; }
dur()  { printf '\n\033[1;33mSENDE:\033[0m %s\n\nHazir oldugunda tekrar: bash %s/kur.sh\n\n' "$1" "$KOK"; exit 0; }

XKB=/usr/share/X11/xkb

# ------------------------------------------------------------------ FAZ 1
if [[ ! -f "$XKB/symbols/tr.backup" ]]; then
  adim "FAZ 1 — yedek + giris ekranini Q'ya sabitle"
  dur "sudo bash $KOK/01-yedekle.sh"
fi
adim "FAZ 1 — tamam (yedekler yerinde)"

# ------------------------------------------------------------------ FAZ 2
if ! grep -q 'xkb_symbols "f_custom"' "$XKB/symbols/tr" 2>/dev/null; then
  adim "FAZ 2 — f_custom varyanti"
  bash "$KOK/uret-f_custom.sh"
  dur "sudo bash $KOK/03-xkb-kur.sh"
fi
adim "FAZ 2 — tamam, olculuyor"
bash "$KOK/test-f_custom.sh" || { echo "TESTLER KALDI - devam etme, yukariyi oku."; exit 1; }

# ------------------------------------------------------------------ FAZ 4a
if [[ "$(kreadconfig6 --file kxkbrc --group Layout --key LayoutList)" != "tr,tr" ]]; then
  adim "FAZ 4a — iki duzen kaydi + panel widget'i"
  bash "$KOK/05-panel-widget.sh"
  dur "Panele sag tikla -> Bilesenleri Duzenle -> Bilesen Ekle -> 'Q/F Degistirici' -> panele surukle"
fi
adim "FAZ 4a — tamam (iki duzen kayitli)"

# ------------------------------------------------------------------ FAZ 3
# Konsole'un "Yeni Sema" adimi kxmlgui5/konsole/ altina konsoleui.rc ve
# sessionui.rc yazar. VSCode.shortcuts diye bir dosya HIC olusmaz - bir tur
# burada onu aradik ve kur.sh sonsuza kadar "once semayi olustur" dedi durdu.
KRC="$HOME/.local/share/kxmlgui5/konsole"
if [[ ! -f "$KRC/konsoleui.rc" || ! -f "$KRC/sessionui.rc" ]]; then
  adim "FAZ 3 — Konsole kisayollari"
  dur "Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir -> Semalari Yonet
       -> Yeni Sema -> ad: VSCode -> Kaydet"
fi
# Kisayollarin gercek yeri: ~/.local/share/konsole/shortcuts/VSCode
SEMA="$HOME/.local/share/konsole/shortcuts/VSCode"
if [[ ! -f "$SEMA" ]] || ! grep -q '<Action ' "$SEMA" 2>/dev/null; then
  adim "FAZ 3 — sema uygulaniyor"
  bash "$KOK/04-konsole-kisayol.sh"
  dur "Konsole'u TAMAMEN KAPATIP yeniden ac, sonra:  bash $KOK/test-konsole.sh"
fi
adim "FAZ 3 — tamam"

# ------------------------------------------------------------------ FAZ 3B
if ! grep -q 'qf-gorev-yoneticisi' "$HOME/.config/kglobalshortcutsrc" 2>/dev/null; then
  adim "FAZ 3B — global kisayol (Ctrl+Shift+Esc)"
  bash "$KOK/06-global-kisayol.sh"
  echo
  echo "  NOT: KWin global kisayol dosyasini izlemiyor - bu kisayol bir sonraki"
  echo "       oturum acilisinda etkin olur."
fi

# ------------------------------------------------------------- SATIR DUZENLEME
if ! grep -q "qf-klavye satir duzenleme" "$HOME/.bashrc" 2>/dev/null; then
  adim "SATIR DUZENLEME — yazdigini tek hamlede silmek"
  bash "$KOK/07-satir-sil.sh"
  echo
  echo "  Ctrl+U ve gecmis aramasi hemen calisir."
  echo "  Shift+Delete gibi tuslar icin dizilerini OLCMEK gerekiyor:"
  dur "bash $KOK/olc-tus.sh     (gercek bir terminalde, 4 tusa basacaksin)"
fi
adim "SATIR DUZENLEME — tamam"

# ------------------------------------------------------------------ MASAUSTU
# Bunlar AYRI ve istege bagli: klavye/kisayol tarafi bunlarsiz da calisir.
# Otomatik uygulamiyoruz cunku mevcut masaustu gorunumunu degistirirler.
adim "MASAUSTU (istege bagli)"
cat <<EOF
  Bu adimlar masaustu gorunumunu DEGISTIRIR, o yuzden kur.sh onlari kendiliginden
  calistirmaz. Her birinin --goster kipi var; once onunla bak, sonra karar ver:

    bash $KOK/masaustu/20-ek-bilesenler.sh --liste    # once bilesenleri kur
    bash $KOK/masaustu/10-kwin.sh --goster            # kose eylemleri, efektler
    bash $KOK/masaustu/30-gorunum.sh --goster         # tema, ikon, imlec, GTK
    bash $KOK/masaustu/40-panel.sh --goster           # panel yapisi
    bash $KOK/masaustu/60-standart-kisayollar.sh --goster
    sudo bash $KOK/masaustu/50-giris-ekrani.sh        # SDDM (once --goster oku!)

  Tam envanter:  $KOK/masaustu/ENVANTER.md

  Kalan iki olcum (elle, kisa):
    bash $KOK/test-klavye-ctrl.sh    # F duzeninde Ctrl konumlari, canli tus
    bash $KOK/test-satir-sil.sh      # satir silme
EOF

adim "HEPSI TAMAM"
bash "$KOK/durum.sh"
echo "Referans:  $KOK/KISAYOLLAR.md"