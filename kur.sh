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
if [[ ! -f "$HOME/.local/share/kxmlgui5/konsole/VSCode.shortcuts" ]]; then
  adim "FAZ 3 — Konsole kisayollari"
  dur "Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir -> Semalari Yonet
       -> Yeni Sema -> ad: VSCode -> Kaydet"
fi
if [[ "$(kreadconfig6 --file konsolerc --group 'Shortcut Schemes' --key 'Current Scheme')" != "VSCode" ]]; then
  adim "FAZ 3 — sema uygulaniyor"
  bash "$KOK/04-konsole-kisayol.sh"
fi
adim "FAZ 3 — tamam"

# ------------------------------------------------------------------ FAZ 3B
if ! grep -q 'qf-gorev-yoneticisi' "$HOME/.config/kglobalshortcutsrc" 2>/dev/null; then
  adim "FAZ 3B — global kisayol (Ctrl+Shift+Esc)"
  bash "$KOK/06-global-kisayol.sh"
fi

adim "HEPSI TAMAM"
bash "$KOK/durum.sh"
echo "Referans:  $KOK/KISAYOLLAR.md"