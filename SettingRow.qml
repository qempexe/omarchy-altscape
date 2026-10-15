import QtQuick
import QtQuick.Layouts
import "Effects.js" as Fx

// one setting row: label + hint, value + reset arrow, control below.
// enum controls: tiles | seg | chips | scheme | effect (seg/chips picked by count if empty)
// also: palette, int (slider), bool (switch), string, color
Item {
    id: root

    property var ui: null
    property string settingKey: ""
    property string label: ""
    property string hint: ""
    property string kind: "string"
    property string control: ""
    property var options: []
    property var labels: ({})
    property var presets: []
    property var value: null

    // show a choice immediately, don't wait for the round trip through the store
    property var optimistic: undefined
    readonly property var current: optimistic !== undefined ? optimistic : value
    onValueChanged: optimistic = undefined
    function commit(v) { optimistic = v; edited(v) }
    property var defaultValue: null
    property real min: 0
    property real max: 100
    property real step: 1
    property real divisor: 1
    property int decimals: 0
    property bool dimmed: false
    property int maxLength: 2048       // longest text this row accepts
    property bool locked: false        // shown, but has no effect right now and ignores input

    signal edited(var v)

    function str(v) { return (v === null || v === undefined) ? "" : String(v) }
    function same(a, b) { return str(a) === str(b) }
    function labelFor(opt) { return labels[opt] !== undefined ? labels[opt] : String(opt) }
    function show(v) {
        var n = Number(v) / divisor
        return isFinite(n) ? String(parseFloat(n.toFixed(decimals))) : "?"
    }
    function nudge(dir) {
        var cur = Number(current)
        var v = Math.max(min, Math.min(max, cur + dir * step))
        if (v !== cur) commit(v)
    }
    function validHex(s) { return /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(s) }
    function rad(k) { return ui.r(k) }

    readonly property string mode: kind !== "enum" ? ""
        : (control !== "" ? control : (options.length <= 5 ? "seg" : "chips"))
    readonly property bool boolValue: current === true || current === "true"
    readonly property bool atDefault: kind === "palette"
        ? JSON.stringify(current) === JSON.stringify(defaultValue) : same(current, defaultValue)
    property var targets: []          // palette: [{ key, label }]
    property int target: 0
    readonly property string targetKey: targets.length > 0 ? targets[Math.min(target, targets.length - 1)].key : ""
    function colorOf(k) { return current && current[k] !== undefined ? String(current[k]) : "#000000" }
    readonly property real span: Math.max(1e-9, max - min)
    readonly property real frac: Math.max(0, Math.min(1, (Number(current) - min) / span))
    readonly property real defFrac: Math.max(0, Math.min(1, (Number(defaultValue) - min) / span))

    implicitWidth: 400
    implicitHeight: col.implicitHeight
    opacity: (dimmed || locked) ? 0.4 : 1.0
    enabled: !locked
    Behavior on opacity { enabled: ui.animations; NumberAnimation { duration: 140 } }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: ui.px(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: ui.px(10)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Txt {
                    ui: root.ui
                    Layout.fillWidth: true
                    text: root.label
                    font.pixelSize: ui.fs(13)
                    font.weight: Font.DemiBold
                }
                Txt {
                    ui: root.ui
                    Layout.fillWidth: true
                    visible: root.hint !== ""
                    text: root.hint
                    font.pixelSize: ui.fs(10)
                    opacity: 0.55
                    wrapMode: Text.Wrap
                }
            }

            // - value +
            RowLayout {
                visible: root.kind === "int"
                spacing: ui.px(6)
                Btn { ui: root.ui; text: "\u2212"; implicitWidth: ui.px(28); implicitHeight: ui.px(28); onClicked: root.nudge(-1) }
                Txt {
                    ui: root.ui
                    Layout.minimumWidth: ui.px(38)
                    horizontalAlignment: Text.AlignHCenter
                    text: root.show(root.current)
                    font.pixelSize: ui.fs(12)
                    font.weight: Font.DemiBold
                }
                Btn { ui: root.ui; text: "+"; implicitWidth: ui.px(28); implicitHeight: ui.px(28); onClicked: root.nudge(1) }
            }

            // reset arrow, only when changed
            Rectangle {
                visible: !root.atDefault
                implicitWidth: ui.px(24); implicitHeight: ui.px(24)
                radius: root.rad(0.5)
                color: ui.tint(resetArea.containsMouse ? 0.18 : 0.08)
                Txt { ui: root.ui; anchors.centerIn: parent; text: "\u21BA"; font.pixelSize: ui.fs(12) }
                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.kind === "palette" ? root.edited({ reset: true }) : root.commit(root.defaultValue)
                }
            }

            // switch
            Sw {
                Layout.alignment: Qt.AlignVCenter
                visible: root.kind === "bool"
                k: ui.densityF
                animate: ui.animations
                ink: ui.fg; accent: ui.accent; knob: ui.accentText
                on: root.boolValue
                onFlipped: root.commit(!root.boolValue)
            }
        }

        // tiles
        GridLayout {
            Layout.fillWidth: true
            visible: root.mode === "tiles"
            columns: Math.max(1, root.options.length <= 5 ? root.options.length : 4)
            columnSpacing: ui.px(10)
            rowSpacing: ui.px(10)

            Repeater {
                model: root.mode === "tiles" ? root.options : []
                delegate: Rectangle {
                    id: tile
                    readonly property bool on: root.same(root.current, modelData)
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: ui.px(84)
                    radius: root.rad(1.4)
                    color: on ? ui.accentTint(0.16) : ui.tint(tArea.containsMouse ? 0.09 : 0.04)
                    border.width: on ? 1.5 : 1
                    border.color: on ? ui.accent : ui.tint(0.08)
                    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 100 } }

                    TileArt {
                        ui: root.ui
                        key: root.settingKey
                        opt: String(modelData)
                        on: tile.on
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: ui.px(12)
                    }
                    Txt {
                        ui: root.ui
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: ui.px(9)
                        width: parent.width - ui.px(12)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.labelFor(modelData)
                        font.pixelSize: ui.fs(10)
                        font.weight: tile.on ? Font.DemiBold : Font.Normal
                        opacity: tile.on ? 1.0 : 0.75
                    }
                    MouseArea {
                        id: tArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.commit(modelData)
                    }
                }
            }
        }

        // color modes (mini switcher in each)
        GridLayout {
            Layout.fillWidth: true
            visible: root.mode === "scheme"
            columns: 4
            columnSpacing: ui.px(8)
            rowSpacing: ui.px(8)

            Repeater {
                model: root.mode === "scheme" ? root.options : []
                delegate: Rectangle {
                    id: stile
                    readonly property string opt: String(modelData)
                    readonly property bool on: root.same(root.current, modelData)
                    readonly property var sc: root.ui.schemeColors(modelData)
                    readonly property bool byCategory: modelData === "category"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: ui.px(76)
                    radius: root.rad(1.4)
                    color: on ? ui.accentTint(0.16) : ui.tint(scArea.containsMouse ? 0.09 : 0.04)
                    border.width: on ? 1.5 : 1
                    border.color: on ? ui.accent : ui.tint(0.08)
                    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 100 } }

                    Rectangle {   // the desktop with three windows on it
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: ui.px(9)
                        width: parent.width - ui.px(18)
                        height: ui.px(32)
                        radius: 4
                        color: stile.sc.bg
                        border.width: 1
                        border.color: ui.tint(0.18)
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    readonly property color c: stile.byCategory ? Qt.hsla(index * 0.29 + 0.05, 0.6, 0.62, 1) : stile.sc.ac
                                    width: 14; height: 10; radius: 2
                                    color: Qt.rgba(stile.sc.fg.r, stile.sc.fg.g, stile.sc.fg.b, 0.22)
                                    border.width: index === 1 || stile.byCategory ? 1.5 : 1
                                    border.color: index === 1 || stile.byCategory ? c
                                        : Qt.rgba(stile.sc.fg.r, stile.sc.fg.g, stile.sc.fg.b, 0.35)
                                }
                            }
                        }
                    }
                    Txt {
                        ui: root.ui
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: ui.px(7)
                        width: parent.width - ui.px(8)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.labelFor(modelData)
                        font.pixelSize: ui.fs(10)
                        font.weight: stile.on ? Font.DemiBold : Font.Normal
                        opacity: stile.on ? 1.0 : 0.75
                    }
                    MouseArea {
                        id: scArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.commit(modelData)
                    }
                }
            }
        }

        // effects, each tile plays it on loop
        GridLayout {
            Layout.fillWidth: true
            visible: root.mode === "effect"
            columns: 4
            columnSpacing: ui.px(8)
            rowSpacing: ui.px(8)

            Repeater {
                model: root.mode === "effect" ? root.options : []
                delegate: Rectangle {
                    id: etile
                    readonly property string opt: String(modelData)
                    readonly property bool on: root.same(root.current, modelData)
                    readonly property bool picking: root.settingKey === "selectEffect"
                    readonly property bool closing: root.settingKey === "closeEffect"
                    // open/close: 0 shown .. 1 gone
                    property real t: 0
                    readonly property var fx: Fx.state(modelData, t, 10)
                    // changing windows: which mini window is selected
                    property int pick: 0
                    readonly property bool live: root.visible && etile.visible && root.opacity > 0.5

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: ui.px(70)
                    radius: root.rad(1.4)
                    color: on ? ui.accentTint(0.16) : ui.tint(efArea.containsMouse ? 0.09 : 0.04)
                    border.width: on ? 1.5 : 1
                    border.color: on ? ui.accent : ui.tint(0.08)
                    Behavior on color { enabled: ui.animations; ColorAnimation { duration: 100 } }

                    SequentialAnimation on t {
                        running: etile.live && !etile.picking
                        loops: Animation.Infinite
                        PauseAnimation { duration: 700 }
                        NumberAnimation {
                            to: 1; duration: 380
                            easing.type: Fx.springy(etile.modelData) ? Easing.InBack : Easing.InCubic
                        }
                        PauseAnimation { duration: 380 }
                        NumberAnimation {
                            to: 0; duration: 380
                            easing.type: Fx.springy(etile.modelData) ? Easing.OutBack : Easing.OutCubic
                            easing.overshoot: 2.2
                        }
                    }
                    Timer {
                        running: etile.live && etile.picking
                        repeat: true
                        interval: 750
                        onTriggered: etile.pick = (etile.pick + 1) % 3
                    }

                    Rectangle {   // a little screen
                        id: screenBox
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: ui.px(7)
                        width: parent.width - ui.px(16)
                        height: ui.px(34)
                        radius: 4
                        color: ui.tint(0.04)
                        border.width: 1
                        border.color: ui.tint(0.10)
                        clip: true

                        Row {
                            id: miniRow
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: etile.picking ? 0 : etile.fx.dx
                            anchors.verticalCenterOffset: etile.picking ? 0 : etile.fx.dy
                            spacing: 4
                            opacity: etile.picking || etile.modelData === "none" ? 1 : Math.max(0, Math.min(1, etile.fx.opacity))
                            transform: Scale {
                                origin.x: miniRow.width / 2
                                origin.y: miniRow.height / 2
                                xScale: etile.picking ? 1 : etile.fx.scale
                                yScale: etile.picking ? 1 : etile.fx.scale * etile.fx.yScale
                            }
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    id: mini
                                    readonly property bool sel: etile.picking ? index === etile.pick : index === 1
                                    property real w: sel ? 1 : 0
                                    Behavior on w {
                                        enabled: etile.picking && etile.modelData !== "none"
                                        NumberAnimation {
                                            duration: etile.modelData === "bounce" ? 380 : 200
                                            easing.type: etile.modelData === "bounce" ? Easing.OutBack : Easing.OutCubic
                                            easing.overshoot: 4
                                        }
                                    }
                                    readonly property var se: Fx.selection(etile.picking ? etile.modelData : "outline", w)
                                    width: 14; height: 10; radius: 2
                                    color: ui.tint(0.30)
                                    border.width: sel ? Math.max(1, se.edge * 0.6) : 1
                                    border.color: sel ? ui.accent : ui.tint(0.18)
                                    scale: se.scale
                                    transform: Translate { y: -mini.se.lift * 0.4 }
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        color: "black"
                                        opacity: mini.sel ? 0 : mini.se.dimOthers
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        radius: parent.radius + 3
                                        color: "transparent"
                                        border.width: 2
                                        border.color: ui.accent
                                        opacity: mini.se.glow * 0.5
                                    }
                                }
                            }
                        }
                    }
                    Txt {
                        ui: root.ui
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: ui.px(6)
                        width: parent.width - ui.px(8)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: root.labelFor(modelData)
                        font.pixelSize: ui.fs(10)
                        font.weight: etile.on ? Font.DemiBold : Font.Normal
                        opacity: etile.on ? 1.0 : 0.75
                    }
                    MouseArea {
                        id: efArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.commit(modelData)
                    }
                }
            }
        }

        // palette: pick bg / text / accent, then swatch or hex
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.kind === "palette"
            spacing: ui.px(10)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ui.px(34)
                radius: root.rad(1.4)
                color: ui.tint(0.05)
                border.width: 1
                border.color: ui.tint(0.08)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 2
                    Repeater {
                        model: root.kind === "palette" ? root.targets : []
                        delegate: Rectangle {
                            id: tg
                            readonly property bool on: index === root.target
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            radius: root.rad(1.1)
                            color: on ? ui.accent : (tgArea.containsMouse ? ui.tint(0.08) : "transparent")
                            Row {
                                anchors.centerIn: parent
                                spacing: ui.px(6)
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: ui.px(11); height: width; radius: width / 2
                                    color: root.colorOf(modelData.key)
                                    border.width: 1
                                    border.color: tg.on ? ui.accentText : ui.tint(0.35)
                                }
                                Txt {
                                    ui: root.ui
                                    text: modelData.label
                                    color: tg.on ? ui.accentText : ui.fg
                                    font.pixelSize: ui.fs(11)
                                    font.weight: tg.on ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: tgArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.target = index
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 8
                columnSpacing: ui.px(8)
                rowSpacing: ui.px(8)
                Repeater {
                    model: root.kind === "palette" ? root.presets : []
                    delegate: Rectangle {
                        readonly property bool on: root.colorOf(root.targetKey).toLowerCase() === String(modelData).toLowerCase()
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: ui.px(24); implicitHeight: implicitWidth
                        radius: width / 2
                        color: modelData
                        border.width: on ? 2 : 1
                        border.color: on ? ui.accent : ui.tint(0.25)
                        scale: swArea.containsMouse ? 1.12 : 1.0
                        Behavior on scale { enabled: ui.animations; NumberAnimation { duration: 90 } }
                        MouseArea {
                            id: swArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.edited({ key: root.targetKey, value: String(modelData).toLowerCase() })
                        }
                    }
                }
            }

            RowLayout {
                spacing: ui.px(8)
                Rectangle {
                    implicitWidth: ui.px(28); implicitHeight: implicitWidth
                    radius: root.rad(1)
                    color: root.colorOf(root.targetKey)
                    border.width: 1
                    border.color: ui.tint(0.25)
                }
                Rectangle {
                    implicitWidth: ui.px(120)
                    implicitHeight: ui.px(28)
                    radius: root.rad(1)
                    color: ui.tint(0.05)
                    border.width: 1
                    border.color: hexBox.activeFocus ? ui.tint(0.28) : ui.tint(0.08)
                    TextBox {
                        id: hexBox
                        ui: root.ui
                        anchors.fill: parent
                        anchors.leftMargin: ui.px(9)
                        anchors.rightMargin: ui.px(9)
                        maximumLength: 7
                        text: root.colorOf(root.targetKey)
                        onEditingFinished: {
                            if (root.validHex(text) && text.toLowerCase() !== root.colorOf(root.targetKey).toLowerCase())
                                root.edited({ key: root.targetKey, value: text.toLowerCase() })
                            else text = root.colorOf(root.targetKey)
                        }
                        Keys.onEscapePressed: { text = root.colorOf(root.targetKey); focus = false }
                        Connections {
                            target: root
                            function onTargetKeyChanged() { hexBox.text = root.colorOf(root.targetKey) }
                            function onCurrentChanged() { hexBox.text = root.colorOf(root.targetKey) }
                        }
                    }
                }
                Txt { ui: root.ui; text: "hex, like #ff6a1f"; font.pixelSize: ui.fs(10); opacity: 0.45 }
            }
        }

        // segmented
        Rectangle {
            Layout.fillWidth: true
            visible: root.mode === "seg"
            implicitHeight: ui.px(38)
            radius: root.rad(1.4)
            color: ui.tint(0.05)
            border.width: 1
            border.color: ui.tint(0.08)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 2

                Repeater {
                    model: root.mode === "seg" ? root.options : []
                    delegate: Rectangle {
                        readonly property bool on: root.same(root.current, modelData)
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        radius: root.rad(1.1)
                        color: on ? ui.accent : (sArea.containsMouse ? ui.tint(0.08) : "transparent")
                        Behavior on color { enabled: ui.animations; ColorAnimation { duration: 90 } }
                        Txt {
                            ui: root.ui
                            anchors.centerIn: parent
                            width: parent.width - ui.px(8)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.labelFor(modelData)
                            color: parent.on ? ui.accentText : ui.fg
                            font.pixelSize: ui.fs(11)
                            font.weight: parent.on ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: sArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.commit(modelData)
                        }
                    }
                }
            }
        }

        // chips
        Flow {
            Layout.fillWidth: true
            visible: root.mode === "chips"
            spacing: ui.px(6)
            Repeater {
                model: root.mode === "chips" ? root.options : []
                delegate: Chip {
                    ui: root.ui
                    label: root.labelFor(modelData)
                    on: root.same(root.current, modelData)
                    onClicked: root.commit(modelData)
                }
            }
        }

        // slider
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.kind === "int"
            spacing: ui.px(2)

            Item {
                id: track
                Layout.fillWidth: true
                implicitHeight: ui.px(24)

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 6; radius: 3
                    color: ui.tint(0.12)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.frac; height: 6; radius: 3
                    color: ui.accent
                }
                Rectangle {   // notch at the default
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * root.defFrac - 1
                    width: 2; height: 12
                    color: ui.tint(0.45)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.frac - width / 2))
                    width: ui.px(16); height: width; radius: width / 2
                    color: ui.accent
                    border.width: 2
                    border.color: ui.surface
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function apply(mx) {
                        var f = Math.max(0, Math.min(1, mx / width))
                        var raw = root.min + f * root.span
                        var snapped = root.min + Math.round((raw - root.min) / root.step) * root.step
                        snapped = Math.max(root.min, Math.min(root.max, snapped))
                        if (snapped !== Number(root.current)) root.commit(snapped)
                    }
                    onPressed: function(m) { apply(m.x) }
                    onPositionChanged: function(m) { if (pressed) apply(m.x) }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Txt { ui: root.ui; text: root.show(root.min); font.pixelSize: ui.fs(9); opacity: 0.5 }
                Item { Layout.fillWidth: true }
                Txt { ui: root.ui; text: root.show(root.max); font.pixelSize: ui.fs(9); opacity: 0.5 }
            }
        }

        // text field
        Rectangle {
            Layout.fillWidth: true
            visible: root.kind === "string" || root.kind === "color"
            implicitHeight: ui.px(34)
            radius: root.rad(1.4)
            color: ui.tint(0.05)
            border.width: 1
            border.color: field.activeFocus ? ui.tint(0.28) : ui.tint(0.08)
            clip: true

            TextBox {
                id: field
                ui: root.ui
                anchors.fill: parent
                anchors.leftMargin: ui.px(12)
                anchors.rightMargin: ui.px(12)
                text: root.str(root.current)
                maximumLength: root.maxLength
                onEditingFinished: {
                    if (root.kind === "color" && !root.validHex(text)) { text = root.str(root.current); return }
                    if (text !== root.str(root.current)) root.commit(text)
                }
                Keys.onEscapePressed: { text = root.str(root.current); focus = false }
                Connections {
                    target: root
                    function onCurrentChanged() { field.text = root.str(root.current) }
                }
            }
        }

        // presets
        Flow {
            Layout.fillWidth: true
            visible: root.kind === "string" && root.presets.length > 0
            spacing: ui.px(6)
            Repeater {
                model: root.kind === "string" ? root.presets : []
                delegate: Chip {
                    ui: root.ui
                    label: String(modelData).trim() === "" ? "(none)" : String(modelData)
                    on: root.same(root.current, modelData)
                    onClicked: root.commit(modelData)
                }
            }
        }

        // swatches
        Flow {
            Layout.fillWidth: true
            visible: root.kind === "color"
            spacing: ui.px(10)
            Repeater {
                model: root.kind === "color" ? root.presets : []
                delegate: Rectangle {
                    readonly property bool on: root.same(root.current, modelData)
                    width: ui.px(28); height: width; radius: width / 2
                    color: modelData
                    border.width: on ? 2 : 1
                    border.color: on ? ui.fg : ui.tint(0.25)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.commit(modelData)
                    }
                }
            }
        }
    }
}
