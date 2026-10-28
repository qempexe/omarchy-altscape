import QtQuick
import QtTest
import "../qml/core"

TestCase {
    id: test
    name: "FocusRequest"
    property var requests: []
    property var acknowledgements: []

    FocusRequest {
        id: focusRequest
        onRequested: function(address) { test.requests = test.requests.concat([address]) }
        onAcknowledged: function(address) { test.acknowledgements = test.acknowledgements.concat([address]) }
    }

    function init() {
        focusRequest.cancel()
        focusRequest.activeAddress = "0xa"
        requests = []
        acknowledgements = []
    }

    function cleanup() { focusRequest.cancel() }

    function test_retriesUntilAcknowledged() {
        focusRequest.request("0xb")
        compare(requests, ["0xb"])
        compare(acknowledgements, [])
        tryVerify(function() { return requests.length >= 2 })
        focusRequest.activeAddress = "0xb"
        compare(acknowledgements, ["0xb"])
        tryCompare(focusRequest, "target", "")
        var count = requests.length
        wait(80)
        compare(requests.length, count)
        compare(focusRequest.target, "")
    }

    function test_retriesAfterTransientAcknowledgement() {
        focusRequest.request("0xb")
        focusRequest.activeAddress = "0xb"
        // The overlay's queued teardown can restore the old floating window
        // just after the requested window briefly receives focus.
        wait(5)
        focusRequest.activeAddress = "0xa"
        var count = requests.length
        tryVerify(function() { return requests.length > count })
        compare(focusRequest.target, "0xb")
        focusRequest.activeAddress = "0xb"
        tryCompare(focusRequest, "target", "")
        compare(acknowledgements, ["0xb", "0xb"])
    }

    function test_newRequestReplacesOldTarget() {
        focusRequest.request("0xb")
        focusRequest.request("0xc")
        requests = []
        tryVerify(function() { return requests.length >= 2 })
        for (var i = 0; i < requests.length; i++) compare(requests[i], "0xc")
    }

    function test_newRequestCancelsPendingAcknowledgement() {
        focusRequest.request("0xb")
        focusRequest.activeAddress = "0xb"
        wait(5)
        focusRequest.request("0xc")
        wait(120)
        compare(focusRequest.target, "0xc")
        compare(requests[requests.length - 1], "0xc")
        focusRequest.activeAddress = "0xc"
        compare(acknowledgements, ["0xb", "0xc"])
    }

    function test_cancelStopsLateFocus() {
        focusRequest.request("0xb")
        focusRequest.cancel()
        focusRequest.activeAddress = "0xb"
        wait(80)
        compare(requests, ["0xb"])
        compare(acknowledgements, [])
    }

    function test_alreadyFocusedDoesNotDispatch() {
        focusRequest.request("0xa")
        wait(80)
        compare(requests, [])
        compare(acknowledgements, ["0xa"])
    }

    function test_alreadyFocusedTargetSurvivesOverlayRestore() {
        focusRequest.request("0xa")
        compare(requests, [])
        wait(5)
        focusRequest.activeAddress = "0xb"
        tryVerify(function() { return requests.length > 0 })
        compare(requests[0], "0xa")
        focusRequest.activeAddress = "0xa"
        compare(acknowledgements, ["0xa", "0xa"])
    }

    function test_unavailableTargetIsBounded() {
        focusRequest.request("0xb")
        tryCompare(focusRequest, "target", "", 1500)
        var count = requests.length
        wait(80)
        compare(requests.length, count)
        focusRequest.activeAddress = "0xb"
        compare(acknowledgements, [])
    }

    function test_replacedTargetIsNotAcknowledged() {
        focusRequest.request("0xb")
        focusRequest.request("0xc")
        focusRequest.activeAddress = "0xb"
        compare(acknowledgements, [])
        focusRequest.activeAddress = "0xc"
        compare(acknowledgements, ["0xc"])
    }
}
