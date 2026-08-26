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
# dedigin an ~/.local/share/kxmlgui5/konsole/ altina IKI dosya yaziyor:
#     konsoleui.rc   -> pencere duzeyi aksiyonlar (new-tab, close-window...)
#     sessionui.rc   -> oturum duzeyi aksiyonlar (edit_copy, edit_paste...)
# ve her ikisinin sonuna BOS bir <ActionProperties scheme="VSCode"/> koyuyor.
# Kisayol ezmeleri iste o elemanin ICINE yaziliyor. Bu script onu dolduruyor.
#
# Aksiyon adlari TAHMIN EDILMIYOR - yukaridaki dosyalardan okunuyor ve
# yazmadan once "bu ad gercekten var mi" diye DOGRULANIYOR.

set -uo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEMA_DIZIN="$HOME/.local/share/kxmlgui5/konsole"
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
  rm -rf "$SEMA_DIZIN" "$KEYTAB"
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

/usr/bin/python3 - "$SEMA_DIZIN" "$SEMA_ADI" "$GOSTER" <<'PYEOF'
import json, pathlib, re, sys, datetime

dizin, sema, goster = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3] == '1'

# dosya -> [(aksiyon_adi, kisayol, insan okunur ad), ...]
# Aksiyonun HANGI dosyada oldugu onemli: KXMLGUIFactory her istemcinin
# ActionProperties'ini yalnizca KENDI aksiyonlarina uygular. edit_copy'yi
# konsoleui.rc'ye yazarsan sessizce hicbir sey olmaz.
PLAN = {
    'sessionui.rc': [
        ('edit_copy',      'Ctrl+C',                     'Kopyala'),
        ('edit_paste',     'Ctrl+V;Ctrl+Shift+V',        'Yapıştır'),
        ('edit_find',      'Ctrl+F',                     'Bul'),
        ('edit_find_next', 'F3',                         'Sonrakini bul'),
        ('edit_find_prev', 'Shift+F3',                   'Öncekini bul'),
        ('close-session',  'Ctrl+W',                     'Sekmeyi kapat'),
    ],
    'konsoleui.rc': [
        ('new-tab',        'Ctrl+T',                     'Yeni sekme'),
    ],
}

rapor, hata = [], 0

for dosya, istekler in PLAN.items():
    p = dizin / dosya
    metin = p.read_text(encoding='utf-8')

    # 1) Aksiyon adlari gercekten bu dosyada mi? Yazmadan once dogrula.
    mevcut = set(re.findall(r'<Action[^>]*\bname="([^"]+)"', metin))
    gecerli = []
    for ad, tus, insan in istekler:
        if ad in mevcut:
            gecerli.append((ad, tus, insan))
        else:
            rapor.append((dosya, ad, tus, insan, 'YOK'))
            hata += 1

    if goster or not gecerli:
        for ad, tus, insan in gecerli:
            rapor.append((dosya, ad, tus, insan, 'hazir'))
        continue

    # 2) <ActionProperties scheme="VSCode"> blogunu kur/yenile (idempotent).
    blok = f'<ActionProperties scheme="{sema}">\n'
    for ad, tus, _ in gecerli:
        blok += f'  <Action name="{ad}" shortcut="{tus}"/>\n'
    blok += ' </ActionProperties>'

    yeni, n = re.subn(
        rf'<ActionProperties\s+scheme="{re.escape(sema)}"\s*(?:/>|>.*?</ActionProperties>)',
        blok, metin, flags=re.S)
    if n == 0:
        # Sema elemani hic yoksa </gui> oncesine ekle
        yeni, n = re.subn(r'</gui>', ' ' + blok + '\n</gui>', metin)
    if n == 0:
        rapor.append((dosya, '-', '-', 'ActionProperties yerlestirilemedi', 'HATA'))
        hata += 1
        continue

    damga = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    (dizin / f'{dosya}.oncesi-{damga}').write_text(metin, encoding='utf-8')
    p.write_text(yeni, encoding='utf-8')
    for ad, tus, insan in gecerli:
        rapor.append((dosya, ad, tus, insan, 'yazildi'))

print(f"{'DOSYA':<16}{'AKSIYON':<18}{'KISAYOL':<24}{'NE':<18}DURUM")
print('-' * 92)
for dosya, ad, tus, insan, durum in rapor:
    print(f'{dosya:<16}{ad:<18}{tus:<24}{insan:<18}{durum}')

if not goster:
    kayit = [(insan, ad, tus) for _d, ad, tus, insan, durum in rapor if durum == 'yazildi']
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