// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Effects

import "code/tools.js" as Tools

// The wallpaper behind the launcher. The sharp image appears first and a blurred copy fades in
// over it, so the desktop never jumps straight to a fully blurred frame.
//
// Blurring a full-screen image on every frame is expensive, so the blurred result is rendered
// once into a texture (`live: false`) and only that texture is animated.
Item {
    id: root

    // Wallpaper file and the size it is decoded at (see Tools.backdropBleed).
    property url source
    property size sourceSize

    // Set to true when the launcher opens: starts the fade-in and the blur.
    property bool blurred: false

    // Positive brightens, negative darkens the blurred copy.
    property real brightness: -0.08

    // 0: only the sharp image, 1: fully blurred.
    property real level: 0

    // The image and the effect are larger than the item by this margin so the blur has real
    // pixels to sample at the edges instead of lightening them.
    readonly property int bleed: Tools.backdropBleed

    // Renders the blur into the cache texture again. It runs twice (now and shortly after)
    // because the image's own texture may not be ready on the first pass.
    function refreshCache() {
        cache.scheduleUpdate();
        settleTimer.restart();
    }

    clip: true
    opacity: blurred ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: root.blurred ? 360 : 220; easing.type: Easing.OutCubic }
    }

    onWidthChanged: refreshCache()
    onHeightChanged: refreshCache()

    onBlurredChanged: {
        if (blurred) {
            level = 0;
            levelAnimation.restart();
        } else {
            levelAnimation.stop();
        }
    }

    // The short pause lets the first frames show the sharp wallpaper before the blur starts.
    SequentialAnimation {
        id: levelAnimation

        PauseAnimation { duration: 90 }
        NumberAnimation { target: root; property: "level"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
    }

    Timer {
        id: settleTimer

        interval: 80
        onTriggered: cache.scheduleUpdate()
    }

    // Sharp wallpaper. Hidden once the blur has fully covered it.
    Image {
        id: image

        x: -root.bleed
        y: -root.bleed
        width: root.width + root.bleed * 2
        height: root.height + root.bleed * 2
        sourceSize: root.sourceSize
        source: root.source
        fillMode: Image.PreserveAspectCrop
        visible: root.level < 1
        opacity: status === Image.Ready ? 1 : 0

        // Fades in if the image finishes loading after the launcher is already open.
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onStatusChanged: {
            if (status === Image.Ready) {
                root.refreshCache();
            }
        }
    }

    // Source of the blur. Never drawn directly: `cache` captures it (hideSource).
    MultiEffect {
        id: blurEffect

        x: image.x
        y: image.y
        width: image.width
        height: image.height
        source: image
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: root.brightness
    }

    // Frozen snapshot of the blur, faded in by `level`.
    ShaderEffectSource {
        id: cache

        x: image.x
        y: image.y
        width: image.width
        height: image.height
        sourceItem: blurEffect
        opacity: root.level
        live: false
        hideSource: true
    }
}
