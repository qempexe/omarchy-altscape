import QtQuick
import Quickshell

// docked panel, hangs off the bar button.
// BarWidget only uses: opened, open(), close(), closeForPopoutSwitch()
Item {
    id: root

    visible: false

    property var bar: null
    property var anchorItem: null
    property var hostWidget: null
    property var svc: null         // the service, injected by BarWidget.qml
    readonly property var ui: svc ? svc.ui : null

    readonly property bool opened: popup.visible
    readonly property bool popoutSwitchClosing: false
    // true for a moment after a click outside closed us, so that same click
    // on the bar button doesn't reopen it
    property bool justClosedByGrab: false

    function open() {
        if (popup.visible) return
        root.locate()
        popup.visible = true
    }
    function close() { popup.visible = false }
    function toggle() { if (popup.visible) root.close(); else root.open() }
    function closeForPopoutSwitch() { root.close() }

    function stepTab(d) {
        if (!root.ui) return
        var names = ["visualisers", "settings"]
        var i = names.indexOf(root.ui.tabName)
        root.ui.tabName = names[(Math.max(0, i) + d + names.length) % names.length]
    }

    // placement. done right before opening because the bar position isn't known at load.
    // anchored to the bar window's outer edge, not the widget (that one sits in the padding)
    readonly property bool vertical: {
        var b = root.bar
        if (!b) return false
        try {
            if (b.vertical === true || b.isVertical === true) return true
            if (b.orientation !== undefined && b.orientation === Qt.Vertical) return true
        } catch (e) { }
        return false
    }
    property bool barAtTop: true              // horizontal bar: top edge (else bottom)
    property bool barAtLeft: true             // vertical bar: left edge (else right)
    property bool useRect: false              // anchor to the bar window's edge
    property var anchorWin: null
    property real rectX: 0
    property real rectY: 0
    property real rectW: 1
    property real rectH: 1
    property real extra: 0                    // extra clearance when only the widget is known
    property real maxHeight: 620
    readonly property int gap: 0              // free space between the bar and the panel (0 = flush)
    readonly property real padTop: (!vertical && barAtTop) ? gap + extra : 0
    readonly property real padBottom: (!vertical && !barAtTop) ? gap + extra : 0
    readonly property real padLeft: (vertical && barAtLeft) ? gap + extra : 0
    readonly property real padRight: (vertical && !barAtLeft) ? gap + extra : 0

    function sideFromText(v) {
        var t = String(v === undefined || v === null ? "" : v).toLowerCase()
        if (t.indexOf("top") >= 0) return "top"
        if (t.indexOf("bottom") >= 0) return "bottom"
        if (t.indexOf("left") >= 0) return "left"
        if (t.indexOf("right") >= 0) return "right"
        return ""
    }

    function locate() {
        var item = root.anchorItem
        if (!item) return
        var scr = item.screen
        var sw = scr ? scr.width : 1920
        var sh = scr ? scr.height : 1080
        var side = ""
        var qsWin = null
        var win = null

        // 1. ask the bar window which edge it's on
        try { qsWin = item.QsWindow.window } catch (e0) { qsWin = null }
        try { win = qsWin ? qsWin : item.Window.window } catch (e1) { win = null }
        try {
            var an = win ? win.anchors : null
            if (an) {
                if (root.vertical) {
                    if (an.left && !an.right) side = "left"
                    else if (an.right && !an.left) side = "right"
                } else {
                    if (an.top && !an.bottom) side = "top"
                    else if (an.bottom && !an.top) side = "bottom"
                }
            }
        } catch (e2) { side = "" }

        // 2. the bar object might just say it
        if (side === "" && root.bar) {
            var names = ["position", "barPosition", "edge", "side", "location", "placement", "barSide"]
            for (var i = 0; i < names.length && side === ""; i++) {
                var got = ""
                try { got = root.sideFromText(root.bar[names[i]]) } catch (e3) { got = "" }
                if ((root.vertical && (got === "left" || got === "right"))
                        || (!root.vertical && (got === "top" || got === "bottom")))
                    side = got
            }
        }

        // 3. fallback: which half of the screen we're in
        var pos = item.mapToItem(null, 0, 0)
        if (side === "") {
            if (root.vertical) side = pos.x < sw / 2 ? "left" : "right"
            else side = pos.y < sh / 2 ? "top" : "bottom"
        }
        root.barAtTop = side === "top"
        root.barAtLeft = side === "left"

        // anchor rect on the bar window's outer edge
        var ww = (win && win.width > 0) ? win.width : 0
        var wh = (win && win.height > 0) ? win.height : 0
        var small = root.vertical ? (ww > 0 && ww < sw * 0.5) : (wh > 0 && wh < sh * 0.5)
        root.useRect = !!qsWin && small
        root.anchorWin = qsWin
        if (root.useRect) {
            if (root.vertical) {
                root.rectW = 1
                root.rectH = Math.max(1, item.height)
                root.rectY = pos.y
                root.rectX = side === "left" ? Math.max(0, ww - 1) : 0
            } else {
                root.rectW = Math.max(1, item.width)
                root.rectH = 1
                root.rectX = pos.x
                root.rectY = side === "top" ? Math.max(0, wh - 1) : 0
            }
            root.extra = 0
        } else {
            root.extra = 6                    // only the widget is known: allow a little for bar padding
        }

        // max height that still fits under/over the bar
        var thick = (!root.vertical && wh > 0 && wh < sh * 0.5) ? wh : 40
        var room = root.vertical ? sh - 40 : sh - thick - root.gap - root.extra - 16
        root.maxHeight = Math.max(300, Math.min(1100, room))
    }

    // click outside closes. focus grab is created at runtime so a shell without
    // the module still works (x button + esc)
    property var grab: null

    Timer { id: grabTimer; interval: 500; onTriggered: root.justClosedByGrab = false }

    Component.onCompleted: {
        try {
            var g = Qt.createQmlObject(
                'import Quickshell.Hyprland\nHyprlandFocusGrab { }', root, "AltscapeFocusGrab")
            g.windows = [popup]
            g.cleared.connect(function() {
                root.justClosedByGrab = true
                grabTimer.restart()
                popup.visible = false
            })
            root.grab = g
        } catch (e) {
            root.grab = null
        }
    }

    PopupWindow {
        id: popup

        visible: false
        color: "transparent"
        implicitWidth: (root.ui ? root.ui.cfgSafe.windowWidth : 600) + root.padLeft + root.padRight
        implicitHeight: Math.min(root.maxHeight, root.ui ? root.ui.cfgSafe.windowHeight : 680) + root.padTop + root.padBottom

        anchor.item: root.useRect ? null : root.anchorItem
        anchor.window: root.useRect ? root.anchorWin : null
        anchor.rect.x: root.rectX
        anchor.rect.y: root.rectY
        anchor.rect.width: root.rectW
        anchor.rect.height: root.rectH
        // open away from the bar
        anchor.edges: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                    : (root.barAtTop ? Edges.Bottom : Edges.Top)
        anchor.gravity: root.vertical ? (root.barAtLeft ? Edges.Right : Edges.Left)
                                      : (root.barAtTop ? Edges.Bottom : Edges.Top)
        // slide along the bar only, never onto it
        anchor.adjustment: root.vertical ? PopupAdjustment.SlideY : PopupAdjustment.SlideX

        onVisibleChanged: {
            if (root.grab) Qt.callLater(function() { root.grab.active = popup.visible })
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: root.close()
        }
        Shortcut {
            sequence: "Alt+Right"
            context: Qt.WindowShortcut
            onActivated: root.stepTab(1)
        }
        Shortcut {
            sequence: "Alt+Left"
            context: Qt.WindowShortcut
            onActivated: root.stepTab(-1)
        }

        Item {
            anchors.fill: parent
            anchors.topMargin: root.padTop
            anchors.bottomMargin: root.padBottom
            anchors.leftMargin: root.padLeft
            anchors.rightMargin: root.padRight

            Loader {
                id: viewLoader
                anchors.fill: parent
                active: root.svc !== null
                sourceComponent: Component { PanelView { svc: root.svc; shown: popup.visible } }
            }
        }
    }
}
