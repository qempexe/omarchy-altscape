import QtQuick
import Quickshell.Hyprland

// Keep shortcut events on one Wayland connection, in key-event order.
// Separate exec/IPC clients can deliver a quick release before its Tab press.
Item {
    id: root

    visible: false
    property string appid: "io.github.qempexe.altscape"
    signal triggered(string action)

    GlobalShortcut {
        appid: root.appid
        name: "next"
        description: "Altscape: next window"
        onPressed: root.triggered("next")
    }
    GlobalShortcut {
        appid: root.appid
        name: "prev"
        description: "Altscape: previous window"
        onPressed: root.triggered("prev")
    }
    GlobalShortcut {
        appid: root.appid
        name: "release"
        description: "Altscape: switch on modifier release"
        onReleased: root.triggered("release")
    }
}
