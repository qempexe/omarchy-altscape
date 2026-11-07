import QtQuick

// the edge of a panel: a plain neutral line, one color when "Window outline" is on,
// or the theme's window border gradient (at its angle) when that has several colors.
// sits over the background, same size as the panel
Item {
    id: root

    property var ui: null
    property real radius: 0

    readonly property bool gradientOn: !!ui && ui.frameGradientOn

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: !root.gradientOn
        border.width: 1
        border.color: root.ui && root.ui.frameOn ? root.ui.frameColor : (root.ui ? root.ui.tint(0.14) : "#24ffffff")
        opacity: root.ui && root.ui.frameOn ? 0.8 : 1
    }

    Canvas {
        anchors.fill: parent
        visible: root.gradientOn
        opacity: 0.85
        readonly property var stops: root.ui ? root.ui.borderColors : []
        readonly property real angle: root.ui ? root.ui.borderAngle : 0
        readonly property real rad: root.radius
        onStopsChanged: requestPaint()
        onAngleChanged: requestPaint()
        onRadChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const n = stops ? stops.length : 0
            if (!visible || n < 2 || width < 4 || height < 4) return
            // the border's gradient, across the panel at its angle
            const a = angle * Math.PI / 180, dx = Math.cos(a), dy = Math.sin(a)
            const half = (Math.abs(dx) * width + Math.abs(dy) * height) / 2
            const g = ctx.createLinearGradient(width / 2 - dx * half, height / 2 - dy * half,
                                               width / 2 + dx * half, height / 2 + dy * half)
            for (let i = 0; i < n; i++) g.addColorStop(i / (n - 1), stops[i])
            // half a pixel in, so the one pixel line lands on whole pixels
            const r = Math.max(0, Math.min(rad, width / 2, height / 2)), x = 0.5, y = 0.5, w = width - 1, h = height - 1
            ctx.strokeStyle = g
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.arcTo(x + w, y, x + w, y + h, r)
            ctx.arcTo(x + w, y + h, x, y + h, r)
            ctx.arcTo(x, y + h, x, y, r)
            ctx.arcTo(x, y, x + w, y, r)
            ctx.closePath()
            ctx.stroke()
        }
    }
}
