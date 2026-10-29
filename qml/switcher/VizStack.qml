import QtQuick

// stack: deck, selected in front, next ones behind (wraps), previous slides off
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property int n: sw.items.length
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    readonly property real captionH: 0
    readonly property real cardW: Math.max(120, Math.min(Math.round(sw.cfg.tileSize * 1.8 * k), width * 0.55,
                                                         (height - captionH - titleH) / 0.62 * 0.82))
    readonly property real cardH: Math.round(cardW * 0.62) + titleH
    readonly property real baseX: width / 2 - cardW / 2 - cardW * 0.18
    readonly property real baseY: (height - captionH) / 2 - cardH / 2 + cardH * 0.08

    Binding { target: view.sw; property: "navCols"; value: 1 }
    Binding { target: view.sw; property: "hoverSelects"; value: false }

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

    Repeater {
        model: view.n
        delegate: WindowCard {
            // distance behind the selection, wraps so the deck never runs out
            readonly property real d: {
                let x = index - view.pos
                if (view.n > 2 && x < -1.5) x += view.n
                return x
            }
            sw: view.sw
            itemIndex: index
            item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
            width: view.cardW
            height: view.cardH
            showTitle: view.sw.cfg.showTitles
            showBadge: true
            iconSize: view.sw.cfg.iconSize * view.k
            visible: d > -1.5 && d < 5
            x: d >= 0 ? view.baseX + d * view.cardW * 0.17 : view.baseX + d * view.cardW * 0.45
            y: d >= 0 ? view.baseY - d * view.cardH * 0.07 : view.baseY
            z: d >= 0 ? 100 - Math.round(d * 10) : 101
            scale: d >= 0 ? 1 - d * 0.075 : 1
            opacity: d >= 0 ? Math.max(0, 1 - d * 0.17) : Math.max(0, 1 + d * 1.4)
        }
    }
}
