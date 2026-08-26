#!/usr/bin/env bash
# yenile-keymap.sh — KWin'e keymap'i YENIDEN DERLETIR (oturum kapatmadan).
#
#   bash ~/klavye/yenile-keymap.sh
#   bash ~/klavye/yenile-keymap.sh --sessiz    # 03-xkb-kur.sh icinden
#
# NEDEN VAR — pahaliya ogrenildi:
# XKB dosyalarini degistirmek YETMIYOR. KWin keymap'i oturum acilisinda BIR KEZ
# derliyor ve o kopyayi kullanmaya devam ediyor. Bir tur boyunca "kod dogru ama
# calismiyor" sanildi; olculdugunde XKB dosyalari 01:50'de degismisti ama KWin
# BES GUN once baslamisti. Yani hicbir sey yuklenmemisti.
#
# TETIKLEME ZINCIRI (libkwin.so'dan okundu):
#   kxkbrc degisir -> KConfigWatcher -> KeyboardLayout::handleXkbConfigChanged
#   -> KeyboardLayout::reconfigure() -> Xkb::reconfigure()
#   -> Xkb::loadKeymapFromConfig()   -> keymap XKB dosyalarindan YENIDEN derlenir
#
# IKINCI TUZAK: kwriteconfig6 deger ZATEN AYNIYSA dosyaya yazmaz; yazmayinca
# --notify de bildirim gondermez ve zincir hic islemez. Bu yuzden asagida once
# bilerek FARKLI bir deger, sonra dogru deger yaziliyor.

set -uo pipefail
SESSIZ=0
[[ "${1:-}" == "--sessiz" ]] && SESSIZ=1
log() { [[ $SESSIZ -eq 1 ]] || echo "$@"; }

DAMGA_DOSYA="${XDG_STATE_HOME:-$HOME/.local/state}/qf-keymap-yenilendi"

command -v kwriteconfig6 >/dev/null || { echo "HATA: kwriteconfig6 yok"; exit 1; }

# KWin'in ISTEMCILERE GONDERDIGI keymap'in boyutunu olcer.
# Diskteki dosyayi degil, KWin'in CANLI kullandigi seyi olcer: xkbcli bir
# Wayland istemcisi olarak baglanir, WAYLAND_DEBUG protokol olayini basar:
#   wl_keyboard#9.keymap(1, fd 4, 42227)
# Boyut bir parmak izidir - keymap degisirse boyut da degisir.
canli_boyut() {
  WAYLAND_DEBUG=1 timeout 5 xkbcli interactive-wayland 2>&1 \
    | grep -oE 'keymap\([0-9]+, fd [0-9]+, [0-9]+\)' \
    | grep -oE '[0-9]+\)$' | tr -d ')' | head -1
}

ONCE="$(kreadconfig6 --file kxkbrc --group Layout --key LayoutList)"
if [[ -z "$ONCE" ]]; then
  echo "HATA: kxkbrc'de LayoutList bos. Once: bash ~/klavye/05-panel-widget.sh"
  exit 1
fi

BOYUT_ONCE="$(canli_boyut)"
log "kxkbrc LayoutList  : $ONCE"
log "canli keymap boyutu: ${BOYUT_ONCE:-okunamadi} bayt"
log ""
log "KWin'e yeniden derletiliyor..."

# Bilerek farkli bir deger -> gercek degisiklik -> bildirim garantisi
GECICI="${ONCE%%,*}"
[[ "$GECICI" == "$ONCE" ]] && GECICI="us"
kwriteconfig6 --notify --file kxkbrc --group Layout --key LayoutList "$GECICI"
sleep 1
kwriteconfig6 --notify --file kxkbrc --group Layout --key LayoutList "$ONCE"
sleep 2

# --------------------------------------------------------------- dogrulama
CIKTI="$(WAYLAND_DEBUG=1 timeout 5 xkbcli interactive-wayland --verbose 2>&1)"
CANLI_SEMBOL="$(grep -m1 'Compiling xkb_symbols' <<<"$CIKTI")"
BOYUT_SONRA="$(grep -oE 'keymap\([0-9]+, fd [0-9]+, [0-9]+\)' <<<"$CIKTI" \
               | grep -oE '[0-9]+\)$' | tr -d ')' | head -1)"

cikis=0
log ""
if [[ -z "$CANLI_SEMBOL" ]]; then
  log "  [?] KWin'in canli keymap'i okunamadi (Wayland oturumu disinda misin?)"
  cikis=2
elif [[ "$CANLI_SEMBOL" != *"f_custom"* ]]; then
  log "  [!] KWin keymap'inde f_custom YOK:"
  log "      ${CANLI_SEMBOL#*Compiling }"
  log "      Duzenler kayitli mi:  bash ~/klavye/durum.sh"
  cikis=1
else
  log "  [ok] KWin canli keymap: ${CANLI_SEMBOL#*Compiling }"
  log "  [ok] boyut: ${BOYUT_SONRA:-?} bayt"
  # Damga dosyasi: bundan sonra XKB dosyalari degisirse keymap BAYAT demektir.
  mkdir -p "$(dirname "$DAMGA_DOSYA")"
  printf '%s\n' "${BOYUT_SONRA:-0}" > "$DAMGA_DOSYA"
fi

if [[ -n "$BOYUT_ONCE" && -n "$BOYUT_SONRA" && "$BOYUT_ONCE" != "$BOYUT_SONRA" ]]; then
  log "  [ok] boyut $BOYUT_ONCE -> $BOYUT_SONRA degisti: keymap YENIDEN DERLENDI"
fi
# Boyut tek basina AYIRT EDICI DEGIL: KWin'in serilestirmesi xkbcli'ninkinden
# farkli ve her degisiklik boyutu oynatmiyor. Bu yuzden damga dosyasina
# guveniyoruz: bu andan SONRA XKB dosyalari degisirse keymap bayat demektir.
# Kesin yanit ise canli tus olcumunde:  test-klavye-ctrl.sh'
log ""
log "  Keymap'in ICERIGI ancak canli tus olcumuyle dogrulanir:"
log "    bash ~/klavye/test-klavye-ctrl.sh"

log ""
log "Simdi test et:  bash ~/klavye/test-klavye-ctrl.sh"
exit $cikis