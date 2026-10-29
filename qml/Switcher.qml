import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "js/Effects.js" as Fx
import "core"
import "switcher"

// the alt+tab overlay, full screen on the focused monitor.
//
// open(payload) gets called on every summon, also while open:
//   next / prev  alt(+shift)+tab: open, or step if already open
//   open         bar / ipc: open on the focused window
//   release      alt let go (hyprland release bind)
Item {
    id: root

    property string omarchyPath: ""
    property var shell: null
    property var manifest: null
    property var service: null

    readonly property string pluginId: "io.github.qempexe.altscape"
    readonly property var svc: service !== null ? service : lookedUp
    property var lookedUp: null
    readonly property var ui: svc ? svc.ui : null
    readonly property var cfg: svc ? svc.cfg : null

    property bool opened: false
    property bool holdMode: false
    readonly property var switchState: sws
    property var targetScreen: null

    // 0 = shown, 1 = gone
    property real t: 0
    property string fxName: "none"
    property bool closing: false
    readonly property bool shown: opened || closing
    // blur: grab the screen first, show the windows only after, so they
    // don't end up blurred into it
    property bool captured: true
    readonly property var fx: Fx.state(fxName, t, 64)

    // service and overlay load in whatever order
    function lookUp() {
        if (root.service !== null || root.lookedUp !== null) return
        if (root.shell && typeof root.shell.serviceFor === "function") root.lookedUp = root.shell.serviceFor(root.pluginId)
    }
    onShellChanged: lookUp()
    Timer {
        interval: 400
        repeat: true
        running: root.svc === null && root.shell !== null
        onTriggered: root.lookUp()
    }

    SwitchState {
        id: sws
        svc: root.svc
        active: root.opened
        onActivated: function(address) { root.switchTo(address) }
    }

    function parse(payload) {
        const p = String(payload || "").trim()
        if (p === "next" || p === "prev" || p === "open" || p === "current" || p === "release") return p
        try {
            const o = JSON.parse(p)
            if (o && typeof o === "object") {
                if (o.step === 1 || o.step === "1") return "next"
                if (o.step === -1 || o.step === "-1") return "prev"
                if (typeof o.mode === "string" && root.svc) root.svc.setMode(o.mode)
            }
        } catch (e) { }
        return "open"
    }

    // switch to the selected window. With nothing to pick (no windows, or none
    // in the chosen scope) the switcher closes instead of staying up empty.
    function pick() {
        if (sws.items.length === 0) root.dismiss()
        else sws.activate()
    }

    // alt let go (from the release bind). only counts if the shortcut opened us
    function release() {
        if (!root.opened) return
        if (root.holdMode && root.cfg && root.cfg.pickOnRelease === true) {
            root.holdMode = false
            root.pick()
        }
    }

    function open(payload) {
        const what = parse(payload)
        console.info("Altscape: " + what + (root.opened ? " (open)" : ""))
        if (what === "release") { root.release(); return }
        if (root.opened) {
            if (what === "next") sws.step(1)
            else if (what === "prev") sws.step(-1)
            else if (what === "open" || what === "current") root.holdMode = false
            return
        }
        if (root.svc && typeof root.svc.cancelFocus === "function") root.svc.cancelFocus()
        root.holdMode = what === "next" || what === "prev"
        exit.stop()
        root.closing = false
        root.targetScreen = pickScreen()
        sws.start(what === "open" ? "current" : what)
        if (root.svc) root.svc.refresh()
        root.fxName = root.cfg ? root.cfg.effect : "none"
        root.t = root.fxName === "none" || !root.cfg || root.cfg.speed <= 0 ? 0 : 1
        root.captured = !(root.cfg && root.cfg.backdrop === "blur")
        root.opened = true
        if (root.captured) startEnter()
        else captureWait.restart()
        Qt.callLater(() => { keyCatcher.forceActiveFocus() })
    }

    function startEnter() {
        captureWait.stop()
        root.captured = true
        if (root.t > 0) enter.restart()
    }
    // don't wait forever for the screenshot
    Timer { id: captureWait; interval: 300; onTriggered: root.startEnter() }

    // `closing` is set before `opened` is cleared: for a moment in between, `shown`
    // would be false, the layer surface would be destroyed and made again just
    // to play the closing effect, and the old frame would flash back on screen.
    function close() {
        if (!root.opened) return
        root.holdMode = false
        enter.stop()
        captureWait.stop()
        const e = root.cfg ? root.cfg.closeEffect : "none"
        if (e === "none" || !root.cfg || root.cfg.speed <= 0 || !root.captured) {
            root.closing = false
            root.opened = false
            root.t = 1
            return
        }
        root.fxName = e
        root.closing = true
        root.opened = false
        exit.restart()
    }

    function toggle() {
        if (root.opened) root.dismiss()
        else root.open("open")
    }

    // close + tell the shell, so its "open" matches ours
    function dismiss() {
        root.close()
        if (root.shell && typeof root.shell.hide === "function") root.shell.hide(root.pluginId)
    }

    function switchTo(address) {
        root.dismiss()
        if (root.svc) root.svc.focusWindow(address)
    }

    function pickScreen() {
        const name = root.svc ? root.svc.info.focusedMonitor : ""
        let list = []
        try { list = Quickshell.screens } catch (e) { list = [] }
        for (let i = 0; i < list.length; i++) if (list[i] && list[i].name === name) return list[i]
        return null
    }

    NumberAnimation {
        id: enter
        target: root
        property: "t"
        to: 0
        duration: root.cfg ? root.cfg.speed : 140
        easing.type: Fx.springy(root.fxName) ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: 1.6
    }
    NumberAnimation {
        id: exit
        target: root
        property: "t"
        to: 1
        duration: root.cfg ? Math.round(root.cfg.speed * 0.85) : 120
        easing.type: Fx.springy(root.fxName) ? Easing.InBack : Easing.InCubic
        onFinished: root.closing = false
    }

    // empty input region while closing, so the animation never eats a click
    Region { id: noInput }

    PanelWindow {
        id: win

        visible: root.shown
        screen: root.targetScreen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "altscape"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: root.opened ? null : noInput

        // backdrop: nothing / dark / blur
        Item {
            id: backdrop
            anchors.fill: parent
            readonly property string kind: root.cfg ? root.cfg.backdrop : "clear"
            visible: kind !== "clear"
            opacity: (1 - Math.max(0, Math.min(1, root.t))) * (root.cfg ? root.cfg.backdropOpacity / 100 : 1)

            Rectangle {
                anchors.fill: parent
                visible: backdrop.kind === "dim"
                color: "black"
                opacity: 0.9
            }

            Loader {
                anchors.fill: parent
                active: backdrop.kind === "blur" && root.shown
                sourceComponent: Component {
                    Item {
                        // hidden until the picture exists, so none of our stuff gets captured
                        visible: root.captured && shot.hasContent

                        ScreencopyView {
                            id: shot
                            anchors.fill: parent
                            visible: false
                            live: false
                            captureSource: win.screen
                            onHasContentChanged: if (hasContent && !root.captured) root.startEnter()
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: shot
                            autoPaddingEnabled: false
                            blurEnabled: true
                            blur: 1.0
                            blurMax: root.cfg ? Math.round(root.cfg.blurAmount * 1.28) : 64
                            blurMultiplier: 1.0
                        }
                        Rectangle {   // Theme color: wash the blur with the Colors choice
                            anchors.fill: parent
                            visible: root.cfg && root.cfg.blurTint === "theme"
                            color: root.ui ? root.ui.surface : "black"
                            opacity: root.cfg ? root.cfg.tintStrength / 100 : 0.35
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.dismiss()
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(e) {
                const shift = (e.modifiers & Qt.ShiftModifier) !== 0
                if (e.key === Qt.Key_Tab) sws.step(shift ? -1 : 1)
                else if (e.key === Qt.Key_Backtab) sws.step(-1)
                else if (e.key === Qt.Key_Right) sws.step(1)
                else if (e.key === Qt.Key_Left) sws.step(-1)
                else if (e.key === Qt.Key_Down) sws.stepRow(1)
                else if (e.key === Qt.Key_Up) sws.stepRow(-1)
                else if (e.key === Qt.Key_Home) sws.select(0)
                else if (e.key === Qt.Key_End) sws.select(sws.items.length - 1)
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.pick()
                else if (e.key === Qt.Key_Escape) root.dismiss()
                else if (e.key === Qt.Key_Delete) sws.closeAt()
                else if (e.key === Qt.Key_BracketRight) { if (root.svc) root.svc.stepMode(1) }
                else if (e.key === Qt.Key_BracketLeft) { if (root.svc) root.svc.stepMode(-1) }
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) sws.jumpGroup(e.key - Qt.Key_0)
                else return
                e.accepted = true
            }
            Keys.onReleased: function(e) {
                if (!root.holdMode || !root.cfg || root.cfg.pickOnRelease !== true) return
                if (e.key === Qt.Key_Alt || e.key === Qt.Key_AltGr || e.key === Qt.Key_Meta
                        || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R) {
                    root.holdMode = false
                    root.pick()
                    e.accepted = true
                }
            }
        }

        // the windows
        Item {
            id: stage

            readonly property var ui: root.ui
            visible: ui !== null && root.captured
            width: Math.round(win.width * 0.9)
            height: Math.round(win.height * 0.86)
            anchors.centerIn: parent
            opacity: Math.max(0, Math.min(1, root.fx.opacity))
            transform: [
                Scale {
                    origin.x: stage.width / 2
                    origin.y: stage.height / 2
                    xScale: root.fx.scale
                    yScale: root.fx.scale * root.fx.yScale
                },
                Translate { x: root.fx.dx; y: root.fx.dy }
            ]

            SwitchView {
                anchors.fill: parent
                sw: sws
            }
        }
    }
}
