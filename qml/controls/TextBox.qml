import QtQuick

// one line text field. typing only, not a TextInput, so no clipboard at all.
// enter or clicking away = done
Item {
    id: field

    property var ui: null
    property string text: ""
    property int maximumLength: 2048
    property int cursor: 0
    property color color: ui ? ui.fg : "white"

    signal editingFinished()

    implicitHeight: label.implicitHeight
    activeFocusOnTab: true
    clip: true

    onActiveFocusChanged: {
        if (activeFocus) cursor = text.length
        else editingFinished()
    }
    onTextChanged: if (cursor > text.length) cursor = text.length

    TextMetrics {
        id: before
        font: label.font
        text: field.text.slice(0, field.cursor)
    }

    Text {
        id: label
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        // keep the caret visible when the text is long
        x: Math.min(0, field.width - 6 - before.advanceWidth)
        text: field.text
        color: field.color
        font.family: field.ui ? field.ui.fontName : ""
        font.pixelSize: field.ui ? field.ui.fs(12) : 12
    }

    Rectangle {   // caret
        visible: field.activeFocus
        x: label.x + before.advanceWidth
        anchors.verticalCenter: parent.verticalCenter
        width: 1.5
        height: label.font.pixelSize + 4
        color: field.color
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: field.forceActiveFocus()
    }

    Keys.onPressed: function(e) {
        const t = field.text, c = field.cursor
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { field.focus = false; e.accepted = true }
        else if (e.key === Qt.Key_Backspace) { if (c > 0) { field.text = t.slice(0, c - 1) + t.slice(c); field.cursor = c - 1 } e.accepted = true }
        else if (e.key === Qt.Key_Delete) { if (c < t.length) field.text = t.slice(0, c) + t.slice(c + 1); e.accepted = true }
        else if (e.key === Qt.Key_Left) { field.cursor = Math.max(0, c - 1); e.accepted = true }
        else if (e.key === Qt.Key_Right) { field.cursor = Math.min(t.length, c + 1); e.accepted = true }
        else if (e.key === Qt.Key_Home) { field.cursor = 0; e.accepted = true }
        else if (e.key === Qt.Key_End) { field.cursor = t.length; e.accepted = true }
        else if ((e.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) === 0
                 && e.text.length === 1 && e.text.charCodeAt(0) >= 32 && e.text.charCodeAt(0) !== 127) {
            if (t.length < field.maximumLength) { field.text = t.slice(0, c) + e.text + t.slice(c); field.cursor = c + 1 }
            e.accepted = true
        }
    }
}
