import QtQuick

// dock: small previews along the bottom, growing around the selection
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property var sections: {
        var g = sw.groups
        if (!g || g.length === 0)
            return sw.items.length > 0 ? [{ start: 0, count: sw.items.length }] : []
        var out = []
        for (var i = 0; i < g.length; i++)
            if (g[i].count > 0) out.push({ start: g[i].start, count: g[i].count })
        return out
    }

    readonly property real gap: Math.round(ui.px(sw.cfg.tileGap * 0.85) * k)
    readonly property real grow: 1.7
    // base size, shrunk until the row (incl. the magnified ones) fits
    readonly property real cellW: {
        var want = Math.max(48, sw.cfg.tileSize * 0.6 * k)
        var n = sw.items.length
        if (n <= 0) return want
        var room = width - (n - 1) * gap - Math.max(0, sections.length - 1) * gap * 3
        return Math.max(28, Math.min(want, room / (n + (grow - 1) * 2.2), height / grow * 1.6 * 0.9))
    }
    readonly property real cellH: Math.round(cellW / 1.6)

    Binding { target: view.sw; property: "navCols"; value: 1 }

    // how much bigger, by distance from the selection
    function magnify(i) {
        var d = Math.abs(i - sw.selected)
        return 1 + (grow - 1) * Math.max(0, 1 - d / 2.2)
    }

    Row {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(view.height * 0.12)
        spacing: view.gap * 1.5

        Repeater {
            model: view.sections
            delegate: Row {
                id: section
                property var sec: modelData
                spacing: view.gap * 1.5
                anchors.bottom: parent.bottom

                Rectangle {
                    visible: index > 0
                    width: 1
                    height: view.cellH
                    anchors.bottom: parent.bottom
                    color: view.ui.tint(0.22)
                }

                Row {
                    spacing: view.gap
                    anchors.bottom: parent.bottom
                    Repeater {
                        model: section.sec.count
                        delegate: WindowCard {
                            readonly property real f: view.magnify(itemIndex)
                            sw: view.sw
                            itemIndex: section.sec.start + index
                            item: view.sw.items[itemIndex] !== undefined ? view.sw.items[itemIndex] : null
                            anchors.bottom: parent.bottom
                            width: Math.round(view.cellW * f)
                            height: Math.round(view.cellH * f) + titleH
                            showTitle: view.sw.cfg.showTitles && isSelected
                            uniform: view.sw.cfg.equalSizes
                            iconSize: Math.min(view.sw.cfg.iconSize * view.k, height * 0.4)
                            Behavior on width { enabled: view.ui.animations; NumberAnimation { duration: view.sw.cfg.speed * 0.8; easing.type: Easing.OutCubic } }
                            Behavior on height { enabled: view.ui.animations; NumberAnimation { duration: view.sw.cfg.speed * 0.8; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
