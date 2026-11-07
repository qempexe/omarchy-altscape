import QtQuick
import QtTest
import "../qml/core"

TestCase {
    name: "RowNavigation"

    QtObject {
        id: service
        property var ui: null
        property var cfg: ({ mode: "grid", scope: "all", order: "workspace", showSpecial: false })
        property var info: ({ windows: [] })
        signal windowsUpdated()
    }

    SwitchState { id: sw; svc: service; active: true }

    // a grid of three columns: one block of five windows (rows of 3 and 2),
    // then a block of two, centered under it
    readonly property var rows: [
        [{ i: 0, x: 50 }, { i: 1, x: 160 }, { i: 2, x: 270 }],
        [{ i: 3, x: 50 }, { i: 4, x: 160 }],
        [{ i: 5, x: 105 }, { i: 6, x: 215 }]
    ]

    function init() {
        sw.items = [0, 1, 2, 3, 4, 5, 6].map(function(k) { return { key: "k" + k, address: "0x" + k } })
        sw.navCols = 1
        sw.navRows = rows
        sw.selected = 1
    }

    function test_downGoesToTheWindowBelow() {
        sw.stepRow(1)
        compare(sw.selected, 4)
    }

    function test_upGoesToTheWindowAbove() {
        sw.selected = 4
        sw.stepRow(-1)
        compare(sw.selected, 1)
    }

    function test_downFromAnEmptyColumnLandsOnTheClosestWindow() {
        sw.selected = 2
        sw.stepRow(1)
        compare(sw.selected, 4)
    }

    function test_downCrossesIntoTheNextWorkspaceBlock() {
        sw.selected = 3
        sw.stepRow(1)
        compare(sw.selected, 5)
    }

    function test_theEdgesStay() {
        sw.selected = 0
        sw.stepRow(-1)
        compare(sw.selected, 0)
        sw.selected = 6
        sw.stepRow(1)
        compare(sw.selected, 6)
    }

    function test_withoutRowsUpDownStepsAsBefore() {
        sw.navRows = []
        sw.selected = 0
        sw.stepRow(1)
        compare(sw.selected, 1)
    }
}
