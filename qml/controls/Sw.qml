import QtQuick

// on/off switch. k scales it with the spacing setting
Rectangle {
    id: sw

    property bool on: false
    property color ink: "white"
    property color accent: "white"
    property color knob: "black"
    property real k: 1
    property bool animate: true

    signal flipped()

    implicitWidth: Math.round(34 * k)
    implicitHeight: Math.round(18 * k)
    radius: height / 2
    opacity: enabled ? 1.0 : 0.45
    color: on ? accent : Qt.rgba(ink.r, ink.g, ink.b, 0.18)
    Behavior on color { enabled: sw.animate; ColorAnimation { duration: 100 } }

    Rectangle {
        readonly property real m: Math.round(3 * sw.k)
        width: sw.height - 2 * m
        height: width
        radius: width / 2
        y: m
        x: sw.on ? sw.width - width - m : m
        color: sw.on ? sw.knob : sw.ink
        opacity: sw.on ? 1 : 0.7
        Behavior on x { enabled: sw.animate; NumberAnimation { duration: 100 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.flipped()
    }
}
