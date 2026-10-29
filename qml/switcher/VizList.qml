import QtQuick

// list: small previews down the side, selected one big
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real gap: Math.round(ui.px(sw.cfg.tileGap * 0.85) * k)
    readonly property real colW: Math.max(90, Math.min(Math.round(sw.cfg.tileSize * 0.9 * k), width * 0.26))
    readonly property real thumbH: Math.round(colW / 1.6)

    readonly property var sections: {
        const g = sw.groups
        if (!g || g.length === 0)
            return sw.items.length > 0 ? [{ start: 0, count: sw.items.length }] : []
        const out = []
        for (let i = 0; i < g.length; i++)
            if (g[i].count > 0) out.push({ start: g[i].start, count: g[i].count })
        return out
    }

    Binding { target: view.sw; property: "navCols"; value: 1 }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: view.colW
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        function reveal(t) {
            const p = t.mapToItem(col, 0, 0)
            if (p.y < contentY) contentY = Math.max(0, p.y - view.gap)
            else if (p.y + t.height > contentY + height)
                contentY = Math.min(Math.max(0, contentHeight - height), p.y + t.height - height + view.gap)
        }

        Column {
            id: col
            width: flick.width
            y: Math.max(0, (flick.height - implicitHeight) / 2)
            spacing: view.gap

            Repeater {
                model: view.sections
                delegate: Column {
                    id: section
                    property var sec: modelData
                    width: col.width
                    spacing: view.gap

                    Rectangle {
                        visible: index > 0
                        width: parent.width * 0.6
                        height: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: view.ui.tint(0.22)
                    }

                    Repeater {
                        model: section.sec.count
                        delegate: WindowCard {
                            sw: view.sw
                            itemIndex: section.sec.start + index
                            item: view.sw.items[itemIndex] !== undefined ? view.sw.items[itemIndex] : null
                            width: section.width
                            height: view.thumbH
                            showTitle: false
                            uniform: view.sw.cfg.equalSizes
                            iconSize: Math.min(view.sw.cfg.iconSize * view.k, view.thumbH * 0.45)
                            onRevealRequested: function(t) { flick.reveal(t) }
                        }
                    }
                }
            }
        }
    }

    // big one
    WindowCard {
        anchors.left: flick.right
        anchors.leftMargin: view.gap * 3
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        sw: view.sw
        itemIndex: view.sw.selected
        item: view.sw.selectedItem
        showTitle: view.sw.cfg.showTitles
        iconSize: view.sw.cfg.iconSize * 1.5 * view.k
    }
}
