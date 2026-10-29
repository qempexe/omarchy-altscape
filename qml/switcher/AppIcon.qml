import QtQuick
import "../controls"

// app icon, or the first letter in a circle if there's none
Item {
    id: root

    property var ui: null
    property string source: ""
    property string name: ""
    property real size: 32

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    // local files and the icon theme only. if some .desktop file points at a url
    // we just show the letter, never fetch anything
    readonly property string url: {
        const s = String(source || "")
        if (s.charAt(0) === "/") return "file://" + s
        if (/^(file:\/\/\/|image:\/\/)/.test(s)) return s
        return ""
    }
    readonly property bool hasImage: img.status === Image.Ready

    Image {
        id: img
        anchors.fill: parent
        source: root.url
        sourceSize.width: Math.ceil(root.size * 2)
        sourceSize.height: Math.ceil(root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        visible: root.hasImage
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.hasImage
        radius: width / 2
        color: root.ui ? root.ui.accentTint(0.22) : "#444444"
        border.width: 1
        border.color: root.ui ? root.ui.tint(0.18) : "#666666"
        Txt {
            ui: root.ui
            anchors.centerIn: parent
            text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : "?"
            font.pixelSize: Math.max(8, Math.round(root.size * 0.46))
            font.weight: Font.DemiBold
        }
    }
}
