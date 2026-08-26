#!/usr/bin/env bash
# 08-ctrl-a-sil.sh — Ctrl+A'yi "yazdigini komple sil" yapar.
#
#   bash ~/klavye/08-ctrl-a-sil.sh            # ac
#   bash ~/klavye/08-ctrl-a-sil.sh --kaldir   # geri al
#
# NE DEGISIR
#   Ctrl+A        terminalde: yazdigin satirin TAMAMINI siler
#   Ctrl+Shift+A  Konsole'da: kaydirma tamponunu secer (eski Ctrl+A islevi)
#
# NEDEN AYRI BIR SCRIPT
# Kullanicinin tarif ettigi akis "Ctrl+A, sonra sil" idi. Iki tusla da
# yapilabiliyor (Ctrl+A ile sec, Shift+Delete ile sil) ama tek tusla daha
# dogrudan. Bunun bedeli var: Ctrl+A artik Konsole'da secmiyor. Bu bir tercih
# meselesi oldugu icin varsayilan degil, ACIK bir secim olarak duruyor.
#
# Ctrl+A duzenden bagimsizdir: QF_CTRL_ALPHABETIC sayesinde F duzeninde de
# Q'nun A tusunda kalir.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISARET="${XDG_STATE_HOME:-$HOME/.local/state}/qf-ctrl-a-sil"
SEMA="$HOME/.local/share/konsole/shortcuts/VSCode"
KALDIR=0
[[ "${1:-}" == "--kaldir" ]] && KALDIR=1

# --- Konsole semasinda select-all'u tasi -----------------------------------
if [[ -f "$SEMA" ]]; then
  /usr/bin/python3 - "$SEMA" "$KALDIR" <<'PYEOF'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1]); kaldir = sys.argv[2] == '1'
t = p.read_text(encoding='utf-8')
yeni_tus = 'Ctrl+A' if kaldir else 'Ctrl+Shift+A'
t2 = re.sub(r'(<Action name="select-all" shortcut=")[^"]*(")',
            lambda m: m.group(1) + yeni_tus + m.group(2), t)
if t2 != t:
    p.write_text(t2, encoding='utf-8')
    print(f'  Konsole select-all -> {yeni_tus}')
else:
    print('  Konsole semasinda select-all bulunamadi (atlandi)')
PYEOF
else
  echo "  [!] Konsole semasi yok: $SEMA"
  echo "      Once: bash $KOK/04-konsole-kisayol.sh"
fi

# --- readline tarafi: isaret dosyasi ---------------------------------------
if [[ $KALDIR -eq 1 ]]; then
  rm -f "$ISARET"
  echo "  Ctrl+A readline baglamasi kaldirildi"
  echo
  echo "Geri alindi. Yeni bir terminal ac ve Konsole'u yeniden baslat."
  exit 0
fi

mkdir -p "$(dirname "$ISARET")"
: > "$ISARET"
echo "  Ctrl+A -> _qf_satir_sil (isaret: ${ISARET/#$HOME/\~})"

echo
echo "Yapilacaklar:"
echo "  1. Konsole'u TAMAMEN KAPATIP yeniden ac (sema acilista okunuyor)"
echo "  2. Yeni terminalde:  uzun bir komut yaz, Ctrl+A'ya bas -> gitmeli"
echo
echo "Geri almak:  bash $KOK/08-ctrl-a-sil.sh --kaldir"