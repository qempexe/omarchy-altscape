import QtQuick

// The layer's keyboard-interactivity commit and the Hyprland IPC focus request
// travel over different connections. Retry a rejected request until focus is
// acknowledged, rather than depending on which connection is handled first.
// A queued overlay teardown can then restore the old floating window. Keep
// the request pending until its acknowledgement stays stable for 100 ms.
Item {
    id: root
    visible: false

    property string activeAddress: ""
    property string target: ""
    property int remaining: 0
    signal requested(string address)
    signal acknowledged(string address)

    function cancel() {
        retry.stop()
        settled.stop()
        target = ""
        remaining = 0
    }

    function request(address) {
        cancel()
        target = address
        remaining = 30
        retry.start()
        if (address === activeAddress) {
            acknowledged(address)
            settled.start()
        } else requested(address)
    }

    onActiveAddressChanged: {
        if (target === "") return
        if (activeAddress === target) {
            acknowledged(target)
            settled.restart()
        } else settled.stop()
    }

    Timer {
        id: settled
        interval: 100
        onTriggered: if (root.target !== "" && root.activeAddress === root.target) root.cancel()
    }

    Timer {
        id: retry
        interval: 16
        repeat: true
        onTriggered: {
            if (root.target === "" || root.remaining <= 0) {
                root.cancel()
                return
            }
            root.remaining--
            if (root.activeAddress !== root.target) root.requested(root.target)
        }
    }
}
