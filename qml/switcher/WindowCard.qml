import QtQuick
import Quickshell.Wayland
import "../js/Effects.js" as Fx
import "../controls"

// one window: live (or still) preview at its real shape, thin edge, icon in the
// corner. that's it, no card around it. used by every layout
Item {
    id: card

    property var sw: null                 // SwitchState
    property int itemIndex: -1
    property var item: null
    property bool showTitle: true
    property bool showPreview: true
    property bool showBadge: false        // kept for callers; nothing is drawn for it
    property real iconSize: 32
    readonly property var ui: sw ? sw.ui : null
    readonly property bool isSelected: sw !== null && sw.selected === itemIndex
    readonly property bool wantsAttention: item !== null && item.urgent === true && sw && sw.cfg.attention !== "off"
    readonly property real titleH: showTitle ? Math.round(ui.fs(11) * 1.9) : 0

    // accent, or the app's own color in by category
    readonly property color tone: ui.appColor(item ? item.cls : "")

    // 0..1, animated, drives the "changing windows" effect
    readonly property string selFx: sw ? sw.cfg.selectEffect : "grow"
    property real w: isSelected ? 1 : 0
    Behavior on w {
        enabled: card.selFx !== "none" && card.ui.animations
        NumberAnimation {
            duration: Math.max(60, card.sw ? card.sw.cfg.speed * (card.selFx === "bounce" ? 2 : 1) : 140)
            easing.type: card.selFx === "bounce" ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 4
        }
    }
    readonly property var sel: Fx.selection(selFx, w)
    z: isSelected ? 10 : 0

    // real width / height of the window
    readonly property real ar: item && item.rh > 0 ? Math.max(0.25, Math.min(5, item.rw / item.rh * item.aspect)) : 16 / 10

    signal revealRequested(var target)

    // scroll into view once layout settles (also for the initial selection)
    onIsSelectedChanged: if (isSelected) revealTimer.restart()
    Component.onCompleted: if (isSelected) revealTimer.restart()
    Timer {
        id: revealTimer
        interval: 30
        onTriggered: if (card.isSelected && !card.sw.pointed) card.revealRequested(card)
    }

    Item {
    id: body
    anchors.fill: parent
    transform: [
        Scale {
            origin.x: frame.x + frame.width / 2
            origin.y: frame.y + frame.height / 2
            xScale: card.sel.scale
            yScale: card.sel.scale
        },
        Translate { y: -card.sel.lift }
    ]

    // glow
    Repeater {
        model: card.sel.glow > 0.01 ? 4 : 0
        delegate: Rectangle {
            readonly property real grow: (index + 1) * 4
            x: frame.x - grow; y: frame.y - grow
            width: frame.width + grow * 2; height: frame.height + grow * 2
            radius: frame.radius + grow
            color: "transparent"
            border.width: 4
            border.color: card.tone
            opacity: card.sel.glow * [0.45, 0.28, 0.16, 0.07][index]
        }
    }

    // shadow for lift
    Rectangle {
        visible: card.sel.lift > 0.5
        x: frame.x + 4; y: frame.y + 6 + card.sel.lift
        width: frame.width - 8; height: frame.height - 4
        radius: frame.radius + 2
        color: "black"
        opacity: 0.35 * card.w
    }

    // the window
    Rectangle {
        id: frame

        readonly property real boxW: card.width
        readonly property real boxH: Math.max(1, card.height - card.titleH)
        width: Math.round(Math.min(boxW, boxH * card.ar))
        height: Math.round(Math.min(boxH, boxW / card.ar))
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((boxH - height) / 2)

        radius: ui.r(1)
        color: shot.hasShot ? "transparent" : Qt.rgba(ui.surface.r, ui.surface.g, ui.surface.b, 0.92)
        clip: true

        Item {
            id: shot
            anchors.fill: parent

            readonly property bool wantShot: card.showPreview && card.sw.cfg.previews !== "off"
                                             && card.item !== null && card.item.toplevel !== null
                                             && card.item.toplevel !== undefined

            Loader {
                id: shotLoader
                anchors.fill: parent
                active: shot.wantShot
                sourceComponent: Component {
                    ScreencopyView {
                        captureSource: card.item ? card.item.toplevel : null
                        live: card.sw.cfg.previews === "live" && card.sw.active
                    }
                }
            }

            readonly property bool hasShot: shotLoader.item !== null && shotLoader.item.hasContent === true
        }

        // no preview (yet): big icon
        AppIcon {
            ui: card.ui
            anchors.centerIn: parent
            visible: !shot.hasShot
            size: Math.min(card.iconSize * 1.4, parent.height * 0.55, parent.width * 0.55)
            source: card.item ? card.item.icon : ""
            name: card.item ? card.item.cls : ""
        }

        // small icon on top of the preview
        AppIcon {
            ui: card.ui
            visible: shot.hasShot && parent.height > 48
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Math.max(4, Math.round(parent.height * 0.04))
            size: Math.max(14, Math.min(card.iconSize * 0.6, parent.height * 0.22))
            source: card.item ? card.item.icon : ""
            name: card.item ? card.item.cls : ""
        }

        // unselected ones a bit darker
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: card.isSelected ? 0 : card.sel.dimOthers
            Behavior on opacity { enabled: card.ui.animations; NumberAnimation { duration: 90 } }
        }
    }

    // edge, outside the clip so it stays sharp
    Rectangle {
        readonly property real out: card.isSelected ? card.sel.edge : 0
        x: frame.x - out
        y: frame.y - out
        width: frame.width + out * 2
        height: frame.height + out * 2
        radius: frame.radius + out
        color: "transparent"
        visible: card.isSelected || ui.cardStyle !== "flat"
        border.width: card.isSelected ? card.sel.edge : 1
        border.color: card.isSelected ? card.tone
            : ui.colorMode === "category" ? Qt.rgba(card.tone.r, card.tone.g, card.tone.b, hover.containsMouse ? 0.8 : 0.45)
            : (hover.containsMouse ? ui.tint(0.45) : ui.tint(ui.cardStyle === "outline" ? 0.35 : 0.16))
        Behavior on border.color { enabled: card.ui.animations; ColorAnimation { duration: 90 } }
    }

    // attention
    Rectangle {
        x: frame.x - 4; y: frame.y - 4
        width: frame.width + 8; height: frame.height + 8
        visible: card.wantsAttention
        radius: frame.radius + 4
        color: "transparent"
        border.width: 2
        border.color: ui.urgent
        SequentialAnimation on opacity {
            running: card.wantsAttention && card.sw.cfg.attention === "pulse" && card.sw.active
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.25; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.25; to: 1; duration: 650; easing.type: Easing.InOutSine }
        }
    }

    Txt {
        visible: card.showTitle
        ui: card.ui
        x: frame.x
        width: frame.width
        y: frame.y + frame.height
        height: card.titleH
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: card.item ? card.item.title : ""
        font.pixelSize: ui.fs(11)
        font.weight: card.isSelected ? Font.DemiBold : Font.Normal
        opacity: card.isSelected ? 1 : 0.7
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.5)
    }

    }

    // only the window reacts, not the empty space around it.
    // SwitchState compares global positions so appearing or moving beneath a
    // stationary cursor doesn't steal the keyboard selection.
    MouseArea {
        id: hover
        x: frame.x; y: frame.y
        width: frame.width; height: frame.height + card.titleH
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: function(mouse) {
            if (card.sw) card.sw.point(card.itemIndex, mapToGlobal(mouse.x, mouse.y))
        }
        onClicked: function(mouse) {
            if (!card.sw) return
            if (mouse.button === Qt.MiddleButton) card.sw.closeAt(card.itemIndex)
            else card.sw.activate(card.itemIndex)
        }
    }
}
