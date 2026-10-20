// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Effects

// Frosted-glass background for the context menus: a blurred snapshot of `source` (the content
// behind the menu) under a translucent dark tint. The menu is a popup, so it cannot see what is
// behind it by itself.
Item {
    id: root

    // The menu this is the background of; it tells us when to refresh the snapshot.
    required property var menu
    property Item source: null

    readonly property int cornerRadius: 6

    // The snapshot is blurred at 1/downscale resolution, which multiplies the blur radius.
    readonly property real downscale: 3

    // Points the snapshot at the part of `source` that is behind the menu right now.
    function refresh() {
        if (source) {
            const origin = mapToItem(source, 0, 0);
            snapshot.sourceRect = Qt.rect(origin.x, origin.y, width, height);
        }
    }

    onWidthChanged: refresh()
    onHeightChanged: refresh()

    Connections {
        target: root.menu

        function onAboutToShow() {
            root.refresh();
            Qt.callLater(root.refresh);
        }

        function onOpened() {
            root.refresh();
        }
    }

    // Live copy of the area behind the menu, at reduced size (see `downscale`).
    ShaderEffectSource {
        id: snapshot

        anchors.fill: parent
        sourceItem: root.source
        textureSize: Qt.size(Math.max(1, Math.round(root.width / root.downscale)), Math.max(1, Math.round(root.height / root.downscale)))
        smooth: true
        live: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: snapshot
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        maskEnabled: true
        maskSource: mask
    }

    // Rounds the corners of the blur.
    Rectangle {
        id: mask

        anchors.fill: parent
        radius: root.cornerRadius
        layer.enabled: true
        visible: false
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(0.1, 0.1, 0.13, 0.85)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }
}
