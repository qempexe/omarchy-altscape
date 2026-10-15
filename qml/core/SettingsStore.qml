import QtQuick
import Quickshell
import Quickshell.Io

// settings, saved to settings.json in the state folder.
//
// NOTE: don't use `omarchy bar set` for this, it reloads the bar config and
// can freeze the shell.
//
// only writer. read once at startup, not watched, so our own write can never
// come back and undo a newer value
Item {
    id: root

    visible: false

    property string stateDir: (Quickshell.env("XDG_STATE_HOME")
        || Quickshell.env("HOME") + "/.local/state") + "/omarchy-altscape"
    property string path: stateDir + "/settings.json"

    property var values: ({})
    property bool loaded: false        // the saved file has been read (or there is none)
    property bool dirReady: false      // the state folder exists, so writes can land

    signal changed()

    function get(key) {
        var v = values[key]
        return v === undefined ? null : v
    }

    function set(key, value) {
        var next = {}
        for (var k in values) next[k] = values[k]
        if (value === null || value === undefined) delete next[key]
        else next[key] = value
        values = next
        persist()
        changed()
    }

    // reset everything in one write
    function resetAll(defaults) {
        var next = {}
        for (var k in defaults) next[k] = defaults[k]
        values = next
        persist()
        changed()
    }

    // write a bit after the last change (slider drag = one write)
    function persist() { writeTimer.restart() }

    Timer {
        id: writeTimer
        interval: 150
        onTriggered: root.flushWrite()
    }

    // never write before we've read the file, or an early edit would wipe it
    function flushWrite() {
        if (!dirReady || !loaded) { writeTimer.restart(); return }
        file.setText(JSON.stringify(root.values, null, 2) + "\n")
    }

    // FileView.text is a function in quickshell, not a property
    function readText(fv) {
        try { return String(typeof fv.text === "function" ? fv.text() : fv.text) } catch (e) { return "" }
    }

    // startup: file values, with in-memory changes on top
    function absorb(text) {
        if (loaded) return
        var fromFile
        try {
            var parsed = JSON.parse(String(text || "{}"))
            fromFile = (parsed && typeof parsed === "object" && !Array.isArray(parsed)) ? parsed : ({})
        } catch (e) {
            fromFile = ({})
        }
        var merged = {}
        for (var k in fromFile) merged[k] = fromFile[k]
        for (var j in values) merged[j] = values[j]
        values = merged
        loaded = true
        changed()
    }

    Component.onCompleted: mkdir.running = true

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.stateDir]
        onExited: {
            root.dirReady = true
            if (!root.loaded) file.reload()
        }
    }

    FileView {
        id: file
        path: root.path
        onLoaded: root.absorb(root.readText(file))
        onLoadFailed: { if (!root.loaded) { root.loaded = true; root.changed() } }
    }
}
