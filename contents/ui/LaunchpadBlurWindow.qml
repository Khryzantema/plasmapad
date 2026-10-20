// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.private.kicker as Kicker

// "Blur only" window: Kicker.DashboardWindow, which makes KWin blur the desktop behind it. The
// blur is applied by the compositor, so it appears and disappears at once instead of fading.
// The window is opened with toggle(), which makes it full screen above the panels.
Kicker.DashboardWindow {
    id: root

    // Same interface as LaunchpadDialogWindow; see LaunchpadContent for what each one is.
    required property var applet
    required property var rootModel
    property var favoritesModel: null
    property var recentModel: null
    property url wallpaper
    property size wallpaperSize
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
        if (!visible) {
            toggle();
        }
    }

    function close() {
        opened = false;
    }

    // keyEventProxy: DashboardWindow forwards typed keys to this item, so typing starts a search.
    visualParent: applet
    keyEventProxy: content.searchInput
    backgroundColor: "transparent"
    visible: false

    onVisibleChanged: {
        if (visible) {
            content.prepare();
            requestActivate();
        } else {
            content.reset();
        }
    }

    // DashboardWindow handles Esc itself and reports it through this signal.
    onKeyEscapePressed: {
        if (!content.handleEscape()) {
            close();
        }
    }

    mainItem: LaunchpadContent {
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
        showWallpaper: false
        opened: root.opened
        windowActive: root.active

        onCloseRequested: root.close()
        onAppUsed: category => root.appUsed(category)
        onFadedOut: root.visible = false
    }
}
