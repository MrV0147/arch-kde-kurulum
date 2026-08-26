#!/usr/bin/env bash
# 04-konsole-kisayol.sh — Konsole'a VS Code tarzi kisayol semasi uygular.
#
#   bash ~/klavye/04-konsole-kisayol.sh            (sudo GEREKMEZ)
#   bash ~/klavye/04-konsole-kisayol.sh --keytab   (SIGINT katman 2'yi de kur)
#   bash ~/klavye/04-konsole-kisayol.sh --kaldir
#
# ONCE ELLE YAPILACAK TEK ADIM:
#   Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir -> Semalari Yonet
#   -> Yeni Sema -> ad: VSCode -> Kaydet
#
# NEDEN: Konsole 26.08 konsoleui.rc'yi diske koymuyor, Qt kaynagina gomuyor.
# Binary'den aksiyon adlari cikarilamadi (close-session disinda hicbiri).
# Ad TAHMIN ETMIYORUZ - Konsole'un kendi yazdigi sema dosyasindaki gercek
# adlari okuyoruz. Hangi aksiyonun hangisi oldugunu da ADINDAN degil, o anki
# VARSAYILAN KISAYOLUNDAN tespit ediyoruz (Kopyala = Ctrl+Shift+C, vb).
# Eslesen her sey ekrana basilir ki dogrulayabilesin.

set -euo pipefail
KOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEMA_DIZIN="$HOME/.local/share/kxmlgui5/konsole"
SEMA="$SEMA_DIZIN/VSCode.shortcuts"
KEYTAB_DIZIN="$HOME/.local/share/konsole"
KEYTAB="$KEYTAB_DIZIN/VSCode.keytab"
KEYTAB_KUR=0; KALDIR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keytab) KEYTAB_KUR=1; shift ;;
    --kaldir) KALDIR=1; shift ;;
    *) echo "bilinmeyen secenek: $1" >&2; exit 2 ;;
  esac
done

if [[ $KALDIR -eq 1 ]]; then
  rm -rf "$SEMA_DIZIN" "$KEYTAB"
  kwriteconfig6 --file konsolerc --group "Shortcut Schemes" --key "Current Scheme" --delete 2>/dev/null || true
  echo "kaldirildi. Konsole'u yeniden baslat."
  exit 0
fi

if [[ ! -f "$SEMA" ]]; then
  cat <<'EOF'
HATA: sema dosyasi yok.

Once su adimi ELLE yap (15 saniye):

  Konsole -> Ayarlar -> Klavye Kisayollarini Yapilandir
          -> Semalari Yonet (Manage Schemes)
          -> Yeni Sema (New Scheme...)   ad: VSCode
          -> Kaydet (Save Scheme)

Bu, Konsole'un TUM gercek aksiyon adlarini iceren su dosyayi uretir:
  ~/.local/share/kxmlgui5/konsole/VSCode.shortcuts

Sonra bu scripti tekrar calistir.
EOF
  exit 2
fi

cp -a "$SEMA" "$SEMA.oncesi-$(date +%Y%m%d-%H%M%S)"

/usr/bin/python3 - "$SEMA" <<'PYEOF'
import sys, xml.etree.ElementTree as ET

yol = sys.argv[1]
agac = ET.parse(yol)
kok  = agac.getroot()

eylemler = kok.iter('Action')
tablo = {}          # varsayilan kisayol -> Action ogesi
tum   = []
for e in eylemler:
    tum.append(e)
    ks = (e.get('shortcut') or '').strip()
    for tek in [k.strip() for k in ks.split(';') if k.strip()]:
        tablo.setdefault(tek, []).append(e)

if len(tum) < 10:
    raise SystemExit(
        f"HATA: sema dosyasinda sadece {len(tum)} aksiyon var. Konsole semayi\n"
        "tam yazmamis. 'Semalari Yonet' penceresinde 'Yeni Sema' ile tekrar dene.")

# (varsayilan kisayol, yeni kisayol, insan okunur ad)
ISTEK = [
    ("Ctrl+Shift+C", "Ctrl+C",                       "Kopyala"),
    ("Ctrl+Shift+V", "Ctrl+V; Ctrl+Shift+V",         "Yapistir"),
    ("Ctrl+Shift+F", "Ctrl+F",                       "Bul"),
    ("Ctrl+Shift+T", "Ctrl+T",                       "Yeni sekme"),
    ("Ctrl+Shift+W", "Ctrl+W",                       "Sekmeyi kapat"),
    ("Shift+Right",  "Ctrl+Tab; Shift+Right",        "Sonraki sekme"),
    ("Shift+Left",   "Ctrl+Shift+Tab; Shift+Left",   "Onceki sekme"),
]

print(f"sema dosyasinda {len(tum)} aksiyon bulundu\n")
print(f"{'ne':<16}{'varsayilan':<16}{'aksiyon adi':<28}{'yeni'}")
print("-" * 82)

uygulandi = eksik = 0
rapor = []
for varsayilan, yeni, ad in ISTEK:
    adaylar = tablo.get(varsayilan, [])
    if not adaylar:
        print(f"{ad:<16}{varsayilan:<16}{'-- BULUNAMADI --':<28}atlandi")
        eksik += 1
        continue
    if len(adaylar) > 1:
        # Birden fazla aksiyon ayni kisayolu tasiyorsa karar bize kalmaz.
        adlar = ', '.join(a.get('name', '?') for a in adaylar)
        print(f"{ad:<16}{varsayilan:<16}{'BELIRSIZ: ' + adlar:<28}atlandi")
        eksik += 1
        continue
    e = adaylar[0]
    e.set('shortcut', yeni)
    print(f"{ad:<16}{varsayilan:<16}{e.get('name', '?'):<28}{yeni}")
    rapor.append((ad, e.get('name', '?'), yeni))
    uygulandi += 1

agac.write(yol, encoding='utf-8', xml_declaration=True)
print(f"\n{uygulandi} uygulandi, {eksik} atlandi")

# KISAYOLLAR.md'nin uretilen bolumu icin makine okunur kayit
import pathlib, json
pathlib.Path(yol).with_name('kesfedilen-aksiyonlar.json').write_text(
    json.dumps(rapor, ensure_ascii=False, indent=2), encoding='utf-8')

if eksik:
    raise SystemExit(1)
PYEOF
DURUM=$?

kwriteconfig6 --file konsolerc --group "Shortcut Schemes" --key "Current Scheme" "VSCode"
echo
echo "konsolerc -> [Shortcut Schemes] Current Scheme=VSCode"

# ---------------------------------------------------------- SIGINT katman 2
if [[ $KEYTAB_KUR -eq 1 ]]; then
  echo
  echo "UYARI: Konsole'un varsayilan tus tablosu C++'ta gomulu; diskte"
  echo "default.keytab YOK. Keytab dosyalari KATMANLI DEGIL, standalone."
  echo "Tek satirlik bir keytab ok/F/Home-End tuslarini bozabilir."
  echo "Bu yuzden katman 1 (secim-gecisi) once olculmeli - bkz. test 9."
  read -r -p "Yine de kurulsun mu? (e/H) " c
  if [[ "${c,,}" == "e" ]]; then
    mkdir -p "$KEYTAB_DIZIN"
    cp "$KOK/payload/VSCode.keytab" "$KEYTAB"
    echo "kuruldu -> $KEYTAB"
    echo "Konsole -> Ayarlar -> Gecerli Profili Duzenle -> Klavye -> VSCode sec"
  fi
fi

# Widget'in sag tik yardim panelini yeni kesfedilen kisayollarla tazele.
if [[ -d "$HOME/.local/share/plasma/plasmoids/org.kaan.qftoggle" ]]; then
  echo
  bash "$KOK/uret-yardim.sh"
  echo "(yardim paneli tazelendi - widget'a sag tikla gorebilirsin)"
fi

echo
echo "Konsole'u KAPATIP yeniden ac (sema oturum basinda okunuyor)."
exit $DURUM