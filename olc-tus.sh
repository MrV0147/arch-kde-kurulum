#!/usr/bin/env bash
# olc-tus.sh — bir tusa basildiginda terminale HANGI BAYTLARIN geldigini olcer.
#
#   bash ~/klavye/olc-tus.sh
#
# NEDEN VAR: readline'a tus baglamak icin terminalin gonderdigi kacis dizisini
# bilmek gerekiyor. Bunu tahmin etmek ("herhalde \e[3;2~'dir") tam da bu projede
# defalarca yanildigimiz sey. Olcup yaziyoruz.
#
# Cikti: ~/.local/state/qf-tuslar.conf  -> bashrc-qf.sh bunu okuyup baglar.

set -uo pipefail
HEDEF="${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"
mkdir -p "$(dirname "$HEDEF")"

[[ -t 0 ]] || { echo "HATA: bu script gercek bir terminalde calistirilmali."; exit 1; }

# ad | gorunen ad | ne icin
TUSLAR=(
  "SATIR_SIL|Shift+Delete|Yazdigin satirin tamamini sil"
  "SECILI_SIL|Ctrl+Shift+Delete|Panodakini satirdan cikar"
  "KELIME_GERI|Ctrl+Backspace|Onceki kelimeyi sil"
  "KELIME_ILERI|Ctrl+Delete|Sonraki kelimeyi sil"
)

# Baytlari readline'in anladigi bicime cevir: ESC -> \e, kontrol -> \Cxx
oku_tus() {
  local ham="" k
  # Ilk bayt bloklu, kalanlar 0.05 sn zaman asimiyla (kacis dizisi tek seferde gelir)
  IFS= read -rsn1 k || return 1
  ham+="$k"
  while IFS= read -rsn1 -t 0.05 k; do ham+="$k"; done
  printf '%s' "$ham"
}

bicimle() {
  local ham="$1" cikti="" i c kod
  for (( i=0; i<${#ham}; i++ )); do
    c="${ham:i:1}"
    kod=$(printf '%d' "'$c" 2>/dev/null)
    if   (( kod == 27 )); then cikti+='\e'
    elif (( kod == 127 )); then cikti+='\C-?'
    elif (( kod < 32 )); then cikti+=$(printf '\\C-%s' "$(printf \\$(printf '%03o' $((kod+96))))")
    else cikti+="$c"
    fi
  done
  printf '%s' "$cikti"
}

onaltilik() { printf '%s' "$1" | od -An -tx1 | tr -s ' ' | sed 's/^ //'; }

# ---------------------------------------------------------------- dedektor
# --dedektor: hangi tusa basarsan bas, gonderdigi baytlari yazar. Belirli bir
# tus listesi sormaz. "Bu tus ne gonderiyor?" sorusunun dogrudan yaniti.
if [[ "${1:-}" == "--dedektor" ]]; then
  cat <<'DEOF'
TUS DEDEKTORU

Herhangi bir tusa bas, ne gonderdigini yazayim.
Cikmak icin:  q  tusuna bas.

Ozellikle merak ettiklerim:
  Ctrl+A     -> bash'e ULASIYOR mu, yoksa Konsole mu yutuyor?
  Delete     -> hangi diziyi gonderiyor?
  Backspace  -> hangi bayti gonderiyor?

DEOF
  while true; do
    printf '  bas: '
    ham="$(oku_tus)"
    [[ "$ham" == "q" ]] && { echo "cikildi"; break; }
    printf '%-20s  onaltilik: %s\n' "$(bicimle "$ham")" "$(onaltilik "$ham")"
  done
  exit 0
fi

cat <<'EOF'
TUS OLCUMU

Her adimda soylenen tusa BIR KEZ bas. Atlamak icin sadece Enter'a bas.
(Enter'a basarsan o tus baglanmaz - uydurma baglama yapilmaz.)

EOF

: > "$HEDEF.yeni"
for satir in "${TUSLAR[@]}"; do
  IFS='|' read -r ad gorunen aciklama <<< "$satir"
  printf '  %-20s %-34s ' "$gorunen" "$aciklama"
  ham="$(oku_tus)"
  # Sadece Enter (CR/LF) geldiyse: atla
  if [[ "$ham" == $'\r' || "$ham" == $'\n' || -z "$ham" ]]; then
    printf 'ATLANDI\n'
    continue
  fi
  dizi="$(bicimle "$ham")"
  printf '%-18s  [%s]\n' "$dizi" "$(onaltilik "$ham")"
  printf '%s=%s\n' "$ad" "$dizi" >> "$HEDEF.yeni"
done

mv "$HEDEF.yeni" "$HEDEF"
echo
echo "yazildi: $HEDEF"
cat "$HEDEF" | sed 's/^/  /'
echo
echo "Simdi:  bash ~/klavye/07-satir-sil.sh"