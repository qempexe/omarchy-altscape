import QtQuick
import Quickshell.Wayland
import "Model.js" as Model

// overview: every workspace as a mini screen, windows where they really are
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property real gap: Math.max(8, Math.round(ui.px(16) * k))
    readonly property real headH: 0

    // one box per workspace (in "recent" order we regroup here)
    readonly property var boxes: {
        var byId = {}
        var out = []
        var items = sw.items
        for (var i = 0; i < items.length; i++) {
            var it = items[i]
            if (!byId[it.ws]) {
                byId[it.ws] = { id: it.ws, label: it.wsLabel, monitor: it.monitor, special: it.special,
                                active: false, aspect: it.aspect, count: 0, idx: [] }
                out.push(byId[it.ws])
            }
            byId[it.ws].idx.push(i)
            byId[it.ws].count++
        }
        var g = sw.groups || []
        for (var j = 0; j < g.length; j++) {
            if (byId[g[j].id]) byId[g[j].id].active = g[j].active
            else if (g[j].count === 0)
                out.push({ id: g[j].id, label: g[j].label, monitor: g[j].monitor, special: false,
                           active: g[j].active, aspect: g[j].aspect, count: 0, idx: [] })
        }
        out.sort(function(a, b) {
            if (a.special !== b.special) return a.special ? 1 : -1
            return a.id - b.id
        })
        return out
    }

    readonly property real aspect: {
        var a = 0
        for (var i = 0; i < boxes.length; i++) a = Math.max(a, boxes[i].aspect || 0)
        return a > 0 ? a : 16 / 9
    }
    readonly property var fit: Model.bestGrid(boxes.length, aspect, width, height, gap, headH)

    Binding { target: view.sw; property: "navCols"; value: 1 }

    Flow {
        id: flow
        width: Math.min(view.width, view.fit.cols * view.fit.bw + (view.fit.cols - 1) * view.gap + 1)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: view.gap

        Repeater {
            model: view.boxes
            delegate: Column {
                id: box
                property var b: modelData
                spacing: Math.round(view.headH * 0.2)
                width: view.fit.bw

                Rectangle {
                    id: screen
                    width: view.fit.bw
                    height: view.fit.bh
                    radius: view.ui.r(2)
                    color: "transparent"
                    border.width: box.b.active ? 1.5 : 1
                    border.color: box.b.active ? view.ui.accentTint(0.7) : view.ui.tint(0.10)
                    clip: true

                    Repeater {
                        model: box.b.idx
                        delegate: Rectangle {
                            id: win
                            readonly property int itemIndex: modelData
                            readonly property var it: view.sw.items[itemIndex] !== undefined ? view.sw.items[itemIndex] : null
                            readonly property bool on: view.sw.selected === itemIndex
                            readonly property bool roomy: width > 70 && height > 46
                            x: it ? Math.round(it.rx * screen.width) : 0
                            y: it ? Math.round(it.ry * screen.height) : 0
                            width: it ? Math.max(14, Math.round(it.rw * screen.width) - 2) : 14
                            height: it ? Math.max(10, Math.round(it.rh * screen.height) - 2) : 10
                            z: on ? 50 : (it && it.floating ? 20 : 1)
                            radius: Math.max(2, view.ui.r(1))
                            color: Qt.rgba(view.ui.surface.r, view.ui.surface.g, view.ui.surface.b, 0.92)
                            border.width: on ? 2 : 1
                            border.color: on ? view.ui.accent
                                        : (it && it.urgent && view.sw.cfg.attention !== "off" ? view.ui.urgent : view.ui.tint(0.22))
                            clip: true

                            Loader {
                                id: shotL
                                anchors.fill: parent
                                anchors.margins: 1
                                active: view.sw.cfg.previews !== "off" && win.roomy && win.it !== null
                                        && win.it.toplevel !== null && win.it.toplevel !== undefined
                                sourceComponent: Component {
                                    ScreencopyView {
                                        captureSource: win.it ? win.it.toplevel : null
                                        live: view.sw.cfg.previews === "live" && view.sw.active
                                    }
                                }
                            }
                            Rectangle {   // unselected windows sit back a little
                                anchors.fill: parent
                                color: "black"
                                opacity: win.on ? 0 : 0.18
                            }
                            AppIcon {
                                ui: view.ui
                                anchors.centerIn: parent
                                visible: !(shotL.item && shotL.item.hasContent === true)
                                size: Math.max(8, Math.min(view.sw.cfg.iconSize * view.k, parent.width * 0.5, parent.height * 0.5))
                                source: win.it ? win.it.icon : ""
                                name: win.it ? win.it.cls : ""
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onPositionChanged: if (!win.on) view.sw.point(win.itemIndex)
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.MiddleButton) view.sw.closeAt(win.itemIndex)
                                    else view.sw.activate(win.itemIndex)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
