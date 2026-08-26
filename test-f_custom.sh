#!/usr/bin/env bash
# test-f_custom.sh — "kod dogru gorunuyor" kanit degildir. Bu script derlenmis
# keymap'i ayristirip iddialari SAYIYLA dogrular.
#
# Kullanim:
#   bash test-f_custom.sh                 # kurulu sistemi olcer
#   bash test-f_custom.sh --kok /tmp/x    # sanal kokte olcer (kurulumdan once)
#
# Olcum 1: 32 Turkce harfin her biri TAM OLARAK BIR tusta, seviye 1'de mi?
# Olcum 2: 32 harf tusunun AltGr katmani (seviye 3-4) tr(basic) ile BIREBIR ayni mi?
#          -> "AltGr+Q hala @" iddiasinin calistirilabilir kaniti
# Olcum 3: Harf OLMAYAN her tus tr(basic) ile birebir ayni mi?
#          -> sayi sirasi, TLDE, BKSL, AB10, LSGT, keypad... hepsi tek testte
# Olcum 4: 32 harfin konumu tr(f) ile ayni mi? Tek sapma x@<AB09> mu?

set -uo pipefail
XKB_KOK=""
[[ "${1:-}" == "--kok" ]] && XKB_KOK="$2"

if [[ -n "$XKB_KOK" ]]; then export XKB_CONFIG_ROOT="$XKB_KOK"; fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

xkbcli compile-keymap --layout tr                    > "$TMP/q.keymap" 2>"$TMP/err" \
  || { echo "HATA: tr(Q) derlenmiyor"; cat "$TMP/err"; exit 1; }
xkbcli compile-keymap --layout tr --variant f        > "$TMP/f.keymap" 2>/dev/null
xkbcli compile-keymap --layout tr --variant f_custom > "$TMP/c.keymap" 2>"$TMP/err" \
  || { echo "HATA: tr(f_custom) derlenmiyor"; cat "$TMP/err"; exit 1; }

/usr/bin/python3 - "$TMP/q.keymap" "$TMP/f.keymap" "$TMP/c.keymap" <<'PYEOF'
import re, sys

TEK   = re.compile(r'key\s+<(\w+)>\s*\{\s*\[([^\]]*)\]\s*\}\s*;')
COKLU = re.compile(r'key\s+<(\w+)>\s*\{\s*(?:type=\s*"([^"]*)"\s*,\s*)?'
                   r'symbols\[\d+\]=\s*\[([^\]]*)\]\s*\}\s*;', re.S)

def ayristir(yol):
    metin = open(yol, encoding='utf-8').read()
    t = {}
    for ad, s in TEK.findall(metin):
        t[ad] = [x.strip() for x in s.split(',')]
    for ad, _tip, s in COKLU.findall(metin):
        t[ad] = [x.strip() for x in s.split(',')]
    return t

Q, F, C = map(ayristir, sys.argv[1:4])

HARFLER = ['a','b','c','ccedilla','d','e','f','g','gbreve','h','idotless','i',
           'j','k','l','m','n','o','odiaeresis','p','q','r','s','scedilla','t',
           'u','udiaeresis','v','w','x','y','z']
assert len(HARFLER) == 32

HARF_TUSLARI = ([f'AD{i:02d}' for i in range(1, 13)] +
                [f'AC{i:02d}' for i in range(1, 12)] +
                [f'AB{i:02d}' for i in range(1, 10)])
KAYNAK = {k: k for k in HARF_TUSLARI}
KAYNAK['AB09'] = 'BKSL'          # x, F'de BKSL'de duruyor

gecti = basarisiz = 0
def bildir(ad, tamam, detay=''):
    global gecti, basarisiz
    if tamam:
        gecti += 1;      print(f'  [ok]   {ad}')
    else:
        basarisiz += 1;  print(f'  [HATA] {ad}\n{detay}')

print('\nOLCUM 1 — 32 Turkce harf, seviye 1, tekrarsiz')
bulunan = {}
for tus, sems in C.items():
    if sems and sems[0] in HARFLER:
        bulunan.setdefault(sems[0], []).append(tus)
eksik  = [h for h in HARFLER if h not in bulunan]
tekrar = {h: v for h, v in bulunan.items() if len(v) > 1}
bildir(f'{len(bulunan)}/32 harf var, {len(tekrar)} tekrar',
       not eksik and not tekrar,
       f'    eksik: {eksik}\n    tekrar: {tekrar}')

print('\nOLCUM 2 — AltGr katmani (seviye 3-4) tr(basic) ile ayni mi')
fark = [(t, Q[t][2:4], C[t][2:4]) for t in HARF_TUSLARI
        if Q.get(t, [])[2:4] != C.get(t, [])[2:4]]
bildir(f'32 harf tusu, {len(fark)} fark', not fark,
       '\n'.join(f'    <{t}>  Q={q}  f_custom={c}' for t, q, c in fark))
ad01 = C.get('AD01', [])
bildir(f'AltGr + fiziksel Q tusu <AD01> = {ad01[2] if len(ad01)>2 else "?"}',
       len(ad01) > 2 and ad01[2] == 'at')

print('\nOLCUM 3 — harf OLMAYAN her tus tr(basic) ile birebir ayni mi')
harf_kume = set(HARF_TUSLARI)
fark = [(t, Q[t], C.get(t)) for t in Q if t not in harf_kume and Q[t] != C.get(t)]
bildir(f'{len(Q)-len(harf_kume)} sembol/diger tus, {len(fark)} fark', not fark,
       '\n'.join(f'    <{t}>  Q={q}  f_custom={c}' for t, q, c in fark[:20]))

print('\nOLCUM 4 — harf konumlari tr(f) ile ayni mi (tek sapma x@<AB09>)')
fark = [(t, F.get(KAYNAK[t], [])[0:2], C.get(t, [])[0:2]) for t in HARF_TUSLARI
        if F.get(KAYNAK[t], [])[0:2] != C.get(t, [])[0:2]]
bildir(f'32 harf tusu, {len(fark)} fark', not fark,
       '\n'.join(f'    <{t}>  F={f}  f_custom={c}' for t, f, c in fark))
bildir("x, F'de <BKSL>'de -> bizde <AB09>'da",
       F.get('BKSL', [''])[0] == 'x' and C.get('AB09', [''])[0] == 'x')
bildir("<BKSL> Q'daki virgulu koruyor",
       C.get('BKSL') == Q.get('BKSL') and C.get('BKSL', [''])[0] == 'comma')

print(f'\nSONUC: {gecti} gecti, {basarisiz} kaldi')
sys.exit(1 if basarisiz else 0)
PYEOF
