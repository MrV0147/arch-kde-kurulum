#!/usr/bin/env bash
# test-satir-sil.sh — satir silme kisayollarini dogrular.
#
#   bash ~/klavye/test-satir-sil.sh
#
# ONEMLI: Olcum 4 ve 5 TUSA BASMADAN calisir. Fonksiyonlari alt kabukta
# cagirip READLINE_LINE'in gercekten degistigini olcerler. Boylece bir mantik
# hatasi kullanicinin tus denemesine kalmaz - bu projede tam olarak o yuzden
# tur kaybettik.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KURULU="$HOME/.local/share/qf-klavye/bashrc-qf.sh"
TUSLAR="${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"

gecti=0; kaldi=0
ok()   { gecti=$((gecti+1)); printf '  \033[32m[ok]\033[0m    %s\n' "$1"; }
hata() { kaldi=$((kaldi+1)); printf '  \033[31m[HATA]\033[0m  %s\n' "$1"; }
bilgi(){ printf '  \033[33m[?]\033[0m     %s\n' "$1"; }

echo "KURULUM"

grep -q "qf-klavye satir duzenleme" "$HOME/.bashrc" 2>/dev/null \
  && ok ".bashrc icinde source satiri var" \
  || hata ".bashrc'de source satiri yok  -> bash $KOK/07-satir-sil.sh"

[[ -r "$KURULU" ]] && ok "kod dosyasi kurulu: ${KURULU/#$HOME/\~}" \
                   || hata "kod dosyasi yok: $KURULU"

echo
echo "FONKSIYONLAR — tusa basmadan, saf mantik olcumu"

# --- 4) Satirin tamami siliniyor mu -----------------------------------------
SONUC="$(bash -c '
  source "'"$KURULU"'" 2>/dev/null
  READLINE_LINE="cok uzun ve yanlis yazilmis bir komut --flag deger"
  READLINE_POINT=10
  _qf_satir_sil
  printf "[%s|%s]" "$READLINE_LINE" "$READLINE_POINT"
' 2>/dev/null)"
if [[ "$SONUC" == "[|0]" ]]; then
  ok "_qf_satir_sil: 45 karakterlik satir -> bos, imlec 0"
else
  hata "_qf_satir_sil beklenen sonucu vermedi: ${SONUC:-cikti yok}"
fi

# --- 5) Pano yolu: yalnizca secili parca siliniyor mu ------------------------
# Klipper'a bilinen bir metin yazip, onu satirin ORTASINA gomup fonksiyonu
# cagiriyoruz. Yalnizca o parca gitmeli, gerisi durmali.
ETIKET="SILINECEK$RANDOM"
if qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.setClipboardContents "$ETIKET" >/dev/null 2>&1; then
  sleep 0.3
  SONUC="$(bash -c '
    source "'"$KURULU"'" 2>/dev/null
    READLINE_LINE="basta '"$ETIKET"' sonda"
    READLINE_POINT=0
    _qf_secili_sil
    printf "%s" "$READLINE_LINE"
  ' 2>/dev/null)"
  if [[ "$SONUC" == "basta  sonda" ]]; then
    ok "_qf_secili_sil: panodaki parca cikarildi, gerisi korundu"
  elif [[ -z "$SONUC" ]]; then
    hata "_qf_secili_sil satirin TAMAMINI sildi (pano okunamamis olabilir)"
  else
    hata "_qf_secili_sil beklenmeyen sonuc: '$SONUC'"
  fi

  # Pano satirda GECMIYORSA tamamini silmeli
  qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.setClipboardContents "ALAKASIZ$RANDOM" >/dev/null 2>&1
  sleep 0.3
  SONUC="$(bash -c '
    source "'"$KURULU"'" 2>/dev/null
    READLINE_LINE="bu satirda pano metni yok"
    _qf_secili_sil
    printf "%s" "$READLINE_LINE"
  ' 2>/dev/null)"
  [[ -z "$SONUC" ]] \
    && ok "_qf_secili_sil: pano satirda yoksa tamamini siliyor (geri dusus)" \
    || hata "geri dusus calismadi: '$SONUC'"
else
  bilgi "Klipper DBus okunamadi - pano olcumleri atlandi"
fi

echo
echo "TUS BAGLAMALARI"

if [[ -r "$TUSLAR" ]]; then
  ok "tus olcumu yapilmis: $(wc -l < "$TUSLAR") tus"
  sed 's/^/           /' "$TUSLAR"
else
  bilgi "tus olcumu yapilmamis -> bash $KOK/olc-tus.sh"
fi

# bind -q / bind -X etkilesimli kabuk ister
BAGLI="$(bash -ic 'bind -X 2>/dev/null; bind -q kill-whole-line 2>/dev/null' 2>/dev/null)"
grep -q "_qf_satir_sil" <<<"$BAGLI" \
  && ok "_qf_satir_sil bir tusa bagli" \
  || bilgi "_qf_satir_sil hicbir tusa bagli degil (olc-tus.sh calistirilmamis olabilir)"

grep -qE "kill-whole-line can be invoked via.*C-u|\\\\C-u" <<<"$BAGLI" \
  && ok "Ctrl+U -> kill-whole-line (satirin tamami)" \
  || bilgi "Ctrl+U baglamasi dogrulanamadi"

echo
echo "SONUC: $gecti gecti, $kaldi kaldi"
echo
echo "Elle deneme (yeni bir terminalde):"
echo "  1. Uzun bir komut yaz, CALISTIRMA"
echo "  2. Ctrl+U        -> satir komple gitmeli"
echo "  3. Tekrar yaz, bir parcasini fareyle sec, Ctrl+C"
echo "     sonra Ctrl+Shift+Delete -> yalnizca o parca gitmeli"
exit $(( kaldi > 0 ))