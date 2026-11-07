import QtQuick

// grid: rows, a block per workspace
Flickable {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real gap: Math.round(ui.px(sw.cfg.tileGap) * k)
    readonly property real cardW: Math.max(90, Math.round(sw.cfg.tileSize * k))
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.titleFs * 1.9) : 0
    readonly property real cardH: Math.round(cardW * 0.62) + titleH
    readonly property int cols: Math.max(1, Math.floor((width + gap) / (cardW + gap)))

    readonly property var sections: {
        const g = sw.groups
        if (!g || g.length === 0)
            return sw.items.length > 0 ? [{ header: false, start: 0, count: sw.items.length, group: null }] : []
        const out = []
        for (let i = 0; i < g.length; i++)
            if (g[i].count > 0) out.push({ header: true, start: g[i].start, count: g[i].count, group: g[i] })
        return out
    }

    // the rows as they are on screen, so up/down goes to the window right above or below
    // the selected one, also across workspace blocks. a row that is short is centered
    // (a block of fewer windows than columns), the last row of a longer block sits left
    readonly property var navRows: {
        const out = []
        const step = cardW + gap
        const secs = sections
        for (let s = 0; s < secs.length; s++) {
            const count = secs[s].count
            const perRow = Math.max(1, Math.min(cols, count))
            const flowW = Math.min(blockW, count * step - gap)
            const left = (blockW - flowW) / 2
            for (let r = 0; r * perRow < count; r++) {
                const row = []
                for (let c = 0; c < perRow && r * perRow + c < count; c++)
                    row.push({ i: secs[s].start + r * perRow + c, x: left + c * step + cardW / 2 })
                out.push(row)
            }
        }
        return out
    }
    Binding { target: view.sw; property: "navRows"; value: view.navRows }

    contentWidth: width
    contentHeight: col.y + col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function reveal(t) {
        const p = t.mapToItem(col, 0, 0)
        const top = p.y - gap
        const bottom = p.y + t.height + gap
        if (top < contentY) contentY = Math.max(0, top)
        else if (bottom > contentY + height) contentY = Math.min(Math.max(0, contentHeight - height), bottom - height)
    }

    // centered block
    readonly property real blockW: Math.min(width, cols * cardW + (cols - 1) * gap)

    Column {
        id: col
        width: view.blockW
        x: Math.round((view.width - width) / 2)
        y: Math.max(0, Math.round((view.height - implicitHeight) / 2))
        spacing: view.gap * 2

        Repeater {
            model: view.sections
            delegate: Column {
                id: section
                property var sec: modelData
                width: col.width
                spacing: Math.round(view.gap * 0.6)

                Flow {
                    // short rows sit centered
                    width: Math.min(parent.width, section.sec.count * (view.cardW + view.gap) - view.gap)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: view.gap

                    Repeater {
                        model: section.sec.count
                        delegate: WindowCard {
                            sw: view.sw
                            itemIndex: section.sec.start + index
                            item: view.sw.items[itemIndex] !== undefined ? view.sw.items[itemIndex] : null
                            width: view.cardW
                            height: view.cardH
                            showTitle: view.sw.cfg.showTitles
                            uniform: view.sw.cfg.equalSizes
                            showBadge: view.sw.showBadges
                            iconSize: view.sw.cfg.iconSize * view.k
                            onRevealRequested: function(t) { view.reveal(t) }
                        }
                    }
                }
            }
        }
    }
}
