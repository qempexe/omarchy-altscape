import QtQuick
import QtTest
import "../qml/core"

TestCase {
    name: "SelectionRefresh"

    QtObject {
        id: service
        property var ui: null
        property var cfg: ({ mode: "strip", scope: "all", order: "recent", showSpecial: false })
        property var info: ({ windows: [] })
        signal windowsUpdated()
    }

    SwitchState { id: sw; svc: service; active: true }

    function snapshot(addresses) {
        service.info = { windows: addresses.map(function(key, index) {
            return { key: key, address: "0x" + key, focusId: index }
        }) }
        service.windowsUpdated()
    }

    function init() {
        snapshot(["a", "b", "c"])
        sw.start("next")
        compare(sw.selectedItem.key, "b")
    }

    function test_focusHistoryChangeKeepsOpeningTarget() {
        // Focus can change while the overlay acquires its keyboard grab.
        // Recomputing "next" here would select the window we started from.
        snapshot(["b", "a", "c"])
        compare(sw.selectedItem.key, "b")
        compare(sw.userMoved, false)
    }

    function test_reverseOpeningTargetSurvivesRefresh() {
        sw.start("prev")
        compare(sw.selectedItem.key, "c")
        snapshot(["c", "a", "b"])
        compare(sw.selectedItem.key, "c")
    }

    function test_keyboardSelectionSurvivesRefresh() {
        sw.step(1)
        snapshot(["c", "a", "b"])
        compare(sw.selectedItem.key, "c")
    }

    function test_initiallyEmptySnapshotChoosesOpeningTarget() {
        snapshot([])
        sw.start("next")
        snapshot(["a", "b", "c"])
        compare(sw.selectedItem.key, "b")
    }

    function test_closedOpeningTargetChoosesAvailableWindow() {
        snapshot(["a", "c"])
        compare(sw.selectedItem.key, "c")
    }
}
