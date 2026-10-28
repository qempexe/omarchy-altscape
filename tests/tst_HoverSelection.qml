import QtQuick
import QtTest
import "../qml/core"

Item {
    id: scene
    width: 500
    height: 300

    QtObject {
        id: service
        property var ui: null
        property var cfg: ({ mode: "strip", scope: "all", order: "recent", showSpecial: false })
        property var info: ({
            windows: [
                { key: "a", address: "0xa", focusId: 0 },
                { key: "b", address: "0xb", focusId: 1 },
                { key: "c", address: "0xc", focusId: 2 }
            ]
        })
        signal windowsUpdated()
    }

    SwitchState { id: sw; svc: service; active: true }
    SignalSpy { id: activated; target: sw; signalName: "activated" }
    SignalSpy { id: positions; target: area; signalName: "positionChanged" }

    Item {
        id: tile
        x: 50; y: 50
        width: 200; height: 150
        Rectangle { anchors.fill: parent; color: "#222222" }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: function(mouse) {
                sw.point(2, mapToGlobal(mouse.x, mouse.y))
            }
            onClicked: sw.activate(2)
        }
    }

    TestCase {
        name: "HoverSelection"
        when: windowShown

        function init() {
            mouseMove(scene, 450, 250)
            tile.x = 50
            tile.visible = true
            sw.hoverSelects = true
            sw.start("next")
            activated.clear()
            compare(sw.selected, 1)
            wait(60)
        }

        function test_initialHoverKeepsRecentWindow() {
            sw.point(2, Qt.point(100, 100))
            compare(sw.selected, 1)
            compare(sw.userMoved, false)
            compare(sw.pointed, false)
            service.windowsUpdated()
            compare(sw.selected, 1)
        }

        function test_stationaryPointerAcrossCards() {
            sw.point(2, Qt.point(100, 100))
            sw.point(0, Qt.point(100, 100))
            compare(sw.selected, 1)
        }

        function test_realMovementSelects() {
            // Record the pointer even when it is over the selected card.
            sw.point(1, Qt.point(100, 100))
            sw.point(2, Qt.point(110, 100))
            compare(sw.selected, 2)
            compare(sw.pointed, true)
            compare(sw.userMoved, true)
        }

        function test_keyboardSelectionSurvivesStationaryHover() {
            sw.point(2, Qt.point(100, 100))
            sw.point(2, Qt.point(110, 100))
            sw.step(1)
            compare(sw.selected, 0)
            sw.point(2, Qt.point(110, 100))
            compare(sw.selected, 0)
            compare(sw.pointed, false)
        }

        function test_smallMovementsAccumulate() {
            sw.point(1, Qt.point(100, 100))
            sw.point(2, Qt.point(100.25, 100))
            compare(sw.selected, 1)
            sw.point(2, Qt.point(100.5, 100))
            sw.point(2, Qt.point(100.75, 100))
            compare(sw.selected, 2)
        }

        function test_reopenResetsPointer() {
            sw.point(2, Qt.point(100, 100))
            sw.point(2, Qt.point(110, 100))
            sw.start("prev")
            sw.point(0, Qt.point(300, 100))
            compare(sw.selected, 2)
            compare(sw.userMoved, false)
        }

        function test_layoutsWithHoverDisabled() {
            sw.hoverSelects = false
            sw.point(2, Qt.point(100, 100))
            sw.point(2, Qt.point(110, 100))
            compare(sw.selected, 1)
        }

        function test_movingPreviewUnderStationaryPointer() {
            mouseMove(scene, 100, 100)
            wait(60)
            // The initial enter only establishes the pointer position.
            compare(sw.selected, 1)
            positions.clear()
            tile.x += 10
            tryVerify(function() { return positions.count > 0 })
            // Qt emits positionChanged with different local coordinates.
            compare(sw.selected, 1)
            compare(sw.userMoved, false)
            mouseMove(scene, 120, 100)
            tryCompare(sw, "selected", 2)
        }

        function test_clickStillActivatesImmediately() {
            mouseClick(area, 50, 50)
            compare(activated.count, 1)
            compare(activated.signalArguments[0][0], "0xc")
        }
    }
}
