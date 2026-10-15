import QtQuick
import "../controls"

// picks the layout component
Item {
    id: root

    property var sw: null
    property real k: 1

    Loader {
        id: loader
        anchors.fill: parent
        active: root.sw !== null && root.sw.ui !== null
        sourceComponent: {
            switch (root.sw ? root.sw.mode : "grid") {
            case "strip": return strip
            case "carousel": return carousel
            case "ring": return ring
            case "list": return list
            case "overview": return overview
            case "stack": return stack
            case "dock": return dock
            default: return grid
            }
        }
    }

    Component { id: grid; VizGrid { sw: root.sw; k: root.k } }
    Component { id: strip; VizStrip { sw: root.sw; k: root.k } }
    Component { id: carousel; VizCarousel { sw: root.sw; k: root.k } }
    Component { id: ring; VizRing { sw: root.sw; k: root.k } }
    Component { id: list; VizList { sw: root.sw; k: root.k } }
    Component { id: overview; VizOverview { sw: root.sw; k: root.k } }
    Component { id: stack; VizStack { sw: root.sw; k: root.k } }
    Component { id: dock; VizDock { sw: root.sw; k: root.k } }

    Txt {
        ui: root.sw ? root.sw.ui : null
        anchors.centerIn: parent
        visible: root.sw !== null && root.sw.ui !== null && root.sw.items.length === 0
        text: root.sw && root.sw.svc && root.sw.svc.ready ? "No windows here" : "Looking for windows…"
        opacity: 0.5
        font.pixelSize: root.sw && root.sw.ui ? root.sw.ui.fs(13) : 13
    }
}
