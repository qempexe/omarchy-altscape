import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "js/Schema.js" as Schema
import "js/Model.js" as Model
import "core"

// the always-loaded part. owns settings, keeps the window list fresh from
// hyprland events (so alt+tab opens instantly), icons, focus/close,
// the keybind and ipc. panel and overlay both read from here.
Item {
    id: root

    visible: false

    property var shell: null
    property var manifest: null

    readonly property string pluginId: "io.github.qempexe.altscape"

    // settings
    SettingsStore { id: settingsStore }
    property alias store: settingsStore
    readonly property var cfg: Schema.resolve(settingsStore.values)

    function setValue(key, value) { settingsStore.set(key, Schema.clean(key, value)) }
    function setMode(name) { if (Schema.modeKeys.indexOf(String(name)) >= 0) setValue("mode", String(name)) }
    function stepMode(d) {
        var keys = Schema.modeKeys
        var i = keys.indexOf(cfg.mode)
        setMode(keys[(Math.max(0, i) + d + keys.length) % keys.length])
    }

    UiState {
        id: ux
        store: settingsStore
        cfg: root.cfg
        barFg: Color.bar.text
        barBg: Color.bar.background
        themeAccent: Color.accent
        themeUrgent: Color.urgent
        fontName: Style.font.family
        onOpenSwitcherRequested: root.openSwitcher("open")
    }
    property alias ui: ux

    // window list
    property var info: ({ windows: [], workspaces: [], focusedMonitor: "", activeWorkspace: 1, activeByMonitor: ({}) })
    property bool ready: false
    property var urgentMap: ({})
    readonly property int windowCount: info.windows.length

    signal windowsUpdated()

    function refresh() {
        if (snapshot.running) { refreshAgain = true; return }
        snapshot.running = true
    }
    property bool refreshAgain: false

    Process {
        id: snapshot
        command: ["sh", "-c",
            "printf '{\"clients\":'; hyprctl -j clients 2>/dev/null || printf '[]';"
            + " printf ',\"workspaces\":'; hyprctl -j workspaces 2>/dev/null || printf '[]';"
            + " printf ',\"monitors\":'; hyprctl -j monitors 2>/dev/null || printf '[]'; printf '}'"]
        stdout: StdioCollector {
            onStreamFinished: root.absorbSnapshot(text)
        }
        onExited: {
            if (root.refreshAgain) { root.refreshAgain = false; Qt.callLater(root.refresh) }
        }
    }

    function absorbSnapshot(text) {
        var snap
        try { snap = JSON.parse(String(text || "")) } catch (e) { return }
        if (!snap || typeof snap !== "object") return
        var next = Model.parseSnapshot(snap)
        var tops = []
        try { tops = Hyprland.toplevels ? Hyprland.toplevels.values : [] } catch (e2) { tops = [] }
        for (var i = 0; i < next.windows.length; i++) {
            var w = next.windows[i]
            w.icon = iconFor(w.cls)
            w.urgent = urgentMap[w.key] === true
            w.toplevel = waylandFor(tops, w.key)
        }
        info = next
        ready = true
        windowsUpdated()
    }

    // wayland toplevel for a hyprland window (previews + closing need it)
    function waylandFor(tops, key) {
        for (var i = 0; i < tops.length; i++) {
            var t = tops[i]
            if (!t) continue
            var a = ""
            try { a = Model.norm(t.address) } catch (e) { a = "" }
            if (a !== "" && a === key) {
                try { return t.wayland ? t.wayland : null } catch (e2) { return null }
            }
        }
        return null
    }

    // debounce: switching workspace fires a bunch of events at once
    Timer { id: refreshTimer; interval: 60; onTriggered: root.refresh() }

    readonly property var refreshEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2",
        "windowtitle", "windowtitlev2", "activewindow", "activewindowv2", "workspace", "workspacev2",
        "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "focusedmon",
        "focusedmonv2", "moveworkspace", "moveworkspacev2", "renameworkspace", "changefloatingmode",
        "fullscreen", "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "urgent",
        "activespecial", "activespecialv2", "minimized", "pin"]

    Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onRawEvent(event) {
            var name = ""
            var data = ""
            try { name = String(event.name); data = String(event.data) } catch (e) { return }
            if (name === "urgent") {
                var u = {}
                for (var k in root.urgentMap) u[k] = true
                u[Model.norm(data.split(",")[0])] = true
                root.urgentMap = u
            } else if (name === "activewindowv2") {
                var key = Model.norm(data.split(",")[0])
                if (root.urgentMap[key] === true) {
                    var n = {}
                    for (var j in root.urgentMap) if (j !== key) n[j] = true
                    root.urgentMap = n
                }
            }
            if (root.refreshEvents.indexOf(name) >= 0) refreshTimer.restart()
        }
    }

    // icons. hits are cached, misses aren't, so apps installed later still get theirs
    property var iconCache: ({})

    // icon name or absolute path -> path
    function resolveIcon(icon) {
        var i = String(icon || "")
        if (i === "") return ""
        if (i.charAt(0) === "/") return i
        return String(Quickshell.iconPath(i, true) || "")
    }

    // web apps: class looks like "chrome-github.com__-Default" (made from the url).
    // match it back to the .desktop that opens that url -> its icon.
    // exact host+path first, then just the host
    property var webIcons: null
    function webKey(url) {
        var m = String(url).match(/^[a-z]+:\/\/([^\/?#"' ]+)([^?#"' ]*)/i)
        if (!m) return null
        var host = m[1].toLowerCase()
        var path = m[2] || "/"
        return { full: host + "_" + path.replace(/\//g, "_"), host: host.replace(/^www\./, "") }
    }
    function buildWebIcons() {
        var full = {}, host = {}
        var list = []
        try { list = DesktopEntries.applications.values } catch (e) { list = [] }
        for (var i = 0; i < list.length; i++) {
            var e = list[i]
            if (!e || !e.icon) continue
            var ex = ""
            try { ex = String(e.execString || e.command || "") } catch (e2) { ex = "" }
            var u = ex.match(/(https?:\/\/[^\s"']+)/)
            if (!u) continue
            var k = webKey(u[1])
            if (!k) continue
            var p = resolveIcon(e.icon)
            if (p === "") continue
            if (full[k.full] === undefined) full[k.full] = p
            if (host[k.host] === undefined) host[k.host] = p
        }
        webIcons = { full: full, host: host }
    }
    function webIconFor(cls) {
        var m = String(cls).match(/^(?:chrome|chromium|brave|msedge|vivaldi|helium|thorium)-(.+?)-(?:Default|Profile_?\d+|Person_?\d+)$/i)
        if (!m) return ""
        if (webIcons === null) buildWebIcons()
        var key = m[1].toLowerCase()
        if (webIcons.full[key]) return webIcons.full[key]
        var h = key.split("__")[0].split("_")[0].replace(/^www\./, "")
        while (h.indexOf(".") > 0) {             // also try the parent domain
            if (webIcons.host[h]) return webIcons.host[h]
            h = h.substring(h.indexOf(".") + 1)
        }
        return ""
    }
    // new web apps can get installed while the shell runs
    Timer { interval: 120000; repeat: true; running: true; onTriggered: { root.webIcons = null; root.iconCache = ({}) } }

    function iconFor(cls) {
        var name = String(cls || "")
        if (name === "") return ""
        if (iconCache[name] !== undefined) return iconCache[name]
        var web = ""
        try { web = webIconFor(name) } catch (ew) { web = "" }
        if (web !== "") {
            var cw = {}
            for (var kw in iconCache) cw[kw] = iconCache[kw]
            cw[name] = web
            iconCache = cw
            return web
        }
        var lower = name.toLowerCase()
        var cands = [name, lower, lower.replace(/ /g, "-"), lower.split(".").pop()]
        var p = ""
        try {
            for (var i = 0; i < cands.length && p === ""; i++) {
                var e = DesktopEntries.byId(cands[i])
                if (e && e.icon) p = resolveIcon(e.icon)
            }
            if (p === "" && typeof DesktopEntries.heuristicLookup === "function") {
                var h = DesktopEntries.heuristicLookup(name)
                if (h && h.icon) p = resolveIcon(h.icon)
            }
            for (var j = 0; j < cands.length && p === ""; j++)
                p = String(Quickshell.iconPath(cands[j], true) || "")
        } catch (err) {
            p = ""
        }
        if (p !== "") {
            var c = {}
            for (var k in iconCache) c[k] = iconCache[k]
            c[name] = p
            iconCache = c
        }
        return p
    }

    // actions. "lua" or "conf" depending on the hyprland config (the helper tells us),
    // focus is written differently in each
    property string hyprFormat: "lua"

    function validAddress(a) { return /^0x[0-9a-fA-F]+$/.test(String(a)) }

    function focusWindow(address) {
        if (!validAddress(address)) return false
        if (hyprFormat === "conf") Hyprland.dispatch("focuswindow address:" + address)
        else Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
        return true
    }

    function closeWindow(address) {
        var key = Model.norm(address)
        var t = null
        try { t = waylandFor(Hyprland.toplevels.values, key) } catch (e) { t = null }
        if (t && typeof t.close === "function") { t.close(); refreshTimer.restart(); return true }
        return false
    }

    function openSwitcher(payload) {
        if (root.shell && typeof root.shell.summon === "function")
            return root.shell.summon(root.pluginId, String(payload || "open")) === true
        return false
    }

    // keybind
    readonly property string bindHelper: String(Qt.resolvedUrl("../bin/altscape-binds")).replace(/^file:\/\//, "")
    property var bindStatus: ({ format: "", file: "", shortcut: "", ok: false, error: "" })
    property string bindApplied: ""

    function syncBinds() {
        if (!settingsStore.loaded) return
        if (bindProc.running) { bindAgain = true; return }
        bindProc.command = ["bash", root.bindHelper, "sync", root.cfg.shortcut]
        bindProc.running = true
    }
    property bool bindAgain: false

    Process {
        id: bindProc
        stdout: StdioCollector {
            onStreamFinished: {
                var st
                try { st = JSON.parse(String(text || "")) } catch (e) { st = null }
                if (!st || typeof st !== "object") st = { ok: false, error: "the keybind helper gave no answer" }
                root.bindStatus = st
                if (st.format === "lua" || st.format === "conf") root.hyprFormat = st.format
                root.bindApplied = String(st.shortcut || "")
            }
        }
        onExited: if (root.bindAgain) { root.bindAgain = false; Qt.callLater(root.syncBinds) }
    }

    readonly property string wantedShortcut: cfg.shortcut
    onWantedShortcutChanged: syncBinds()

    Connections {
        target: settingsStore
        function onLoadedChanged() { if (settingsStore.loaded) root.syncBinds() }
    }

    Component.onCompleted: {
        try { Hyprland.refreshToplevels() } catch (e) { }
        refresh()
        if (settingsStore.loaded) syncBinds()
    }

    // ipc: omarchy-shell io.github.qempexe.altscape <function>
    IpcHandler {
        target: root.pluginId

        function open(): string { return root.openSwitcher("open") ? "ok" : "unavailable" }
        function next(): string { return root.openSwitcher("next") ? "ok" : "unavailable" }
        function prev(): string { return root.openSwitcher("prev") ? "ok" : "unavailable" }

        function mode(name: string): string {
            if (Schema.modeKeys.indexOf(name) < 0) return "unknown mode; use one of " + Schema.modeKeys.join(", ")
            root.setMode(name)
            return name
        }

        function binds(): string {
            root.syncBinds()
            return JSON.stringify(root.bindStatus)
        }

        function status(): string {
            return JSON.stringify({
                windows: root.windowCount,
                mode: root.cfg.mode,
                scope: root.cfg.scope,
                shortcut: root.cfg.shortcut,
                binds: root.bindStatus
            })
        }
    }
}
