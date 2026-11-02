import QtQuick
import Quickshell.Wayland

// A window capture shown small without aliasing.
//
// A ScreencopyView drawn straight into a thumbnail samples a 2560 px buffer at
// ~200 px with plain bilinear filtering: most source pixels are skipped, so
// text and thin lines shimmer and break up. Here the capture is drawn
// off-screen at its native size and shown through a mipmapped texture, so the
// GPU averages every pixel it shrinks away.
Item {
    id: root

    property var captureSource: null
    property bool live: false
    // Cap the off-screen texture so a huge window can't eat video memory.
    property int maxTextureSide: 2560

    readonly property bool hasContent: view.hasContent

    readonly property real nativeW: view.hasContent && view.sourceSize.width > 0 ? view.sourceSize.width : Math.max(1, width)
    readonly property real nativeH: view.hasContent && view.sourceSize.height > 0 ? view.sourceSize.height : Math.max(1, height)
    readonly property real capScale: Math.min(1, maxTextureSide / Math.max(nativeW, nativeH))
    // Never render below the size it is shown at.
    readonly property int texW: Math.max(Math.ceil(width), Math.round(nativeW * capScale))
    readonly property int texH: Math.max(Math.ceil(height), Math.round(nativeH * capScale))

    ScreencopyView {
        id: view
        width: root.texW
        height: root.texH
        captureSource: root.captureSource
        live: root.live
    }

    ShaderEffectSource {
        anchors.fill: parent
        sourceItem: view
        hideSource: true
        textureSize: Qt.size(root.texW, root.texH)
        smooth: true
        mipmap: true
    }
}
