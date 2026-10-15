import QtQuick

// on/off chip
Rectangle {
    id: root

    property var ui: null
    property string label: ""
    property bool on: false
    property color tone: ui.accent

    signal clicked()

    implicitWidth: lbl.implicitWidth + ui.px(16)
    implicitHeight: ui.px(24)
    radius: ui.r(1.5)
    color: on ? Qt.rgba(tone.r, tone.g, tone.b, 0.22) : ui.tint(area.containsMouse ? 0.12 : 0.06)
    border.width: 1
    border.color: on ? tone : ui.tint(0.10)
    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 90 } }

    Txt {
        id: lbl
        ui: root.ui
        anchors.centerIn: parent
        text: root.label
        color: root.on ? ui.onText(root.tone) : ui.fg
        font.pixelSize: ui.fs(11)
        font.weight: root.on ? Font.DemiBold : Font.Normal
        opacity: root.on ? 1.0 : 0.8
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
