import QtQuick

// carousel: selected in front, the rest turning away
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    readonly property real captionH: 0
    readonly property real cardW: Math.max(110, Math.min(Math.round(sw.cfg.tileSize * 1.5 * k), width * 0.42,
                                                         (height - captionH - titleH) / 0.62 * 0.9))
    readonly property real cardH: Math.round(cardW * 0.62) + titleH

    Binding { target: view.sw; property: "navCols"; value: 1 }
    Binding { target: view.sw; property: "hoverSelects"; value: false }

    // follows the selection smoothly, snaps on big jumps
    property real pos: sw.selected
    NumberAnimation { id: posAnim; target: view; property: "pos"; duration: view.sw.cfg.speed; easing.type: Easing.OutCubic }
    Connections {
        target: view.sw
        function onSelectedChanged() {
            posAnim.stop()
            if (Math.abs(view.sw.selected - view.pos) > 1.5 || view.sw.cfg.speed <= 0) view.pos = view.sw.selected
            else { posAnim.to = view.sw.selected; posAnim.start() }
        }
    }

    function offsetFor(d) {
        const a = Math.abs(d)
        const s = d < 0 ? -1 : 1
        return s * (Math.min(a, 1) * cardW * 0.66 + Math.max(a - 1, 0) * cardW * 0.30)
    }

    Item {
        id: stage
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height - view.captionH

        Repeater {
            model: view.sw.items.length
            delegate: WindowCard {
                id: c
                readonly property real d: index - view.pos
                readonly property real ad: Math.abs(d)
                sw: view.sw
                itemIndex: index
                item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
                width: view.cardW
                height: view.cardH
                showTitle: view.sw.cfg.showTitles
                showBadge: true
                iconSize: view.sw.cfg.iconSize * view.k
                visible: ad < 4.5
                x: stage.width / 2 - width / 2 + view.offsetFor(d)
                y: stage.height / 2 - height / 2
                z: 100 - Math.round(ad * 10)
                scale: 1 - Math.min(ad, 3) * 0.13
                opacity: ad < 2.5 ? 1 : Math.max(0, 1 - (ad - 2.5) * 0.5)
                transform: Rotation {
                    origin.x: c.width / 2
                    origin.y: c.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: Math.max(-55, Math.min(55, -c.d * 38))
                }
            }
        }
    }
}
