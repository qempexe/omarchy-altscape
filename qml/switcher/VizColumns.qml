import QtQuick
import "../controls"

// columns: one column per workspace, its windows stacked top to bottom,
// the workspace's name above it
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real gap: Math.max(Math.round(ui.px(sw.cfg.tileGap) * k), Math.round(4 * k))
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    readonly property real headH: Math.round(ui.fs(11) * 2 * Math.max(0.6, k))

    // one column per workspace, also in "recent" order (most recent on top)
    readonly property var columns: {
        const byId = {}
        const out = []
        const items = sw.items
        for (let i = 0; i < items.length; i++) {
            const it = items[i]
            if (!byId[it.ws]) {
                byId[it.ws] = { id: it.ws, label: it.wsLabel, special: it.special, idx: [] }
                out.push(byId[it.ws])
            }
            byId[it.ws].idx.push(i)
        }
        out.sort((a, b) => a.special !== b.special ? (a.special ? 1 : -1) : a.id - b.id)
        return out
    }
    readonly property int tallest: {
        let m = 1
        for (let i = 0; i < columns.length; i++) m = Math.max(m, columns[i].idx.length)
        return m
    }

    // Preview size, made smaller until every column fits across and the
    // tallest one fits down
    readonly property real colW: {
        const cols = Math.max(1, columns.length)
        const across = (width * 0.96 - (cols - 1) * gap * 2) / cols
        const down = ((height * 0.92 - headH - (tallest - 1) * gap) / tallest - titleH) / 0.62
        return Math.max(56, Math.floor(Math.min(sw.cfg.tileSize * k, across, down)))
    }
    readonly property real cardH: Math.round(colW * 0.62) + titleH

    Binding { target: view.sw; property: "navCols"; value: 1 }

    Row {
        anchors.centerIn: parent
        spacing: view.gap * 2

        Repeater {
            model: view.columns
            delegate: Column {
                id: column
                property var c: modelData
                width: view.colW
                spacing: view.gap

                Txt {
                    ui: view.ui
                    width: parent.width
                    height: view.headH - view.gap
                    verticalAlignment: Text.AlignBottom
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: Math.max(9, Math.round(view.ui.fs(11) * Math.max(0.7, view.k)))
                    font.weight: Font.DemiBold
                    opacity: 0.7
                    text: column.c.label
                }

                Repeater {
                    model: column.c.idx
                    delegate: WindowCard {
                        sw: view.sw
                        itemIndex: modelData
                        item: view.sw.items[modelData] !== undefined ? view.sw.items[modelData] : null
                        width: view.colW
                        height: view.cardH
                        showTitle: view.sw.cfg.showTitles
                        uniform: view.sw.cfg.equalSizes
                        showBadge: false
                        iconSize: view.sw.cfg.iconSize * view.k
                    }
                }
            }
        }
    }
}
