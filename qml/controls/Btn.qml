import QtQuick

// kind: primary | normal | danger
Rectangle {
    id: root

    property var ui: null
    property string text: ""
    property string kind: "normal"
    property bool active: false          // toggled-on look for normal buttons
    property alias hovered: area.containsMouse

    signal clicked()

    readonly property bool primary: kind === "primary"
    readonly property bool danger: kind === "danger"

    implicitWidth: label.implicitWidth + ui.px(16)
    implicitHeight: ui.px(24)
    radius: ui.r(1.5)
    opacity: enabled ? 1.0 : 0.4
    color: primary ? ui.accent
         : (active ? ui.accentTint(0.25) : ui.tint(area.containsMouse ? 0.16 : 0.08))
    border.width: danger || active ? 1 : 0
    border.color: danger ? ui.bad : ui.accent
    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 90 } }

    Txt {
        id: label
        ui: root.ui
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? ui.accentText : (root.danger ? ui.bad : ui.fg)
        font.pixelSize: ui.fs(11)
        font.weight: root.primary ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
