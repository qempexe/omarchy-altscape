import QtQuick

// little picture on a settings tile
Item {
    id: root

    property var ui: null
    property string key: ""
    property string opt: ""
    property bool on: false

    width: 64
    height: 34

    readonly property color ink: on ? ui.accent : ui.tint(0.55)
    readonly property color soft: on ? ui.accentTint(0.40) : ui.tint(0.20)

    // card style
    Rectangle {
        visible: root.key === "cardStyle"
        anchors.centerIn: parent
        width: 40; height: 26; radius: 5
        color: root.opt === "soft" ? root.soft : "transparent"
        border.width: root.opt === "flat" ? 0 : 1.5
        border.color: root.opt === "outline" ? root.ink : root.ui.tint(0.12)
        Rectangle { anchors.centerIn: parent; width: 16; height: 3; radius: 1.5; color: root.ink }
    }

    // spacing
    Row {
        visible: root.key === "density"
        anchors.centerIn: parent
        spacing: root.opt === "compact" ? 2 : (root.opt === "spacious" ? 9 : 5)
        Repeater { model: 3; Rectangle { width: 10; height: 18; radius: 2; color: root.ink } }
    }

    // scope
    Row {
        visible: root.key === "scope"
        anchors.centerIn: parent
        spacing: 3
        Repeater {
            model: 4
            Rectangle {
                width: 13; height: 18; radius: 2
                // index 1 = the workspace you're on
                readonly property bool shown: root.opt === "all" || (root.opt === "others" && index !== 1)
                    || (root.opt === "monitor" && index < 2) || (root.opt === "workspace" && index === 1)
                color: shown ? root.ink : root.soft
                opacity: shown ? 1 : 0.5
                border.width: index === 1 ? 1 : 0
                border.color: root.ink
            }
        }
    }

    // previews
    Rectangle {
        visible: root.key === "previews"
        anchors.centerIn: parent
        width: 42; height: 28; radius: 4
        color: root.opt === "off" ? "transparent" : root.soft
        border.width: 1; border.color: root.ui.tint(0.18)
        Rectangle {
            visible: root.opt !== "off"
            x: 5; y: 7; width: 22; height: 3; radius: 1.5; color: root.ink
            SequentialAnimation on width {
                running: root.opt === "live" && root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 30; duration: 700 }
                NumberAnimation { to: 14; duration: 700 }
            }
        }
        Rectangle { visible: root.opt !== "off"; x: 5; y: 13; width: 16; height: 3; radius: 1.5; color: root.ink; opacity: 0.6 }
        Rectangle {
            anchors.centerIn: parent
            visible: root.opt === "off"
            width: 14; height: 14; radius: 4; color: root.ink
        }
    }

    // backdrop
    Rectangle {
        visible: root.key === "backdrop"
        anchors.centerIn: parent
        width: 46; height: 28; radius: 4
        clip: true
        color: root.opt === "dim" ? Qt.rgba(0, 0, 0, 0.55) : root.ui.tint(0.10)
        border.width: 1; border.color: root.ui.tint(0.18)
        Repeater {   // desktop "detail": sharp, darkened, or blurred
            model: 4
            Rectangle {
                x: 5 + index * 9; y: 5 + (index % 2) * 9
                width: root.opt === "blur" ? 12 : 6; height: root.opt === "blur" ? 12 : 6
                radius: root.opt === "blur" ? 6 : 1
                color: Qt.hsla(index * 0.22, 0.5, 0.6, 1)
                opacity: root.opt === "blur" ? 0.35 : (root.opt === "dim" ? 0.4 : 0.9)
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 16; height: 11; radius: 2
            color: root.ui.surface
            border.width: 1.5; border.color: root.ink
        }
    }

    // open as
    Item {
        visible: root.key === "openAs"
        anchors.fill: parent
        Rectangle { x: 6; y: 3; width: 52; height: 5; radius: 2; color: root.soft }
        Rectangle {
            x: root.opt === "panel" ? 10 : 18
            y: root.opt === "panel" ? 9 : 12
            width: 28; height: 20; radius: 3
            color: root.ink
        }
    }
}
