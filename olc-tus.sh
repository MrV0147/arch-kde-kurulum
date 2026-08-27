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
# --dedektor: tuslari TEK TEK, ADIYLA sorar ve ne gonderdiklerini yazar.
#
# Ilk surum serbest kipti ve okunmaz cikti verdi: kullanicinin panosunda
# TUM KAYDIRMA TAMPONU vardi (Ctrl+A ile secip Ctrl+C ile kopyalamis) ve bir
# yapistirma olunca binlerce bayt girdi olarak dokuldu. Bu surum uzun girdiyi
# YAPISTIRMA olarak tanir, kirpar ve ne oldugunu soyler.
if [[ "${1:-}" == "--dedektor" ]]; then
  [[ -t 0 ]] || { echo "HATA: gercek terminalde calistir."; exit 1; }
  SORULACAK=(
    "Ctrl+A|bash'e ulasiyor mu, yoksa Konsole mu yutuyor"
    "Delete|hangi diziyi gonderiyor"
    "Backspace|hangi bayti gonderiyor"
    "Shift+Delete|ayirt edilebiliyor mu"
  )
  echo "TUS DEDEKTORU — her tusa BIR KEZ bas"
  echo
  for s in "${SORULACAK[@]}"; do
    IFS='|' read -r ad aciklama <<< "$s"
    printf '  %-14s (%s)\n' "$ad" "$aciklama"
    printf '      bas: '
    ham="$(oku_tus)"
    uz=${#ham}
    if (( uz > 12 )); then
      printf 'YAPISTIRMA! %d bayt geldi\n' "$uz"
      printf '      ilk 40 karakter: %.40s...\n' "$ham"
      printf '      -> Bu tus yapistirma yapti. Panonda buyuk bir metin var\n'
      printf '         (muhtemelen Ctrl+A + Ctrl+C ile aldigin tum tampon).\n'
    elif [[ -z "$ham" ]]; then
      printf '(hicbir bayt gelmedi -> Konsole tusu YUTUYOR)\n'
    else
      printf '%-18s  onaltilik: %s\n' "$(bicimle "$ham")" "$(onaltilik "$ham")"
    fi
    echo
  done
  echo "Bitti. Ciktiyi oldugu gibi paylas."
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