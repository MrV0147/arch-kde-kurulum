/*
    Yardim.qml — sag tikla acilan kisayol hatirlatici.
    SPDX-License-Identifier: MIT

    Icerik BURAYA GOMULU DEGIL: contents/data/kisayollar.json dosyasindan
    okunuyor ve o dosyayi ~/klavye/uret-yardim.sh CANLI SISTEMDEN uretiyor.
    Boylece bir kisayolu degistirdiginde bu panel yalan soylemiyor.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Representation {
    id: yardim

    property string aktifHarf: "?"

    Layout.minimumWidth:   Kirigami.Units.gridUnit * 20
    Layout.minimumHeight:  Kirigami.Units.gridUnit * 18
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight:Kirigami.Units.gridUnit * 28

    property var veri: ({ uretim: "", bolumler: [] })

    function yukle() {
        const istek = new XMLHttpRequest()
        istek.onreadystatechange = function () {
            if (istek.readyState !== XMLHttpRequest.DONE)
                return
            try {
                yardim.veri = JSON.parse(istek.responseText)
            } catch (e) {
                yardim.veri = {
                    uretim: "",
                    bolumler: [{
                        baslik: "Yardım dosyası okunamadı",
                        satirlar: [{
                            tus: "!",
                            ne: "contents/data/kisayollar.json yok veya bozuk",
                            "not": "bash ~/klavye/uret-yardim.sh"
                        }]
                    }]
                }
            }
        }
        istek.open("GET", Qt.resolvedUrl("../data/kisayollar.json"))
        istek.send()
    }

    Component.onCompleted: yukle()

    header: PlasmaExtras.BasicPlasmoidHeading {
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.Heading {
                level: 4
                text: "Klavye ve kısayollar"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                text: "şu an: " + yardim.aktifHarf
                font.bold: true
                opacity: 0.8
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents3.AbstractButton.IconOnly
                PlasmaComponents3.ToolTip.text: "Yeniden oku"
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                onClicked: yardim.yukle()
            }
        }
    }

    contentItem: PlasmaComponents3.ScrollView {
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: yardim.veri.bolumler

                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    Kirigami.ListSectionHeader {
                        Layout.fillWidth: true
                        text: modelData.baslik
                    }

                    Repeater {
                        model: modelData.satirlar

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                            Layout.rightMargin: Kirigami.Units.smallSpacing
                            Layout.topMargin: Kirigami.Units.smallSpacing / 2
                            Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                            spacing: Kirigami.Units.largeSpacing

                            // tus rozeti — sabit genislik, sag hizali metin
                            Rectangle {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                Layout.preferredHeight: rozet.implicitHeight
                                                        + Kirigami.Units.smallSpacing
                                Layout.alignment: Qt.AlignTop
                                radius: Kirigami.Units.cornerRadius
                                color: Kirigami.Theme.alternateBackgroundColor
                                border.width: 1
                                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                                PlasmaComponents3.Label {
                                    id: rozet
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing
                                    text: modelData.tus
                                    font.family: "monospace"
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    text: modelData.ne
                                    wrapMode: Text.Wrap
                                }
                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    visible: (modelData["not"] || "") !== ""
                                    text: modelData["not"] || ""
                                    wrapMode: Text.Wrap
                                    opacity: 0.65
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.smallSpacing }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        position: PlasmaExtras.PlasmoidHeading.Footer
        contentItem: PlasmaComponents3.Label {
            text: "Tam referans: ~/klavye/KISAYOLLAR.md   ·   Durum: durum.sh"
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
            elide: Text.ElideRight
        }
    }
}