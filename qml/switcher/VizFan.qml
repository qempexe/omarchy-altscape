import QtQuick

// fan: the windows spread out like a hand of cards, the selected one pulled up
// out of the hand
Item {
    id: view

    property var sw: null
    property real k: 1
    readonly property var ui: sw.ui

    readonly property int n: sw.items.length
    readonly property real titleH: sw.cfg.showTitles ? Math.round(ui.fs(11) * 1.9) : 0
    // degrees between two cards, narrower as the hand fills up
    readonly property real step: n <= 1 ? 0 : Math.min(14, 110 / (n - 1))
    // half the hand's angle, and how far the cards sit from the point they turn around
    readonly property real half: step * Math.max(0, n - 1) / 2 * Math.PI / 180
    readonly property real arm: 2.6
    // Preview size, made smaller until the whole hand fits across and down
    readonly property real cardW: Math.max(56, Math.min(Math.round(sw.cfg.tileSize * k),
        width * 0.92 / (2 * arm * Math.sin(half) + 1.15),
        height * 0.86 / (arm * (1 - Math.cos(half)) + 0.62 * 0.32 + 1.1)))
    readonly property real cardH: Math.round(cardW * 0.62) + titleH
    readonly property real reach: cardW * arm
    readonly property real pull: cardH * 0.32
    // the turning point, below the hand, so the hand sits in the middle
    readonly property real pivotY: height / 2 + (reach + pull + reach * Math.cos(half)) / 2

    Binding { target: view.sw; property: "navCols"; value: 1 }

    Repeater {
        model: view.n
        delegate: WindowCard {
            id: card
            readonly property real deg: (index - (view.n - 1) / 2) * view.step
            readonly property real rad: deg * Math.PI / 180
            readonly property real out: view.reach + (isSelected ? view.pull : 0)
            sw: view.sw
            itemIndex: index
            item: view.sw.items[index] !== undefined ? view.sw.items[index] : null
            width: view.cardW
            height: view.cardH
            showTitle: view.sw.cfg.showTitles
            uniform: view.sw.cfg.equalSizes
            showBadge: true
            iconSize: Math.min(view.sw.cfg.iconSize * view.k, view.cardW * 0.35)
            x: view.width / 2 + Math.sin(rad) * out - width / 2
            y: view.pivotY - Math.cos(rad) * out - height / 2
            rotation: isSelected ? deg * 0.4 : deg
            z: isSelected ? 100 : index
            Behavior on x { enabled: view.ui.animations; NumberAnimation { duration: Math.max(60, view.sw.cfg.speed); easing.type: Easing.OutCubic } }
            Behavior on y { enabled: view.ui.animations; NumberAnimation { duration: Math.max(60, view.sw.cfg.speed); easing.type: Easing.OutCubic } }
            Behavior on rotation { enabled: view.ui.animations; NumberAnimation { duration: Math.max(60, view.sw.cfg.speed); easing.type: Easing.OutCubic } }
        }
    }
}
