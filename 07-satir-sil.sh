#!/usr/bin/env bash
# 07-satir-sil.sh — satir duzenleme kisayollarini kurar.
#
#   bash ~/klavye/07-satir-sil.sh            (sudo GEREKMEZ)
#   bash ~/klavye/07-satir-sil.sh --kaldir
#
# ~/.bashrc'ye TEK SATIR 'source' ekler; asil kod ayri dosyada durur.
# Boylece .bashrc'de en fazla iki satirlik bir iz kalir ve geri alma tek
# satiri silmekten ibarettir - oturum acilisini bozacak bir sey yok.
#
# POLITIKA NOTU: bu proje simdiye kadar ~/.bashrc'ye ve stty'ye HIC dokunmadi,
# bu bilincli bir ilkeydi. 'bind -x' bir bash builtin'i oldugu icin .inputrc'ye
# yazilamiyor; READLINE_LINE'a erisim de yalnizca oradan mumkun. Yani .bashrc
# gerekiyor. stty yine DEGISMIYOR.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAYNAK="$KOK/payload/bashrc-qf.sh"
HEDEF="$HOME/.local/share/qf-klavye/bashrc-qf.sh"
BASHRC="$HOME/.bashrc"
BAS="# >>> qf-klavye satir duzenleme (klavye/07-satir-sil.sh) >>>"
BIT="# <<< qf-klavye BITIS <<<"
KALDIR=0
[[ "${1:-}" == "--kaldir" ]] && KALDIR=1

/usr/bin/python3 - "$BASHRC" "$BAS" "$BIT" "$HEDEF" "$KALDIR" <<'PYEOF'
import pathlib, re, sys, datetime

bashrc, bas, bit, hedef, kaldir = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5] == '1'
p = pathlib.Path(bashrc)
metin = p.read_text(encoding='utf-8') if p.exists() else ''

# Once eskiyi sok (idempotent)
yeni = re.sub(re.escape(bas) + r'.*?' + re.escape(bit) + r'\n?', '', metin, flags=re.S)

if not kaldir:
    blok = f'{bas}\n[[ -r "{hedef}" ]] && source "{hedef}"\n{bit}\n'
    yeni = yeni.rstrip('\n') + '\n\n' + blok
else:
    yeni = yeni.rstrip('\n') + '\n'

if yeni != metin:
    damga = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    p.with_name(f'.bashrc.qf-oncesi-{damga}').write_text(metin, encoding='utf-8')
    p.write_text(yeni, encoding='utf-8')
    print(f'  .bashrc {"temizlendi" if kaldir else "guncellendi"} (yedek: .bashrc.qf-oncesi-{damga})')
else:
    print('  .bashrc zaten istenen halde')
PYEOF

if [[ $KALDIR -eq 1 ]]; then
  rm -f "$HEDEF"
  rmdir "$(dirname "$HEDEF")" 2>/dev/null || true
  rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"
  echo "kaldirildi. Yeni bir terminal ac."
  exit 0
fi

mkdir -p "$(dirname "$HEDEF")"
cp "$KAYNAK" "$HEDEF"
echo "  kod kuruldu -> $HEDEF"

TUSLAR="${XDG_STATE_HOME:-$HOME/.local/state}/qf-tuslar.conf"
echo
if [[ -r "$TUSLAR" ]]; then
  echo "  olculmus tuslar:"
  sed 's/^/    /' "$TUSLAR"
else
  echo "  [!] Tus olcumu YAPILMAMIS. Su an yalnizca Ctrl+U ve gecmis aramasi"
  echo "      calisir. Shift+Delete gibi tuslar icin once:"
  echo "        bash $KOK/olc-tus.sh"
fi

echo
echo "Yeni bir terminal ac, sonra:  bash $KOK/test-satir-sil.sh"