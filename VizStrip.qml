import QtQuick

// strip: one row across, split by workspace
Flickable {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real gap: Math.max(6, Math.round(ui.px(12) * k))
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    readonly property real headH: 0
    // as big as the setting allows but never taller than we have,
    // and shrunk so everything fits before it has to scroll
    readonly property real fitW: sw.items.length > 0
        ? (width - (sw.items.length - 1) * gap - Math.max(0, sections.length - 1) * gap * 3) / sw.items.length : width
    readonly property real cardW: Math.max(80, Math.min(Math.round(sw.cfg.tileSize * k), Math.floor(fitW),
                                                        Math.round((height - headH - titleH - 8) / 0.62)))
    readonly property real cardH: Math.round(cardW * 0.62) + titleH

    readonly property var sections: {
        var g = sw.groups
        if (!g || g.length === 0)
            return sw.items.length > 0 ? [{ header: false, start: 0, count: sw.items.length, group: null }] : []
        var out = []
        for (var i = 0; i < g.length; i++)
            if (g[i].count > 0) out.push({ header: true, start: g[i].start, count: g[i].count, group: g[i] })
        return out
    }

    Binding { target: view.sw; property: "navCols"; value: 1 }

    contentWidth: Math.max(width, row.implicitWidth)
    contentHeight: height
    clip: true
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds

    function reveal(t) {
        var p = t.mapToItem(row, 0, 0)
        var left = row.x + p.x - gap
        var right = row.x + p.x + t.width + gap
        if (left < contentX) contentX = Math.max(0, left)
        else if (right > contentX + width) contentX = Math.min(Math.max(0, contentWidth - width), right - width)
    }

    Row {
        id: row
        x: Math.max(0, (view.width - implicitWidth) / 2)
        y: Math.max(0, (view.height - (view.headH + view.cardH)) / 2)
        spacing: view.gap * 1.5

        Repeater {
            model: view.sections
            delegate: Row {
                id: section
                property var sec: modelData
                spacing: view.gap * 1.5

                Rectangle {   // divider before every section but the first
                    visible: index > 0
                    width: 1
                    height: view.headH + view.cardH
                    color: view.ui.tint(0.14)
                }

                Column {
                    spacing: Math.round(view.gap * 0.6)
                    Row {
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
}
