import QtQuick
import QtTest
import "../qml/js/Model.js" as Model

TestCase {
    name: "Minimized"
    function snapshot(tags, name) {
        return Model.parseSnapshot({
            clients: [{address: "0xab", mapped: true, workspace: {id: -99, name: name || "special:minimized"}, tags: tags, monitor: 0}],
            workspaces: [{id: 2, name: "Work", monitor: "DP-2"}],
            monitors: [{id: 0, name: "DP-1", focused: true, activeWorkspace: {id: 1}},
                       {id: 1, name: "DP-2", activeWorkspace: {id: 2}}]
        })
    }
    function items(state, scope) {
        return Model.build(state, {scope: scope, order: "workspace", showSpecial: false}).items
    }
    function test_originAndScopes() {
        const state = snapshot(["omarchy-minimized-from-2"])
        const window = state.windows[0]
        verify(window.minimized)
        verify(!window.special)
        compare(window.ws, 2)
        compare(window.wsLabel, "Work")
        compare(window.monitor, "DP-2")
        compare(items(state, "all").length, 1)
        compare(items(state, "others").length, 1)
        compare(items(state, "workspace").length, 0)
        compare(items(state, "monitor").length, 0)
        state.activeWorkspace = 2
        compare(items(state, "workspace").length, 1)
    }
    function test_destroyedOrigin() {
        const state = snapshot(["omarchy-minimized-from-7"])
        compare(state.windows[0].ws, 7)
        compare(items(state, "all")[0].wsLabel, "Workspace 7")
    }
    function test_legacyAndInvalidTags() {
        for (const tags of [[], ["omarchy-minimized-from-0"], ["omarchy-minimized-from-2;exec"], ["omarchy-minimized-from-999999999999999999999"]]) {
            const state = snapshot(tags)
            compare(state.windows[0].ws, 1)
            compare(items(state, "workspace").length, 1)
        }
    }
    function test_scratchpadStillExcluded() {
        const state = snapshot(["omarchy-minimized-from-2"], "special:scratchpad")
        verify(!state.windows[0].minimized)
        compare(items(state, "all").length, 0)
    }
}
