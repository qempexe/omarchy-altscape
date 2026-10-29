import QtQuick

// tiny drawing of each layout for the picker
Item {
    id: root

    property var ui: null
    property string mode: "grid"
    property bool on: false

    width: 72
    height: 40

    readonly property color ink: on ? ui.accent : ui.tint(0.55)
    readonly property color soft: on ? ui.accentTint(0.45) : ui.tint(0.22)

    // grid 3x2
    Grid {
        visible: root.mode === "grid"
        anchors.centerIn: parent
        columns: 3
        spacing: 4
        Repeater { model: 6; Rectangle { width: 18; height: 12; radius: 2; color: index === 4 ? root.ink : root.soft } }
    }
    // strip
    Row {
        visible: root.mode === "strip"
        anchors.centerIn: parent
        spacing: 3
        Repeater { model: 5; Rectangle { width: 12; height: 16; radius: 2; color: index === 2 ? root.ink : root.soft } }
    }
    // carousel
    Item {
        visible: root.mode === "carousel"
        anchors.fill: parent
        Rectangle { x: 6; y: 14; width: 14; height: 14; radius: 2; color: root.soft; opacity: 0.6 }
        Rectangle { x: 16; y: 11; width: 16; height: 18; radius: 2; color: root.soft }
        Rectangle { x: 52; y: 14; width: 14; height: 14; radius: 2; color: root.soft; opacity: 0.6 }
        Rectangle { x: 40; y: 11; width: 16; height: 18; radius: 2; color: root.soft }
        Rectangle { x: 24; y: 7; width: 24; height: 26; radius: 3; color: root.ink }
    }
    // ring
    Item {
        visible: root.mode === "ring"
        anchors.fill: parent
        Repeater {
            model: 7
            Rectangle {
                readonly property real a: index / 7 * Math.PI * 2 - Math.PI / 2
                width: 9; height: 7; radius: 2
                x: root.width / 2 + Math.cos(a) * 15 - width / 2
                y: root.height / 2 + Math.sin(a) * 15 - height / 2
                color: index === 0 ? root.ink : root.soft
            }
        }
        Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: root.soft }
    }
    // list + big one
    Item {
        visible: root.mode === "list"
        anchors.fill: parent
        Column {
            x: 6; y: 6; spacing: 3
            Repeater { model: 5; Rectangle { width: 24; height: 4; radius: 2; color: index === 1 ? root.ink : root.soft } }
        }
        Rectangle { x: 36; y: 6; width: 30; height: 28; radius: 3; color: root.ink; opacity: 0.85 }
    }
    // overview
    Row {
        visible: root.mode === "overview"
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: 3
            Rectangle {
                width: 20; height: 14; radius: 2; color: "transparent"
                border.width: 1; border.color: index === 1 ? root.ink : root.soft
                Rectangle { x: 2; y: 2; width: index === 0 ? 16 : 7; height: 10; radius: 1; color: index === 1 ? root.ink : root.soft }
                Rectangle { visible: index !== 0; x: 11; y: 2; width: 7; height: 10; radius: 1; color: root.soft }
            }
        }
    }
    // stack
    Item {
        visible: root.mode === "stack"
        anchors.fill: parent
        Repeater {
            model: 4
            Rectangle {
                readonly property int d: 3 - index
                x: 14 + d * 7; y: 8 - d * 2
                width: 30 - d * 2; height: 22 - d * 2; radius: 3
                color: d === 0 ? root.ink : root.soft
                opacity: 1 - d * 0.18
            }
        }
    }
    // dock
    Row {
        visible: root.mode === "dock"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        spacing: 3
        Repeater {
            model: 5
            Rectangle {
                readonly property real f: [1, 1.35, 1.8, 1.35, 1][index]
                anchors.bottom: parent.bottom
                width: Math.round(9 * f); height: Math.round(6 * f); radius: 1.5
                color: index === 2 ? root.ink : root.soft
            }
        }
    }
    // compact: equal windows close together in one panel
    Rectangle {
        visible: root.mode === "compact"
        anchors.centerIn: parent
        width: 60; height: 26; radius: 4
        color: "transparent"
        border.width: 1; border.color: root.soft
        Row {
            anchors.centerIn: parent
            spacing: 2
            Repeater { model: 4; Rectangle { width: 12; height: 14; radius: 1.5; color: index === 1 ? root.ink : root.soft } }
        }
    }
}
