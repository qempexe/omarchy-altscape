import QtQuick

// ring: windows in a circle, selection turns to the top
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property int n: sw.items.length
    readonly property real side: Math.min(width, height)
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(10) * 1.8) : 0
    // smaller cards as the ring fills up so they don't overlap
    readonly property real cardW: Math.max(64, Math.min(Math.round(sw.cfg.tileSize * 0.7 * k),
                                                        side * 0.28,
                                                        n > 0 ? (Math.PI * side * 0.62) / n * 0.86 : 200))
    readonly property real cardH: Math.round(cardW * 0.62) + titleH
    readonly property real radius: Math.max(10, side / 2 - Math.max(cardW, cardH) * 0.62)

    Binding { target: view.sw; property: "navCols"; value: 1 }
    Binding { target: view.sw; property: "hoverSelects"; value: false }

    // turn = index at the top, always rotates the short way
    property real turn: sw.selected
    NumberAnimation { id: turnAnim; target: view; property: "turn"; duration: view.sw.cfg.speed; easing.type: Easing.OutCubic }
    Connections {
        target: view.sw
        function onSelectedChanged() {
            turnAnim.stop()
            if (view.n <= 0) { view.turn = 0; return }
            var cur = view.turn
            var want = view.sw.selected
            var delta = want - (((cur % view.n) + view.n) % view.n)
            if (delta > view.n / 2) delta -= view.n
            if (delta < -view.n / 2) delta += view.n
            if (view.sw.cfg.speed <= 0) { view.turn = cur + delta; return }
            turnAnim.to = cur + delta
            turnAnim.start()
        }
    }

    Repeater {
        model: view.n
        delegate: WindowCard {
            readonly property real ang: (index - view.turn) / Math.max(1, view.n) * Math.PI * 2 - Math.PI / 2
            sw: view.sw
            itemIndex: index
            item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
            width: view.cardW
            height: view.cardH
            showTitle: view.sw.cfg.showTitles
            showBadge: true
            iconSize: Math.min(view.sw.cfg.iconSize * view.k, view.cardW * 0.35)
            x: view.width / 2 + Math.cos(ang) * view.radius - width / 2
            y: view.height / 2 + Math.sin(ang) * view.radius - height / 2
            z: isSelected ? 10 : 1
            scale: isSelected ? 1.12 : 1
            Behavior on scale { enabled: view.ui.animations; NumberAnimation { duration: 120 } }
        }
    }
}
