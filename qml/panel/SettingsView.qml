import QtQuick
import QtQuick.Layouts
import "../js/Schema.js" as Schema
import "../controls"

// The Settings tab:
//   * a search box that looks through every setting;
//   * one underlined tab per group in Schema.js, and About last;
//   * that group's settings (tiles, segmented bars, sliders, switches), or every
//     match while searching.
// Every change is applied instantly and saved through the SettingsStore.
Item {
    id: root

    property var svc: null
    readonly property var ui: svc ? svc.ui : null
    readonly property int group: ui ? Math.max(0, Math.min(Schema.groups.length, ui.settingsGroup)) : 0
    readonly property string filter: searchBox.text
    property bool confirmReset: false

    readonly property bool searching: filter.trim() !== ""
    readonly property bool onAbout: group === Schema.groups.length && !searching

    function rad(k) { return ui.r(k) }

    function val(key) {
        return svc && svc.cfg && svc.cfg[key] !== undefined ? svc.cfg[key] : Schema.defaults[key]
    }

    // A row's value: one setting, or for a palette row its colors as { key: value }.
    function rowValue(item) {
        if (item.kind !== "palette") return val(item.key)
        const o = {}
        for (let i = 0; i < item.targets.length; i++) o[item.targets[i].key] = val(item.targets[i].key)
        return o
    }

    function same(item) {
        if (item.kind !== "palette") return String(val(item.key)) === String(item.fallback)
        for (let i = 0; i < item.targets.length; i++) {
            const k = item.targets[i].key
            if (String(val(k)).toLowerCase() !== String(item.fallback[k]).toLowerCase()) return false
        }
        return true
    }

    function edit(item, v) {
        if (!svc) return
        if (item.kind !== "palette") { svc.setValue(item.key, v); return }
        if (v && v.reset) {
            for (let i = 0; i < item.targets.length; i++)
                svc.setValue(item.targets[i].key, item.fallback[item.targets[i].key])
        } else if (v && v.key) {
            svc.setValue(v.key, v.value)
        }
    }

    // the shortcut row also says when the keybind couldn't be written
    function hintOf(item) {
        if (offHere(item)) return "Not used in a pop-out window: your window manager sizes it. Dock it to use this."
        if (item.key === "shortcut" && svc && svc.bindStatus.error) return item.hint + "\n⚠ " + svc.bindStatus.error
        return item.hint || ""
    }

    // Window size is set by the window manager while the panel is popped out,
    // so these two settings have no effect there. Shown, but locked.
    function offHere(item) {
        return ui.popped === true && (item.key === "windowWidth" || item.key === "windowHeight")
    }

    function dimmed(item) {
        if (!item.when) return false
        for (let i = 0; i < item.when.length; i++) {
            const c = item.when[i]
            if (c.is.map(String).indexOf(String(val(c.key))) < 0) return true
        }
        return false
    }

    function matches(item) {
        const f = filter.trim().toLowerCase()
        if (f === "") return true
        return (item.label + " " + item.hint + " " + (item.section || "")).toLowerCase().indexOf(f) >= 0
    }

    // the rows to show: the chosen group, or every match while searching.
    // `head` is the heading over a row: the group title while searching, otherwise
    // the row's section when it starts a new one.
    readonly property var rows: {
        const out = []
        for (let g = 0; g < Schema.groups.length; g++) {
            if (!searching && g !== group) continue
            const items = Schema.groups[g].items
            let first = true
            let lastSection = ""
            for (let i = 0; i < items.length; i++) {
                if (!matches(items[i])) continue
                const section = items[i].section || ""
                const head = searching ? (first ? Schema.groups[g].title : "")
                                     : (section !== lastSection ? section : "")
                out.push({ item: items[i], head })
                lastSection = section
                first = false
            }
        }
        return out
    }

    // how many settings differ from their defaults
    readonly property int changed: {
        let n = 0
        for (let g = 0; g < Schema.groups.length; g++) {
            const items = Schema.groups[g].items
            for (let i = 0; i < items.length; i++)
                if (!same(items[i])) n++
        }
        return n
    }

    function resetAll() {
        if (!root.confirmReset) { root.confirmReset = true; confirmTimer.restart(); return }
        root.confirmReset = false
        if (!svc || !svc.store) return
        // keep the layout, that one's picked on the other tab
        const keep = svc.cfg.mode
        svc.store.resetAll(Schema.defaults)
        svc.setValue("mode", keep)
    }
    Timer { id: confirmTimer; interval: 2500; onTriggered: root.confirmReset = false }

    ColumnLayout {
        anchors.fill: parent
        spacing: ui.px(10)

        // ---- search ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: ui.px(420)
            implicitHeight: ui.px(28)
            radius: ui.r(1.5)
            color: ui.tint(0.05)
            border.width: 1
            border.color: searchBox.activeFocus ? ui.tint(0.28) : ui.tint(0.08)
            clip: true

            Txt { ui: root.ui; anchors.left: parent.left; anchors.leftMargin: ui.px(10); anchors.verticalCenter: parent.verticalCenter; text: "⌕"; opacity: 0.5; font.pixelSize: ui.fs(14) }
            TextBox {
                id: searchBox
                ui: root.ui
                anchors.fill: parent
                anchors.leftMargin: ui.px(30)
                anchors.rightMargin: ui.px(30)
                maximumLength: 50
                Keys.onEscapePressed: function(e) {
                    if (text !== "") { text = ""; e.accepted = true }
                    else e.accepted = false
                }
                Txt {
                    ui: root.ui
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: Text.ElideRight
                    visible: searchBox.text === "" && !searchBox.activeFocus
                    text: "Search settings…"
                    opacity: 0.4
                }
            }
            Txt {
                ui: root.ui
                anchors.right: parent.right
                anchors.rightMargin: ui.px(10)
                anchors.verticalCenter: parent.verticalCenter
                visible: searchBox.text !== ""
                text: "✕"
                opacity: 0.6
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: searchBox.text = "" }
            }
        }

        // ---- tabs -------------------------------------------------------------------
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

            // When the window is narrow or the text large, the tabs keep their natural
            // width and the row scrolls sideways instead of drawing them over each other.
            Flickable {
                id: tabsFlick
                anchors.fill: parent
                contentWidth: Math.max(width, tabsRow.implicitWidth)
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                // scroll the open tab into view
                function reveal(item) {
                    if (!item || contentWidth <= width) return
                    const pad = ui.px(24)
                    if (item.x - pad < contentX) contentX = Math.max(0, item.x - pad)
                    else if (item.x + item.width + pad > contentX + width)
                        contentX = Math.min(contentWidth - width, item.x + item.width + pad - width)
                }

            RowLayout {
                id: tabsRow
                // the widest tab title, in the open tab's (bold) weight, plus some air
                TextMetrics {
                    id: widest
                    font.family: ui.fontName
                    font.pixelSize: ui.fs(12)
                    font.weight: Font.DemiBold
                    text: Schema.groups.concat([{ title: "About" }]).map((g) => g.title)
                        .reduce((a, b) => (b.length > a.length ? b : a), "")
                }
                readonly property real tabW: Math.ceil(widest.width) + ui.px(24)
                width: tabsFlick.contentWidth
                height: tabsFlick.height
                spacing: 0

                Repeater {
                    model: Schema.groups.concat([{ title: "About" }])
                    delegate: Item {
                        readonly property bool on: index === root.group && !root.searching
                        Layout.fillWidth: true
                        // every tab as wide as the widest one
                        Layout.preferredWidth: tabsRow.tabW
                        Layout.minimumWidth: tabsRow.tabW
                        Layout.fillHeight: true
                        onOnChanged: if (on) Qt.callLater(tabsFlick.reveal, this)
                        onXChanged: if (on) Qt.callLater(tabsFlick.reveal, this)

                        Txt {
                            id: tabLabel
                            ui: root.ui
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: modelData.title
                            opacity: root.searching ? 0.3 : (parent.on ? 1.0 : (tabArea.containsMouse ? 0.8 : 0.5))
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
                            onClicked: { root.ui.settingsGroup = index; searchBox.text = ""; flick.contentY = 0 }
                        }
                    }
                }
            }
            }
        }

        // ---- the settings of the active tab -------------------------------------------
        // the last tab: About
        AboutPage {
            svc: root.svc
            visible: root.onAbout
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Flickable {
            id: flick
            visible: !root.onAbout
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

                    Txt {
                        ui: root.ui
                        visible: root.rows.length === 0
                        Layout.topMargin: ui.px(14)
                        Layout.bottomMargin: ui.px(14)
                        text: "No setting matches that."
                        opacity: 0.5
                    }

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
                            Txt {
                                ui: root.ui
                                visible: modelData.head !== ""
                                Layout.topMargin: ui.px(12)
                                text: modelData.head.toUpperCase()
                                font.pixelSize: ui.fs(9)
                                font.letterSpacing: 1
                                font.weight: Font.DemiBold
                                opacity: 0.45
                            }
                            SettingRow {
                                Layout.fillWidth: true
                                Layout.topMargin: ui.px(14)
                                Layout.bottomMargin: ui.px(14)
                                ui: root.ui
                                settingKey: modelData.item.key
                                label: modelData.item.label
                                hint: root.hintOf(modelData.item)
                                kind: modelData.item.kind
                                control: modelData.item.control || ""
                                options: modelData.item.options || []
                                labels: modelData.item.labels || ({})
                                presets: modelData.item.presets || []
                                maxLength: modelData.item.maxLength !== undefined ? modelData.item.maxLength : 2048
                                min: modelData.item.min !== undefined ? modelData.item.min : 0
                                max: modelData.item.max !== undefined ? modelData.item.max : 100
                                step: modelData.item.step !== undefined ? modelData.item.step : 1
                                divisor: modelData.item.divisor !== undefined ? modelData.item.divisor : 1
                                decimals: modelData.item.decimals !== undefined ? modelData.item.decimals : 0
                                defaultValue: modelData.item.fallback
                                dimmed: root.dimmed(modelData.item)
                                locked: root.offHere(modelData.item)
                                value: root.rowValue(modelData.item)
                                targets: modelData.item.targets || []
                                onEdited: function(v) {
                                    if (root.offHere(modelData.item)) return
                                    root.edit(modelData.item, v)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
