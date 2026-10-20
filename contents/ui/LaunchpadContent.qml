// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// Everything inside the launcher window: backdrop, layout, fade and keyboard handling. The window
// itself (LaunchpadDialogWindow or LaunchpadBlurWindow) only decides how it is shown, and calls
// prepare() / reset() when it appears and disappears.
Item {
    id: root

    // Data, passed through from main.qml.
    required property var applet
    required property var rootModel
    property var favoritesModel: null
    property var recentModel: null
    property url wallpaper
    property size wallpaperSize
    property var usage: ({})
    property real iconScale: 1

    // false: no wallpaper image; the blur applied behind the window by KWin shows through a
    // dark tint instead.
    property bool showWallpaper: true

    // State driven by the window.
    property bool opened: false
    property bool windowActive: false

    readonly property alias searchInput: view.searchInput

    // True once the window has been active at least once. Without it, the window not being active
    // yet when it appears would look like having lost focus and close it right away.
    property bool wasActive: false

    // The window must close (Esc, click outside, app launched, focus lost).
    signal closeRequested()

    // An app was launched; `category` is the folder it came from ("" when unknown).
    signal appUsed(string category)

    // The closing fade has finished and the window can be hidden.
    signal fadedOut()

    // Esc closes one layer at a time (search, then folder). Returns false when nothing is left.
    function handleEscape() {
        return view.handleEscape();
    }

    // Called by the window right after it is shown.
    function prepare() {
        wasActive = windowActive;
        view.usage = usage;
        backdrop.refreshCache();
        view.searchInput.forceActiveFocus();
    }

    // Called by the window after it is hidden, so the next opening starts clean.
    function reset() {
        wasActive = false;
        view.reset();
    }

    // Typing anywhere starts a search, even if the search field lost focus (for example after a
    // click on empty space). Shortcuts (Ctrl/Alt/Meta + key) are left alone.
    function typeToSearch(event) {
        const printable = event.text.length > 0 && event.text.charCodeAt(0) >= 32;
        const shortcut = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
        if (printable && !shortcut && !view.searchInput.activeFocus) {
            view.searchInput.forceActiveFocus();
            view.searchInput.insert(view.searchInput.length, event.text);
            event.accepted = true;
        }
    }

    // The whole content fades, with a slight zoom-in that settles at full opacity.
    opacity: opened ? 1 : 0
    scale: 1.04 - 0.04 * opacity
    focus: true

    Behavior on opacity {
        NumberAnimation {
            duration: root.opened ? 200 : 220
            easing.type: root.opened ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpacityChanged: {
        if (opacity === 0 && !opened) {
            fadedOut();
        }
    }

    onWindowActiveChanged: {
        if (windowActive) {
            wasActive = true;
            focusLostTimer.stop();
        } else if (wasActive && opened) {
            focusLostTimer.restart();
        }
    }

    Keys.onEscapePressed: {
        if (!handleEscape()) {
            closeRequested();
        }
    }
    Keys.onPressed: event => typeToSearch(event)

    // Closes the launcher when another window takes over (for example Alt+Tab). The short delay
    // ignores focus changes that come straight back, such as popups.
    Timer {
        id: focusLostTimer

        interval: 150
        onTriggered: {
            if (!root.windowActive) {
                root.closeRequested();
            }
        }
    }

    Backdrop {
        id: backdrop

        anchors.fill: parent
        visible: root.showWallpaper
        source: root.showWallpaper ? root.wallpaper : ""
        sourceSize: root.wallpaperSize
        blurred: root.opened
    }

    // Replaces the wallpaper in "blur only" mode.
    Rectangle {
        anchors.fill: parent
        visible: !root.showWallpaper
        color: Qt.rgba(0.05, 0.05, 0.08, 0.4)
    }

    LaunchpadView {
        id: view

        anchors.fill: parent
        rootModel: root.rootModel
        favoritesModel: root.favoritesModel
        recentModel: root.recentModel
        applet: root.applet
        blurSource: root
        iconScale: root.iconScale

        onCloseRequested: root.closeRequested()
        onAppLaunched: category => {
            root.appUsed(category);
            root.closeRequested();
        }
    }
}
