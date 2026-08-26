/*
    org.kaan.qftoggle — Q/F klavye duzeni degistirici
    SPDX-License-Identifier: MIT

    NEDEN alt surec yok:
    Gorevde onerilen yol `qdbus ... switchToNextLayout` calistirmakti. Iki sorun:
      1) Bu sistemde `qdbus` yok, `qdbus6` var.
      2) Daha onemlisi: buton uzerindeki harfi guncel tutmak icin o komutu
         saniyede birkac kez calistirmak gerekirdi -> saniyede iki alt surec.
    Bunun yerine KWin'in QML modulu dogrudan kullaniliyor. `layoutChanged`
    sinyali harfi ANINDA guncelliyor, poll yok, alt surec yok, maliyet sifir.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.keyboardlayout as KL

PlasmoidItem {
    id: root

    KL.KeyboardLayout {
        id: kbd
    }

    // NOT: kbd.initialize() CAGRILMIYOR. qmltypes onu Method olarak listeliyor
    // ama ozel bir slot -> QML'den cagrilinca "not a function" hatasi veriyor
    // (olculdu, plasmashell logunda goruldu). switchToNextLayout/Previous ise
    // gercekten public. layoutsList zaten okundugunda DBus'a soruyor, ayrica
    // baslatmaya gerek yok.

    // layoutsList baslangicta bos gelebilir; guard sart.
    readonly property var mevcut: (kbd.layoutsList && kbd.layoutsList.length > kbd.layout)
                                  ? kbd.layoutsList[kbd.layout] : null

    // kxkbrc'deki DisplayNames=Q,F sayesinde displayName dogrudan "Q" / "F".
    // Yoksa shortName'e, o da yoksa "?" isaretine duser.
    readonly property string harf: mevcut
        ? (mevcut.displayName || mevcut.shortName || "?").toUpperCase()
        : "?"

    readonly property bool fAktif: harf === "F"

    toolTipMainText: fAktif ? "F klavye" : "Q klavye"
    toolTipSubText: mevcut
        ? (mevcut.longName || "") + "\nSol tik: degistir   ·   Sag tik: kisayollar"
        : "Klavye duzeni okunamadi"

    // Panelde her zaman kucuk rozet dursun; yardim paneli SAG TIKLA acilsin.
    preferredRepresentation: compactRepresentation
    fullRepresentation: Yardim { aktifHarf: root.harf }

    compactRepresentation: MouseArea {
        id: dugme

        hoverEnabled: true
        // Sag tusu KABUL ediyoruz -> Plasma'nin varsayilan baglam menusu
        // bastirilir ve yerine kendi yardim panelimiz acilir.
        // Widget'i kaldirmak/yapilandirmak icin: panele sag tik -> Bilesenleri
        // Duzenle. (Bu not yardim panelinin altbilgisinde de yaziyor.)
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (fare) => {
            if (fare.button === Qt.RightButton) {
                root.expanded = !root.expanded
            } else {
                kbd.switchToNextLayout()
            }
        }

        // Tekerlek de calissin: yukari sonraki, asagi onceki.
        onWheel: (wheel) => wheel.angleDelta.y > 0 ? kbd.switchToNextLayout()
                                                   : kbd.switchToPreviousLayout()

        readonly property int cap: Math.max(
            16, Math.min(width, height) - Kirigami.Units.smallSpacing)

        Layout.minimumWidth:  cap
        Layout.minimumHeight: cap
        Layout.preferredWidth:  cap
        Layout.preferredHeight: cap

        Rectangle {
            id: kapsul
            anchors.centerIn: parent
            width:  dugme.cap
            height: dugme.cap
            radius: height / 2          // tam yuvarlak, koseli hat yok

            // Duzeni METIN OKUMADAN da ayirt etmenin yolu:
            //   F -> dolu kapsul,  Q -> sadece kenarlik
            color: root.fAktif
                ? Kirigami.Theme.highlightColor
                : (dugme.containsMouse ? Kirigami.Theme.hoverColor : "transparent")

            border.width: root.fAktif ? 0 : Math.max(1, Math.round(height / 14))
            border.color: Kirigami.Theme.textColor

            Behavior on color  { ColorAnimation { duration: 120 } }
            scale: dugme.pressed ? 0.90 : 1.0
            Behavior on scale  { NumberAnimation { duration: 80 } }
        }

        Text {
            anchors.centerIn: kapsul
            text: root.harf
            font.pixelSize: Math.round(kapsul.height * 0.58)
            font.bold: true
            font.family: Kirigami.Theme.defaultFont.family
            // Yuksek kontrast: dolu kapsulde vurgu-metin rengi, bosta metin rengi
            color: root.fAktif
                ? Kirigami.Theme.highlightedTextColor
                : Kirigami.Theme.textColor
        }
    }
}