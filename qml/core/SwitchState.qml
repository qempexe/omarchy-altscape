import QtQuick
import "../js/Model.js" as Model

// what a layout draws + how the selection moves.
// overlay and panel preview each have one. layouts read items/groups/selected
// and call select()/activate()/closeAt()
Item {
    id: root

    visible: false

    property var svc: null
    property bool active: false          // drawn on screen right now (live previews run)
    property string mode: cfg.mode
    property int navCols: 1              // set by the visualiser: how far Up/Down moves
    // carousel/ring/stack move the selection to a fixed spot, so hover-select
    // would slide windows out from under the mouse. they turn this off
    property bool hoverSelects: true
    // selection came from the mouse: don't scroll lists for it
    property bool pointed: false
    property bool pointerKnown: false
    property point pointerPosition: Qt.point(0, 0)

    readonly property var ui: svc ? svc.ui : null
    readonly property var cfg: svc ? svc.cfg : ({ mode: "grid", scope: "all", order: "workspace", showSpecial: false,
                                                   showEmpty: false, previews: "off", tileSize: 220, iconSize: 40,
                                                   showTitles: true, attention: "pulse", speed: 140 })

    property var items: []
    property var groups: []
    property int selected: 0
    property bool userMoved: false
    property var marks: ({ current: 0, next: 0, prev: 0 })
    property string startWhere: "current"

    // workspace badges when there are no group headers
    readonly property bool showBadges: cfg.order === "recent"
    readonly property var selectedItem: items.length > 0 && selected >= 0 && selected < items.length ? items[selected] : null

    signal activated(string address)

    function rebuild() {
        if (!svc) return
        var keep = selectedItem ? selectedItem.key : ""
        var m = Model.build(svc.info, cfg)
        marks = { current: m.current, next: m.next, prev: m.prev }
        groups = m.groups
        items = m.items
        var i = keep !== "" ? Model.indexOfKey(items, keep) : -1
        if (i >= 0) selected = i
        else selected = Math.max(0, Math.min(selected, items.length - 1))
    }

    // where: current | next | prev
    function start(where) {
        startWhere = where
        userMoved = false
        pointed = false
        pointerKnown = false
        rebuild()
        selected = items.length === 0 ? 0 : marks[where] !== undefined ? marks[where] : 0
    }

    // new data while open: stay on the same window (or the alt+tab target if
    // nothing moved yet)
    function refreshKeeping(where) {
        if (userMoved) { rebuild(); return }
        rebuild()
        selected = items.length === 0 ? 0 : marks[where]
    }

    function select(i) {
        if (items.length === 0) return
        pointed = false
        selected = Math.max(0, Math.min(items.length - 1, i))
        userMoved = true
    }

    // Qt also sends positionChanged when previews appear or move beneath a
    // stationary cursor. The first event only records its global position;
    // later events select only if the cursor itself moved, across all cards.
    function point(i, position) {
        var moved = pointerKnown && (Math.abs(position.x - pointerPosition.x) > 0.5
                                     || Math.abs(position.y - pointerPosition.y) > 0.5)
        if (!pointerKnown || moved) pointerPosition = position
        pointerKnown = true
        if (!moved || items.length === 0 || !hoverSelects) return
        pointed = true
        selected = Math.max(0, Math.min(items.length - 1, i))
        userMoved = true
    }

    function step(d) {
        if (items.length === 0) return
        pointed = false
        selected = (selected + d + items.length * 4) % items.length
        userMoved = true
    }

    function stepRow(d) {
        if (items.length === 0) return
        var n = Math.max(1, navCols)
        if (n === 1) { step(d); return }
        var t = selected + d * n
        if (t < 0 || t >= items.length) return
        pointed = false
        selected = t
        userMoved = true
    }

    // 1-9 -> first window of that group
    function jumpGroup(n) {
        if (groups.length === 0 || n < 1 || n > groups.length) return
        var g = groups[n - 1]
        if (g.count > 0) select(g.start)
    }

    function activate(i) {
        var it = items[i === undefined ? selected : i]
        if (it) activated(it.address)
    }

    function closeAt(i) {
        var it = items[i === undefined ? selected : i]
        if (it && svc) svc.closeWindow(it.address)
    }

    function wsLabelFor(item) { return item ? item.wsLabel : "" }

    Connections {
        target: root.svc
        ignoreUnknownSignals: true
        function onWindowsUpdated() { if (root.active) root.refreshKeeping(root.startWhere) }
    }

    onModeChanged: { navCols = 1; hoverSelects = true }
}
