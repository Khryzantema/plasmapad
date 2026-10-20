// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.core as PlasmaCore

// Default window: a full-screen, background-less Plasma dialog. Unlike Kicker.DashboardWindow it
// does not ask KWin to blur everything behind it, so the desktop stays sharp until the wallpaper
// fades in (and after it fades out). It is kept above other windows and covers the panels.
PlasmaCore.Dialog {
    id: root

    // Same interface as LaunchpadBlurWindow; see LaunchpadContent for what each one is.
    required property var applet
    required property var rootModel
    property var favoritesModel: null
    property var recentModel: null
    property url wallpaper
    property size wallpaperSize
    // Geometry of the screen to cover, in virtual desktop coordinates.
    property rect screenGeometry
    property var usage: ({})
    property real iconScale: 1

    // True from open() until close(); the window stays visible a little longer for the fade-out.
    property bool opened: false

    signal appUsed(string category)

    function open() {
        if (opened) {
            return;
        }
        opened = true;
        visible = true;
    }

    function close() {
        opened = false;
    }

    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Types.NoBackground
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    visible: false

    x: screenGeometry.x
    y: screenGeometry.y

    onVisibleChanged: {
        if (visible) {
            content.prepare();
            requestActivate();
        } else {
            content.reset();
        }
    }

    // The dialog sizes itself from its main item.
    mainItem: Item {
        implicitWidth: root.screenGeometry.width
        implicitHeight: root.screenGeometry.height

        LaunchpadContent {
            id: content

            anchors.fill: parent
            applet: root.applet
            rootModel: root.rootModel
            favoritesModel: root.favoritesModel
            recentModel: root.recentModel
            wallpaper: root.wallpaper
            wallpaperSize: root.wallpaperSize
            usage: root.usage
            iconScale: root.iconScale
            opened: root.opened
            windowActive: root.active

            onCloseRequested: root.close()
            onAppUsed: category => root.appUsed(category)
            onFadedOut: root.visible = false
        }
    }
}
