import QtQuick

// The layer's keyboard-interactivity commit and the Hyprland IPC focus request
// travel over different connections. Retry a rejected request until focus is
// acknowledged, rather than depending on which connection is handled first.
Item {
    id: root
    visible: false

    property string activeAddress: ""
    property string target: ""
    property int remaining: 0
    signal requested(string address)

    function cancel() {
        retry.stop()
        target = ""
        remaining = 0
    }

    function request(address) {
        cancel()
        if (address === activeAddress) return
        target = address
        remaining = 30
        retry.start()
        requested(address)
    }

    onActiveAddressChanged: if (target !== "" && activeAddress === target) cancel()

    Timer {
        id: retry
        interval: 16
        repeat: true
        onTriggered: {
            if (root.target === "" || root.activeAddress === root.target || root.remaining <= 0) {
                root.cancel()
                return
            }
            root.remaining--
            root.requested(root.target)
        }
    }
}
