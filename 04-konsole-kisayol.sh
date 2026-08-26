#!/usr/bin/env bash
# 04-konsole-kisayol.sh — Konsole'a VS Code tarzi kisayol semasi uygular.
#
#   bash ~/klavye/04-konsole-kisayol.sh            (sudo GEREKMEZ)
#   bash ~/klavye/04-konsole-kisayol.sh --goster   (yazmadan ne yapacagini soyle)
#   bash ~/klavye/04-konsole-kisayol.sh --keytab   (SIGINT katman 2'yi de kur)
#   bash ~/klavye/04-konsole-kisayol.sh --kaldir
#
# ONCE ELLE YAPILACAK TEK ADIM:
#   Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir -> Semalari Yonet
#   -> Yeni Sema -> ad: VSCode -> Kaydet
#
# MEKANIZMA (olculdu, tahmin degil):
# Konsole 26.08 konsoleui.rc'yi diske koymuyor, Qt kaynagina gomuyor. "Yeni Sema"
# dedigin an IKI ayri yere dosya yaziyor:
#
#   1) ~/.local/share/kxmlgui5/konsole/{konsoleui,sessionui}.rc
#      Bunlar menu yapisi. ICLERINDE TUM GERCEK AKSIYON ADLARI VAR - biz
#      buradan okuyup dogruluyoruz. Ama kisayol yazmak icin DOGRU YER DEGIL.
#
#   2) ~/.local/share/konsole/shortcuts/<SemaAdi>          <-- ASIL HEDEF
#      Ilk halinde bos: <gui><ActionProperties/></gui>
#      KShortcutSchemesHelper semayi QStandardPaths::AppDataLocation altinda
#      "shortcuts/<ad>" olarak arar. Konsole icin bu ~/.local/share/konsole.
#      Kisayol ezmeleri ISTE BURAYA yazilir.
#
# Ve konsolerc'de [Shortcut Schemes] Current Scheme=<SemaAdi> olmali; olmazsa
# sema hic yuklenmez.
#
# ONCE bunu ui.rc dosyalarina yazmayi denedik: hicbir sey olmadi, sessizce.
# Aksiyon adlari TAHMIN EDILMIYOR - ui.rc'lerden okunup dogrulaniyor.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEMA_DIZIN="$HOME/.local/share/kxmlgui5/konsole"      # aksiyon adlari burada
SEMA_DOSYA="$HOME/.local/share/konsole/shortcuts/VSCode"  # kisayollar BURAYA
KEYTAB_DIZIN="$HOME/.local/share/konsole"
KEYTAB="$KEYTAB_DIZIN/VSCode.keytab"
SEMA_ADI="VSCode"
KEYTAB_KUR=0; KALDIR=0; GOSTER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keytab) KEYTAB_KUR=1; shift ;;
    --kaldir) KALDIR=1; shift ;;
    --goster) GOSTER=1; shift ;;
    *) echo "bilinmeyen secenek: $1" >&2; exit 2 ;;
  esac
done

if [[ $KALDIR -eq 1 ]]; then
  rm -rf "$SEMA_DIZIN" "$KEYTAB" "$SEMA_DOSYA"
  kwriteconfig6 --file konsolerc --group "Shortcut Schemes" --key "Current Scheme" --delete 2>/dev/null || true
  echo "kaldirildi. Konsole'u yeniden baslat."
  exit 0
fi

if [[ ! -f "$SEMA_DIZIN/konsoleui.rc" || ! -f "$SEMA_DIZIN/sessionui.rc" ]]; then
  cat <<'EOF'
HATA: sema dosyalari yok.

Once su adimi ELLE yap (15 saniye):

  Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir
          -> Semalari Yonet (Manage Schemes)
          -> Yeni Sema (New Scheme...)   ad: VSCode
          -> Kaydet (Save Scheme)

Bu, Konsole'un TUM gercek aksiyon adlarini iceren su iki dosyayi uretir:
  ~/.local/share/kxmlgui5/konsole/konsoleui.rc
  ~/.local/share/kxmlgui5/konsole/sessionui.rc

Sonra bu scripti tekrar calistir.
EOF
  exit 2
fi

/usr/bin/python3 - "$SEMA_DIZIN" "$SEMA_DOSYA" "$GOSTER" <<'PYEOF'
import json, pathlib, re, sys, datetime

dizin, sema_dosya, goster = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3] == '1'

# (aksiyon_adi, kisayol, insan okunur ad)
# Ctrl+Ins / Shift+Ins KASTEN ekli: kisayol "fiziksel tus" degil, "o harfi
# ureten tus" demektir. Q -> F gecince 'c' ve 'v' harfleri yer degistiriyor
# (olculdu: Q'da AB03=c AB04=v, f_custom'da tam tersi). Insert tusu hicbir
# duzende tasinmaz -> her iki duzende de ayni yerde.
# Kisayollar LISTE olarak tutuluyor ve AYIRICI tek yerde uygulanıyor.
#
# DUZEN BAGIMSIZLIGI (olculdu):
# Bir kisayol "su fiziksel tus" degil, "o harfi ureten tus" demektir. Q ve
# f_custom arasinda 32 harften 30'u yer degistiriyor (sadece p ve l sabit).
# Harf OLMAYAN 453 tusun hepsi ayni yerde. Bu yuzden kritik eylemlere harf
# olmayan bir alternatif de baglaniyor:
#     Ctrl+Insert  kopyala      Shift+Insert  yapistir      Ctrl+F4  sekmeyi kapat
#     F3 / Shift+F3  bul ileri/geri  (islev tuslari zaten sabit)
# Ctrl+C'yi iki duzende AYNI fiziksel tusa oturtmak imkansiz: F modunda o tus
# 'v' uretiyor ve Ctrl+V'nin yapistir kalmasi gerekiyor.
#
# NEDEN: Qt'nin QKeySequence::listFromString ayiricisi "; " - noktali virgul
# ARTI BOSLUK. Boslugu koymazsan Qt tum dizgeyi tek bir kombinasyon sanip
# ayristiramiyor ve aksiyona BOS kisayol veriyor. Olculdu (PySide6 ile):
#     "Ctrl+C;Ctrl+Ins"   -> 1 adet ['']            <- kisayol yok olur
#     "Ctrl+C; Ctrl+Ins"  -> 2 adet ['Ctrl+C','Ctrl+Ins']
# Tam da bu yuzden Ctrl+A calisirken (tek kisayol, ayirici yok) Ctrl+C
# hicbir sey yapmiyordu. Listeyi burada birlestirerek hata tekrarlanamaz.
AYIRICI = '; '
ISTEKLER = [
    ('edit_copy',      ['Ctrl+C', 'Ctrl+Ins'],                    'Kopyala'),
    ('edit_paste',     ['Ctrl+V', 'Ctrl+Shift+V', 'Shift+Ins'],   'Yapıştır'),
    ('select-all',     ['Ctrl+A'],                                'Tümünü seç'),
    ('edit_find',      ['Ctrl+F'],                                'Bul'),
    ('edit_find_next', ['F3'],                                    'Sonrakini bul'),
    ('edit_find_prev', ['Shift+F3'],                              'Öncekini bul'),
    ('close-session',  ['Ctrl+W', 'Ctrl+F4'],                     'Sekmeyi kapat'),
    ('new-tab',        ['Ctrl+T'],                                'Yeni sekme'),
]
ISTEKLER = [(ad, AYIRICI.join(tuslar), insan) for ad, tuslar, insan in ISTEKLER]

# 1) Aksiyon adlarini ui.rc dosyalarindan DOGRULA (tahmin yok).
mevcut = {}
for rc in ('konsoleui.rc', 'sessionui.rc'):
    p = dizin / rc
    if not p.exists():
        continue
    for ad in re.findall(r'<Action[^>]*\bname="([^"]+)"', p.read_text(encoding='utf-8')):
        mevcut.setdefault(ad, rc)

rapor, hata, gecerli = [], 0, []
for ad, tus, insan in ISTEKLER:
    if ad in mevcut:
        gecerli.append((ad, tus, insan))
        rapor.append((mevcut[ad], ad, tus, insan, 'hazir' if goster else 'yazildi'))
    else:
        rapor.append(('?', ad, tus, insan, 'AD YOK'))
        hata += 1

print(f"{'BULUNDUGU YER':<16}{'AKSIYON':<18}{'KISAYOL':<32}{'NE':<16}DURUM")
print('-' * 96)
for yer, ad, tus, insan, durum in rapor:
    print(f'{yer:<16}{ad:<18}{tus:<32}{insan:<16}{durum}')

if goster:
    print(f"\nHEDEF DOSYA: {sema_dosya}")
    sys.exit(1 if hata else 0)

# 2) Sema dosyasini yaz. Tek <gui>, isimsiz -> tum istemcilere uygulanir.
sema_dosya.parent.mkdir(parents=True, exist_ok=True)
if sema_dosya.exists():
    damga = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    sema_dosya.with_name(f'{sema_dosya.name}.oncesi-{damga}').write_text(
        sema_dosya.read_text(encoding='utf-8'), encoding='utf-8')

govde = '\n'.join(f'        <Action name="{ad}" shortcut="{tus}"/>' for ad, tus, _ in gecerli)
sema_dosya.write_text(f'<gui>\n    <ActionProperties>\n{govde}\n    </ActionProperties>\n</gui>\n',
                      encoding='utf-8')
print(f'\nyazildi: {sema_dosya}')

# 3) ui.rc'lerdeki bizim eklediklerimizi TEMIZLE. Kisayollarin yeri orasi degil;
#    birakirsak hangi katmanin gecerli oldugu belirsizlesir.
for rc in ('konsoleui.rc', 'sessionui.rc'):
    p = dizin / rc
    if not p.exists():
        continue
    metin = p.read_text(encoding='utf-8')
    temiz, n = re.subn(r'<ActionProperties(?:\s[^>]*?)?\s*(?:/>|>.*?</ActionProperties>)',
                       '<ActionProperties/>', metin, flags=re.S)
    if n and temiz != metin:
        p.write_text(temiz, encoding='utf-8')
        print(f'temizlendi: {rc} (ActionProperties bosaltildi)')

kayit = [(insan, ad, tus) for _y, ad, tus, insan, durum in rapor if durum == 'yazildi']
(dizin / 'kesfedilen-aksiyonlar.json').write_text(
    json.dumps(kayit, ensure_ascii=False, indent=2), encoding='utf-8')

sys.exit(1 if hata else 0)
PYEOF
DURUM=$?

if [[ $GOSTER -eq 1 ]]; then
  echo
  echo "(--goster kipi: hicbir sey yazilmadi)"
  exit 0
fi

# Sema dosyasi artik DOLU, dolayisiyla Current Scheme AYARLANMALI.
# Ayarlanmazsa KShortcutSchemesHelper semayi hic yuklemez.
kwriteconfig6 --file konsolerc --group "Shortcut Schemes" --key "Current Scheme" "$SEMA_ADI"
echo
echo "konsolerc -> [Shortcut Schemes] Current Scheme=$SEMA_ADI"

# ---------------------------------------------------------- SIGINT katman 2
if [[ $KEYTAB_KUR -eq 1 ]]; then
  echo
  echo "UYARI: Konsole'un varsayilan tus tablosu C++'ta gomulu; diskte"
  echo "default.keytab YOK. Keytab dosyalari KATMANLI DEGIL, standalone."
  echo "Once katman 1 (secim-gecisi) olculmeli."
  read -r -p "Yine de kurulsun mu? (e/H) " c
  if [[ "${c,,}" == "e" ]]; then
    mkdir -p "$KEYTAB_DIZIN"
    cp "$KOK/payload/VSCode.keytab" "$KEYTAB"
    echo "kuruldu -> $KEYTAB"
    echo "Konsole -> Ayarlar -> Gecerli Profili Duzenle -> Klavye -> VSCode sec"
  fi
fi

# Widget'in sag tik yardim panelini tazele.
if [[ -d "$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle" ]]; then
  echo
  bash "$KOK/uret-yardim.sh"
fi

echo
echo "Konsole'u TAMAMEN KAPATIP yeniden ac (sema oturum basinda okunuyor)."
exit $DURUM