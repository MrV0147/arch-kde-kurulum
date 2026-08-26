#!/usr/bin/env bash
# uret-f_custom.sh — tr(f_custom) XKB blogunu DERLENMIS keymap'lerden uretir.
#
# Neden elle yazilmiyor: 32 tus x 4 seviye = 128 sembol adi. Elle transkripsiyon
# hata daveti. Ayrica kaynak dosyada GORUNMEYEN seviyeler var: ornegin tr(basic)
# icinde <AD11> sadece {[gbreve, Gbreve]} olarak yaziyor ama derlenmis keymap'te
# seviye 3-4 latin'den mirasla dolu (dead_diaeresis, dead_abovering). Kaynagi
# okusaydik bunlari kaybederdik.
#
# KURAL:
#   seviye 1-2 (harf, buyuk harf)     -> tr(f)'den      (F klavye harf konumlari)
#   seviye 3-4 (AltGr, AltGr+Shift)   -> tr(basic)'ten  (Q klavye sembol katmani)
#   seviye 5   (Control basiliyken)   -> tr(basic)'ten  (Q klavye HARFI)
#   sembol tuslari                     -> hic dokunulmaz (include "tr(basic)")
#
# 5. SEVIYE NEDEN VAR:
# Bir kisayol "su fiziksel tus" degil "o harfi ureten tus" demektir. F duzenine
# gecince 32 harften 30'u yer degistiriyor - Ctrl+C ile Ctrl+V birbirinin
# yerine geciyordu. Cozum: Control'u bir SEVIYE SECICI yapmak. Control
# basiliyken tus, o fiziksel konumun Q'daki harfini uretiyor; boylece butun
# Ctrl+<harf> kisayollari iki duzende de AYNI fiziksel tusta kaliyor.
# preserve[Control] sayesinde Control yine de uygulamaya iletiliyor - yani
# uygulama gercekten "Ctrl+C" goruyor, sadece "c" degil.
# Ayni numarayi upstream de kullaniyor: types/pc -> PC_CONTROL_SUPER_LEVEL2.
# Bu XKB katmaninda oldugu icin Konsole'la sinirli degil: Firefox, VS Code,
# her yerde gecerli.
#
# Cikti: payload/tr-f_custom.xkb

set -euo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CIKTI="$KOK/payload/tr-f_custom.xkb"

command -v xkbcli >/dev/null || { echo "HATA: xkbcli yok (paket: libxkbcommon)"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

xkbcli compile-keymap --layout tr             > "$TMP/q.keymap"
xkbcli compile-keymap --layout tr --variant f > "$TMP/f.keymap"

/usr/bin/python3 - "$TMP/q.keymap" "$TMP/f.keymap" "$CIKTI" <<'PYEOF'
import re, sys

q_yol, f_yol, cikti_yol = sys.argv[1:4]

# ---------------------------------------------------------------- ayristirma
# Derlenmis keymap'te tus tanimi iki bicimde gelir:
#   key <AD05>  {  [ o, O, ocircumflex, Ocircumflex ] };
#   key <AD04>  {
#           type= "FOUR_LEVEL_SEMIALPHABETIC",
#           symbols[1]= [ idotless, I, paragraph, VoidSymbol ]
#   };
TEK   = re.compile(r'key\s+<(\w+)>\s*\{\s*\[([^\]]*)\]\s*\}\s*;')
COKLU = re.compile(r'key\s+<(\w+)>\s*\{\s*(?:type=\s*"([^"]*)"\s*,\s*)?'
                   r'symbols\[\d+\]=\s*\[([^\]]*)\]\s*\}\s*;', re.S)

def ayristir(yol):
    metin = open(yol, encoding='utf-8').read()
    tablo = {}
    for ad, sems in TEK.findall(metin):
        tablo[ad] = (None, [s.strip() for s in sems.split(',')])
    for ad, tip, sems in COKLU.findall(metin):
        tablo[ad] = (tip or None, [s.strip() for s in sems.split(',')])
    return tablo

Q = ayristir(q_yol)
F = ayristir(f_yol)

def sev(tablo, ad, n):
    """n. seviyeyi dondurur (1 tabanli); tanimsizsa VoidSymbol."""
    if ad not in tablo:
        raise SystemExit(f"HATA: <{ad}> derlenmis keymap'te yok")
    sems = tablo[ad][1]
    return sems[n-1] if n <= len(sems) else 'VoidSymbol'

# ------------------------------------------------------------------ harita
# hedef fiziksel tus -> tr(f) icinde harfin durdugu tus
# AD01..AD12, AC01..AC11, AB01..AB08 dogrudan ayni tus.
# AB09 istisnasi: F'de 'x' <BKSL>'de durur, ama <BKSL> bizde Q'nun virgulu
# olarak kalacak. F'de <AB09> sembol (nokta) oldugu icin o tus harften bosalir;
# 'x' oraya yerlesir. Boylece 32 harfin hepsi tam, hicbir Q sembolu kaybolmaz.
HARITA = {}
for i in range(1, 13):
    HARITA[f'AD{i:02d}'] = f'AD{i:02d}'
for i in range(1, 12):
    HARITA[f'AC{i:02d}'] = f'AC{i:02d}'
for i in range(1, 9):
    HARITA[f'AB{i:02d}'] = f'AB{i:02d}'
HARITA['AB09'] = 'BKSL'          # <- x buradan geliyor

assert len(HARITA) == 32, len(HARITA)

def alfabetik_cift(alt, ust):
    """(alt,ust) bir kucuk/buyuk harf cifti mi? -> CapsLock 3-4. seviyeye de
    uygulanmali mi sorusunun yaniti."""
    if alt.startswith('dead_') or alt in ('VoidSymbol', 'NoSymbol'):
        return False
    return bool(alt) and alt[0].islower() and ust == alt[0].upper() + alt[1:]

satirlar = []
for hedef in sorted(HARITA, key=lambda k: (k[:2], int(k[2:]))):
    kaynak = HARITA[hedef]
    s1, s2 = sev(F, kaynak, 1), sev(F, kaynak, 2)   # harf: F'den
    s3, s4 = sev(Q, hedef, 3),  sev(Q, hedef, 4)    # AltGr: Q'dan, ayni fiziksel tus
    s5     = sev(Q, hedef, 1)                       # Ctrl: bu tusun Q'daki harfi
    # Tip her tusta ACIKCA yazilir: include "tr(basic)" sonrasi tus yeniden
    # tanimlanirken eski tusun tipi sizabilir (orn. <AC11> Q'da 'i' icin
    # SEMIALPHABETIC'ti, bizde 's' oluyor). Acik yazinca sizma imkansiz.
    # Tip artik her zaman QF_CTRL_ALPHABETIC: 5. seviyeyi Control seciyor.
    # (Tipin tanimi types/complete icine 03-xkb-kur.sh tarafindan enjekte edilir.)
    satirlar.append(
        f'    key <{hedef}> {{ type[group1] = "QF_CTRL_ALPHABETIC",\n'
        f'                 [ {s1:>14}, {s2:>14}, {s3:>14}, {s4:>14}, {s5:>14} ]}};'
    )

blok = f'''
// ---------------------------------------------------------------------------
// Turkish F-letters / Q-symbols hybrid.
// URETILDI: klavye/uret-f_custom.sh  (elle duzenleme, bir sonraki uretimde silinir)
//
//   seviye 1-2 -> tr(f)      : harf konumlari F klavye
//   seviye 3-4 -> tr(basic)  : AltGr katmani Q klavyeyle BIREBIR ayni
//   seviye 5   -> tr(basic)  : Control basiliyken o tusun Q'daki harfi, yani
//                              butun Ctrl+<harf> kisayollari Q konumunda kalir
//   sembol/sayi tuslari      : include "tr(basic)" ile oldugu gibi
//
// Tek bilincli sapma: F'de <BKSL>'de duran 'x', burada <AB09>'a alindi; cunku
// <BKSL> Q'da virgul/noktali virgul ve o sembol korunuyor. F'de <AB09> zaten
// harf degil (nokta) oldugu icin cakisma yok. 32 harfin hepsi tam.
// ---------------------------------------------------------------------------
partial alphanumeric_keys
xkb_symbols "f_custom" {{

    include "tr(basic)"

    name[Group1]="Turkish (F letters, Q symbols)";

{chr(10).join(satirlar)}
}};
'''

open(cikti_yol, 'w', encoding='utf-8').write(blok.lstrip('\n'))
print(f"uretildi: {cikti_yol}  ({len(satirlar)} tus)")

# Uretim sirasinda hemen kendi kendini denetle: 32 harf, tekrarsiz.
harfler = [sev(F, HARITA[h], 1) for h in HARITA]
if len(set(harfler)) != 32:
    tekrar = [h for h in set(harfler) if harfler.count(h) > 1]
    raise SystemExit(f"HATA: harfler tekrarsiz degil: {tekrar}")
print(f"kendi denetimi: {len(set(harfler))}/32 harf, tekrar yok")
PYEOF
