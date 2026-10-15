import QtQuick
import QtQuick.Layouts
import "../js/Schema.js" as Schema
import "../controls"

// settings tab: one tab per group in Schema.js, rows underneath
Item {
    id: root

    property var svc: null
    readonly property var ui: svc ? svc.ui : null
    property bool confirmReset: false

    readonly property int group: ui ? Math.max(0, Math.min(Schema.groups.length - 1, ui.settingsGroup)) : 0

    function val(key) {
        var it = Schema.itemByKey[key]
        if (it && it.kind === "palette") {
            var o = {}
            for (var i = 0; i < it.targets.length; i++) o[it.targets[i].key] = val(it.targets[i].key)
            return o
        }
        return svc && svc.cfg && svc.cfg[key] !== undefined ? svc.cfg[key] : Schema.defaults[key]
    }

    function same(item) {
        var v = val(item.key)
        return item.kind === "palette" ? JSON.stringify(v) === JSON.stringify(item.fallback) : String(v) === String(item.fallback)
    }

    // popped out, the window manager decides the size, so lock these two
    function offHere(item) {
        return ui.popped === true && (item.key === "windowWidth" || item.key === "windowHeight")
    }

    function dimmed(item) {
        if (!item.when) return false
        for (var i = 0; i < item.when.length; i++) {
            var c = item.when[i]
            if (c.is.map(String).indexOf(String(val(c.key))) < 0) return true
        }
        return false
    }

    readonly property var rows: Schema.groups[group].items

    // count of changed settings (footer)
    readonly property int changed: {
        var n = 0
        for (var g = 0; g < Schema.groups.length; g++) {
            var items = Schema.groups[g].items
            for (var i = 0; i < items.length; i++)
                if (!same(items[i])) n++
        }
        return n
    }

    function resetAll() {
        if (!root.confirmReset) { root.confirmReset = true; confirmTimer.restart(); return }
        root.confirmReset = false
        if (svc && svc.store) {
            // keep the layout, that one's picked on the other tab
            var keep = svc.cfg.mode
            svc.store.resetAll(Schema.defaults)
            svc.setValue("mode", keep)
        }
    }
    Timer { id: confirmTimer; interval: 2500; onTriggered: root.confirmReset = false }

    ColumnLayout {
        anchors.fill: parent
        spacing: ui.px(12)

        // group tabs
        Item {
            Layout.fillWidth: true
            implicitHeight: ui.px(32)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: ui.tint(0.10)
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: Schema.groups
                    delegate: Item {
                        readonly property bool on: index === root.group
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Txt {
                            ui: root.ui
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: modelData.title
                            opacity: parent.on ? 1.0 : (tabArea.containsMouse ? 0.8 : 0.5)
                            font.pixelSize: ui.fs(12)
                            font.weight: parent.on ? Font.DemiBold : Font.Normal
                        }
                        Rectangle {
                            visible: parent.on
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2
                            radius: 1
                            color: ui.accent
                        }
                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.ui.settingsGroup = index; flick.contentY = 0 }
                        }
                    }
                }
            }
        }

        // rows
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: card.implicitHeight + ui.px(4)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Item {
                id: card
                width: flick.width
                implicitHeight: rowsCol.implicitHeight + ui.px(12)

                ColumnLayout {
                    id: rowsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: ui.px(16)
                    anchors.rightMargin: ui.px(16)
                    anchors.topMargin: ui.px(6)
                    spacing: 0

                    Repeater {
                        model: root.rows
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Rectangle {
                                visible: index > 0
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: ui.tint(0.07)
                            }
                            SettingRow {
                                Layout.fillWidth: true
                                Layout.topMargin: ui.px(14)
                                Layout.bottomMargin: ui.px(14)
                                ui: root.ui
                                settingKey: modelData.key
                                label: modelData.label
                                hint: root.offHere(modelData)
                                    ? "Not used in a pop-out window: your window manager sizes it. Dock it to use this."
                                    : (modelData.key === "shortcut" && root.svc && root.svc.bindStatus.error
                                       ? modelData.hint + "\n⚠ " + root.svc.bindStatus.error
                                       : (modelData.hint || ""))
                                kind: modelData.kind
                                control: modelData.control || ""
                                options: modelData.options || []
                                labels: modelData.labels || ({})
                                presets: modelData.presets || []
                                maxLength: modelData.maxLength !== undefined ? modelData.maxLength : 2048
                                min: modelData.min !== undefined ? modelData.min : 0
                                max: modelData.max !== undefined ? modelData.max : 100
                                step: modelData.step !== undefined ? modelData.step : 1
                                divisor: modelData.divisor !== undefined ? modelData.divisor : 1
                                decimals: modelData.decimals !== undefined ? modelData.decimals : 0
                                defaultValue: modelData.fallback
                                dimmed: root.dimmed(modelData)
                                locked: root.offHere(modelData)
                                value: root.val(modelData.key)
                                targets: modelData.targets || []
                                onEdited: function(v) {
                                    if (root.offHere(modelData) || !root.svc) return
                                    if (modelData.kind === "palette") {
                                        if (v && v.reset) {
                                            for (var i = 0; i < modelData.targets.length; i++) {
                                                var k = modelData.targets[i].key
                                                root.svc.setValue(k, modelData.fallback[k])
                                            }
                                        } else if (v && v.key) root.svc.setValue(v.key, v.value)
                                        return
                                    }
                                    root.svc.setValue(modelData.key, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
