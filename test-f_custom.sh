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

def tipler(yol):
    """tus adi -> tip adi"""
    metin = open(yol, encoding='utf-8').read()
    return dict(re.findall(r'key\s+<(\w+)>\s*\{\s*type=\s*"([^"]*)"', metin))

def ham(yol):
    return open(yol, encoding='utf-8').read()

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

print("\nOLCUM 5 — Ctrl seviyesi (5) o tusun Q'daki harfi mi")
# Bu, "Ctrl+<harf> kisayollari iki duzende de ayni fiziksel tusta" iddiasinin
# calistirilabilir kaniti.
fark = []
for tus in HARF_TUSLARI:
    q1 = Q.get(tus, [''])[0]
    sems = C.get(tus, [])
    c5 = sems[4] if len(sems) > 4 else '(seviye 5 YOK)'
    if c5 != q1:
        fark.append((tus, q1, c5))
bildir(f'32 harf tusu, {len(fark)} fark', not fark,
       '\n'.join(f'    <{t}>  Q seviye1={q}  f_custom seviye5={c}' for t, q, c in fark))

# En kritik ikili: Q'nun C ve V tuslari
ab03 = C.get('AB03', [])
ab04 = C.get('AB04', [])
bildir("Q'nun C tusunda (AB03): yazarken 'v', Ctrl ile 'c'",
       len(ab03) > 4 and ab03[0] == 'v' and ab03[4] == 'c')
bildir("Q'nun V tusunda (AB04): yazarken 'c', Ctrl ile 'v'",
       len(ab04) > 4 and ab04[0] == 'c' and ab04[4] == 'v')

print('\nOLCUM 6 — Control uygulamaya iletiliyor mu (preserve)')
# preserve[] olmazsa Control bir seviye secici olarak "tuketilir" ve uygulama
# sadece "c" gorur, "Ctrl+C" degil. Bu satir olmadan tum numara ise yaramaz.
metin_c = ham(sys.argv[3])
tip_blok = re.search(r'type "QF_CTRL_ALPHABETIC" \{(.*?)\n\t\};', metin_c, re.S)
govde = tip_blok.group(1) if tip_blok else ''
bildir('QF_CTRL_ALPHABETIC tipi keymap\'de var', bool(tip_blok))
bildir('preserve[Control]= Control satiri var',
       'preserve[Control]= Control' in govde,
       '    preserve yoksa Control tuketilir, uygulama Ctrl gormez')
bildir('Control seviye 5\'i seciyor', 'map[Control]= 5' in govde)

tip_haritasi = tipler(sys.argv[3])
yanlis_tip = [t for t in HARF_TUSLARI if tip_haritasi.get(t) != 'QF_CTRL_ALPHABETIC']
bildir(f'32 harf tusunun hepsi QF_CTRL_ALPHABETIC, {len(yanlis_tip)} sapma',
       not yanlis_tip, f'    {yanlis_tip[:8]}')

print(f'\nSONUC: {gecti} gecti, {basarisiz} kaldi')
sys.exit(1 if basarisiz else 0)
PYEOF
