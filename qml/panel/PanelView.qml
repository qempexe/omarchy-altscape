import QtQuick
import QtQuick.Layouts
import "../controls"

// the whole panel: header, two tabs, content, footer.
// used by both the docked popup and the popped out window
Item {
    id: view

    property var svc: null
    property bool shown: false
    readonly property var ui: svc ? svc.ui : null
    clip: true

    // popped out there's no shortcut for esc, so handle it here
    Keys.onEscapePressed: function(e) {
        if (ui.popped) { ui.closeRequested(); e.accepted = true }
        else e.accepted = false
    }

    // background
    Rectangle {
        anchors.fill: parent
        radius: ui.r(3)
        color: ui.panelColor
    }
    Rectangle {   // optional accent wash (Window tint, 0 by default)
        anchors.fill: parent
        radius: ui.r(3)
        visible: ui.tintPct > 0
        color: ui.accentTint(ui.tintPct / 100)
    }
    Rectangle {   // edge: a plain neutral line; accent only if "Window outline" is on
        anchors.fill: parent
        radius: ui.r(3)
        color: "transparent"
        border.width: 1
        border.color: ui.frameOn ? ui.accent : ui.tint(0.14)
        opacity: ui.frameOn ? 0.8 : 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ui.px(14)
        spacing: ui.px(12)

        // header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + ui.px(24)
            radius: ui.r(2.5)
            color: ui.tint(0.05)
            border.width: 1
            border.color: ui.tint(0.08)

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: ui.px(12)
                spacing: ui.px(10)

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: ui.px(30); implicitHeight: ui.px(30)
                    radius: ui.r(1.5)
                    color: ui.accentTint(0.18)
                    border.width: 1
                    border.color: ui.tint(0.08)
                    Image {   // the logo, dark on a light panel
                        anchors.centerIn: parent
                        width: ui.px(24); height: width
                        source: Qt.resolvedUrl(ui.lightSurface ? "../../assets/logo-dark.png" : "../../assets/logo.png")
                        sourceSize.width: 96
                        sourceSize.height: 96
                        smooth: true
                        mipmap: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Txt {
                        ui: view.ui
                        Layout.fillWidth: true
                        text: "Altscape"
                        font.pixelSize: ui.fs(13)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Txt {
                        ui: view.ui
                        Layout.fillWidth: true
                        font.pixelSize: ui.fs(11)
                        opacity: 0.6
                        elide: Text.ElideRight
                        text: {
                            if (!view.svc) return "Starting…"
                            var n = view.svc.windowCount
                            var s = n + (n === 1 ? " window" : " windows")
                            var b = view.svc.bindStatus
                            if (view.svc.cfg.shortcut === "off") s += "  ·  no shortcut"
                            else if (b && b.ok && b.shortcut === view.svc.cfg.shortcut && b.active === "false")
                                s += "  ·  shortcut written, but Hyprland is not using it"
                            else if (b && b.ok && b.shortcut === view.svc.cfg.shortcut)
                                s += "  ·  " + (b.shortcut === "super" ? "Super" : "Alt") + " + Tab ready"
                            else if (b && b.error) s += "  ·  shortcut not set"
                            return s
                        }
                    }
                }

                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    kind: "primary"
                    text: "Open switcher"
                    onClicked: ui.openSwitcherRequested()
                }
                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    visible: ui.tabName === "settings"
                    kind: settingsView.confirmReset ? "primary" : "normal"
                    text: settingsView.confirmReset ? "Really reset?" : "Reset all"
                    onClicked: settingsView.resetAll()
                }
                Btn {
                    ui: view.ui
                    Layout.alignment: Qt.AlignVCenter
                    text: ui.popped ? "Dock" : "Pop out"
                    onClicked: ui.popped ? ui.dockRequested() : ui.popOutRequested()
                }
                Btn { ui: view.ui; Layout.alignment: Qt.AlignVCenter; text: "×"; implicitWidth: ui.px(24); onClicked: ui.closeRequested() }
            }
        }

        // tabs
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
                    model: [
                        { key: "visualisers", label: "Visualisers" },
                        { key: "settings", label: "Settings" }
                    ]
                    delegate: Item {
                        id: tab
                        readonly property bool on: ui.tabName === modelData.key
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true

                        Txt {
                            ui: view.ui
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -1
                            text: modelData.label
                            font.pixelSize: ui.fs(12)
                            font.weight: tab.on ? Font.DemiBold : Font.Normal
                            opacity: tab.on ? 1 : (tabArea.containsMouse ? 0.8 : 0.5)
                        }
                        Rectangle {
                            visible: tab.on
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
                            onClicked: ui.tabName = modelData.key
                        }
                    }
                }
            }
        }

        // content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            radius: ui.r(2.5)
            color: ui.tint(0.035)
            border.width: 1
            border.color: ui.tint(0.07)
            clip: true

            VisualisersView {
                anchors.fill: parent
                anchors.margins: ui.px(12)
                visible: ui.tabName !== "settings"
                svc: view.svc
                shown: view.shown && visible
                onWindowPicked: ui.closeRequested()
            }
            SettingsView {
                id: settingsView
                anchors.fill: parent
                anchors.margins: ui.px(10)
                visible: ui.tabName === "settings"
                svc: view.svc
            }
        }

        // footer
        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(8)

            Rectangle {
                implicitWidth: escLabel.implicitWidth + ui.px(12)
                implicitHeight: ui.px(18)
                radius: ui.r(1)
                color: ui.tint(0.08)
                Txt { id: escLabel; ui: view.ui; anchors.centerIn: parent; text: "Esc"; font.pixelSize: ui.fs(10); opacity: 0.75 }
            }
            Txt { ui: view.ui; text: "close"; font.pixelSize: ui.fs(10); opacity: 0.45 }

            Txt {
                ui: view.ui
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: ui.fs(10)
                opacity: 0.45
                text: ui.tabName === "settings"
                    ? (settingsView.changed === 0 ? "All settings are at their defaults"
                       : settingsView.changed + (settingsView.changed === 1 ? " setting differs" : " settings differ") + " from the defaults")
                    : (view.svc && view.svc.cfg.shortcut !== "off"
                       ? (view.svc.cfg.shortcut === "super" ? "Super" : "Alt") + " + Tab opens the switcher, Shift goes back"
                       : "Pick a style; the switcher uses it next time")
            }
            Txt { ui: view.ui; text: "Changes apply instantly"; font.pixelSize: ui.fs(10); opacity: 0.45 }
        }
    }
}
