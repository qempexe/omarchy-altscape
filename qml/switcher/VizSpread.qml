import QtQuick
import "../js/Model.js" as Model

// spread: every window at its own shape, as big as the screen allows, in rows
// that fill it. Like Mission Control, without the workspaces.
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property int n: sw.items.length
    readonly property real gap: Math.max(Math.round(ui.px(sw.cfg.tileGap) * k), Math.round(16 * k))
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    readonly property real roomW: width * 0.96
    readonly property real roomH: height * 0.92

    // each window's shape; the same for all with Same size for every window
    readonly property var shapes: {
        const out = []
        for (let i = 0; i < n; i++) {
            const it = sw.items[i]
            out.push(sw.cfg.equalSizes || !it || !(it.rh > 0) ? 16 / 10
                     : Math.max(0.4, Math.min(3, it.rw / it.rh * it.aspect)))
        }
        return out
    }
    // the windows' own height plus the title under it, so the rows leave room for titles
    readonly property var fit: {
        const ars = []
        const t = titleH
        for (let i = 0; i < shapes.length; i++) ars.push(shapes[i])
        const maxH = Math.max(80, height * (n <= 2 ? 0.5 : 0.62))
        const r = Model.spread(ars, roomW, roomH - (t > 0 ? t : 0), gap + t, maxH)
        return r
    }

    Binding { target: view.sw; property: "navCols"; value: 1 }

    Item {
        width: view.roomW
        height: view.roomH
        anchors.centerIn: parent

        Repeater {
            model: view.n
            delegate: WindowCard {
                readonly property var box: view.fit.boxes[index] || { x: 0, y: 0, w: 0, h: 0 }
                sw: view.sw
                itemIndex: index
                item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
                x: box.x
                y: box.y
                width: box.w
                height: box.h + view.titleH
                showTitle: view.sw.cfg.showTitles
                uniform: true
                showBadge: view.sw.showBadges
                iconSize: Math.min(view.sw.cfg.iconSize * view.k, box.h * 0.4)
            }
        }
    }
}
