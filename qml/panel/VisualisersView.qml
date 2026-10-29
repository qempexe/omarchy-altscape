import QtQuick
import QtQuick.Layouts
import "../js/Schema.js" as Schema
import "../controls"
import "../core"
import "../switcher"

// visualisers tab: a tile per layout + live preview with your windows (click to switch)
Item {
    id: root

    property var svc: null
    property bool shown: false           // the panel is on screen
    readonly property var ui: svc ? svc.ui : null

    signal windowPicked()

    readonly property int cols: width >= 380 ? 4 : 2

    SwitchState {
        id: preview
        svc: root.svc
        active: root.shown
        onActivated: function(address) {
            if (root.svc && root.svc.focusWindow(address)) root.windowPicked()
        }
    }

    function restart() { if (root.shown && root.svc) { root.svc.refresh(); preview.start("current") } }
    onShownChanged: restart()
    Component.onCompleted: restart()

    // preview follows scope/order/previews changes right away
    Connections {
        target: root.svc
        ignoreUnknownSignals: true
        function onCfgChanged() { if (root.shown) preview.rebuild() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: ui.px(12)

        GridLayout {
            id: tiles
            Layout.fillWidth: true
            columns: root.cols
            columnSpacing: ui.px(8)
            rowSpacing: ui.px(8)

            Repeater {
                model: Schema.modes
                delegate: Rectangle {
                    id: tile
                    readonly property bool on: root.svc && root.svc.cfg.mode === modelData.key
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: ui.px(70)
                    radius: ui.r(1.4)
                    color: on ? ui.accentTint(0.16) : ui.tint(tArea.containsMouse ? 0.09 : 0.04)
                    border.width: on ? 1.5 : 1
                    border.color: on ? ui.accent : ui.tint(0.08)
                    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 100 } }

                    ModeArt {
                        ui: root.ui
                        mode: modelData.key
                        on: tile.on
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: ui.px(7)
                    }
                    Txt {
                        ui: root.ui
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: ui.px(6)
                        width: parent.width - ui.px(10)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.label
                        font.pixelSize: ui.fs(11)
                        font.weight: tile.on ? Font.DemiBold : Font.Normal
                        opacity: tile.on ? 1.0 : 0.75
                    }
                    MouseArea {
                        id: tArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.svc.setMode(modelData.key)
                    }
                }
            }
        }

        // layout name + window count
        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(8)
            Txt {
                ui: root.ui
                Layout.fillWidth: true
                elide: Text.ElideRight
                readonly property var m: {
                    for (let i = 0; i < Schema.modes.length; i++)
                        if (root.svc && Schema.modes[i].key === root.svc.cfg.mode) return Schema.modes[i]
                    return Schema.modes[0]
                }
                text: m.label + "  ·  " + m.hint
                font.pixelSize: ui.fs(11)
                opacity: 0.7
            }
            Txt {
                ui: root.ui
                text: preview.items.length + (preview.items.length === 1 ? " window" : " windows") + "  \u00B7  click one to switch"
                font.pixelSize: ui.fs(10)
                opacity: 0.5
            }
        }

        // preview
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: ui.px(160)
            radius: ui.r(2)
            color: ui.tint(0.03)
            border.width: 1
            border.color: ui.tint(0.07)
            clip: true

            SwitchView {
                anchors.fill: parent
                anchors.margins: ui.px(10)
                sw: preview
                k: 0.62
                visible: root.shown
            }
        }
    }
}
