import QtQuick
import "../controls"

// compact: one panel with every window in it at the same size, packed close
// together, the selected window's title underneath. The Windows and macOS way.
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property int n: sw.items.length
    readonly property real gap: Math.round(ui.px(sw.cfg.tileGap) * k)
    readonly property real pad: Math.max(Math.round(ui.px(12) * k), gap)
    readonly property real titleH: Math.round(ui.fs(12) * 2.2)
    readonly property real roomW: Math.max(120, width * 0.94 - pad * 2)
    readonly property real roomH: Math.max(90, height * 0.9 - pad * 2 - titleH)

    // the preview size: Preview size, made smaller until every window fits
    // without scrolling, but never smaller than a readable thumbnail
    readonly property real ratio: 0.625
    readonly property var fit: {
        const want = Math.max(80, Math.round(sw.cfg.tileSize * k))
        if (n <= 0) return { w: want, cols: 1, rows: 1 }
        for (let w = want; w >= 72; w -= 4) {
            const cols = Math.max(1, Math.min(n, Math.floor((roomW + gap) / (w + gap))))
            const rows = Math.ceil(n / cols)
            if (rows * Math.round(w * ratio) + (rows - 1) * gap <= roomH) return { w: w, cols: cols, rows: rows }
        }
        const cols = Math.max(1, Math.min(n, Math.floor((roomW + gap) / (72 + gap))))
        return { w: 72, cols: cols, rows: Math.ceil(n / cols) }
    }
    readonly property real cardW: fit.w
    readonly property real cardH: Math.round(cardW * ratio)
    readonly property int cols: fit.cols

    Binding { target: view.sw; property: "navCols"; value: view.cols }

    readonly property var current: sw.selectedItem

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(view.width, view.cols * view.cardW + (view.cols - 1) * view.gap + view.pad * 2)
        height: Math.min(view.height, flick.contentHeight + view.pad * 2 + view.titleH)
        visible: view.n > 0
        radius: ui.r(3)
        color: Qt.rgba(ui.surface.r, ui.surface.g, ui.surface.b, Math.max(0.6, ui.opacityF))
        border.width: 1
        border.color: ui.frameOn ? ui.accent : ui.tint(0.14)

        Flickable {
            id: flick
            x: view.pad
            y: view.pad
            width: panel.width - view.pad * 2
            height: panel.height - view.pad * 2 - view.titleH
            contentWidth: width
            contentHeight: grid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            function reveal(t) {
                const p = t.mapToItem(grid, 0, 0)
                if (p.y < contentY) contentY = Math.max(0, p.y)
                else if (p.y + t.height > contentY + height)
                    contentY = Math.min(Math.max(0, contentHeight - height), p.y + t.height - height)
            }

            Grid {
                id: grid
                columns: view.cols
                spacing: view.gap
                Repeater {
                    model: view.n
                    delegate: WindowCard {
                        sw: view.sw
                        itemIndex: index
                        item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
                        width: view.cardW
                        height: view.cardH
                        uniform: true
                        showTitle: false
                        showBadge: view.sw.showBadges
                        iconSize: view.sw.cfg.iconSize * view.k
                        onRevealRequested: function(t) { flick.reveal(t) }
                    }
                }
            }
        }

        // the selected window's title and app
        Txt {
            ui: view.ui
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: view.pad
            anchors.rightMargin: view.pad
            height: view.titleH
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: ui.fs(12)
            font.weight: Font.DemiBold
            text: view.current ? (view.current.title || view.current.cls || "") : ""
        }
    }
}
