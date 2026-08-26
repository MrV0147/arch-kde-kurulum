#!/usr/bin/env bash
# 40-panel.sh — panelleri ve masaustu bilesenlerini kurar.
#
#   bash masaustu/40-panel.sh --goster    # ne yapacagini anlat, dokunma
#   bash masaustu/40-panel.sh             # kur
#
# NEDEN appletsrc KOPYALANMIYOR:
#   1) plasmashell calisirken o dosyayi kendi bellek kopyasiyla EZER; elle
#      yazdigin her sey kaybolur.
#   2) Icinde makineye ozgu seyler var: ekran UUID'leri, etkinlik UUID'leri,
#      applet id'leri, ItemGeometries-1920x1080 gibi cozunurluge bagli konumlar.
#      Baska bir makinede ise yaramaz.
#   3) Ve KISISEL: hava durumu konumu, kdeconnect cihazi, gorev cubugu
#      baslaticilarin, uygulama menusu favorilerin, duvar kagidi video yolun.
#
# Bunun yerine Plasma'nin KENDI betik API'si (org.kde.PlasmaShell.evaluateScript)
# ile panel YAPISI kuruluyor. Kisisel olan her sey disarida - onlari kendin
# eklersin.

set -uo pipefail
GOSTER=0
[[ "${1:-}" == "--goster" ]] && GOSTER=1

if [[ $GOSTER -eq 1 ]]; then
cat <<'EOF'
KURULACAK YAPI

  HER EKRANIN ALT PANELI (yukseklik 50, ortalanmis)
    org.kde.plasma.icontasks           simgesel gorev yoneticisi
    org.kde.plasma.systemtray          sistem tepsisi (asagidaki ogelerle)
    luisbocanegra.panel.colorizer      panel renklendirici
    org.kde.plasma.kickerdash          uygulama menusu (tam ekran)      [1. ekran]
    org.kde.plasma.digitalclock        saat                              [1. ekran]
    org.kde.plasma.systemmonitor.diskusage  disk kullanimi               [2. ekran]
    org.kaan.qftoggle                  Q/F klavye degistirici

  SISTEM TEPSISI OGELERI
    kdeconnect · vault · devicenotifier · networkmanagement
    keyboardindicator · printmanager · manage-inputmethod · clipboard
    kscreen · cameraindicator · volume · weather · notifications
    keyboardlayout · brightness · battery · mediacontroller

  MASAUSTU (org.kde.plasma.folder + video duvar kagidi)
    com.axzoros.yorhahud                YoRHa HUD
    org.zayronxio.vector.clock          vektor saat
    org.lucy.sidemenu                   yan menu
    org.muddyblack.plasmaAudioVisualizer ses gorsellestirici

    1920x1080'de konumlar (sol,ust,genislik,yukseklik):
      YoRHa HUD          32,   32, 528, 240
      vektor saat      1408,   32, 496, 192
      yan menu           24,  556, 392, 420
      ses gorsel.      1408,  848, 496, 208

  KURULMAYAN (kisisel oldugu icin) — bunlari kendin ayarlarsin:
    · gorev cubugu baslaticilarin
    · uygulama menusu favorilerin
    · hava durumu konumun
    · duvar kagidi video dosyan
    · kdeconnect eslesmis cihazin
EOF
exit 0
fi

command -v qdbus6 >/dev/null || { echo "HATA: qdbus6 yok (paket: qt6-tools)"; exit 1; }

echo "panel yapisi kuruluyor..."
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var TEPSI = ["org.kde.kdeconnect","org.kde.plasma.vault","org.kde.plasma.devicenotifier",
  "org.kde.plasma.networkmanagement","org.kde.plasma.keyboardindicator",
  "org.kde.plasma.printmanager","org.kde.plasma.manage-inputmethod",
  "org.kde.plasma.clipboard","org.kde.kscreen","org.kde.plasma.cameraindicator",
  "org.kde.plasma.volume","org.kde.plasma.weather","org.kde.plasma.notifications",
  "org.kde.plasma.keyboardlayout","org.kde.plasma.brightness","org.kde.plasma.battery",
  "org.kde.plasma.mediacontroller"];

var cikti = [];
var mevcut = panels();

for (var e = 0; e < screenCount; e++) {
    // Bu ekranda alt panel var mi?
    var p = null;
    for (var i = 0; i < mevcut.length; i++) {
        if (mevcut[i].screen === e && mevcut[i].location === "bottom") { p = mevcut[i]; break; }
    }
    if (p === null) {
        p = new Panel("org.kde.panel");
        p.location  = "bottom";
        p.screen    = e;
        cikti.push("ekran " + e + ": yeni panel olusturuldu");
    } else {
        cikti.push("ekran " + e + ": mevcut panel kullaniliyor");
    }
    p.height    = 50;
    p.alignment = "center";

    // Zaten duran bilesenleri tekrar ekleme (idempotan)
    function varMi(tur) {
        var w = p.widgets();
        for (var k = 0; k < w.length; k++) if (w[k].type === tur) return true;
        return false;
    }
    function ekle(tur) {
        if (varMi(tur)) { cikti.push("   = " + tur + " (zaten var)"); return null; }
        var w = p.addWidget(tur);
        cikti.push("   + " + tur);
        return w;
    }

    ekle("org.kde.plasma.icontasks");

    var tepsi = null;
    var w = p.widgets();
    for (var k = 0; k < w.length; k++) if (w[k].type === "org.kde.plasma.systemtray") tepsi = w[k];
    if (tepsi === null) { tepsi = p.addWidget("org.kde.plasma.systemtray"); cikti.push("   + sistem tepsisi"); }
    if (tepsi) {
        tepsi.currentConfigGroup = ["General"];
        tepsi.writeConfig("extraItems", TEPSI.join(","));
        tepsi.writeConfig("knownItems", TEPSI.join(","));
    }

    ekle("luisbocanegra.panel.colorizer");
    if (e === 0) {
        ekle("org.kde.plasma.kickerdash");
        ekle("org.kde.plasma.digitalclock");
    } else {
        ekle("org.kde.plasma.systemmonitor.diskusage");
    }
    ekle("org.kaan.qftoggle");
}
print(cikti.join("\n"));
' 2>&1

echo
echo "MASAUSTU BILESENLERI"
echo "  Bunlar konum/boyut tasidigi icin betikle degil ELLE eklenir:"
echo "    masaustune sag tik -> Bilesenleri Duzenle -> Bilesen Ekle"
echo "    YoRHa HUD · Vector Clock · Side Menu · Audio Visualizer"
echo "  Konumlar icin: bash masaustu/40-panel.sh --goster"
echo
echo "PANEL COLORIZER AYARLARI"
echo "  Panel Colorizer bileseni -> Yapilandir -> Ayarlari Ice Aktar"
echo "  -> masaustu/panel-colorizer-ayarlari.json"